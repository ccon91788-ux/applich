import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../main.dart' show themeMode;
import '../services/backup_service.dart';
import '../services/csv_service.dart';
import '../utils.dart';

const _palette = [
  Colors.teal, Colors.orange, Colors.indigo, Colors.pink, Colors.green,
  Colors.amber, Colors.purple, Colors.brown, Colors.cyan, Colors.red,
];

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<AnalyticsScreen> {
  int r = 0;
  static const _rl = ['Tháng này', 'Tháng trước', '3 tháng', '6 tháng', 'Năm nay'];

  (DateTime, DateTime) _range() {
    final n = DateTime.now();
    switch (r) {
      case 0:
        return (DateTime(n.year, n.month), DateTime(n.year, n.month + 1));
      case 1:
        return (DateTime(n.year, n.month - 1), DateTime(n.year, n.month));
      case 2:
        return (DateTime(n.year, n.month - 2), DateTime(n.year, n.month + 1));
      case 3:
        return (DateTime(n.year, n.month - 5), DateTime(n.year, n.month + 1));
      default:
        return (DateTime(n.year), DateTime(n.year + 1));
    }
  }

  Future<File> _tmp(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    return f.writeAsString(content, encoding: utf8);
  }

  Future<void> _export() async {
    try {
      final s = BackupService.build(await Repo.events(), await Repo.txns());
      final f = await _tmp('LifeSync_Backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json', s);
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) {
      if (mounted) toast(context, 'Không thể xuất sao lưu.');
    }
  }

  Future<void> _csv() async {
    try {
      final f = await _tmp('LifeSync_Transactions_${DateFormat('yyyy-MM').format(DateTime.now())}.csv', CsvService.build(await Repo.txns()));
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) {
      if (mounted) toast(context, 'Không thể xuất CSV.');
    }
  }

  Future<void> _import() async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: true);
      if (res == null || res.files.isEmpty) return;
      final bytes = res.files.first.bytes;
      if (bytes == null) throw const FormatException('empty');
      final data = BackupService.parse(utf8.decode(bytes));
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Khôi phục dữ liệu?'),
          content: Text('Toàn bộ dữ liệu hiện tại sẽ bị thay thế bằng ${data.events.length} sự kiện và ${data.txns.length} giao dịch từ tệp sao lưu.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Khôi phục')),
          ],
        ),
      );
      if (ok != true) return;
      await Repo.restore(data.events, data.txns);
      if (mounted) toast(context, 'Đã khôi phục dữ liệu.');
    } catch (_) {
      if (mounted) toast(context, 'Không thể nhập dữ liệu. Tệp sao lưu không hợp lệ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê & Cài đặt')),
      body: ValueListenableBuilder<int>(
        valueListenable: dataTick,
        builder: (context, _, __) => FutureBuilder<List<Txn>>(
          future: Repo.txns(),
          builder: (context, snap) {
            final (a, b) = _range();
            final all = snap.data ?? <Txn>[];
            final list = all.where((t) => !t.date.isBefore(a) && t.date.isBefore(b)).toList();
            final inc = list.where((t) => t.isIncome).fold<int>(0, (s, t) => s + t.amount);
            final exp = list.where((t) => !t.isIncome).fold<int>(0, (s, t) => s + t.amount);
            final byCat = <String, int>{};
            for (final t in list.where((t) => !t.isIncome)) {
              byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
            }
            final cats = byCat.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: r,
                  decoration: const InputDecoration(labelText: 'Khoảng thời gian', border: OutlineInputBorder()),
                  items: [for (var i = 0; i < _rl.length; i++) DropdownMenuItem(value: i, child: Text(_rl[i]))],
                  onChanged: (v) => setState(() => r = v ?? 0),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng thu: ${fmtMoney(inc)}'),
                        Text('Tổng chi: ${fmtMoney(exp)}'),
                        Text('Số dư / tiết kiệm: ${fmtMoney(inc - exp)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Chi tiêu theo danh mục', style: Theme.of(context).textTheme.titleMedium),
                if (cats.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Chưa có dữ liệu chi tiêu')))
                else ...[
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          for (var i = 0; i < cats.length; i++)
                            PieChartSectionData(
                              value: cats[i].value.toDouble(),
                              color: _palette[i % _palette.length],
                              radius: 70,
                              title: cats[i].value / exp >= 0.05 ? '${(cats[i].value / exp * 100).round()}%' : '',
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  for (var i = 0; i < cats.length; i++)
                    Row(
                      children: [
                        Icon(Icons.square, size: 14, color: _palette[i % _palette.length]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cats[i].key, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(fmtMoney(cats[i].value)),
                      ],
                    ),
                ],
                const SizedBox(height: 16),
                Text('Thu và chi', style: Theme.of(context).textTheme.titleMedium),
                if (inc == 0 && exp == 0)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Chưa có dữ liệu')))
                else
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: max(inc, exp).toDouble() * 1.15,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(v == 0 ? 'Thu' : 'Chi'),
                              ),
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: inc.toDouble(), width: 40, color: Colors.green)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: exp.toDouble(), width: 40, color: Colors.red)]),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 32),
                Text('Giao diện', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeMode,
                  builder: (context, m, _) => SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Hệ thống')),
                      ButtonSegment(value: 1, label: Text('Sáng')),
                      ButtonSegment(value: 2, label: Text('Tối')),
                    ],
                    selected: {m.index},
                    onSelectionChanged: (s) async {
                      themeMode.value = ThemeMode.values[s.first];
                      final sp = await SharedPreferences.getInstance();
                      await sp.setInt('theme', s.first);
                    },
                  ),
                ),
                const Divider(height: 32),
                ListTile(leading: const Icon(Icons.upload_file), title: const Text('Xuất sao lưu (JSON)'), onTap: _export),
                ListTile(leading: const Icon(Icons.download), title: const Text('Nhập / khôi phục sao lưu'), onTap: _import),
                ListTile(leading: const Icon(Icons.table_chart), title: const Text('Xuất giao dịch (CSV)'), onTap: _csv),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../services/quick_input_service.dart';
import '../utils.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  Future<void> _quick(BuildContext context) async {
    final ctl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nhập nhanh'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ví dụ: Chi 50k ăn sáng'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Phân tích')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final r = parseQuick(text);
    // Luôn hiển thị màn hình xác nhận, không tự lưu.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TxnForm(
          initial: Txn(
            isIncome: r.isIncome ?? false,
            amount: r.amount ?? 0,
            category: r.category,
            note: r.note,
            date: DateTime.now(),
          ),
          fromQuick: true,
          uncertain: !r.certain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài chính'),
        actions: [
          IconButton(tooltip: 'Nhập nhanh', icon: const Icon(Icons.bolt), onPressed: () => _quick(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TxnForm())),
        icon: const Icon(Icons.add),
        label: const Text('Giao dịch'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: dataTick,
        builder: (context, _, __) => FutureBuilder<List<Txn>>(
          future: Repo.txns(),
          builder: (context, snap) {
            final list = snap.data ?? <Txn>[];
            final inc = list.where((t) => t.isIncome).fold<int>(0, (a, t) => a + t.amount);
            final exp = list.where((t) => !t.isIncome).fold<int>(0, (a, t) => a + t.amount);
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Số dư'),
                        Text(fmtMoney(inc - exp), style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Thu: ${fmtMoney(inc)}'),
                        Text('Chi: ${fmtMoney(exp)}'),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Chưa có giao dịch nào'))),
                for (final t in list)
                  ListTile(
                    leading: Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                    title: Text(t.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(t.date)}${t.note.isEmpty ? '' : ' • ${t.note}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${t.isIncome ? '+' : '-'}${fmtMoney(t.amount)}'),
                        IconButton(
                          tooltip: 'Xóa giao dịch',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => Repo.deleteTxn(t),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TxnForm(initial: t))),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TxnForm extends StatefulWidget {
  final Txn? initial;
  final bool fromQuick;
  final bool uncertain;
  const TxnForm({super.key, this.initial, this.fromQuick = false, this.uncertain = false});
  @override
  State<TxnForm> createState() => _TxnFormState();
}

class _TxnFormState extends State<TxnForm> {
  late bool income;
  late DateTime date;
  final _amount = TextEditingController();
  final _cat = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    income = t?.isIncome ?? false;
    date = t?.date ?? DateTime.now();
    if (t != null) {
      if (t.amount > 0) _amount.text = '${t.amount}';
      _cat.text = t.category;
      _note.text = t.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _cat.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = int.tryParse(_amount.text);
    if (a == null || a <= 0) {
      toast(context, 'Số tiền không hợp lệ.');
      return;
    }
    final cat = _cat.text.trim().isEmpty ? (income ? 'Thu nhập khác' : 'Chi tiêu khác') : _cat.text.trim();
    final t = widget.initial ?? Txn(isIncome: income, amount: a, category: cat, date: date);
    t.isIncome = income;
    t.amount = a;
    t.category = cat;
    t.note = _note.text.trim();
    t.date = date;
    try {
      await Repo.saveTxn(t);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) toast(context, 'Không thể lưu giao dịch.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = income ? incomeCats : expenseCats;
    return Scaffold(
      appBar: AppBar(title: Text(widget.fromQuick ? 'Xác nhận giao dịch' : 'Giao dịch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.uncertain)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Chưa chắc chắn về kết quả phân tích. Vui lòng kiểm tra lại trước khi lưu.'),
              ),
            ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Chi'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: true, label: Text('Thu'), icon: Icon(Icons.arrow_downward)),
            ],
            selected: {income},
            onSelectionChanged: (s) => setState(() => income = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Số tiền (₫)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(controller: _cat, decoration: const InputDecoration(labelText: 'Danh mục (có thể tự nhập)', border: OutlineInputBorder())),
          Wrap(
            spacing: 8,
            children: [for (final c in cats) ActionChip(label: Text(c), onPressed: () => setState(() => _cat.text = c))],
          ),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder())),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(DateFormat('dd/MM/yyyy').format(date)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) setState(() => date = d);
            },
          ),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Lưu')),
        ],
      ),
    );
  }
}

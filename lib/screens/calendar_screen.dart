import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../utils.dart';

const reminderLabels = {
  -1: 'Không nhắc',
  0: 'Đúng giờ',
  5: 'Trước 5 phút',
  10: 'Trước 10 phút',
  15: 'Trước 15 phút',
  30: 'Trước 30 phút',
  60: 'Trước 1 giờ',
  1440: 'Trước 1 ngày',
};
const repeatLabels = {0: 'Không lặp', 1: 'Mỗi ngày', 2: 'Mỗi tuần', 3: 'Mỗi tháng'};

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarState();
}

class _CalendarState extends State<CalendarScreen> {
  late DateTime month;
  late DateTime sel;

  @override
  void initState() {
    super.initState();
    _go(DateTime.now(), notify: false);
  }

  void _go(DateTime d, {bool notify = true}) {
    void f() {
      sel = DateTime(d.year, d.month, d.day);
      month = DateTime(d.year, d.month);
    }

    notify ? setState(f) : f();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch'),
        actions: [
          IconButton(
            tooltip: 'Hôm nay',
            icon: const Icon(Icons.today),
            onPressed: () => _go(DateTime.now()),
          ),
          IconButton(
            tooltip: 'Chọn ngày',
            icon: const Icon(Icons.event),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: sel,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d != null) _go(d);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventForm(day: sel)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Sự kiện'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: dataTick,
        builder: (context, _, __) => FutureBuilder<List<Event>>(
          future: Repo.events(),
          builder: (context, snap) {
            final evs = snap.data ?? <Event>[];
            final day = evs.where((e) => e.occursOn(sel)).toList()
              ..sort((a, b) => (a.start.hour * 60 + a.start.minute)
                  .compareTo(b.start.hour * 60 + b.start.minute));
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                _header(),
                _grid(evs),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    DateFormat('EEEE, dd/MM/yyyy', 'vi').format(sel),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (day.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Không có sự kiện trong ngày này')),
                  ),
                for (final e in day)
                  ListTile(
                    leading: Text(DateFormat('HH:mm').format(e.start)),
                    title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [
                        if (e.description.isNotEmpty) e.description,
                        repeatLabels[e.repeat] ?? '',
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventForm(ev: e)),
                    ),
                    trailing: IconButton(
                      tooltip: 'Xóa sự kiện',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => Repo.deleteEvent(e),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      IconButton(
        tooltip: 'Tháng trước',
        icon: const Icon(Icons.chevron_left),
        onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)),
      ),
      Expanded(
        child: Center(
          child: Text(
            DateFormat('MMMM yyyy', 'vi').format(month),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Tháng sau',
        icon: const Icon(Icons.chevron_right),
        onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)),
      ),
    ],
  );

  Widget _grid(List<Event> evs) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= days; d++) {
      final date = DateTime(month.year, month.month, d);
      final isSel = date == sel;
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final has = evs.any((e) => e.occursOn(date));
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => sel = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSel ? cs.primaryContainer : null,
              border: isToday ? Border.all(color: cs.primary, width: 2) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FittedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$d', style: TextStyle(fontWeight: isToday ? FontWeight.bold : null)),
                  Icon(Icons.circle, size: 6, color: has ? cs.primary : Colors.transparent),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final w in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
                Expanded(child: Center(child: Text(w))),
            ],
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class EventForm extends StatefulWidget {
  final Event? ev;
  final DateTime? day;
  const EventForm({super.key, this.ev, this.day});
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late DateTime date;
  late TimeOfDay time;
  int rem = 10;
  int rep = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.ev;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description;
      date = DateTime(e.start.year, e.start.month, e.start.day);
      time = TimeOfDay(hour: e.start.hour, minute: e.start.minute);
      rem = e.reminderMin;
      rep = e.repeat;
    } else {
      final d = widget.day ?? DateTime.now();
      date = DateTime(d.year, d.month, d.day);
      time = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      toast(context, 'Vui lòng nhập tiêu đề.');
      return;
    }
    final e = widget.ev ?? Event(title: '', start: date);
    e.title = _title.text.trim();
    e.description = _desc.text.trim();
    e.start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    e.reminderMin = rem;
    e.repeat = rep;
    try {
      await Repo.saveEvent(e);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) toast(context, 'Không thể lưu sự kiện.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ev == null ? 'Thêm sự kiện' : 'Sửa sự kiện')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Chi tiết', border: OutlineInputBorder())),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(DateFormat('dd/MM/yyyy').format(date)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) setState(() => date = d);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(time.format(context)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: time);
              if (t != null) setState(() => time = t);
            },
          ),
          DropdownButtonFormField<int>(
            value: rem,
            decoration: const InputDecoration(labelText: 'Nhắc nhở', border: OutlineInputBorder()),
            items: [for (final e in reminderLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => rem = v ?? rem),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: rep,
            decoration: const InputDecoration(labelText: 'Lặp lại', border: OutlineInputBorder()),
            items: [for (final e in repeatLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => rep = v ?? rep),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Lưu')),
        ],
      ),
    );
  }
}

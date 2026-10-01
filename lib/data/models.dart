class Event {
  int? id;
  String title;
  String description;
  DateTime start;
  int reminderMin; // -1 = không nhắc
  int repeat; // 0 không, 1 ngày, 2 tuần, 3 tháng

  Event({
    this.id,
    required this.title,
    this.description = '',
    required this.start,
    this.reminderMin = -1,
    this.repeat = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'start_ms': start.millisecondsSinceEpoch,
    'reminder_min': reminderMin,
    'repeat': repeat,
  };

  factory Event.fromMap(Map<String, Object?> m) => Event(
    id: (m['id'] as num?)?.toInt(),
    title: (m['title'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    start: DateTime.fromMillisecondsSinceEpoch((m['start_ms'] as num).toInt()),
    reminderMin: (m['reminder_min'] as num?)?.toInt() ?? -1,
    repeat: (m['repeat'] as num?)?.toInt() ?? 0,
  );

  /// Sự kiện lặp lại thật: tính theo quy tắc, không chỉ lưu chữ "weekly".
  bool occursOn(DateTime day) {
    final a = DateTime.utc(start.year, start.month, start.day);
    final b = DateTime.utc(day.year, day.month, day.day);
    if (b.isBefore(a)) return false;
    switch (repeat) {
      case 1:
        return true;
      case 2:
        return b.difference(a).inDays % 7 == 0;
      case 3:
        return b.day == a.day;
      default:
        return b == a;
    }
  }
}

class Txn {
  int? id;
  bool isIncome;
  int amount; // VND, số nguyên
  String category;
  String note;
  DateTime date;

  Txn({
    this.id,
    required this.isIncome,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'type': isIncome ? 'income' : 'expense',
    'amount': amount,
    'category': category,
    'note': note,
    'date_ms': date.millisecondsSinceEpoch,
  };

  factory Txn.fromMap(Map<String, Object?> m) => Txn(
    id: (m['id'] as num?)?.toInt(),
    isIncome: m['type'] == 'income',
    amount: (m['amount'] as num).toInt(),
    category: (m['category'] as String?) ?? '',
    note: (m['note'] as String?) ?? '',
    date: DateTime.fromMillisecondsSinceEpoch((m['date_ms'] as num).toInt()),
  );
}

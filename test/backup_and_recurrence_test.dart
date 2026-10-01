import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/data/models.dart';
import 'package:lifesync/services/backup_service.dart';

void main() {
  test('Backup: export rồi import', () {
    final s = BackupService.build(
      [Event(id: 1, title: 'A', start: DateTime(2026, 10, 1, 19))],
      [Txn(id: 1, isIncome: false, amount: 50000, category: 'Ăn uống', date: DateTime(2026, 10, 1))],
    );
    final d = BackupService.parse(s);
    expect(d.events.single.title, 'A');
    expect(d.txns.single.amount, 50000);
  });
  test('Backup: JSON hỏng / thiếu trường / sai phiên bản', () {
    expect(() => BackupService.parse('không phải json'), throwsFormatException);
    expect(() => BackupService.parse('{"version":1}'), throwsFormatException);
    expect(() => BackupService.parse('{"version":99,"events":[],"transactions":[]}'), throwsFormatException);
    expect(() => BackupService.parse('{"version":1,"events":[{"x":1}],"transactions":[]}'), throwsFormatException);
  });
  test('Sự kiện lặp', () {
    final start = DateTime(2026, 10, 1, 19); // thứ Năm
    Event e(int rep) => Event(title: 'Học Lý', start: start, repeat: rep);
    expect(e(0).occursOn(DateTime(2026, 10, 2)), false);
    expect(e(1).occursOn(DateTime(2026, 10, 2)), true);
    expect(e(2).occursOn(DateTime(2026, 10, 8)), true);
    expect(e(2).occursOn(DateTime(2026, 10, 9)), false);
    expect(e(3).occursOn(DateTime(2026, 11, 1)), true);
    expect(e(1).occursOn(DateTime(2026, 9, 30)), false);
  });
}

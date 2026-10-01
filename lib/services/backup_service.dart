import 'dart:convert';
import '../data/models.dart';

class BackupService {
  static const int version = 1;

  static String build(List<Event> ev, List<Txn> tx) => jsonEncode({
    'app': 'LifeSync',
    'version': version,
    'exported_at': DateTime.now().toIso8601String(),
    'events': ev.map((e) => e.toMap()).toList(),
    'transactions': tx.map((t) => t.toMap()).toList(),
  });

  /// Ném FormatException nếu tệp không hợp lệ.
  static ({List<Event> events, List<Txn> txns}) parse(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map || j['version'] != version) {
        throw const FormatException('version');
      }
      final ev = j['events'];
      final tx = j['transactions'];
      if (ev is! List || tx is! List) throw const FormatException('missing');
      final events = ev.map((e) {
        if (e is! Map || e['title'] is! String || e['start_ms'] is! int) {
          throw const FormatException('event');
        }
        return Event.fromMap(e.cast<String, Object?>());
      }).toList();
      final txns = tx.map((t) {
        if (t is! Map ||
            (t['type'] != 'income' && t['type'] != 'expense') ||
            t['amount'] is! int ||
            (t['amount'] as int) <= 0 ||
            t['date_ms'] is! int) {
          throw const FormatException('txn');
        }
        return Txn.fromMap(t.cast<String, Object?>());
      }).toList();
      return (events: events, txns: txns);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('corrupt');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'notif.dart';

/// Tăng giá trị này để các màn hình tải lại dữ liệu.
final ValueNotifier<int> dataTick = ValueNotifier<int>(0);

class Repo {
  static Database? _d;

  static Future<Database> get _db async =>
      _d ??= await openDatabase(
        p.join(await getDatabasesPath(), 'lifesync.db'),
        version: 1,
        onCreate: (d, v) async {
          await d.execute(
            'CREATE TABLE events(id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title TEXT NOT NULL, description TEXT, start_ms INTEGER NOT NULL, '
            'reminder_min INTEGER NOT NULL, repeat INTEGER NOT NULL)',
          );
          await d.execute(
            'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'type TEXT NOT NULL, amount INTEGER NOT NULL, category TEXT NOT NULL, '
            'note TEXT, date_ms INTEGER NOT NULL)',
          );
        },
      );

  static Future<List<Event>> events() async {
    final rows = await (await _db).query('events', orderBy: 'start_ms');
    return rows.map(Event.fromMap).toList();
  }

  static Future<void> saveEvent(Event e) async {
    final d = await _db;
    if (e.id == null) {
      e.id = await d.insert('events', e.toMap()..remove('id'));
    } else {
      await d.update('events', e.toMap(), where: 'id=?', whereArgs: [e.id]);
    }
    await Notif.schedule(e);
    dataTick.value++;
  }

  static Future<void> deleteEvent(Event e) async {
    if (e.id == null) return;
    await Notif.cancel(e.id!);
    await (await _db).delete('events', where: 'id=?', whereArgs: [e.id]);
    dataTick.value++;
  }

  static Future<List<Txn>> txns() async {
    final rows = await (await _db).query('transactions', orderBy: 'date_ms DESC');
    return rows.map(Txn.fromMap).toList();
  }

  static Future<void> saveTxn(Txn t) async {
    final d = await _db;
    if (t.id == null) {
      t.id = await d.insert('transactions', t.toMap()..remove('id'));
    } else {
      await d.update('transactions', t.toMap(), where: 'id=?', whereArgs: [t.id]);
    }
    dataTick.value++;
  }

  static Future<void> deleteTxn(Txn t) async {
    if (t.id == null) return;
    await (await _db).delete('transactions', where: 'id=?', whereArgs: [t.id]);
    dataTick.value++;
  }

  static Future<void> restore(List<Event> ev, List<Txn> tx) async {
    final d = await _db;
    for (final e in await events()) {
      await Notif.cancel(e.id!);
    }
    await d.transaction((t) async {
      await t.delete('events');
      await t.delete('transactions');
      for (final e in ev) {
        await t.insert('events', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final x in tx) {
        await t.insert('transactions', x.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await Notif.rescheduleAll(await events());
    dataTick.value++;
  }
}

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/reading.dart';

class AppDatabase {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'bp_tracker.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE readings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          systolic INTEGER NOT NULL,
          diastolic INTEGER NOT NULL,
          pulse INTEGER NOT NULL,
          measured_at INTEGER NOT NULL,
          arm TEXT,
          position TEXT,
          tags TEXT,
          note TEXT
        )
      '''),
    );
    return _db!;
  }

  Future<List<Reading>> all() async {
    final db = await _database;
    final rows = await db.query('readings', orderBy: 'measured_at DESC');
    return rows.map(Reading.fromMap).toList();
  }

  Future<int> insert(Reading r) async {
    final db = await _database;
    return db.insert('readings', r.toMap()..remove('id'));
  }

  Future<void> update(Reading r) async {
    final db = await _database;
    await db.update('readings', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('readings', where: 'id = ?', whereArgs: [id]);
  }
}

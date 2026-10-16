import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/money_entry.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stride.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE money_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            is_expense INTEGER NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(MoneyEntry entry) async {
    final db = await database;
    return db.insert('money_entries', entry.toMap());
  }

  Future<List<MoneyEntry>> getEntries() async {
    final db = await database;
    final rows = await db.query('money_entries', orderBy: 'date DESC');
    return rows.map((row) => MoneyEntry.fromMap(row)).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('money_entries', where: 'id = ?', whereArgs: [id]);
  }
}

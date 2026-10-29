import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';
import '../models/money_entry.dart';
import '../models/task_item.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await _createMoneyTable(db);
        await _createTasksTable(db);
        await _createHabitTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTasksTable(db);
        }
        if (oldVersion < 3) {
          await _createHabitTables(db);
        }
      },
    );
  }

  Future<void> _createMoneyTable(Database db) async {
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
  }

  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL,
        due_date TEXT,
        is_done INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createHabitTables(Database db) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_checkins (
        habit_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        PRIMARY KEY (habit_id, day)
      )
    ''');
  }

  // ---------- Money ----------

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

  // ---------- Tasks ----------

  Future<int> insertTask(TaskItem task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<List<TaskItem>> getTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'id DESC');
    return rows.map((row) => TaskItem.fromMap(row)).toList();
  }

  Future<void> setTaskDone(int id, bool done) async {
    final db = await database;
    await db.update(
      'tasks',
      {'is_done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Habits ----------

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final rows = await db.query('habits', orderBy: 'id ASC');
    return rows.map((row) => Habit.fromMap(row)).toList();
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'habit_checkins',
        where: 'habit_id = ?',
        whereArgs: [id],
      );
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Map<int, Set<String>>> getCheckins() async {
    final db = await database;
    final rows = await db.query('habit_checkins');
    final Map<int, Set<String>> result = {};
    for (final row in rows) {
      final habitId = row['habit_id'] as int;
      final day = row['day'] as String;
      result.putIfAbsent(habitId, () => <String>{}).add(day);
    }
    return result;
  }

  Future<void> setCheckin(int habitId, String day, bool done) async {
    final db = await database;
    if (done) {
      await db.insert('habit_checkins', {
        'habit_id': habitId,
        'day': day,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete(
        'habit_checkins',
        where: 'habit_id = ? AND day = ?',
        whereArgs: [habitId, day],
      );
    }
  }
}

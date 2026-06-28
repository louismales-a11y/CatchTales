import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/catch.dart';
import '../models/counter.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bestfishbuddy.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            angler TEXT NOT NULL,
            species TEXT NOT NULL,
            location TEXT DEFAULT '',
            lure TEXT DEFAULT '',
            photo_paths TEXT,
            weight REAL,
            weight_unit TEXT DEFAULT 'kg',
            length REAL,
            length_unit TEXT DEFAULT 'cm',
            latitude REAL,
            longitude REAL,
            weather_temp REAL,
            weather_condition TEXT,
            notes TEXT,
            trip_name TEXT,
            caught_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE counters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            angler TEXT NOT NULL UNIQUE,
            count INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE catches ADD COLUMN photo_paths TEXT');
        }
      },
    );
  }

  // ---- Catches ----

  Future<int> getCatchCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM catches');
    return result.first['c'] as int? ?? 0;
  }

  Future<List<Catch>> getCatches() async {
    final db = await database;
    final maps = await db.query('catches', orderBy: 'created_at DESC');
    return maps.map((m) => Catch.fromMap(m)).toList();
  }

  Future<int> addCatch(Catch c) async {
    final db = await database;
    return await db.insert('catches', c.toMap());
  }

  Future<int> updateCatch(Catch c) async {
    final db = await database;
    return await db.update(
      'catches',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<int> deleteCatch(int id) async {
    final db = await database;
    return await db.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Counters ----

  Future<List<FishCounter>> getCounters() async {
    final db = await database;
    final maps = await db.query('counters', orderBy: 'angler ASC');
    return maps.map((m) => FishCounter.fromMap(m)).toList();
  }

  Future<int> addCounter(String angler) async {
    final db = await database;
    return await db.insert(
      'counters',
      FishCounter(angler: angler).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> incrementCounter(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE counters SET count = count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> decrementCounter(int id) async {
    final db = await database;
    final current =
        await db.query('counters', where: 'id = ?', whereArgs: [id]);
    if (current.isNotEmpty && (current.first['count'] as int) > 0) {
      return await db.rawUpdate(
        'UPDATE counters SET count = count - 1 WHERE id = ?',
        [id],
      );
    }
    return 0;
  }

  Future<void> resetCounters() async {
    final db = await database;
    await db.update('counters', {'count': 0});
  }

  Future<int> deleteCounter(int id) async {
    final db = await database;
    return await db.delete('counters', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Statistics ----

  Future<Map<String, int>> speciesBreakdown() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT species, COUNT(*) as count FROM catches GROUP BY species ORDER BY count DESC');
    return {for (var r in result) r['species'] as String: r['count'] as int};
  }

  Future<Map<String, int>> catchesByMonth() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT strftime('%Y-%m', caught_at) as month, COUNT(*) as count FROM catches GROUP BY month ORDER BY month ASC");
    return {for (var r in result) r['month'] as String: r['count'] as int};
  }

  Future<Map<String, int>> topAnglers({int limit = 5}) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT angler, COUNT(*) as count FROM catches GROUP BY angler ORDER BY count DESC LIMIT ?',
        [limit]);
    return {for (var r in result) r['angler'] as String: r['count'] as int};
  }

  Future<Map<String, int>> topLocations({int limit = 5}) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT location, COUNT(*) as count FROM catches WHERE location != \'\' GROUP BY location ORDER BY count DESC LIMIT ?',
        [limit]);
    return {for (var r in result) r['location'] as String: r['count'] as int};
  }

  Future<Catch?> biggestByWeight() async {
    final db = await database;
    final result = await db.query('catches',
        where: 'weight IS NOT NULL',
        orderBy: 'weight DESC',
        limit: 1);
    if (result.isEmpty) return null;
    return Catch.fromMap(result.first);
  }

  Future<Catch?> biggestByLength() async {
    final db = await database;
    final result = await db.query('catches',
        where: 'length IS NOT NULL',
        orderBy: 'length DESC',
        limit: 1);
    if (result.isEmpty) return null;
    return Catch.fromMap(result.first);
  }
}

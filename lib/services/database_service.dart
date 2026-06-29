import 'dart:ui' show Color;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/catch.dart';
import '../models/counter.dart';
import '../models/favorite_spot.dart';
import '../models/fish_status.dart';
import '../models/fish_data.dart';
import '../data/fish_database.dart';

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
      version: 5,
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
        await db.execute('''
          CREATE TABLE favorite_spots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            notes TEXT,
            best_species TEXT,
            photo_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE catches ADD COLUMN photo_paths TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE favorite_spots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              notes TEXT,
              best_species TEXT,
              photo_path TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE custom_fish (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              scientific_name TEXT DEFAULT '',
              region TEXT DEFAULT 'All',
              size_range TEXT DEFAULT '',
              habitat TEXT DEFAULT '',
              water_type TEXT DEFAULT '',
              diet TEXT DEFAULT '',
              common_tackle TEXT DEFAULT '',
              description TEXT DEFAULT '',
              tips TEXT DEFAULT '',
              color_hex INTEGER DEFAULT 4280391411,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE fish_status (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              species_name TEXT NOT NULL UNIQUE,
              caught_count INTEGER DEFAULT 0,
              is_master INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 5 && oldVersion >= 4) {
          try {
            await db.execute(
              'ALTER TABLE fish_status ADD COLUMN is_favorite INTEGER DEFAULT 0',
            );
          } catch (_) {
            // Column may already exist
          }
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

  /// Get catches for a specific calendar date using date( caught_at ).
  Future<List<Catch>> getCatchesByDate(DateTime date) async {
    final db = await database;
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final maps = await db.query('catches',
        where: "caught_at LIKE ?",
        whereArgs: ['$y-$m-$d%'],
        orderBy: 'caught_at DESC');
    return maps.map((m) => Catch.fromMap(m)).toList();
  }

  /// Returns a map of 'YYYY-MM-DD' → catch count for the given month range.
  Future<Map<String, int>> getCatchCountByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final s = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final e = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT DATE(caught_at) as day, COUNT(*) as count
      FROM catches
      WHERE DATE(caught_at) BETWEEN ? AND ?
      GROUP BY day
      ORDER BY day ASC
    ''', [s, e]);
    return {
      for (var r in result)
        r['day'] as String: (r['count'] as int?) ?? 0
    };
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

  // ---- Favorite Spots ----

  Future<List<FavoriteSpot>> getSpots() async {
    final db = await database;
    final maps = await db.query('favorite_spots', orderBy: 'name ASC');
    return maps.map((m) => FavoriteSpot.fromMap(m)).toList();
  }

  Future<int> addSpot(FavoriteSpot spot) async {
    final db = await database;
    return await db.insert('favorite_spots', spot.toMap());
  }

  Future<int> updateSpot(FavoriteSpot spot) async {
    final db = await database;
    return await db.update(
      'favorite_spots',
      spot.toMap(),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
  }

  Future<int> deleteSpot(int id) async {
    final db = await database;
    return await db.delete('favorite_spots',
        where: 'id = ?', whereArgs: [id]);
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

  // ---- Custom Fish ----

  Future<List<FishSpecies>> getCustomFish() async {
    final db = await database;
    final maps = await db.query('custom_fish', orderBy: 'name ASC');
    return maps.map((m) => _customFishToSpecies(m)).toList();
  }

  FishSpecies _customFishToSpecies(Map<String, dynamic> m) {
    final tipsStr = m['tips'] as String? ?? '';
    final tips = tipsStr.isEmpty ? <String>[] : tipsStr.split('\n');
    return FishSpecies(
      name: m['name'] as String,
      scientificName: m['scientific_name'] as String? ?? '',
      regions: [m['region'] as String? ?? 'All'],
      sizeRange: m['size_range'] as String? ?? '',
      habitat: m['habitat'] as String? ?? '',
      waterType: m['water_type'] as String? ?? '',
      diet: m['diet'] as String? ?? '',
      commonTackle: m['common_tackle'] as String? ?? '',
      description: m['description'] as String? ?? '',
      tips: tips,
      color: Color(m['color_hex'] as int? ?? 0xFF2196F3),
    );
  }

  Map<String, dynamic> _customSpeciesToMap(FishSpecies fish) {
    return {
      'name': fish.name,
      'scientific_name': fish.scientificName,
      'region': fish.regions.isNotEmpty ? fish.regions.first : 'All',
      'size_range': fish.sizeRange,
      'habitat': fish.habitat,
      'water_type': fish.waterType,
      'diet': fish.diet,
      'common_tackle': fish.commonTackle,
      'description': fish.description,
      'tips': fish.tips.join('\n'),
      'color_hex': fish.color.toARGB32(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  Future<int> addCustomFish(FishSpecies fish) async {
    final db = await database;
    final map = _customSpeciesToMap(fish);
    return await db.insert('custom_fish', map);
  }

  Future<int> updateCustomFish(FishSpecies fish, int id) async {
    final db = await database;
    final map = _customSpeciesToMap(fish);
    return await db.update('custom_fish', map,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomFish(int id) async {
    final db = await database;
    return await db.delete('custom_fish', where: 'id = ?', whereArgs: [id]);
  }

  /// Check if a fish name already exists in built-in or custom database.
  Future<bool> isDuplicateFish(String name) async {
    final query = name.trim().toLowerCase();
    // Check built-in
    for (final f in fishDatabase) {
      if (f.name.trim().toLowerCase() == query) return true;
    }
    // Check custom
    final db = await database;
    final result = await db.query('custom_fish',
        where: 'LOWER(name) = ?', whereArgs: [query]);
    return result.isNotEmpty;
  }

  // ---- Fish Status (Caught / Master) ----

  Future<Map<String, FishStatus>> getAllFishStatus() async {
    final db = await database;
    final maps = await db.query('fish_status');
    return {
      for (var m in maps)
        m['species_name'] as String: FishStatus.fromMap(m),
    };
  }

  Future<FishStatus?> getFishStatus(String speciesName) async {
    final db = await database;
    final maps = await db.query('fish_status',
        where: 'species_name = ?', whereArgs: [speciesName]);
    if (maps.isEmpty) return null;
    return FishStatus.fromMap(maps.first);
  }

  Future<void> upsertFishStatus(FishStatus status) async {
    final db = await database;
    await db.insert(
      'fish_status',
      status.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> toggleCaught(String speciesName) async {
    final d = await database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      final newCount = existing.caughtCount > 0 ? 0 : 1;
      await d.update(
        'fish_status',
        {'caught_count': newCount},
        where: 'species_name = ?', whereArgs: [speciesName],
      );
    } else {
      await upsertFishStatus(FishStatus(
        speciesName: speciesName,
        caughtCount: 1,
      ));
    }
  }

  Future<void> toggleMaster(String speciesName) async {
    final d = await database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      await d.update(
        'fish_status',
        {'is_master': existing.isMaster ? 0 : 1},
        where: 'species_name = ?', whereArgs: [speciesName],
      );
    } else {
      await upsertFishStatus(FishStatus(
        speciesName: speciesName,
        isMaster: true,
      ));
    }
  }

  Future<void> toggleFavorite(String speciesName) async {
    final d = await database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      await d.update(
        'fish_status',
        {'is_favorite': existing.isFavorite ? 0 : 1},
        where: 'species_name = ?', whereArgs: [speciesName],
      );
    } else {
      await upsertFishStatus(FishStatus(
        speciesName: speciesName,
        isFavorite: true,
      ));
    }
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

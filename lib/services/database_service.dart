import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
      version: 10,
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
        await db.execute('''
          CREATE TABLE species_tallies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            angler TEXT NOT NULL,
            species TEXT NOT NULL,
            count INTEGER DEFAULT 0,
            sizes TEXT DEFAULT '',
            UNIQUE(angler, species)
          )
        ''');
        await db.execute('''
          CREATE TABLE tackle_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            photo_path TEXT,
            target_species TEXT DEFAULT '',
            tips TEXT DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE depth_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            depth_feet REAL NOT NULL,
            angler TEXT,
            logged_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tackle_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              photo_path TEXT,
              target_species TEXT DEFAULT '',
              tips TEXT DEFAULT '',
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tackle_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              photo_path TEXT,
              target_species TEXT DEFAULT '',
              tips TEXT DEFAULT '',
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS species_tallies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              angler TEXT NOT NULL,
              species TEXT NOT NULL,
              count INTEGER DEFAULT 0,
              sizes TEXT DEFAULT '',
              UNIQUE(angler, species)
            )
          ''');
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE depth_readings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              depth_feet REAL NOT NULL,
              angler TEXT,
              logged_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 9) {
          try {
            await db.execute(
              'ALTER TABLE species_tallies ADD COLUMN sizes TEXT DEFAULT \'\'',
            );
          } catch (_) {}
        }
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
}

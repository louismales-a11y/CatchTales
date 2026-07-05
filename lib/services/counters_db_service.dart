import 'package:sqflite/sqflite.dart';
import '../models/counter.dart';
import 'database_service.dart';

/// Angler counter CRUD.
class CountersDbService {
  static final CountersDbService instance = CountersDbService._();
  CountersDbService._();

  Future<List<FishCounter>> getCounters() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('counters', orderBy: 'angler ASC');
    return maps.map((m) => FishCounter.fromMap(m)).toList();
  }

  Future<int> addCounter(String angler) async {
    final db = await DatabaseService.instance.database;
    return await db.insert(
      'counters',
      FishCounter(angler: angler).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> incrementCounter(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.rawUpdate(
      'UPDATE counters SET count = count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> decrementCounter(int id) async {
    final db = await DatabaseService.instance.database;
    final current = await db.query('counters', where: 'id = ?', whereArgs: [id]);
    if (current.isNotEmpty && (current.first['count'] as int) > 0) {
      return await db.rawUpdate(
        'UPDATE counters SET count = count - 1 WHERE id = ?',
        [id],
      );
    }
    return 0;
  }

  Future<void> resetCounters() async {
    final db = await DatabaseService.instance.database;
    await db.update('counters', {'count': 0});
  }

  Future<int> deleteCounter(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('counters', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete an angler and all their tallies.
  Future<void> deleteAngler(String angler) async {
    final db = await DatabaseService.instance.database;
    await db.delete('species_tallies',
        where: 'angler = ?', whereArgs: [angler]);
    await db.delete('counters',
        where: 'angler = ?', whereArgs: [angler]);
  }
}

import '../models/catch.dart';
import 'database_service.dart';

/// Catch CRUD and catch-related statistics queries.
class CatchesDbService {
  static final CatchesDbService instance = CatchesDbService._();
  CatchesDbService._();

  Future<int> getCatchCount() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM catches');
    return result.first['c'] as int? ?? 0;
  }

  Future<List<Catch>> getCatches() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('catches', orderBy: 'created_at DESC');
    return maps.map((m) => Catch.fromMap(m)).toList();
  }

  Future<List<Catch>> getCatchesByDate(DateTime date) async {
    final db = await DatabaseService.instance.database;
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final maps = await db.query('catches',
        where: "caught_at LIKE ?",
        whereArgs: ['$y-$m-$d%'],
        orderBy: 'caught_at DESC');
    return maps.map((m) => Catch.fromMap(m)).toList();
  }

  Future<Map<String, int>> getCatchCountByDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.instance.database;
    final s = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final e = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT DATE(caught_at) as day, COUNT(*) as count
      FROM catches
      WHERE DATE(caught_at) BETWEEN ? AND ?
      GROUP BY day
      ORDER BY day ASC
    ''', [s, e]);
    return {for (var r in result) r['day'] as String: (r['count'] as int?) ?? 0};
  }

  Future<int> addCatch(Catch c) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('catches', c.toMap());
  }

  Future<int> updateCatch(Catch c) async {
    final db = await DatabaseService.instance.database;
    return await db.update('catches', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCatch(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Statistics ----

  Future<Map<String, int>> speciesBreakdown() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
        'SELECT species, COUNT(*) as count FROM catches GROUP BY species ORDER BY count DESC');
    return {for (var r in result) r['species'] as String: r['count'] as int};
  }

  Future<Map<String, int>> catchesByMonth() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
        "SELECT strftime('%Y-%m', caught_at) as month, COUNT(*) as count FROM catches GROUP BY month ORDER BY month ASC");
    return {for (var r in result) r['month'] as String: r['count'] as int};
  }

  Future<Map<String, int>> topAnglers({int limit = 5}) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
        'SELECT angler, COUNT(*) as count FROM catches GROUP BY angler ORDER BY count DESC LIMIT ?',
        [limit]);
    return {for (var r in result) r['angler'] as String: r['count'] as int};
  }

  Future<Map<String, int>> topLocations({int limit = 5}) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
        'SELECT location, COUNT(*) as count FROM catches WHERE location != \'\' GROUP BY location ORDER BY count DESC LIMIT ?',
        [limit]);
    return {for (var r in result) r['location'] as String: r['count'] as int};
  }

  Future<Catch?> biggestByWeight() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('catches',
        where: 'weight IS NOT NULL',
        orderBy: 'weight DESC',
        limit: 1);
    if (result.isEmpty) return null;
    return Catch.fromMap(result.first);
  }

  Future<Catch?> biggestByLength() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('catches',
        where: 'length IS NOT NULL',
        orderBy: 'length DESC',
        limit: 1);
    if (result.isEmpty) return null;
    return Catch.fromMap(result.first);
  }
}

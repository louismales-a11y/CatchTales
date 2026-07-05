import '../models/depth_reading.dart';
import 'database_service.dart';

/// Depth readings CRUD.
class DepthDbService {
  static final DepthDbService instance = DepthDbService._();
  DepthDbService._();

  Future<List<DepthReading>> getDepthReadings() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('depth_readings', orderBy: 'logged_at DESC');
    return maps.map((m) => DepthReading.fromMap(m)).toList();
  }

  Future<int> addDepthReading(DepthReading r) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('depth_readings', r.toMap());
  }

  Future<int> deleteDepthReading(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('depth_readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDepthReadings() async {
    final db = await DatabaseService.instance.database;
    await db.delete('depth_readings');
  }
}

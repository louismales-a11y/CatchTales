import '../models/favorite_spot.dart';
import 'database_service.dart';

/// Favorite fishing spots CRUD.
class SpotsDbService {
  static final SpotsDbService instance = SpotsDbService._();
  SpotsDbService._();

  Future<List<FavoriteSpot>> getSpots() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('favorite_spots', orderBy: 'name ASC');
    return maps.map((m) => FavoriteSpot.fromMap(m)).toList();
  }

  Future<int> addSpot(FavoriteSpot spot) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('favorite_spots', spot.toMap());
  }

  Future<int> updateSpot(FavoriteSpot spot) async {
    final db = await DatabaseService.instance.database;
    return await db.update('favorite_spots', spot.toMap(),
        where: 'id = ?', whereArgs: [spot.id]);
  }

  Future<int> deleteSpot(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('favorite_spots',
        where: 'id = ?', whereArgs: [id]);
  }
}

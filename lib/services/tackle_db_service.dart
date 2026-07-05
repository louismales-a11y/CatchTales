import '../models/tackle_item.dart';
import 'database_service.dart';

/// Tackle box items CRUD.
class TackleDbService {
  static final TackleDbService instance = TackleDbService._();
  TackleDbService._();

  Future<List<TackleItem>> getTackleItems() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('tackle_items', orderBy: 'created_at DESC');
    return maps.map((m) => TackleItem.fromMap(m)).toList();
  }

  Future<int> getTackleItemCount() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM tackle_items');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> addTackleItem(TackleItem item) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('tackle_items', item.toMap());
  }

  Future<int> updateTackleItem(TackleItem item) async {
    final db = await DatabaseService.instance.database;
    return await db.update('tackle_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteTackleItem(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('tackle_items',
        where: 'id = ?', whereArgs: [id]);
  }
}

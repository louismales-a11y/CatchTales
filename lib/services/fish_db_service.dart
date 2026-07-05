import 'dart:ui' show Color;
import 'package:sqflite/sqflite.dart';
import '../models/fish_data.dart';
import '../models/fish_status.dart';
import '../data/fish_database.dart';
import 'database_service.dart';

/// Custom fish species and fish status (caught/master/favorite).
class FishDbService {
  static final FishDbService instance = FishDbService._();
  FishDbService._();

  /// Convert a custom_fish DB row to FishSpecies.
  FishSpecies _rowToSpecies(Map<String, dynamic> m) {
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

  Map<String, dynamic> _speciesToRow(FishSpecies fish) {
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

  Future<List<FishSpecies>> getCustomFish() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('custom_fish', orderBy: 'name ASC');
    return maps.map((m) => _rowToSpecies(m)).toList();
  }

  Future<int> addCustomFish(FishSpecies fish) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('custom_fish', _speciesToRow(fish));
  }

  Future<int> updateCustomFish(FishSpecies fish, int id) async {
    final db = await DatabaseService.instance.database;
    return await db.update('custom_fish', _speciesToRow(fish),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomFish(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('custom_fish', where: 'id = ?', whereArgs: [id]);
  }

  /// Check if a fish name already exists in built-in or custom database.
  Future<bool> isDuplicateFish(String name) async {
    final query = name.trim().toLowerCase();
    for (final f in fishDatabase) {
      if (f.name.trim().toLowerCase() == query) return true;
    }
    final db = await DatabaseService.instance.database;
    final result = await db.query('custom_fish',
        where: 'LOWER(name) = ?', whereArgs: [query]);
    return result.isNotEmpty;
  }

  // ---- Fish Status ----

  Future<Map<String, FishStatus>> getAllFishStatus() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('fish_status');
    return {for (var m in maps) m['species_name'] as String: FishStatus.fromMap(m)};
  }

  Future<FishStatus?> getFishStatus(String speciesName) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('fish_status',
        where: 'species_name = ?', whereArgs: [speciesName]);
    if (maps.isEmpty) return null;
    return FishStatus.fromMap(maps.first);
  }

  Future<void> upsertFishStatus(FishStatus status) async {
    final db = await DatabaseService.instance.database;
    await db.insert('fish_status', status.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleCaught(String speciesName) async {
    final d = await DatabaseService.instance.database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      final newCount = existing.caughtCount > 0 ? 0 : 1;
      await d.update('fish_status', {'caught_count': newCount},
          where: 'species_name = ?', whereArgs: [speciesName]);
    } else {
      await upsertFishStatus(FishStatus(speciesName: speciesName, caughtCount: 1));
    }
  }

  Future<void> toggleMaster(String speciesName) async {
    final d = await DatabaseService.instance.database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      await d.update('fish_status', {'is_master': existing.isMaster ? 0 : 1},
          where: 'species_name = ?', whereArgs: [speciesName]);
    } else {
      await upsertFishStatus(FishStatus(speciesName: speciesName, isMaster: true));
    }
  }

  Future<void> toggleFavorite(String speciesName) async {
    final d = await DatabaseService.instance.database;
    final existing = await getFishStatus(speciesName);
    if (existing != null) {
      await d.update('fish_status', {'is_favorite': existing.isFavorite ? 0 : 1},
          where: 'species_name = ?', whereArgs: [speciesName]);
    } else {
      await upsertFishStatus(FishStatus(speciesName: speciesName, isFavorite: true));
    }
  }
}

import '../models/species_tally.dart';
import 'database_service.dart';

/// Species tallies for per-angler catch tracking.
class SpeciesTallyDbService {
  static final SpeciesTallyDbService instance = SpeciesTallyDbService._();
  SpeciesTallyDbService._();

  /// Get all tallies grouped by angler.
  Future<List<AnglerBreakdown>> getSpeciesBreakdown() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('species_tallies', orderBy: 'angler ASC, species ASC');

    final Map<String, List<SpeciesTally>> grouped = {};
    for (final row in rows) {
      final tally = SpeciesTally.fromMap(row);
      if (tally.species.isEmpty) continue;
      grouped.putIfAbsent(tally.angler, () => []);
      grouped[tally.angler]!.add(tally);
    }

    final allAnglers = await db.query('counters');
    for (final a in allAnglers) {
      final name = a['angler'] as String;
      grouped.putIfAbsent(name, () => []);
    }

    return grouped.entries.map((e) => AnglerBreakdown(
      angler: e.key,
      total: e.value.fold(0, (sum, t) => sum + t.count),
      species: e.value,
    )).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Increment a species tally for an angler.
  Future<void> incrementSpeciesTally(String angler, String species,
      {double? sizeInches}) async {
    final db = await DatabaseService.instance.database;
    final existing = await db.query('species_tallies',
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, species]);

    if (existing.isEmpty) {
      await db.insert('species_tallies', {
        'angler': angler,
        'species': species,
        'count': 1,
        'sizes': sizeInches != null ? sizeInches.toStringAsFixed(1) : '',
      });
    } else {
      final id = existing.first['id'] as int;
      await db.rawUpdate(
        'UPDATE species_tallies SET count = count + 1 WHERE id = ?', [id]);

      if (sizeInches != null) {
        final currentSizes = existing.first['sizes'] as String? ?? '';
        final sizes = currentSizes.isEmpty
            ? <double>[]
            : currentSizes.split(',').map((s) => double.tryParse(s.trim()) ?? 0).where((d) => d > 0).toList();
        sizes.add(sizeInches);
        sizes.sort((a, b) => b.compareTo(a));
        if (sizes.length > 5) sizes.removeRange(5, sizes.length);
        await db.rawUpdate(
          'UPDATE species_tallies SET sizes = ? WHERE id = ?',
          [sizes.map((s) => s.toStringAsFixed(1)).join(','), id]);
      }
    }
  }

  /// Decrement (or remove) a species tally for an angler.
  Future<void> decrementSpeciesTally(String angler, String species) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('species_tallies',
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, species]);
    if (rows.isEmpty) return;
    final id = rows.first['id'] as int;
    final count = rows.first['count'] as int;
    if (count <= 1) {
      await db.delete('species_tallies',
          where: 'id = ?', whereArgs: [id]);
    } else {
      await db.rawUpdate(
        'UPDATE species_tallies SET count = count - 1 WHERE id = ?',
        [id],
      );
    }
  }

  /// Rename a species for an angler. If [newSpecies] already exists the
  /// counts and sizes are merged into it and the old row is deleted.
  Future<void> renameSpecies(
      String angler, String oldSpecies, String newSpecies) async {
    final db = await DatabaseService.instance.database;
    // Check if target species already exists for this angler
    final existing = await db.query('species_tallies',
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, newSpecies]);
    if (existing.isNotEmpty) {
      // Merge: add counts and sizes from old species into new species
      final oldRow = await db.query('species_tallies',
          where: 'angler = ? AND species = ?',
          whereArgs: [angler, oldSpecies]);
      if (oldRow.isNotEmpty) {
        final oldCount = oldRow.first['count'] as int? ?? 0;
        final oldSizes = oldRow.first['sizes'] as String? ?? '';
        final newCount = existing.first['count'] as int? ?? 0;
        final newSizes = existing.first['sizes'] as String? ?? '';
        // Combine sizes (comma-separated) and let the SpeciesTally trim to 5
        final combined = [newSizes, oldSizes]
            .where((s) => s.isNotEmpty)
            .join(',');
        await db.update(
          'species_tallies',
          {'count': newCount + oldCount, 'sizes': combined},
          where: 'angler = ? AND species = ?',
          whereArgs: [angler, newSpecies],
        );
        // Delete the old species row
        await db.delete('species_tallies',
            where: 'angler = ? AND species = ?',
            whereArgs: [angler, oldSpecies]);
      }
    } else {
      // No conflict — simple rename
      await db.update(
        'species_tallies',
        {'species': newSpecies},
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, oldSpecies],
      );
    }
  }

  Future<void> resetSpeciesTallies() async {
    final db = await DatabaseService.instance.database;
    await db.delete('species_tallies');
  }

  Future<List<String>> getCaughtSpecies() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT species FROM species_tallies ORDER BY species ASC');
    return rows.map((r) => r['species'] as String).toList();
  }
}

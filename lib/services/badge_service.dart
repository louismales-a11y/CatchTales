import '../services/catches_db_service.dart';

/// Achievement badges earned by the user.
class BadgeService {
  static final BadgeService instance = BadgeService._();
  BadgeService._();

  /// Calculate earned badges based on catch data.
  Future<List<Badge>> getBadges() async {
    final db = CatchesDbService.instance;
    final catches = await db.getCatches();
    final speciesSet = catches.map((c) => c.species.toLowerCase()).toSet();
    final speciesCount = speciesSet.length;
    final totalCatches = catches.length;
    final topAnglers = await db.topAnglers();
    final biggest = await db.biggestByWeight();

    final badges = <Badge>[];

    // First Catch
    if (totalCatches >= 1) badges.add(Badge('first_catch', 'First Catch!', 'You caught your first fish', true));

    // Double Digits
    if (totalCatches >= 10) badges.add(Badge('double_digits', 'Double Digits', 'Caught 10 fish total', true));

    // One-Trip Wonder
    final trips = <String>{};
    for (final c in catches) {
      if (c.tripName != null && c.tripName!.isNotEmpty) trips.add(c.tripName!);
    }
    if (catches.length >= 5 && trips.isEmpty) {
      badges.add(Badge('one_trip', 'One-Trip Wonder', 'Caught 5+ fish in a single trip', true));
    }

    // Species Collector
    if (speciesCount >= 3) badges.add(Badge('species_collector', 'Species Collector', 'Caught 3 different species', true));
    if (speciesCount >= 5) badges.add(Badge('species_hunter', 'Species Hunter', 'Caught 5 different species', true));
    if (speciesCount >= 10) badges.add(Badge('species_master', 'Species Master', 'Caught 10 different species', true));

    // Master Angler
    if (totalCatches >= 25) badges.add(Badge('master_angler', 'Master Angler', 'Caught 25 fish total', true));
    if (totalCatches >= 100) badges.add(Badge('legendary', 'Legendary Angler', 'Caught 100 fish total', true));

    // Big Catch
    if (biggest != null && biggest.weight != null && biggest.weight! >= 5) {
      badges.add(Badge('big_catch', 'Big Catch!', 'Caught a 5kg+ fish', true));
    }
    if (biggest != null && biggest.weight != null && biggest.weight! >= 10) {
      badges.add(Badge('monster_catch', 'Monster Catch!', 'Caught a 10kg+ fish', true));
    }

    // Top Rod
    if (topAnglers.isNotEmpty) {
      badges.add(Badge('top_rod', 'Top Rod', 'Leading the leaderboard', true));
    }

    return badges;
  }
}

class Badge {
  final String emoji;
  final String name;
  final String description;
  final bool earned;

  const Badge(this.emoji, this.name, this.description, this.earned);
}

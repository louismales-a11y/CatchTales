import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/catch.dart';

/// Aggregates anonymized catch data from all users for community insights.
///
/// Data stored in Firestore collection `catch_stats`:
///   doc id: "{species}_{state}" (e.g. "Largemouth Bass_Florida")
///   {
///     species: "Largemouth Bass",
///     state: "Florida",
///     country: "USA",
///     totalCatches: 42,
///     lureCounts: { "Spinnerbait": 15, "Plastic Worm": 10 },
///     weatherCounts: { "Clear": 20, "Cloudy": 15 },
///     monthCounts: { "June": 12, "July": 15 },
///     lastUpdated: Timestamp
///   }
///
/// No user IDs, no lat/lng — only species + state + aggregated stats.
class CommunityStatsService {
  static final CommunityStatsService instance = CommunityStatsService._();
  CommunityStatsService._();

  static const _collection = 'catch_stats';

  /// Maximum number of top species to return per state.
  static const int topSpeciesLimit = 30;

  // ─── Reverse Geocode ─────────────────────────────────────────────────

  /// Reverse geocode lat/lng to get state + country using Nominatim (free, no API key).
  /// Returns null if lookup fails.
  Future<Map<String, String>?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${lat.toStringAsFixed(4)}'
          '&lon=${lng.toStringAsFixed(4)}'
          '&format=json'
          '&zoom=5' // zoom 5 = state/province level
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'BestFishBuddy/1.0 (community stats)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final state = address['state'] as String?;
      final countryCode = address['country_code'] as String?;

      if (state == null || countryCode == null) return null;

      String country;
      if (countryCode == 'us') {
        country = 'USA';
      } else if (countryCode == 'ca') {
        country = 'Canada';
      } else {
        return null; // Only USA/Canada for now
      }

      return {'state': state, 'country': country};
    } catch (_) {
      return null; // Silent fail — stats are best-effort
    }
  }

  // ─── Update Stats ────────────────────────────────────────────────────

  /// Update aggregated catch stats in Firestore for this catch.
  /// Returns true if successful.
  Future<bool> updateCatchStats(Catch catchItem) async {
    // Need lat/lng for reverse geocode
    if (catchItem.latitude == null || catchItem.longitude == null) return false;

    try {
      // Reverse geocode to get state
      final geo = await reverseGeocode(
        catchItem.latitude!,
        catchItem.longitude!,
      );
      if (geo == null) return false;

      final state = geo['state']!;
      final country = geo['country']!;
      final species = catchItem.species;
      // Try to get water body name (best-effort, no extra API call — already have lat/lng)
      String? waterBody;
      try {
        waterBody = await _reverseGeocodeWater(catchItem.latitude!, catchItem.longitude!);
      } catch (_) {}
      final docId = waterBody != null && waterBody.isNotEmpty
          ? '${species}_${state.replaceAll(' ', '_')}_${waterBody.replaceAll(' ', '_')}'
          : '${species}_${state.replaceAll(' ', '_')}';

      // Determine lure/bait
      final lure = catchItem.lure.isNotEmpty ? catchItem.lure : 'Unknown';

      // Determine weather
      final weather = catchItem.weatherCondition?.isNotEmpty == true
          ? catchItem.weatherCondition!
          : 'Unknown';

      // Determine month
      final month = _monthName(catchItem.caughtAt.month);

      // Build update map with atomic increments
      final updates = <String, dynamic>{
        'species': species,
        'state': state,
        'country': country,
        'totalCatches': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      if (waterBody != null && waterBody.isNotEmpty) {
        updates['waterBody'] = waterBody;
      };

      // Increment nested counters
      updates['lureCounts.$lure'] = FieldValue.increment(1);
      updates['weatherCounts.$weather'] = FieldValue.increment(1);
      updates['monthCounts.$month'] = FieldValue.increment(1);

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(docId)
          .set(updates, SetOptions(merge: true));

      return true;
    } catch (_) {
      return false; // Silent fail — stats are best-effort
    }
  }

  // ─── Query Stats ─────────────────────────────────────────────────────

  /// Get top species for a given state, sorted by totalCatches descending.
  Future<List<CommunitySpeciesStats>> getTopSpeciesByWater(
      String state, String waterBody) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('state', isEqualTo: state)
          .where('waterBody', isEqualTo: waterBody)
          .orderBy('totalCatches', descending: true)
          .limit(topSpeciesLimit)
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CommunitySpeciesStats(
          species: data['species'] as String? ?? '',
          state: data['state'] as String? ?? '',
          country: data['country'] as String? ?? '',
          totalCatches: (data['totalCatches'] as num?)?.toInt() ?? 0,
          topLures: _topEntries(data['lureCounts'] as Map<String, dynamic>?),
          topWeather: _topEntries(data['weatherCounts'] as Map<String, dynamic>?),
          topMonths: _topEntries(data['monthCounts'] as Map<String, dynamic>?),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get top species for a given state, sorted by totalCatches descending.
  Future<List<CommunitySpeciesStats>> getTopSpecies(String state) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('state', isEqualTo: state)
          .orderBy('totalCatches', descending: true)
          .limit(topSpeciesLimit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CommunitySpeciesStats(
          species: data['species'] as String? ?? '',
          state: data['state'] as String? ?? '',
          country: data['country'] as String? ?? '',
          totalCatches: (data['totalCatches'] as num?)?.toInt() ?? 0,
          topLures: _topEntries(data['lureCounts'] as Map<String, dynamic>?),
          topWeather: _topEntries(data['weatherCounts'] as Map<String, dynamic>?),
          topMonths: _topEntries(data['monthCounts'] as Map<String, dynamic>?),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get stats for a specific species in a specific state.
  Future<CommunitySpeciesStats?> getSpeciesStats(
      String species, String state) async {
    try {
      final docId = '${species}_${state.replaceAll(' ', '_')}';
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(docId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return CommunitySpeciesStats(
        species: data['species'] as String? ?? species,
        state: data['state'] as String? ?? state,
        country: data['country'] as String? ?? '',
        totalCatches: (data['totalCatches'] as num?)?.toInt() ?? 0,
        topLures: _topEntries(data['lureCounts'] as Map<String, dynamic>?),
        topWeather: _topEntries(data['weatherCounts'] as Map<String, dynamic>?),
        topMonths: _topEntries(data['monthCounts'] as Map<String, dynamic>?),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Get sample top species for a given state (used as placeholder when no real data exists).
  List<CommunitySpeciesStats> getSampleTopSpecies(String state) {
    // Sample data for common states — shows what the feature looks like
    final samples = <String, List<CommunitySpeciesStats>>{
      'Florida': [
        _sample('Largemouth Bass', 'Florida', 'USA', 156, ['Spinnerbait', 'Plastic Worm', 'Crankbait'], ['Clear', 'Cloudy', 'Rain'], ['March', 'April', 'May']),
        _sample('Bluegill', 'Florida', 'USA', 89, ['Worms', 'Crickets', 'Small Jigs'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
        _sample('Snook', 'Florida', 'USA', 67, ['Live Bait', 'D.O.A. Shrimp', 'Topwater'], ['Clear', 'Cloudy'], ['April', 'May', 'June']),
        _sample('Redfish (Red Drum)', 'Florida', 'USA', 54, ['Gold Spoon', 'Cut Bait', 'Gulp Shrimp'], ['Cloudy', 'Clear'], ['October', 'November', 'September']),
        _sample('Spotted Seatrout', 'Florida', 'USA', 48, ['Soft Plastic', 'Live Shrimp', 'MirrOLure'], ['Clear', 'Cloudy'], ['March', 'April', 'May']),
        _sample('Tarpon', 'Florida', 'USA', 34, ['Crab Imitation', 'Live Mullet', 'Jig'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Crappie', 'Florida', 'USA', 31, ['Minnows', 'Small Jigs', 'Tiny Spinner'], ['Cloudy', 'Clear'], ['January', 'February', 'March']),
        _sample('Channel Catfish', 'Florida', 'USA', 27, ['Chicken Liver', 'Cut Bait', 'Stink Bait'], ['Cloudy', 'Rain'], ['May', 'June', 'July']),
        _sample('Florida Gar', 'Florida', 'USA', 22, ['Rope Lure', 'Cut Bait', 'Live Minnow'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Bowfin', 'Florida', 'USA', 18, ['Live Minnow', 'Spinnerbait', 'Plastic Worm'], ['Cloudy', 'Clear'], ['April', 'May', 'June']),
      ],
      'Texas': [
        _sample('Largemouth Bass', 'Texas', 'USA', 203, ['Plastic Worm', 'Spinnerbait', 'Crankbait'], ['Clear', 'Cloudy', 'Rain'], ['March', 'April', 'May']),
        _sample('White Bass', 'Texas', 'USA', 87, ['Small Jigs', 'Spinners', 'Live Minnows'], ['Clear', 'Cloudy'], ['March', 'April', 'May']),
        _sample('Channel Catfish', 'Texas', 'USA', 76, ['Cut Bait', 'Chicken Liver', 'Stink Bait'], ['Cloudy', 'Clear'], ['May', 'June', 'July']),
        _sample('Blue Catfish', 'Texas', 'USA', 62, ['Cut Bait', 'Shad', 'Stink Bait'], ['Cloudy', 'Rain'], ['June', 'July', 'August']),
        _sample('Crappie', 'Texas', 'USA', 55, ['Minnows', 'Small Jigs', 'Tiny Spinner'], ['Cloudy', 'Clear'], ['February', 'March', 'April']),
        _sample('Bluegill', 'Texas', 'USA', 48, ['Worms', 'Crickets', 'Poppers'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
        _sample('Spotted Bass', 'Texas', 'USA', 42, ['Jig', 'Plastic Worm', 'Spinnerbait'], ['Clear', 'Cloudy'], ['March', 'April', 'May']),
        _sample('Guadalupe Bass', 'Texas', 'USA', 38, ['Spinnerbait', 'Crankbait', 'Tube Jig'], ['Clear', 'Cloudy'], ['March', 'April', 'May']),
      ],
      'Ontario': [
        _sample('Walleye', 'Ontario', 'Canada', 134, ['Jig + Minnow', 'Bottom Bouncer', 'Crankbait'], ['Cloudy', 'Overcast', 'Clear'], ['June', 'July', 'August']),
        _sample('Smallmouth Bass', 'Ontario', 'Canada', 98, ['Tube Jig', 'Drop-Shot', 'Spinnerbait'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Northern Pike', 'Ontario', 'Canada', 87, ['Spoons', 'Spinnerbaits', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'September']),
        _sample('Lake Trout', 'Ontario', 'Canada', 65, ['Downrigger Spoon', 'Tube Jig', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'October']),
        _sample('Yellow Perch', 'Ontario', 'Canada', 54, ['Minnows', 'Small Jigs', 'Worms'], ['Clear', 'Cloudy'], ['July', 'August', 'September']),
        _sample('Muskellunge (Muskie)', 'Ontario', 'Canada', 43, ['Large Bucktail', 'Jerkbait', 'Topwater'], ['Cloudy', 'Clear'], ['September', 'October', 'August']),
        _sample('Largemouth Bass', 'Ontario', 'Canada', 38, ['Plastic Worm', 'Spinnerbait', 'Frog'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Rainbow Trout', 'Ontario', 'Canada', 31, ['Spoons', 'Spinners', 'Worms'], ['Clear', 'Cloudy'], ['April', 'May', 'June']),
      ],
      'California': [
        _sample('Largemouth Bass', 'California', 'USA', 145, ['Plastic Worm', 'Jig', 'Drop-Shot'], ['Clear', 'Cloudy'], ['March', 'April', 'May']),
        _sample('Rainbow Trout', 'California', 'USA', 98, ['PowerBait', 'Spoons', 'Worms'], ['Clear', 'Cloudy'], ['April', 'May', 'June']),
        _sample('Striped Bass', 'California', 'USA', 67, ['Live Bait', 'Jig', 'Plug'], ['Clear', 'Cloudy'], ['May', 'June', 'October']),
        _sample('Bluegill', 'California', 'USA', 54, ['Worms', 'Crickets', 'Small Jigs'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
        _sample('Channel Catfish', 'California', 'USA', 48, ['Cut Bait', 'Chicken Liver', 'Stink Bait'], ['Cloudy', 'Clear'], ['June', 'July', 'August']),
        _sample('Smallmouth Bass', 'California', 'USA', 36, ['Tube Jig', 'Crankbait', 'Drop-Shot'], ['Clear', 'Cloudy'], ['April', 'May', 'June']),
      ],
      'New York': [
        _sample('Largemouth Bass', 'New York', 'USA', 112, ['Plastic Worm', 'Spinnerbait', 'Frog'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Smallmouth Bass', 'New York', 'USA', 87, ['Tube Jig', 'Drop-Shot', 'Crankbait'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Walleye', 'New York', 'USA', 65, ['Jig + Minnow', 'Crankbait', 'Live Bait'], ['Cloudy', 'Clear'], ['May', 'June', 'October']),
        _sample('Yellow Perch', 'New York', 'USA', 54, ['Minnows', 'Small Jigs', 'Worms'], ['Clear', 'Cloudy'], ['July', 'August', 'September']),
        _sample('Northern Pike', 'New York', 'USA', 43, ['Spoons', 'Spinnerbaits', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'September']),
        _sample('Bluegill', 'New York', 'USA', 38, ['Worms', 'Crickets', 'Poppers'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
      ],
      'British Columbia': [
        _sample('Chinook Salmon (King)', 'British Columbia', 'Canada', 112, ['Spoons', 'Hoochies', 'Cut Plug'], ['Cloudy', 'Clear'], ['July', 'August', 'September']),
        _sample('Coho Salmon (Silver)', 'British Columbia', 'Canada', 87, ['Spoons', 'Jigs', 'Flies'], ['Cloudy', 'Clear'], ['August', 'September', 'October']),
        _sample('Rainbow Trout', 'British Columbia', 'Canada', 76, ['Spoons', 'Spinners', 'Flies'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
        _sample('Halibut (Pacific)', 'British Columbia', 'Canada', 54, ['Herring', 'Jig', 'Octopus'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Lingcod', 'British Columbia', 'Canada', 43, ['Jig', 'Live Bait', 'Iron'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
      ],
      'Michigan': [
        _sample('Walleye', 'Michigan', 'USA', 98, ['Jig + Minnow', 'Bottom Bouncer', 'Crankbait'], ['Cloudy', 'Clear'], ['May', 'June', 'October']),
        _sample('Smallmouth Bass', 'Michigan', 'USA', 87, ['Tube Jig', 'Drop-Shot', 'Crankbait'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Yellow Perch', 'Michigan', 'USA', 76, ['Minnows', 'Small Jigs', 'Worms'], ['Clear', 'Cloudy'], ['July', 'August', 'September']),
        _sample('Largemouth Bass', 'Michigan', 'USA', 65, ['Plastic Worm', 'Spinnerbait', 'Frog'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
        _sample('Northern Pike', 'Michigan', 'USA', 54, ['Spoons', 'Spinnerbaits', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'September']),
        _sample('Lake Trout', 'Michigan', 'USA', 43, ['Downrigger Spoon', 'Jig', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'October']),
      ],
    };
    // Return custom data for known states, or generic data for any other state
    if (samples.containsKey(state)) return samples[state]!;
    // Generic fallback for all other states/provinces
    final country = _canadaStates.contains(state) ? 'Canada' : 'USA';
    return _genericSample(state, country);
  }

  static final _canadaStates = {
    'Ontario', 'Quebec', 'British Columbia', 'Alberta', 'Manitoba',
    'Saskatchewan', 'Nova Scotia', 'New Brunswick', 'Newfoundland and Labrador',
    'Prince Edward Island', 'Northwest Territories', 'Nunavut', 'Yukon',
  };

  static List<CommunitySpeciesStats> _genericSample(String state, String country) {
    return [
      _sample('Largemouth Bass', state, country, 87, ['Plastic Worm', 'Spinnerbait', 'Crankbait'], ['Clear', 'Cloudy'], ['May', 'June', 'July']),
      _sample('Smallmouth Bass', state, country, 65, ['Tube Jig', 'Drop-Shot', 'Spinnerbait'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
      _sample('Walleye', state, country, 54, ['Jig + Minnow', 'Crankbait', 'Live Bait'], ['Cloudy', 'Clear'], ['May', 'June', 'September']),
      _sample('Northern Pike', state, country, 48, ['Spoons', 'Spinnerbaits', 'Live Bait'], ['Clear', 'Cloudy'], ['May', 'June', 'August']),
      _sample('Yellow Perch', state, country, 42, ['Minnows', 'Small Jigs', 'Worms'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
      _sample('Bluegill', state, country, 38, ['Worms', 'Crickets', 'Small Jigs'], ['Clear', 'Cloudy'], ['June', 'July', 'August']),
      _sample('Channel Catfish', state, country, 32, ['Cut Bait', 'Chicken Liver', 'Worms'], ['Cloudy', 'Clear'], ['June', 'July', 'August']),
      _sample('Crappie', state, country, 28, ['Minnows', 'Small Jigs', 'Tiny Spinner'], ['Cloudy', 'Clear'], ['April', 'May', 'June']),
    ];
  }

  static CountEntry _entry(String label, int count) => CountEntry(label, count);

  static CommunitySpeciesStats _sample(
    String species,
    String state,
    String country,
    int total,
    List<String> lures,
    List<String> weather,
    List<String> months,
  ) {
    return CommunitySpeciesStats(
      species: species,
      state: state,
      country: country,
      totalCatches: total,
      topLures: lures.map((l) => _entry(l, (total / (lures.indexOf(l) + 2)).round())).toList(),
      topWeather: weather.map((w) => _entry(w, (total / (weather.indexOf(w) + 2)).round())).toList(),
      topMonths: months.map((m) => _entry(m, (total / (months.indexOf(m) + 2)).round())).toList(),
      isSample: true,
    );
  }

  /// Reverse geocode to get water body name (lake, river, etc.) at zoom 10.
  static Future<String?> _reverseGeocodeWater(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${lat.toStringAsFixed(4)}'
          '&lon=${lng.toStringAsFixed(4)}'
          '&format=json'
          '&zoom=10');
      final response = await http
          .get(url, headers: {'User-Agent': 'BestFishBuddy/1.0'})
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return null;
      for (final key in ['water', 'river', 'lake', 'reservoir', 'bay']) {
        if (address[key] != null) return address[key] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  /// Extract top 3 entries from a counts map sorted by value descending.
  static List<CountEntry> _topEntries(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return [];
    final entries = map.entries
        .map((e) => CountEntry(e.key, (e.value as num?)?.toInt() ?? 0))
        .where((e) => e.count > 0)
        .toList();
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(3).toList();
  }
}

// ─── Data Classes ────────────────────────────────────────────────────────

class CommunitySpeciesStats {
  final String species;
  final String state;
  final String country;
  final int totalCatches;
  final List<CountEntry> topLures;
  final List<CountEntry> topWeather;
  final List<CountEntry> topMonths;
  final bool isSample;

  const CommunitySpeciesStats({
    required this.species,
    required this.state,
    required this.country,
    this.totalCatches = 0,
    this.topLures = const [],
    this.topWeather = const [],
    this.topMonths = const [],
    this.isSample = false,
  });

  bool get hasData => totalCatches > 0;
}

class CountEntry {
  final String label;
  final int count;
  const CountEntry(this.label, this.count);
}

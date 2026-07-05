import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/cache_service.dart';

/// Tide data for a NOAA station.
class TideData {
  final String stationName;
  final List<TideEvent> events;
  final double? currentHeight;

  TideData({
    required this.stationName,
    required this.events,
    this.currentHeight,
  });
}

/// A single tide event (high/low).
class TideEvent {
  final DateTime time;
  final String type; // 'high' or 'low'
  final double height;

  TideEvent({
    required this.time,
    required this.type,
    required this.height,
  });
}

/// Fetches tide predictions from NOAA CO-OPS API.
///
/// Uses nearest station based on lat/lng. Data is cached for 1 hour.
/// NOAA CO-OPS data is public domain — no API key required.
class TideService {
  static final TideService instance = TideService._();
  TideService._();

  /// Find the nearest NOAA tide station and return today's predictions.
  Future<TideData?> getTideData(double lat, double lng) async {
    try {
      // 1. Find nearest station (within 50 km)
      final station = await _findNearestStation(lat, lng);
      if (station == null) return null;

      // 2. Get predictions for today
      final today = DateTime.now();
      final dateStr =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      final cacheKey = 'tide_${station['id']}_$dateStr';

      // Check cache first
      final cached = await CacheService.instance.get<String>(cacheKey,
          maxAge: const Duration(hours: 1));
      if (cached != null) {
        return _parseTideData(station, cached);
      }

      final url =
          'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter'
          '?product=predictions&application=BestFishBuddy'
          '&station=${station['id']}'
          '&begin_date=$dateStr&end_date=$dateStr'
          '&datum=MLLW&time_zone=gmt&units=metric&format=json';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final body = response.body;
      // Cache it
      await CacheService.instance.put(cacheKey, body);
      return _parseTideData(station, body);
    } catch (_) {
      return null; // Graceful degradation
    }
  }

  Future<Map<String, dynamic>?> _findNearestStation(
      double lat, double lng) async {
    final url =
        'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json'
        '?type=tidepredictions';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map;
    final stations = data['stations'] as List? ?? [];

    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final s in stations) {
      final sLat = _parseCoord(s['lat']);
      final sLng = _parseCoord(s['lng']);
      if (sLat == null || sLng == null) continue;

      final dist = _haversine(lat, lng, sLat, sLng);
      if (dist < minDist && dist < 50) {
        // Within 50 km
        minDist = dist;
        nearest = s;
      }
    }
    return nearest;
  }

  TideData _parseTideData(
      Map<String, dynamic> station, String jsonBody) {
    final data = json.decode(jsonBody) as Map;
    final predictions = data['predictions'] as List? ?? [];
    final events = <TideEvent>[];

    for (final p in predictions) {
      final t = p['t'] as String?;
      final v = double.tryParse(p['v'] as String? ?? '');
      if (t == null || v == null) continue;

      // Classify as high/low (will be refined below)
      events.add(TideEvent(
        time: DateTime.parse(t),
        type: events.isEmpty
            ? 'low'
            : (v > events.last.height ? 'high' : 'low'),
        height: v,
      ));
    }

    // Smarter classification: actual highs/lows alternate
    if (events.length > 2) {
      for (int i = 1; i < events.length - 1; i++) {
        final prev = events[i - 1].height;
        final curr = events[i].height;
        final next = events[i + 1].height;
        events[i] = TideEvent(
          time: events[i].time,
          type: (curr > prev && curr > next) ? 'high' : 'low',
          height: curr,
        );
      }
    }

    return TideData(
      stationName: station['name'] as String? ?? 'Unknown',
      events: events,
      currentHeight: events.isNotEmpty ? events.last.height : null,
    );
  }

  double? _parseCoord(dynamic coord) {
    if (coord is num) return coord.toDouble();
    if (coord is String) return double.tryParse(coord);
    return null;
  }

  /// Haversine distance in km between two lat/lng points.
  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return r * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180;
}

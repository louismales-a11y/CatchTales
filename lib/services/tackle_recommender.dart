import '../data/tackle_database.dart';
import '../models/tackle_item.dart';
import '../services/database_service.dart';
/// A suggestion with reasoning.
class TackleSuggestion {
  final String name;
  final String type;
  final String? photoPath;
  final String? imageUrl; // from catalog (Wikipedia)
  final String icon;
  final String tips;
  final double score;
  final List<String> reasons;
  final bool isInMyBox;

  TackleSuggestion({
    required this.name,
    required this.type,
    this.photoPath,
    this.imageUrl,
    required this.icon,
    required this.tips,
    required this.score,
    required this.reasons,
    this.isInMyBox = false,
  });
}

/// Recommends the best tackle for today based on species, season,
/// time of day, and weather.
class TackleRecommender {
  /// Returns ranked suggestions for [targetSpecies].
  ///
  /// [weather] is optional — pass current weather data if available.
  static Future<List<TackleSuggestion>> recommend({
    required String targetSpecies,
    Map<String, dynamic>? weather,
  }) async {
    final now = DateTime.now();

    // ── Context ──
    final season = _getSeason(now);
    final timeOfDay = _getTimeOfDay(now);
    final isOvercast = _isOvercast(weather);
    final isWindy = _isWindy(weather);
    final tempC = weather?['temp'] as double?;
    final isCold = tempC != null && tempC < 12;
    final isWarm = tempC != null && tempC > 25;

    // ── Gather candidate tackle ──

    // 1. From user's tackle box
    final myItems = await DatabaseService.instance.getTackleItems();

    // 2. From catalog (all types that target this species)
    final catalogTypes = tackleTypeDatabase.where(
      (t) => t.targetSpecies.any((s) =>
          s.toLowerCase().contains(targetSpecies.toLowerCase()) ||
          targetSpecies.toLowerCase().contains(s.toLowerCase())),
    ).toList();

    // ── Score each candidate ──
    final suggestions = <TackleSuggestion>[];

    for (final item in myItems) {
      if (!_speciesMatch(item, targetSpecies)) continue;
      final typeInfo = _findTypeInfo(item.type);

      final score = _score(
        typeInfo: typeInfo,
        season: season,
        timeOfDay: timeOfDay,
        isOvercast: isOvercast,
        isWindy: isWindy,
        isCold: isCold,
        isWarm: isWarm,
      );

      final reasons = _buildReasons(
        typeInfo: typeInfo,
        season: season,
        timeOfDay: timeOfDay,
        isOvercast: isOvercast,
        isWindy: isWindy,
        isCold: isCold,
        isWarm: isWarm,
      );

      suggestions.add(TackleSuggestion(
        name: item.name,
        type: item.type,
        photoPath: item.photoPath,
        icon: typeInfo?.icon ?? '🎣',
        tips: item.tips,
        score: score,
        reasons: reasons,
        isInMyBox: true,
      ));
    }

    for (final type in catalogTypes) {
      // Skip if already in user's tackle box (by type match)
      if (myItems.any((i) => i.type == type.name)) continue;

      final score = _score(
        typeInfo: type,
        season: season,
        timeOfDay: timeOfDay,
        isOvercast: isOvercast,
        isWindy: isWindy,
        isCold: isCold,
        isWarm: isWarm,
      );

      final reasons = _buildReasons(
        typeInfo: type,
        season: season,
        timeOfDay: timeOfDay,
        isOvercast: isOvercast,
        isWindy: isWindy,
        isCold: isCold,
        isWarm: isWarm,
      );

      suggestions.add(TackleSuggestion(
        name: type.name,
        type: type.category,
        icon: type.icon,
        tips: type.tips,
        score: score,
        reasons: reasons,
        isInMyBox: false,
      ));
    }

    // Sort by score descending
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  static bool _speciesMatch(TackleItem item, String target) {
    final t = target.toLowerCase();
    return item.targetSpecies
        .any((s) => s.toLowerCase().contains(t) || t.contains(s.toLowerCase()));
  }

  static TackleTypeInfo? _findTypeInfo(String name) {
    try {
      return tackleTypeDatabase.firstWhere(
        (t) => t.name == name || t.category == name,
      );
    } catch (_) {
      return null;
    }
  }

  /// Score 0-10 based on how well conditions match.
  static double _score({
    TackleTypeInfo? typeInfo,
    required String season,
    required String timeOfDay,
    required bool isOvercast,
    required bool isWindy,
    required bool isCold,
    required bool isWarm,
  }) {
    double score = 5.0; // baseline

    if (typeInfo == null) return score;

    // Season match (+2 if matches)
    if (typeInfo.bestSeasons.any((s) => s == season)) {
      score += 2.0;
    } else {
      score -= 1.0;
    }

    // Time of day match (+1.5 if matches)
    if (typeInfo.bestTimeOfDay.any((t) => t == timeOfDay)) {
      score += 1.5;
    }

    // Overcast boosts topwater and spinnerbaits (+1)
    if (isOvercast) {
      if (typeInfo.category == 'Topwater' || typeInfo.category == 'Spinnerbait') {
        score += 1.0;
      }
    }

    // Windy boosts vibration lures (+0.5)
    if (isWindy) {
      if (typeInfo.category == 'Spinnerbait' || typeInfo.category == 'Crankbait') {
        score += 0.5;
      }
    }

    // Cold water boosts slow presentations
    if (isCold) {
      if (typeInfo.name == 'Jig' || typeInfo.name == 'Ned Rig' ||
          typeInfo.name == 'Finesse Jig' || typeInfo.name == 'Live Bait Rig') {
        score += 1.0;
      }
      if (typeInfo.category == 'Topwater') {
        score -= 1.5;
      }
    }

    // Warm water boosts topwater and fast presentations
    if (isWarm) {
      if (typeInfo.category == 'Topwater' || typeInfo.category == 'Spinnerbait') {
        score += 1.0;
      }
    }

    return score.clamp(0, 10);
  }

  static List<String> _buildReasons({
    TackleTypeInfo? typeInfo,
    required String season,
    required String timeOfDay,
    required bool isOvercast,
    required bool isWindy,
    required bool isCold,
    required bool isWarm,
  }) {
    final reasons = <String>[];

    if (typeInfo == null) return reasons;

    if (typeInfo.bestSeasons.any((s) => s == season)) {
      reasons.add('Great for ${_seasonLabel(season)} fishing');
    }

    if (typeInfo.bestTimeOfDay.any((t) => t == timeOfDay)) {
      reasons.add('Ideal for ${_timeLabel(timeOfDay)}');
    }

    if (isOvercast && (typeInfo.category == 'Topwater' || typeInfo.category == 'Spinnerbait')) {
      reasons.add('Overcast = perfect topwater conditions');
    }

    if (isWindy && (typeInfo.category == 'Spinnerbait' || typeInfo.category == 'Crankbait')) {
      reasons.add('Wind chops the surface — vibration lures excel');
    }

    if (isCold && (typeInfo.name == 'Jig' || typeInfo.name == 'Ned Rig' ||
        typeInfo.name == 'Finesse Jig' || typeInfo.name == 'Live Bait Rig')) {
      reasons.add('Cold water calls for slow, subtle presentations');
    }

    if (isWarm && (typeInfo.category == 'Topwater' || typeInfo.category == 'Spinnerbait')) {
      reasons.add('Warm water = active fish, aggressive lures shine');
    }

    if (reasons.isEmpty) {
      reasons.add('Solid all-round choice for this species');
    }

    return reasons;
  }

  static String _getSeason(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'fall';
    return 'winter';
  }

  static String _getTimeOfDay(DateTime date) {
    final h = date.hour;
    if (h >= 5 && h < 8) return 'dawn';
    if (h >= 8 && h < 17) return 'day';
    if (h >= 17 && h < 20) return 'dusk';
    return 'night';
  }

  static bool _isOvercast(Map<String, dynamic>? weather) {
    if (weather == null) return false;
    final cond = (weather['condition'] as String? ?? '').toLowerCase();
    return cond.contains('cloud') || cond.contains('overcast') ||
        cond.contains('rain') || cond.contains('drizzle');
  }

  static bool _isWindy(Map<String, dynamic>? weather) {
    if (weather == null) return false;
    final wind = (weather['wind_speed'] as double? ?? 0);
    return wind > 15;
  }

  static String _seasonLabel(String s) {
    switch (s) {
      case 'spring': return 'spring';
      case 'summer': return 'summer';
      case 'fall': return 'fall';
      case 'winter': return 'winter';
      default: return s;
    }
  }

  static String _timeLabel(String t) {
    switch (t) {
      case 'dawn': return 'early morning';
      case 'day': return 'midday';
      case 'dusk': return 'evening';
      case 'night': return 'night fishing';
      default: return t;
    }
  }
}

import 'dart:math';

class SolunarService {
  /// Returns moon phase info for [date].
  static MoonPhaseInfo getMoonPhase(DateTime date) {
    // Calculate Julian day
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final jd = 1721013.5 +
        367 * y -
        (7 * (y + (m + 9) ~/ 12) / 4).floor() +
        (275 * m / 9).floor() +
        d;

    // Days since known new moon (Jan 6, 2000)
    final daysSinceNew = jd - 2451549.5;
    final lunations = daysSinceNew / 29.53058867;
    final phase = lunations - lunations.floor(); // 0–1

    // Age in days
    final age = phase * 29.53;

    // Illumination
    final illumination = (1 - cos(2 * pi * phase)) / 2;

    // Phase name
    String name;
    if (phase < 0.025 || phase > 0.975) {
      name = 'New Moon';
    } else if (phase < 0.25) {
      name = 'Waxing Crescent';
    } else if (phase < 0.275) {
      name = 'First Quarter';
    } else if (phase < 0.5) {
      name = 'Waxing Gibbous';
    } else if (phase < 0.525) {
      name = 'Full Moon';
    } else if (phase < 0.75) {
      name = 'Waning Gibbous';
    } else if (phase < 0.775) {
      name = 'Third Quarter';
    } else {
      name = 'Waning Crescent';
    }

    return MoonPhaseInfo(
      phase: phase,
      age: age,
      illumination: illumination,
      name: name,
    );
  }

  /// Calculate solunar best fishing times for [date] at [lat], [lng].
  /// Returns major and minor periods.
  static SolunarPeriods getSolunarTimes(DateTime date, double lat, double lng) {
    // Simplified solunar calculation based on moon transit (overhead) and
    // anti-transit (underfoot) times.
    // Major periods: moon overhead & underfoot (~2 hours each)
    // Minor periods: moonrise & moonset (~1 hour each)

    final moonPhase = getMoonPhase(date);

    // Approximate moon overhead time based on moon phase
    // New moon: moon overhead at ~12:00 (noon)
    // Full moon: moon overhead at ~00:00 (midnight)
    final overheadHour = (12.0 + (moonPhase.phase * 24)) % 24;
    final underfootHour = (overheadHour + 12) % 24;

    // Approximate moonrise/set times (simplified)
    // Using phase to estimate: new moon rises at ~6am, full moon at ~6pm
    final moonriseHour = (6.0 + (moonPhase.phase * 12)) % 24;
    final moonsetHour = (moonriseHour + 12) % 24;

    return SolunarPeriods(
      major1Start: _timeOfDay(overheadHour - 1),
      major1End: _timeOfDay(overheadHour + 1),
      major2Start: _timeOfDay(underfootHour - 1),
      major2End: _timeOfDay(underfootHour + 1),
      minor1Start: _timeOfDay(moonriseHour),
      minor1End: _timeOfDay(moonriseHour + 1),
      minor2Start: _timeOfDay(moonsetHour),
      minor2End: _timeOfDay(moonsetHour + 1),
      moonriseHour: moonriseHour,
      moonsetHour: moonsetHour,
    );
  }

  static String _timeOfDay(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, ' ')}:${m.toString().padLeft(2, '0')} $period';
  }
}

class MoonPhaseInfo {
  final double phase; // 0–1 (0 = new, 0.5 = full)
  final double age; // days since new moon
  final double illumination; // 0–1
  final String name;

  const MoonPhaseInfo({
    required this.phase,
    required this.age,
    required this.illumination,
    required this.name,
  });

  /// Unicode moon emoji based on phase
  String get emoji {
    if (phase < 0.025) return '🌑';
    if (phase < 0.25) return '🌒';
    if (phase < 0.275) return '🌓';
    if (phase < 0.5) return '🌔';
    if (phase < 0.525) return '🌕';
    if (phase < 0.75) return '🌖';
    if (phase < 0.775) return '🌗';
    return '🌘';
  }
}

class SolunarPeriods {
  final String major1Start;
  final String major1End;
  final String major2Start;
  final String major2End;
  final String minor1Start;
  final String minor1End;
  final String minor2Start;
  final String minor2End;
  final double moonriseHour;
  final double moonsetHour;

  const SolunarPeriods({
    required this.major1Start,
    required this.major1End,
    required this.major2Start,
    required this.major2End,
    required this.minor1Start,
    required this.minor1End,
    required this.minor2Start,
    required this.minor2End,
    required this.moonriseHour,
    required this.moonsetHour,
  });
}

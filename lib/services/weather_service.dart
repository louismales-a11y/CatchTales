import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const _apiKey = '34dfeae3007957e5d3ba01a471f2bd21';

  /// Current weather at [lat], [lng].
  static Future<Map<String, dynamic>?> fetchWeather(
      double lat, double lng) async {
    try {
      final uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lng&appid=$_apiKey&units=metric');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'temp': (data['main']['temp'] as num).toDouble(),
          'feels_like': (data['main']['feels_like'] as num).toDouble(),
          'temp_min': (data['main']['temp_min'] as num).toDouble(),
          'temp_max': (data['main']['temp_max'] as num).toDouble(),
          'humidity': data['main']['humidity'] as int? ?? 0,
          'pressure': data['main']['pressure'] as int? ?? 0,
          'wind_speed': (data['wind']['speed'] as num?)?.toDouble() ?? 0,
          'condition': data['weather'][0]['description'] as String? ?? '',
          'icon': data['weather'][0]['icon'] as String? ?? '',
          'city': data['name'] as String? ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  /// 5-day / 3-hour forecast at [lat], [lng].
  /// Returns a list of forecast entries grouped by day.
  static Future<List<ForecastDay>?> fetchForecast(
      double lat, double lng) async {
    try {
      final uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast'
          '?lat=$lat&lon=$lng&appid=$_apiKey&units=metric');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final list = data['list'] as List<dynamic>?;
      if (list == null || list.isEmpty) return null;

      // Group by day
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final entry in list) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
            (entry['dt'] as int) * 1000);
        final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

        final main = entry['main'] as Map<String, dynamic>;
        final weather = (entry['weather'] as List<dynamic>?)?.first
            as Map<String, dynamic>?;
        final wind = entry['wind'] as Map<String, dynamic>?;

        grouped.putIfAbsent(dayKey, () => []);
        grouped[dayKey]!.add({
          'dt': dt,
          'temp': (main['temp'] as num).toDouble(),
          'temp_min': (main['temp_min'] as num).toDouble(),
          'temp_max': (main['temp_max'] as num).toDouble(),
          'humidity': main['humidity'] as int? ?? 0,
          'wind_speed': (wind?['speed'] as num?)?.toDouble() ?? 0,
          'condition': weather?['description'] as String? ?? '',
          'icon': weather?['icon'] as String? ?? '',
        });
      }

      final days = grouped.entries.map((e) {
        final entries = e.value;
        final minTemp =
            entries.map((e) => e['temp_min'] as double).reduce(
                (a, b) => a < b ? a : b);
        final maxTemp =
            entries.map((e) => e['temp_max'] as double).reduce(
                (a, b) => a > b ? a : b);
        // Pick the middle entry's icon/condition as representative
        final mid = entries[entries.length ~/ 2];
        return ForecastDay(
          date: mid['dt'] as DateTime,
          condition: mid['condition'] as String,
          icon: mid['icon'] as String,
          tempMin: minTemp,
          tempMax: maxTemp,
          humidity: (entries.map((e) => e['humidity'] as int).reduce(
              (a, b) => (a + b) ~/ 2)),
          windSpeed: (entries
                  .map((e) => e['wind_speed'] as double)
                  .reduce((a, b) => a + b)) /
              entries.length,
        );
      }).toList();

      return days;
    } catch (_) {
      return null;
    }
  }
}

class ForecastDay {
  final DateTime date;
  final String condition;
  final String icon;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;

  const ForecastDay({
    required this.date,
    required this.condition,
    required this.icon,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
  });

  String get dayName {
    final now = DateTime.now();
    final diff = date.day - now.day;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$icon@2x.png';
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const _apiKey = '34dfeae3007957e5d3ba01a471f2bd21';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>?> fetchWeather(
      double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = (data['main']['temp'] as num).toDouble();
        final condition = data['weather'][0]['description'] as String? ?? '';
        final icon = data['weather'][0]['icon'] as String? ?? '';
        return {
          'temp': temp,
          'condition': condition,
          'icon': icon,
        };
      }
    } catch (_) {}
    return null;
  }
}

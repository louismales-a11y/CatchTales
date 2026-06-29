import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches Wikipedia images for tackle / lure types.
/// Results are cached in memory so each type is fetched at most once per session.
class TackleImageService {
  static final Map<String, String?> _cache = {};

  /// Returns the best Wikipedia thumbnail URL for a lure type (e.g. "Spinnerbait").
  /// Returns `null` if no image could be found.
  static Future<String?> getImageUrl(String query) async {
    final key = query.trim().toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];

    const headers = {
      'User-Agent': 'BestFishBuddy/1.0 (fishing-log-app)',
      'Accept': 'application/json',
    };

    try {
      final title = query.replaceAll(' ', '_');
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/$title');
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final thumb = data['thumbnail'] as Map<String, dynamic>?;
        if (thumb != null && thumb['source'] is String) {
          final url = thumb['source'] as String;
          _cache[key] = url;
          return url;
        }
      }
    } catch (_) {}

    _cache[key] = null;
    return null;
  }

  /// Clear the in-memory cache.
  static void clearCache() => _cache.clear();
}

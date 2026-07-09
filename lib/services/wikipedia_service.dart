import 'dart:convert';
import 'package:http/http.dart' as http;

/// Structured fish info returned from a Wikipedia lookup.
class WikipediaFishInfo {
  final String? scientificName;
  final String? description;
  final String? imageUrl;

  WikipediaFishInfo({
    this.scientificName,
    this.description,
    this.imageUrl,
  });
}

/// Fetches fish information from Wikipedia's free REST API.
/// No API key required.
class WikipediaService {
  static const _headers = {
    'User-Agent': 'CatchTales/1.0 (fishing-log-app)',
    'Accept': 'application/json',
  };

  /// Looks up [query] (common fish name) on Wikipedia and returns info.
  /// Returns `null` when the page doesn't exist or the request fails.
  static Future<WikipediaFishInfo?> fetchFishInfo(String query) async {
    try {
      final title = query.trim().replaceAll(' ', '_');
      final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$title',
      );
      final resp = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 8),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return WikipediaFishInfo(
          scientificName: data['title'] as String?,
          description: data['extract'] as String?,
          imageUrl:
              (data['thumbnail'] as Map<String, dynamic>?)?['source']
                  as String?,
        );
      }
    } catch (_) {}
    return null;
  }
}

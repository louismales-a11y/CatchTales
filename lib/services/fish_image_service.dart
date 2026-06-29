import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches fish images from Wikipedia (Wikimedia Commons) using the free
/// REST API. No API key required — just the fish's scientific or common name.
///
/// Results are cached in memory so each species is fetched at most once
/// per app session.
class FishImageService {
  // ── In-memory URL cache ──────────────────────────────────────────────
  static final Map<String, String?> _urlCache = {};
  static final Map<String, String?> _pageTitleCache = {};
  /// Returns the best Wikipedia article image URL for a fish species.
  ///
  /// Tries [scientificName] first (which usually redirects to the article),
  /// falls back to [commonName] on 404.
  ///
  /// Returns `null` when no image could be found.
  static Future<String?> getImageUrl({
    required String commonName,
    required String scientificName,
  }) async {
    final key = scientificName;
    if (_urlCache.containsKey(key)) return _urlCache[key];

    // Try scientific name first — most precise
    String? url = await _fetchThumbnail(scientificName);
    if (url == null && commonName.isNotEmpty) {
      url = await _fetchThumbnail(commonName);
    }

    _urlCache[key] = url;
    return url;
  }

  /// Returns the Wikipedia page title for a fish (for linking).
  static Future<String?> getPageTitle(String scientificName) async {
    final key = scientificName;
    if (_pageTitleCache.containsKey(key)) return _pageTitleCache[key];

    try {
      final title = scientificName.replaceAll(' ', '_');
      final resp = await http.get(
        Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$title'),
        headers: _headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final pageTitle = data['title'] as String?;
        _pageTitleCache[key] = pageTitle;
        return pageTitle;
      }
    } catch (_) {}
    return null;
  }

  // ── Internals ────────────────────────────────────────────────────────

  static final _headers = {
    'User-Agent': 'BestFishBuddy/1.0 (fishing-log-app)',
    'Accept': 'application/json',
  };

  static Future<String?> _fetchThumbnail(String query) async {
    try {
      final title = query.replaceAll(' ', '_');
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/$title');
      final resp = await http.get(uri, headers: _headers);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final thumb = data['thumbnail'] as Map<String, dynamic>?;
        if (thumb != null && thumb['source'] is String) {
          return thumb['source'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Clears the in-memory cache (e.g. on refresh).
  static void clearCache() {
    _urlCache.clear();
    _pageTitleCache.clear();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Fetches fish images from Wikipedia (Wikimedia Commons) using the free
/// REST API. No API key required.
///
/// Images are cached to local storage so each species is fetched at most
/// once — surviving app restarts.
class FishImageService {
  // ── In-memory path cache ─────────────────────────────────────────────
  static final Map<String, String?> _pathCache = {};
  static final Map<String, String?> _pageTitleCache = {};

  /// Returns the **local file path** of the best Wikipedia image for a fish.
  ///
  /// Tries [scientificName] first, falls back to [commonName] on 404.
  /// Downloads the image once and caches it to [cacheDir]/fish_images/.
  ///
  /// Returns `null` when no image could be found.
  static Future<String?> getImagePath({
    required String commonName,
    required String scientificName,
  }) async {
    final key = scientificName;
    if (_pathCache.containsKey(key)) return _pathCache[key];

    // Check if already cached on disk
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, '${_sanitise(key)}.jpg'));
    if (await file.exists()) {
      _pathCache[key] = file.path;
      return file.path;
    }

    // Get the image URL from Wikipedia
    String? url = await _fetchThumbnailUrl(scientificName);
    if (url == null && commonName.isNotEmpty) {
      url = await _fetchThumbnailUrl(commonName);
    }

    if (url == null) {
      _pathCache[key] = null;
      return null;
    }

    // Download and cache the image
    try {
      final imgResp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (imgResp.statusCode == 200) {
        await file.create(recursive: true);
        await file.writeAsBytes(imgResp.bodyBytes);
        _pathCache[key] = file.path;
        return file.path;
      }
    } catch (_) {}

    // Fall back to the URL if caching fails
    return url;
  }

  /// Returns the Wikipedia page title for a fish (for linking).
  static Future<String?> getPageTitle(String scientificName) async {
    final key = scientificName;
    if (_pageTitleCache.containsKey(key)) return _pageTitleCache[key];

    try {
      final title = scientificName.replaceAll(' ', '_');
      final resp = await http
          .get(
            Uri.parse(
                'https://en.wikipedia.org/api/rest_v1/page/summary/$title'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final pageTitle = data['title'] as String?;
        _pageTitleCache[key] = pageTitle;
        return pageTitle;
      }
    } catch (_) {}
    return null;
  }

  /// Clears both in-memory and on-disk caches.
  static Future<void> clearCache() async {
    _pathCache.clear();
    _pageTitleCache.clear();
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // ── Internals ────────────────────────────────────────────────────────

  static final _headers = {
    'User-Agent': 'BestFishBuddy/1.0 (fishing-log-app)',
    'Accept': 'application/json',
  };

  /// Sanitises a string for use as a file name.
  static String _sanitise(String s) =>
      s.replaceAll(RegExp(r'[^\w\-]'), '_').toLowerCase();

  /// Returns the cache subdirectory for fish images.
  static Future<Directory> _cacheDir() async {
    final appDir = await getTemporaryDirectory();
    final dir = Directory(p.join(appDir.path, 'fish_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String?> _fetchThumbnailUrl(String query) async {
    try {
      final title = query.replaceAll(' ', '_');
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/$title');
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

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
}

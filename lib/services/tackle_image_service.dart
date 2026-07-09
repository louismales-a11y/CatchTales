import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches free images for tackle / lure types from Wikipedia.
/// Results are cached in memory so each type is fetched at most once per session.
class TackleImageService {
  static final Map<String, String?> _cache = {};

  /// Returns the best image URL for a lure type.
  /// Returns `null` if no image could be found.
  static Future<String?> getImageUrl(String query) async {
    final key = query.trim().toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];

    final url = await _searchWikipedia(key);
    _cache[key] = url;
    return url;
  }

  /// Search Wikipedia for a page about this lure, get its thumbnail image.
  static Future<String?> _searchWikipedia(String query) async {
    const headers = {
      'User-Agent': 'CatchTales/1.0 (fishing-log-app)',
      'Accept': 'application/json',
    };

    // Step 1: Search Wikipedia for pages matching this lure
    final searchQuery = _searchQuery(query);
    
    try {
      final searchUri = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query'
          '&list=search&srwhat=text&srsearch=${Uri.encodeComponent(searchQuery)}'
          '&format=json&srlimit=5');
      final resp = await http
          .get(searchUri, headers: headers)
          .timeout(const Duration(seconds: 8));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = data['query']?['search'] as List?;
        
        if (results != null && results.isNotEmpty) {
          // Step 2: Try each result page to find one with a thumbnail
          for (final result in results) {
            final pageTitle = result['title'] as String;
            final thumb = await _getPageThumbnail(pageTitle, headers);
            if (thumb != null) return thumb;
          }
        }
      }
    } catch (_) {}

    // Step 3: Try direct page access as fallback
    final directTerms = _directTerms(query);
    for (final term in directTerms) {
      final thumb = await _getPageThumbnail(term, headers);
      if (thumb != null) return thumb;
    }

    return null;
  }

  /// Get the thumbnail URL for a Wikipedia page.
  static Future<String?> _getPageThumbnail(
      String title, Map<String, String> headers) async {
    try {
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/'
          '${Uri.encodeComponent(title)}');
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 6));
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

  /// Create a good search query for this lure type.
  static String _searchQuery(String query) {
    final lower = query.toLowerCase();
    // Add context for better results
    if (lower.contains('lure') || lower.contains('bait') || lower.contains('rig')) {
      return '$query fishing';
    }
    return '$query fishing lure';
  }

  /// Direct page titles that might have images (used as fallback).
  static List<String> _directTerms(String query) {
    final lower = query.toLowerCase();
    final map = <String, List<String>>{
      'spinnerbait': ['Spinnerbait'],
      'buzzbait': ['Buzzbait'],
      'crankbait': ['Crankbait'],
      'lipless crankbait': ['Lipless crankbait'],
      'jig': ['Fishing jig', 'Jig (fishing lure)'],
      'football jig': ['Football jig'],
      'finesse jig': ['Finesse jig'],
      'plastic worm': ['Soft plastic bait'],
      'soft plastic jerkbait': ['Soft plastic bait'],
      'creature bait': ['Soft plastic bait'],
      'drop shot rig': ['Drop shot (fishing)'],
      'ned rig': ['Ned rig'],
      'popper': ['Popper (fishing lure)'],
      'walking bait': ['Walk the dog (fishing)'],
      'frog': ['Frog (fishing lure)'],
      'prop bait': ['Propeller bait (fishing)'],
      'spoon': ['Spoon lure', 'Fishing spoon'],
      'jigging spoon': ['Jigging spoon'],
      'live bait rig': ['Live bait rig'],
      'carolina rig': ['Carolina rig'],
      'ice jig': ['Ice fishing jig'],
      'tip-up rig': ['Tip-up (fishing)'],
      'dry fly': ['Dry fly fishing'],
      'nymph': ['Nymph (fly fishing)'],
      'streamer': ['Streamer (fly fishing)'],
      'popping cork rig': ['Popping cork'],
      'bucktail jig': ['Bucktail jig'],
      'trolling spoon': ['Fishing spoon'],
    };
    return map[lower] ?? [query];
  }

  /// Clear the in-memory cache.
  static void clearCache() => _cache.clear();
}

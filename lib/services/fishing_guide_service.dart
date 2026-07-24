import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/fishing_guide.dart';

/// Loads and provides fishing guide data from bundled JSON assets.
class FishingGuideService {
  static final FishingGuideService instance = FishingGuideService._();
  FishingGuideService._();

  List<FishingHub>? _hubs;
  List<FishingRegion>? _regions;
  List<BlogPost>? _blogPosts;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final hubsJson = await rootBundle.loadString('assets/guides/fishing_hubs.json');
    final regionsJson = await rootBundle.loadString('assets/guides/fishing_regions.json');
    final blogJson = await rootBundle.loadString('assets/guides/blog_posts.json');

    final hubsList = json.decode(hubsJson) as List<dynamic>;
    final regionsList = json.decode(regionsJson) as List<dynamic>;
    final blogList = json.decode(blogJson) as List<dynamic>;

    _hubs = hubsList.map((h) => FishingHub.fromJson(h as Map<String, dynamic>)).toList();
    _regions = regionsList.map((r) => FishingRegion.fromJson(r as Map<String, dynamic>)).toList();
    _blogPosts = blogList.map((b) => BlogPost.fromJson(b as Map<String, dynamic>)).toList();

    _loaded = true;
  }

  /// All hubs (provinces + states), sorted by title.
  Future<List<FishingHub>> getHubs() async {
    await _ensureLoaded();
    return _hubs!;
  }

  /// Hubs filtered by country.
  Future<List<FishingHub>> getHubsByCountry(String country) async {
    final all = await getHubs();
    return all.where((h) => h.country == country).toList();
  }

  /// All regions, sorted by title.
  Future<List<FishingRegion>> getRegions() async {
    await _ensureLoaded();
    return _regions!;
  }

  /// Regions belonging to a specific hub.
  Future<List<FishingRegion>> getRegionsForHub(String hubSlug) async {
    await _ensureLoaded();
    return _regions!
        .where((r) => r.parentHub == hubSlug)
        .toList();
  }

  /// Get a single region by slug.
  Future<FishingRegion?> getRegion(String slug) async {
    await _ensureLoaded();
    try {
      return _regions!.firstWhere((r) => r.slug == slug);
    } catch (_) {
      return null;
    }
  }

  /// All blog posts.
  Future<List<BlogPost>> getBlogPosts() async {
    await _ensureLoaded();
    return _blogPosts!;
  }

  /// Search across all content.
  Future<List<Map<String, dynamic>>> search(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final r in _regions!) {
      if (r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.spots.any((s) =>
              s.name.toLowerCase().contains(q) ||
              s.species.any((sp) => sp.toLowerCase().contains(q)))) {
        results.add({
          'type': 'region',
          'title': r.title,
          'slug': r.slug,
          'subtitle': r.subtitle.isNotEmpty ? r.subtitle : r.description,
        });
      }
    }

    for (final h in _hubs!) {
      if (h.title.toLowerCase().contains(q) ||
          h.description.toLowerCase().contains(q)) {
        results.add({
          'type': 'hub',
          'title': h.title,
          'slug': h.slug,
          'subtitle': h.description,
        });
      }
    }

    return results;
  }
}

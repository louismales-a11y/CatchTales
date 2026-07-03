import 'package:firebase_analytics/firebase_analytics.dart';

/// Simple centralized analytics for Firebase.
/// Logs screen views and key user actions anonymously.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Call this when a screen becomes visible.
  Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  /// User added a catch.
  Future<void> logCatchAdded({String? species, String? state}) async {
    await _analytics.logEvent(
      name: 'catch_added',
      parameters: {
        if (species != null) 'species': species,
        if (state != null) 'state': state,
      },
    );
  }

  /// User viewed a fish species in detail.
  Future<void> logFishViewed(String species) async {
    await _analytics.logEvent(
      name: 'fish_viewed',
      parameters: {'species': species},
    );
  }

  /// User searched a lake in Community Stats.
  Future<void> logLakeSearch(String lake, {String? state}) async {
    await _analytics.logEvent(
      name: 'lake_search',
      parameters: {
        'lake': lake,
        if (state != null) 'state': state,
      },
    );
  }

  /// User performed a Google Places search.
  Future<void> logPlacesSearch(String query) async {
    await _analytics.logEvent(
      name: 'places_search',
      parameters: {'query': query},
    );
  }

  /// User viewed Community Stats results.
  Future<void> logCommunityStatsViewed(
      {String? state, String? lake, bool isSample = false}) async {
    await _analytics.logEvent(
      name: 'community_stats_viewed',
      parameters: {
        if (state != null) 'state': state,
        if (lake != null) 'lake': lake,
        'is_sample': isSample ? 'true' : 'false',
      },
    );
  }

  /// User toggled nautical chart overlay.
  Future<void> logNauticalChartToggled(bool enabled) async {
    await _analytics.logEvent(
      name: 'nautical_chart_toggle',
      parameters: {'enabled': enabled ? 'true' : 'false'},
    );
  }

  /// User switched theme.
  Future<void> logThemeChanged(String themeName) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme': themeName},
    );
  }

  /// User switched language.
  Future<void> logLanguageChanged(String lang) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': lang},
    );
  }

  /// User triggered Pro upgrade dialog.
  Future<void> logProUpgradePrompt() async {
    await _analytics.logEvent(name: 'pro_upgrade_prompt');
  }

  /// User completed Pro upgrade (called from unlockPro).
  Future<void> logProUpgraded() async {
    await _analytics.logEvent(name: 'pro_upgraded');
  }

  /// User shared catches.
  Future<void> logShare() async {
    await _analytics.logEvent(name: 'share');
  }

  /// Toggle dark mode.
  Future<void> logDarkModeToggled(bool enabled) async {
    await _analytics.logEvent(
      name: 'dark_mode_toggle',
      parameters: {'enabled': enabled ? 'true' : 'false'},
    );
  }
}

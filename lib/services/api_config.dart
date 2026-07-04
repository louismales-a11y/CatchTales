/// API keys read from --dart-define at build time.
///
/// To set your own keys:
///   flutter build apk --release \
///     --dart-define=OPENWEATHER_API_KEY=your_key_here
///
/// The build.sh script also reads from .env automatically.
class ApiConfig {
  ApiConfig._();

  /// OpenWeatherMap API key.
  /// Falls back to the hardcoded dev key if not provided via --dart-define.
  static String get openWeatherApiKey =>
      const String.fromEnvironment(
        'OPENWEATHER_API_KEY',
        defaultValue: '34dfeae3007957e5d3ba01a471f2bd21',
      );

  /// Google Maps / Places API key.
  /// Compiled into the app via --dart-define=GOOGLE_MAPS_API_KEY=...
  /// from build.sh or .env.
  static String get googleMapsApiKey =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // ─── App Version ────────────────────────────────────────────────

  /// Which build variant this is: 'dev', 'pro', or 'free'.
  /// Set via --dart-define=APP_VERSION=pro when building.
  static String get appVersion =>
      const String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  /// Whether this is the developer build (has toggle).
  static bool get isDev => appVersion == 'dev' || appVersion == 'jason';

  /// Whether this is the Pro build.
  static bool get isProBuild => appVersion == 'pro';

  /// Display name for the app.
  static String get appDisplayName {
    switch (appVersion) {
      case 'pro':
        return 'Best Fish Buddy Pro';
      case 'free':
        return 'Best Fish Buddy Free';
      default:
        return 'Best Fish Buddy Jason';
    }
  }
}

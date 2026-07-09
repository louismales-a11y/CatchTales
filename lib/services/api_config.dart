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
        defaultValue: '',
      );

  /// Google Maps / Places API key.
  /// Compiled into the app via --dart-define=GOOGLE_MAPS_API_KEY=...
  /// from build.sh or .env.
  static String get googleMapsApiKey =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Google Gemini API key for AI features.
  /// Set via --dart-define=GEMINI_API_KEY=... or pass password-store.
  static String get geminiApiKey =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // ─── App Version ────────────────────────────────────────────────

  /// Which build variant this is: 'dev', 'pro', or 'free'.
  /// Set via --dart-define=APP_VERSION=pro when building.
  static String get appVersion =>
      const String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  /// Whether this is the developer build (has toggle).
  static bool get isDev => appVersion == 'dev';

  /// Whether this is the Pro build.
  static bool get isProBuild => appVersion == 'pro';

  /// Whether this is the Free build.
  static bool get isFreeBuild => appVersion == 'free';

  /// Display name for the app.
  static String get appDisplayName {
    switch (appVersion) {
      case 'pro':
        return 'CatchTales Pro';
      case 'free':
        return 'CatchTales';
      default:
        return 'CatchTales Dev';
    }
  }
}

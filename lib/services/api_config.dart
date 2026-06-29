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
}

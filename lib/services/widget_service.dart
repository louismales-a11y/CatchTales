import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/solunar_service.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';

class WidgetService {
  static const _widgetName = 'BestFishBuddyWidgetProvider';

  /// Prepares data from the database and pushes it to the home screen widget.
  static Future<void> updateWidget() async {
    try {
      final db = DatabaseService.instance;

      // ── Catch Count ──
      final totalCatches = await db.getCatchCount();

      // ── Biggest Catch ──
      final biggest = await db.biggestByWeight();
      final biggestDisplay = biggest != null
          ? '${biggest.weight!.toStringAsFixed(1)} kg'
          : '-- kg';

      // ── Solunar Best Time ──
      String solunarTime = '--:--';
      try {
        final now = DateTime.now();
        LocationPermission permission =
            await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
          final solunar =
              SolunarService.getSolunarTimes(now, pos.latitude, pos.longitude);
          solunarTime = solunar.major1Start;
        }
      } catch (_) {
        // Location not available, use moon phase only
        final moon = SolunarService.getMoonPhase(DateTime.now());
        if (moon.name.contains('Full') || moon.name.contains('New')) {
          solunarTime = 'All day!';
        }
      }

      // ── Weather ──
      String weatherDisplay = '--°C';
      try {
        LocationPermission permission =
            await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
          final w = await WeatherService.fetchWeather(
              pos.latitude, pos.longitude);
          if (w != null) {
            final temp = (w['temp'] as double).round();
            final condition = w['condition'] as String? ?? '';
            weatherDisplay = condition.isNotEmpty
                ? '$temp°C • ${condition.split(' ').first}'
                : '$temp°C';
          }
        }
      } catch (_) {}

      // ── Subtitle ──
      final now = DateTime.now();
      final dateStr = DateFormat('MMM d, yyyy').format(now);
      final subtitle = 'Updated $dateStr';

      // ── Save Widget Data ──
      await HomeWidget.saveWidgetData<String>('catch_count', '$totalCatches');
      await HomeWidget.saveWidgetData<String>('solunar_time', solunarTime);
      await HomeWidget.saveWidgetData<String>('weather', weatherDisplay);
      await HomeWidget.saveWidgetData<String>('biggest_catch', biggestDisplay);
      await HomeWidget.saveWidgetData<String>('subtitle', subtitle);

      // ── Update Widget ──
      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: 'BestFishBuddyWidget',
      );
    } catch (e) {
      // Silently fail — widget just shows defaults
    }
  }
}

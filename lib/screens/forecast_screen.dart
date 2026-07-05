import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/help_text.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../services/weather_service.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  List<ForecastDay>? _forecast;
  Map<String, dynamic>? _current;
  bool _loading = true;
  String? _error;
  String _city = '';
  bool _notifPrompted = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_notifPrompted && mounted) {
        _notifPrompted = true;
        NotificationService.instance.requestPermissionIfNeeded(context);
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission needed for weather';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final results = await Future.wait([
        WeatherService.fetchWeather(pos.latitude, pos.longitude),
        WeatherService.fetchForecast(pos.latitude, pos.longitude),
      ]);

      if (mounted) {
        setState(() {
          _current = results[0] as Map<String, dynamic>?;
          _forecast = results[1] as List<ForecastDay>?;
          _city = _current?['city'] as String? ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load weather: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('weatherForecast')),
),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(theme),
          ),
          helpChip(context, 'weather'),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh),
                label: Text(tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWeather,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current weather card
          if (_current != null) _buildCurrentCard(theme),
          const SizedBox(height: 20),

          // Forecast
          if (_forecast != null && _forecast!.isNotEmpty) ...[
            Text(tr('fiveDayForecast'),
                style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 12),
            ..._forecast!.map((day) => _buildForecastTile(theme, day)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCurrentCard(ThemeData theme) {
    final temp = _current!['temp'] as double;
    final feelsLike = _current!['feels_like'] as double;
    final condition = _current!['condition'] as String;
    final icon = _current!['icon'] as String;
    final humidity = _current!['humidity'] as int;
    final wind = _current!['wind_speed'] as double;
    final iconUrl = 'https://openweathermap.org/img/wn/$icon@4x.png';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // City + temp
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_city.isNotEmpty)
                        Text(_city,
                            style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                      const SizedBox(height: 4),
                      Text('$temp°C',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.primary,
                          )),
                      Text('${tr('feelsLike')} $feelsLike°C • $condition',
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Image.network(iconUrl,
                    width: 100, height: 100, errorBuilder: (_, _, _) =>
                        const Icon(Icons.wb_sunny, size: 64)),
              ],
            ),
            const Divider(height: 24),
            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _detailCol(Icons.water_drop, 'Humidity', '$humidity%'),
                _detailCol(
                    Icons.air, 'Wind', '${wind.toStringAsFixed(1)} m/s'),
                _detailCol(Icons.compress, 'Pressure',
                    '${_current!['pressure']} hPa'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCol(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildForecastTile(ThemeData theme, ForecastDay day) {
    final iconUrl = day.iconUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Image.network(iconUrl,
            width: 50, height: 50, errorBuilder: (_, _, _) =>
                const Icon(Icons.wb_cloudy, size: 32)),
        title: Text(day.dayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(day.condition,
            style: TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.6))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${day.tempMin.round()}°',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(width: 8),
            Text('${day.tempMax.round()}°',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

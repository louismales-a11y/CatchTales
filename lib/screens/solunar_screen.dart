import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/solunar_service.dart';
import '../services/weather_service.dart';

class SolunarScreen extends StatefulWidget {
  const SolunarScreen({super.key});

  @override
  State<SolunarScreen> createState() => _SolunarScreenState();
}

class _SolunarScreenState extends State<SolunarScreen> {
  bool _loading = true;
  String? _error;
  MoonPhaseInfo? _moon;
  SolunarPeriods? _solunar;
  Map<String, dynamic>? _weather;
  double _lat = 0, _lng = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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
          _error = 'Location permission needed';
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

      _lat = pos.latitude;
      _lng = pos.longitude;

      final now = DateTime.now();
      final moon = SolunarService.getMoonPhase(now);
      final solunar =
          SolunarService.getSolunarTimes(now, _lat, _lng);
      final weather =
          await WeatherService.fetchWeather(_lat, _lng);

      if (mounted) {
        setState(() {
          _moon = moon;
          _solunar = solunar;
          _weather = weather;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Best Fishing Times')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Moon Phase card
                      _buildMoonCard(theme),
                      const SizedBox(height: 16),

                      // Best fishing times
                      Text('Best Fishing Times Today',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      _buildTimeCard(
                        theme,
                        'Major Period',
                        Icons.access_time,
                        '${_solunar!.major1Start} – ${_solunar!.major1End}',
                        Colors.green,
                        'Moon overhead — best action!',
                      ),
                      const SizedBox(height: 8),
                      _buildTimeCard(
                        theme,
                        'Major Period',
                        Icons.access_time,
                        '${_solunar!.major2Start} – ${_solunar!.major2End}',
                        Colors.green.shade700,
                        'Moon underfoot — also great',
                      ),
                      const SizedBox(height: 8),
                      _buildTimeCard(
                        theme,
                        'Minor Period',
                        Icons.schedule,
                        '${_solunar!.minor1Start} – ${_solunar!.minor1End}',
                        Colors.amber.shade700,
                        'Moonrise — good activity',
                      ),
                      const SizedBox(height: 8),
                      _buildTimeCard(
                        theme,
                        'Minor Period',
                        Icons.schedule,
                        '${_solunar!.minor2Start} – ${_solunar!.minor2End}',
                        Colors.amber.shade700,
                        'Moonset — good activity',
                      ),

                      const SizedBox(height: 16),

                      // Weather summary if available
                      if (_weather != null) ...[
                        Text('Current Conditions',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.wb_sunny,
                                    color: Colors.amber.shade600,
                                    size: 40),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${(_weather!['temp'] as double).round()}°C',
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight:
                                                FontWeight.w300)),
                                    Text(
                                      _weather!['condition'] as String? ??
                                          '',
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.onSurface
                                              .withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  children: [
                                    Text(
                                        '💧 ${_weather!['humidity']}%',
                                        style: const TextStyle(
                                            fontSize: 14)),
                                    Text(
                                        '💨 ${(_weather!['wind_speed'] as double).toStringAsFixed(1)} m/s',
                                        style: const TextStyle(
                                            fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildMoonCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(_moon!.emoji,
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_moon!.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700)),
                      Text(
                        'Illumination: ${(_moon!.illumination * 100).round()}%',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                // Moon age indicator circle
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _moon!.phase,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: theme.colorScheme.primary,
                      ),
                      Center(
                        child: Text(
                          '${_moon!.age.round()}d',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Moon phase bar (visual)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: (_moon!.phase * 100).round(),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      flex: 100 - (_moon!.phase * 100).round(),
                      child: Container(color: Colors.grey.shade200),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Moon',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500)),
                Text('Full Moon',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(ThemeData theme, String label, IconData icon,
      String time, Color color, String hint) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 22,
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color)),
        subtitle: Text(hint,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5))),
        trailing: Text(time,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color)),
      ),
    );
  }
}

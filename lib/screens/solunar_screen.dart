import 'dart:math';
import 'package:flutter/material.dart';
import '../services/help_text.dart';
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
      appBar: AppBar(title: const Text('Best Fishing Times'),
        actions: [
          helpButton(context, 'solunar'),
        ]),
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
                      // Today's rating card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Row(
                            children: [
                              _ratingCircle(_solunar!.rating),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Today\'s Rating',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    Text(
                                      _ratingLabel(_solunar!.rating),
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      _ratingDesc(_solunar!.rating),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Moon Phase card
                      _buildMoonCard(theme),
                      const SizedBox(height: 16),

                      // Moonrise / Moonset
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniCard(
                              theme,
                              Icons.nightlight_round,
                              'Moonrise',
                              _solunar!.minor1Start,
                              Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniCard(
                              theme,
                              Icons.nights_stay,
                              'Moonset',
                              _solunar!.minor2Start,
                              Colors.indigo.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Solar info
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniCard(
                              theme,
                              Icons.wb_sunny,
                              'Sunrise',
                              _sunriseTime(),
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniCard(
                              theme,
                              Icons.wb_twilight,
                              'Sunset',
                              _sunsetTime(),
                              Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Best fishing times
                      Text('Best Fishing Times Today',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      // Visual timeline
                      _buildTimeline(theme),
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

  // Approximate sunrise/sunset based on latitude and time of year
  String _sunriseTime() {
    // Rough approximation for northern hemisphere
    final day = DateTime.now().dayOfYear;
    final latRad = _lat * pi / 180;
    final declination = 23.44 * pi / 180 * cos(2 * pi / 365 * (day - 173));
    final ha = acos(-tan(latRad) * tan(declination)) * 180 / pi / 15;
    final sunrise = 12 - ha;
    return _formatHour(sunrise);
  }

  String _sunsetTime() {
    final day = DateTime.now().dayOfYear;
    final latRad = _lat * pi / 180;
    final declination = 23.44 * pi / 180 * cos(2 * pi / 365 * (day - 173));
    final ha = acos(-tan(latRad) * tan(declination)) * 180 / pi / 15;
    final sunset = 12 + ha;
    return _formatHour(sunset);
  }

  String _formatHour(double hour) {
    final h = hour.round();
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12}:00 $period';
  }

  String _ratingLabel(int rating) {
    if (rating >= 9) return 'Excellent — Get out there!';
    if (rating >= 7) return 'Very Good';
    if (rating >= 5) return 'Good';
    if (rating >= 3) return 'Fair';
    return 'Poor — Better luck another day';
  }

  String _ratingDesc(int rating) {
    if (rating >= 8) return 'Major periods align with dawn/dusk — peak action!';
    if (rating >= 6) return 'Good overlap with feeding times.';
    if (rating >= 4) return 'Moderate activity expected.';
    return 'Minimal solunar activity today.';
  }

  Widget _ratingCircle(int rating) {
    final color = rating >= 7 ? Colors.green :
                 rating >= 5 ? Colors.amber :
                 Colors.red;
    return SizedBox(
      width: 56, height: 56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: rating / 10,
            strokeWidth: 5,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
          Center(
            child: Text('$rating/10',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    // Build a 24h bar showing major/minor periods
    final periods = [
      _Period('Major', _solunar!.major1Start, _solunar!.major1End, Colors.green),
      _Period('Major', _solunar!.major2Start, _solunar!.major2End, Colors.green.shade700),
      _Period('Minor', _solunar!.minor1Start, _solunar!.minor1End, Colors.amber),
      _Period('Minor', _solunar!.minor2Start, _solunar!.minor2End, Colors.amber.shade700),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('24-Hour Timeline',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: List.generate(24, (hour) {
                    // Check if this hour falls in any period
                    Color? barColor;
                    String? label;
                    for (final p in periods) {
                      if (hour >= p.startHour && hour <= p.endHour) {
                        barColor = p.color.withValues(alpha: hour == p.startHour || hour == p.endHour ? 0.5 : 0.8);
                        if (hour == p.startHour) label = p.type == 'Major' ? 'M' : 'm';
                        break;
                      }
                    }
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor ?? Colors.grey.shade100,
                          border: Border.all(width: 0.3, color: Colors.grey.shade300),
                        ),
                        child: label != null
                            ? Center(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)))
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12 AM', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('6 AM', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('12 PM', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('6 PM', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('11 PM', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(Colors.green, 'Major'),
                const SizedBox(width: 16),
                _legendDot(Colors.amber, 'Minor'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
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

/// Helper to parse time strings into hours for the timeline bar.
class _Period {
  final String type;
  final String startStr;
  final String endStr;
  final Color color;

  _Period(this.type, this.startStr, this.endStr, this.color);

  double get startHour => _parseH(startStr);
  double get endHour => _parseH(endStr);

  static double _parseH(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 12;
    final t = parts[0].split(':');
    final h = int.tryParse(t[0]) ?? 12;
    final m = int.tryParse(t[1]) ?? 0;
    return (parts[1] == 'PM' ? (h == 12 ? 12 : h + 12) : (h == 12 ? 0 : h)) + m / 60.0;
  }
}

extension on DateTime {
  int get dayOfYear {
    final first = DateTime(year, 1, 1);
    return difference(first).inDays + 1;
  }
}

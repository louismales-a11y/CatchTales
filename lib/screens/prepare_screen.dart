import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/help_text.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';
import '../services/solunar_service.dart';
import 'forecast_screen.dart';
import 'fish_id_screen.dart';
import 'map_screen.dart';
import 'solunar_screen.dart';
import 'tackle_box_screen.dart';

class PrepareScreen extends StatefulWidget {
  const PrepareScreen({super.key});

  @override
  State<PrepareScreen> createState() => _PrepareScreenState();
}

class _PrepareScreenState extends State<PrepareScreen> {
  bool _loading = true;
  bool _hasAnglers = false;
  bool _hasTackle = false;
  bool _hasSpots = false;
  int _anglerCount = 0;
  int _tackleCount = 0;
  int _spotCount = 0;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    try {
      final counters = await db.getCounters();
      final tackle = await db.getTackleItems();
      final spots = await db.getSpots();
      _anglerCount = counters.length;
      _tackleCount = tackle.length;
      _spotCount = spots.length;
      _hasAnglers = _anglerCount > 0;
      _hasTackle = _tackleCount > 0;
      _hasSpots = _spotCount > 0;

      // Try solunar rating
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 3)),
        );
        final sol = SolunarService.getSolunarTimes(DateTime.now(), pos.latitude, pos.longitude);
        _rating = sol.rating;
      } catch (_) {
        final sol = SolunarService.getSolunarTimes(DateTime.now(), 0, 0);
        _rating = sol.rating;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('prepare')),

      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.checklist, size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(tr('letsGetReady'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Checklist items
                _checkItem(
                  icon: Icons.people,
                  label: tr('checkAddAnglers'),
                  done: _hasAnglers,
                  detail: _hasAnglers ? trp('nAnglers', {'count': '$_anglerCount'}) : tr('noAnglersYet'),
                  screen: null,
                  onTap: _showAddAnglersHelp,
                ),
                _checkItem(
                  icon: Icons.wb_sunny,
                  label: tr('checkWeather'),
                  done: true,
                  detail: tr('todayForecastSolunar'),
                  screen: const ForecastScreen(),
                ),
                _checkItem(
                  icon: Icons.nights_stay,
                  label: tr('solunar'),
                  done: _rating >= 5,
                  detail: _rating >= 5 ? '${tr('todaysRating')}: $_rating/10' : '${tr('rating')}: $_rating/10',
                  screen: const SolunarScreen(),
                  detailColor: _rating >= 7 ? Colors.green : _rating >= 5 ? Colors.amber : Colors.grey,
                ),
                _checkItem(
                  icon: Icons.inventory_2,
                  label: tr('checkTackle'),
                  done: _hasTackle,
                  detail: _hasTackle ? trp('nItems', {'count': '$_tackleCount'}) : tr('tackleBoxEmpty'),
                  screen: const TackleBoxScreen(),
                ),
                _checkItem(
                  icon: Icons.menu_book,
                  label: tr('checkFishId'),
                  done: true,
                  detail: tr('browseSpecies'),
                  screen: const FishIdScreen(),
                ),
                _checkItem(
                  icon: Icons.map,
                  label: tr('checkMapSpots'),
                  done: _hasSpots,
                  detail: _hasSpots ? trp('nSpots', {'count': '$_spotCount'}) : tr('noSavedSpots'),
                  screen: const MapScreen(),
                ),

                const SizedBox(height: 20),

                // Summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _summaryTile(Icons.people, '$_anglerCount', tr('anglers')),
                            _summaryTile(Icons.inventory_2, '$_tackleCount', tr('tackle')),
                            _summaryTile(Icons.star, '$_rating/10', tr('rating')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Start New Trip
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _hasAnglers ? _startTrip : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(tr('startNewTrip')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (!_hasAnglers)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(tr('addAnglerFirst'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          helpChip(context, 'prepare'),
        ],
      ),
    );
  }

  void _showAddAnglersHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Anglers'),
        content: const Text(
          'Go to the **Counter** tab (bottom navigation)\n'
          'and type an angler\'s name, then tap **Add**.\n\n'
          'You can also say **"fish buddy add [name]"**\n'
          'with the mic on the Counter screen!',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('gotIt')),
          ),
        ],
      ),
    );
  }

  Widget _checkItem({
    required IconData icon,
    required String label,
    required bool done,
    required String detail,
    Widget? screen,
    VoidCallback? onTap,
    Color? detailColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done
              ? Colors.green.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          child: Icon(
            done ? Icons.check : icon,
            color: done ? Colors.green : theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: done ? Colors.green.shade700 : null)),
        subtitle: Text(detail,
            style: TextStyle(
                fontSize: 12,
                color: detailColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap ?? (screen != null
            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
            : null),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: theme.colorScheme.primary)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _startTrip() async {
    await DatabaseService.instance.resetSpeciesTallies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('newTripStarted')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


}

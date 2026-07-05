import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/help_text.dart';
import '../services/translation_service.dart';
import '../services/counters_db_service.dart';
import '../services/tackle_db_service.dart';
import '../services/spots_db_service.dart';
import '../services/species_tally_db_service.dart';
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
  Set<String> _done = {};
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
    final countersDb = CountersDbService.instance;
    final tackleDb = TackleDbService.instance;
    final spotsDb = SpotsDbService.instance;
    try {
      final counters = await countersDb.getCounters();
      final tackle = await tackleDb.getTackleItems();
      final spots = await spotsDb.getSpots();
      _anglerCount = counters.length;
      _tackleCount = tackle.length;
      _spotCount = spots.length;

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

  void _toggle(String key) {
    setState(() {
      if (_done.contains(key)) {
        _done.remove(key);
      } else {
        _done.add(key);
      }
    });
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

                // Checklist items — tap to check off as you go
                _checkItem(
                  key: 'anglers',
                  icon: Icons.people,
                  label: tr('checkAddAnglers'),
                  detail: _anglerCount > 0 ? trp('nAnglers', {'count': '$_anglerCount'}) : tr('noAnglersYet'),
                ),
                _checkItem(
                  key: 'weather',
                  icon: Icons.wb_sunny,
                  label: tr('checkWeather'),
                  detail: tr('todayForecastSolunar'),
                  screen: const ForecastScreen(),
                ),
                _checkItem(
                  key: 'solunar',
                  icon: Icons.nights_stay,
                  label: tr('solunar'),
                  detail: _rating >= 5 ? '${tr('todaysRating')}: $_rating/10' : '${tr('rating')}: $_rating/10',
                  screen: const SolunarScreen(),
                  detailColor: _rating >= 7 ? Colors.green : _rating >= 5 ? Colors.amber : Colors.grey,
                ),
                _checkItem(
                  key: 'tackle',
                  icon: Icons.inventory_2,
                  label: tr('checkTackle'),
                  detail: _tackleCount > 0 ? trp('nItems', {'count': '$_tackleCount'}) : tr('tackleBoxEmpty'),
                  screen: const TackleBoxScreen(),
                ),
                _checkItem(
                  key: 'fishid',
                  icon: Icons.menu_book,
                  label: tr('checkFishId'),
                  detail: tr('browseSpecies'),
                  screen: const FishIdScreen(),
                ),
                _checkItem(
                  key: 'spots',
                  icon: Icons.map,
                  label: tr('checkMapSpots'),
                  detail: _spotCount > 0 ? trp('nSpots', {'count': '$_spotCount'}) : tr('noSavedSpots'),
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

                // Start New Trip — enabled when at least one item checked
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _done.isNotEmpty ? _startTrip : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(tr('startNewTrip')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (_done.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Tap items above to check them off your list',
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
    required String key,
    required IconData icon,
    required String label,
    required String detail,
    Widget? screen,
    Color? detailColor,
  }) {
    final done = _done.contains(key);
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!done)
              Text('Tap to check',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            if (!done) const SizedBox(width: 6),
            Icon(Icons.check_circle_outline,
                size: 20,
                color: done ? Colors.green : Colors.grey.shade300),
          ],
        ),
        onTap: () {
          _toggle(key);
          if (screen != null && !done) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
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
    await SpeciesTallyDbService.instance.resetSpeciesTallies();
    if (!mounted) return;
    setState(() => _done.clear());
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/catches_db_service.dart';
import '../services/trip_service.dart';
import '../services/translation_service.dart';
import '../services/help_text.dart';
import '../models/catch.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  List<String> _trips = [];
  Map<String, List<Catch>> _tripCatches = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final names = await CatchesDbService.instance.getTripNames();
    final Map<String, List<Catch>> map = {};
    for (final name in names) {
      map[name] = await CatchesDbService.instance.getCatchesByTrip(name);
    }
    if (!mounted) return;
    setState(() {
      _trips = names;
      _tripCatches = map;
      _loading = false;
    });
  }

  Future<void> _startNewTrip() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('startNewTrip')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tr('tripName'),
            hintText: tr('tripNameHint'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(tr('startTrip')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await TripService.instance.startTrip(name);
    if (!mounted) return;
    // Show trip walkthrough on first use
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('trip_walkthrough_seen') ?? false)) {
      await prefs.setBool('trip_walkthrough_seen', true);
      if (!mounted) return;
      showHelp(context, 'trips');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(trp('tripStarted', {'name': name})),
      ),
    );
    _load();
  }

  Future<void> _endActiveTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('endTrip')),
        content: Text('End the active trip "${TripService.instance.activeTrip}"?\nNew catches will no longer be auto-tagged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('endTrip')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await TripService.instance.endTrip();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(tr('tripEnded')),
      ),
    );
    setState(() {});
  }

  Future<void> _renameTrip(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('renameTrip')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tr('tripName'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(tr('rename')),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == oldName) return;
    await CatchesDbService.instance.renameTrip(oldName, newName);
    _load();
  }

  Future<void> _deleteTrip(String tripName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('deleteTrip')),
        content: Text(trp('deleteTripConfirm', {'name': tripName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('removeTrip')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await CatchesDbService.instance.deleteTrip(tripName);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    final activeTrip = TripService.instance.activeTrip;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('trips')),
        actions: [
          if (TripService.instance.isActive)
            TextButton.icon(
              onPressed: _endActiveTrip,
              icon: const Icon(Icons.stop, size: 18),
              label: Text(tr('endTrip')),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: tr('startNewTrip'),
            onPressed: _startNewTrip,
          ),

        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? _emptyState(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _trips.length + (activeTrip != null ? 1 : 0) + 1,
                    itemBuilder: (ctx, i) {
                      final isLast = i == _trips.length + (activeTrip != null ? 1 : 0);
                      if (isLast) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: helpChip(context, 'trips'),
                        );
                      }
                      if (i == 0 && activeTrip != null) {
                        return _activeTripBanner(theme, activeTrip);
                      }
                      final idx = activeTrip != null ? i - 1 : i;
                      final name = _trips[idx];
                      final catches = _tripCatches[name] ?? [];
                      return _tripCard(context, name, catches);
                    },
                  ),
                ),
              );
  }

  Widget _activeTripBanner(ThemeData theme, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.directions_boat_filled, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Trip',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary)),
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _endActiveTrip(),
                icon: const Icon(Icons.stop, size: 16),
                label: Text(tr('endTrip')),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripCard(BuildContext context, String name, List<Catch> catches) {
    final count = catches.length;
    final species = catches.map((c) => c.species).toSet().length;
    final biggest = catches
        .where((c) => c.weight != null)
        .fold<Catch?>(null, (prev, c) => prev == null || c.weight! > prev.weight! ? c : prev);
    final dates = catches.map((c) => c.caughtAt).toList()..sort();
    final dateRange = dates.length >= 2
        ? '${DateFormat('MMM d').format(dates.first)} - ${DateFormat('MMM d, yyyy').format(dates.last)}'
        : DateFormat('MMM d, yyyy').format(dates.first);

    return Dismissible(
      key: ValueKey('trip_$name'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
      ),
      confirmDismiss: (_) async {
        _deleteTrip(name);
        return false;
      },
      child: Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTripDetail(context, name, catches),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _renameTrip(name);
                          break;
                        case 'delete':
                          _deleteTrip(name);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 18),
                          title: Text('Rename', style: TextStyle(fontSize: 13)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.remove_circle_outline, size: 18),
                          title: Text('Remove Trip', style: TextStyle(fontSize: 13)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _stat(Icons.checklist, '$count catch${count == 1 ? '' : 'es'}'),
                  _stat(Icons.set_meal, '$species species'),
                  if (biggest != null)
                    _stat(Icons.monitor_weight,
                        'Biggest: ${biggest.weightDisplay}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateRange,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Icon(Icons.directions_boat_filled, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(tr('noTripsYet'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              tr('noTripsDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startNewTrip,
              icon: const Icon(Icons.add),
              label: Text(tr('startNewTrip')),
            ),
            const SizedBox(height: 24),
            helpChip(context, 'trips'),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          ],
        ),
      ),
    );
  }

  Future<void> _showTripDetail(
      BuildContext context, String name, List<Catch> catches) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(tripName: name, catches: catches),
      ),
    );
    _load();
  }
}

// ─── Trip Detail Screen ───────────────────────────────────────────────────

class TripDetailScreen extends StatelessWidget {
  final String tripName;
  final List<Catch> catches;

  const TripDetailScreen({
    super.key,
    required this.tripName,
    required this.catches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final species = catches.map((c) => c.species).toSet().toList()..sort();
    final totalWeight = catches
        .where((c) => c.weight != null)
        .fold<double>(0, (s, c) => s + c.weight!);
    final biggest = catches
        .where((c) => c.weight != null)
        .fold<Catch?>(null, (prev, c) => prev == null || c.weight! > prev.weight! ? c : prev);

    return Scaffold(
      appBar: AppBar(title: Text(tripName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats row
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCol('Total', '${catches.length}', Icons.checklist),
                  ),
                  Expanded(
                    child: _statCol('Species', '${species.length}', Icons.set_meal),
                  ),
                  if (biggest != null)
                    Expanded(
                      child: _statCol(
                          'Biggest', biggest.weightDisplay, Icons.monitor_weight),
                    ),
                ],
              ),
            ),
          ),
          if (totalWeight > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Total Weight: ${totalWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ),
          const SizedBox(height: 8),

          // Species breakdown
          Text('Species Breakdown',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...species.map((s) {
            final count = catches.where((c) => c.species == s).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                  Text('$count',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Catch list
          Text('Catch Log',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...catches.reversed.map((c) {
            final dateStr = DateFormat('MMM d, HH:mm').format(c.caughtAt);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.circle,
                    size: 10, color: theme.colorScheme.primary),
                title: Text('${c.species} by ${c.angler}',
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${c.weightDisplay.isNotEmpty ? '${c.weightDisplay} · ' : ''}'
                  '${c.lengthDisplay.isNotEmpty ? '${c.lengthDisplay} · ' : ''}'
                  '${c.location.isNotEmpty ? '${c.location} · ' : ''}$dateStr',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

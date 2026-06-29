import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/favorite_spot.dart';
import '../services/database_service.dart';

class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  List<FavoriteSpot> _spots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final spots = await DatabaseService.instance.getSpots();
    if (mounted) {
      setState(() {
        _spots = spots;
        _loading = false;
      });
    }
  }

  Future<void> _addSpot() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AddSpotScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _deleteSpot(FavoriteSpot spot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Spot'),
        content: Text('Remove "${spot.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteSpot(spot.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Spots')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSpot,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _spots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No favorite spots yet',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap + to add a spot',
                          style: TextStyle(
                              color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _spots.length,
                    itemBuilder: (context, index) {
                      final s = _spots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary,
                            child: const Icon(Icons.star,
                                color: Colors.white),
                          ),
                          title: Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)}'
                            '${s.bestSpecies != null && s.bestSpecies!.isNotEmpty ? " • ${s.bestSpecies}" : ""}'
                            '${s.notes != null && s.notes!.isNotEmpty ? "\n${s.notes}" : ""}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20),
                            onPressed: () => _deleteSpot(s),
                            color: theme.colorScheme.error,
                          ),
                          isThreeLine: s.notes != null &&
                              s.notes!.isNotEmpty,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Add Spot Screen ──────────────────────────────────────────────────────

class _AddSpotScreen extends StatefulWidget {
  const _AddSpotScreen();

  @override
  State<_AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<_AddSpotScreen> {
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _speciesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        setState(() => _fetchingLocation = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid latitude & longitude required')),
      );
      return;
    }

    setState(() => _saving = true);
    await DatabaseService.instance.addSpot(FavoriteSpot(
      name: _nameCtrl.text.trim(),
      latitude: lat,
      longitude: lng,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      bestSpecies:
          _speciesCtrl.text.isNotEmpty ? _speciesCtrl.text.trim() : null,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Spot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Spot Name *',
              prefixIcon: Icon(Icons.star),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          // Location row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(Icons.explore),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.explore),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _fetchingLocation ? null : _useCurrentLocation,
            icon: _fetchingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, size: 18),
            label: const Text('Use current location'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speciesCtrl,
            decoration: const InputDecoration(
              labelText: 'Best species (optional)',
              prefixIcon: Icon(Icons.set_meal),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save Spot'),
            ),
          ),
        ],
      ),
    );
  }
}

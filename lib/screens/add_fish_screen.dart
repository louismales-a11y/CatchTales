import 'dart:async';
import 'package:flutter/material.dart';
import '../services/help_text.dart';
import '../models/fish_data.dart';
import '../services/database_service.dart';
import '../services/wikipedia_service.dart';

class AddFishScreen extends StatefulWidget {
  const AddFishScreen({super.key});

  @override
  State<AddFishScreen> createState() => _AddFishScreenState();
}

class _AddFishScreenState extends State<AddFishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sciNameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _habitatCtrl = TextEditingController();
  final _dietCtrl = TextEditingController();
  final _tackleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tipsCtrl = TextEditingController();

  String _selectedRegion = 'All';
  String _selectedWater = 'Freshwater';
  bool _saving = false;
  bool _lookingUp = false;
  String? _duplicateError;

  /// Debounce timer for Wikipedia auto-fill.
  Timer? _debounce;

  static const _regions = [
    'All', 'USA', 'Canada', 'Europe',
    'Asia/Pacific', 'South America', 'Africa', 'Australia',
  ];

  static const _waterTypes = [
    'Freshwater', 'Saltwater', 'Saltwater / Freshwater',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _sciNameCtrl.dispose();
    _sizeCtrl.dispose();
    _habitatCtrl.dispose();
    _dietCtrl.dispose();
    _tackleCtrl.dispose();
    _descCtrl.dispose();
    _tipsCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicate(String name) async {
    if (name.trim().isEmpty) return;
    final isDup = await DatabaseService.instance.isDuplicateFish(name);
    setState(() => _duplicateError =
        isDup ? 'A fish named "$name" already exists!' : null);
  }

  /// Debounced Wikipedia lookup triggered when the name field changes.
  void _onNameChanged(String value) {
    _checkDuplicate(value);

    _debounce?.cancel();
    if (value.trim().length < 3) return; // require at least 3 chars

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _lookupWikipedia(value.trim());
    });
  }

  /// Fetch fish info from Wikipedia and fill in empty fields.
  Future<void> _lookupWikipedia(String query) async {
    if (query.isEmpty) return;
    setState(() => _lookingUp = true);

    try {
      final info = await WikipediaService.fetchFishInfo(query);
      if (info == null || !mounted) return;

      setState(() {
        // Scientific name — only overwrite if empty
        if (_sciNameCtrl.text.isEmpty &&
            info.scientificName != null &&
            info.scientificName!.isNotEmpty) {
          _sciNameCtrl.text = info.scientificName!;
        }
        // Description — only overwrite if empty
        if (_descCtrl.text.isEmpty &&
            info.description != null &&
            info.description!.isNotEmpty) {
          // Trim to a reasonable length
          final extract = info.description!
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          _descCtrl.text = extract.length > 500
              ? '${extract.substring(0, 500)}…'
              : extract;
        }
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_duplicateError != null) return;

    setState(() => _saving = true);

    final fish = FishSpecies(
      name: _nameCtrl.text.trim(),
      scientificName: _sciNameCtrl.text.trim(),
      regions: [_selectedRegion],
      sizeRange: _sizeCtrl.text.trim(),
      habitat: _habitatCtrl.text.trim(),
      waterType: _selectedWater,
      diet: _dietCtrl.text.trim(),
      commonTackle: _tackleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      tips: _tipsCtrl.text.trim().isNotEmpty
          ? _tipsCtrl.text.trim().split('\n')
              .map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : [],
      color: Color(_regionColors[_selectedRegion] ?? 0xFF2196F3),
    );

    await DatabaseService.instance.addCustomFish(fish);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${fish.name} added!')),
      );
      Navigator.pop(context, true);
    }
  }

  static const _regionColors = <String, int>{
    'All': 0xFF2196F3,
    'USA': 0xFF4CAF50,
    'Canada': 0xFFE53935,
    'Europe': 0xFFFF9800,
    'Asia/Pacific': 0xFFFFD600,
    'South America': 0xFF00BCD4,
    'Africa': 0xFFFF6F00,
    'Australia': 0xFF42A5F5,
  };

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Fish'),
),
      body: Form(
        key: _formKey,
        child: ListView(
          // Fix #1: bottom padding so save button isn't hidden by nav bar
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad + 80),
          children: [
            // ── Name + Wikipedia lookup ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    onChanged: _onNameChanged,
                    decoration: const InputDecoration(
                      labelText: 'Common Name *',
                      hintText: 'e.g. Blue Catfish',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (_duplicateError != null) return _duplicateError;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: Tooltip(
                    message: 'Look up on Wikipedia',
                    child: IconButton(
                      icon: _lookingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high),
                      onPressed: _lookingUp
                          ? null
                          : () => _lookupWikipedia(_nameCtrl.text.trim()),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_duplicateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_duplicateError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // ── Scientific Name ──
            TextFormField(
              controller: _sciNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Scientific Name',
                hintText: 'e.g. Ictalurus furcatus',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Region ──
            DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              items: _regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRegion = v ?? 'All'),
            ),
            const SizedBox(height: 16),

            // ── Water Type ──
            DropdownButtonFormField<String>(
              initialValue: _selectedWater,
              decoration: const InputDecoration(
                labelText: 'Water Type',
                border: OutlineInputBorder(),
              ),
              items: _waterTypes
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWater = v ?? 'Freshwater'),
            ),
            const SizedBox(height: 16),

            // ── Size Range ──
            TextFormField(
              controller: _sizeCtrl,
              decoration: const InputDecoration(
                labelText: 'Size Range',
                hintText: 'e.g. 50–120 cm, up to 50 kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Habitat ──
            TextFormField(
              controller: _habitatCtrl,
              decoration: const InputDecoration(
                labelText: 'Habitat',
                hintText: 'e.g. Large rivers, reservoirs',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Diet ──
            TextFormField(
              controller: _dietCtrl,
              decoration: const InputDecoration(
                labelText: 'Diet',
                hintText: 'e.g. Fish, mussels, crustaceans',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Common Tackle ──
            TextFormField(
              controller: _tackleCtrl,
              decoration: const InputDecoration(
                labelText: 'Common Tackle',
                hintText: 'e.g. Cut bait, live bait, trotlines',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tips ──
            TextFormField(
              controller: _tipsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Fishing Tips (one per line)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Save ──
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Add Fish'),
              ),
            ),
            const SizedBox(height: 8),
            helpChip(context, 'add_fish'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

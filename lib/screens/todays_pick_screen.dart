import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/tackle_database.dart';
import '../models/fish_data.dart';
import '../models/tackle_item.dart';
import '../data/fish_database.dart';
import '../services/tackle_recommender.dart';
import '../services/weather_service.dart';
import '../services/tackle_image_service.dart';
import '../services/database_service.dart';
import 'tackle_detail_screen.dart';

class TodaysPickScreen extends StatefulWidget {
  const TodaysPickScreen({super.key});

  @override
  State<TodaysPickScreen> createState() => _TodaysPickScreenState();
}

class _TodaysPickScreenState extends State<TodaysPickScreen> {
  String _selectedSpecies = '';
  List<TackleSuggestion> _suggestions = [];
  bool _loadingWeather = true;
  bool _loadingRecs = false;
  Map<String, dynamic>? _weather;
  String _weatherSummary = 'Loading weather…';
  String _season = '';
  String _timeOfDay = '';
  String? _error;

  final _searchCtrl = TextEditingController();
  List<FishSpecies> _filteredSpecies = [];

  /// All unique species from the fish database.
  List<String> get _allSpecies {
    final set = <String>{};
    for (final f in fishDatabase) {
      set.add(f.name);
    }
    // Also add ones from tackle database target species
    for (final t in tackleTypeDatabase) {
      for (final s in t.targetSpecies) {
        set.add(s);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _season = _getSeason(now);
    _timeOfDay = _getTimeOfDay(now);
    _loadWeather();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
        final w = await WeatherService.fetchWeather(pos.latitude, pos.longitude);
        if (w != null) {
          _weather = w;
          final temp = (w['temp'] as double).round();
          final cond = w['condition'] as String? ?? '';
          _weatherSummary = '$temp°C${cond.isNotEmpty ? ' • $cond' : ''}';
        } else {
          _weatherSummary = 'Weather unavailable';
        }
      } else {
        _weatherSummary = 'Location access needed for weather';
      }
    } catch (_) {
      _weatherSummary = 'Weather unavailable';
    }
    if (mounted) setState(() => _loadingWeather = false);
  }

  void _onSpeciesChanged(String value) {
    final query = value.toLowerCase().trim();
    setState(() {
      _selectedSpecies = value;
      if (query.isEmpty) {
        _filteredSpecies = [];
      } else {
        _filteredSpecies = _allSpecies
            .where((s) => s.toLowerCase().contains(query))
            .take(8)
            .map((name) => fishDatabase.firstWhere(
                  (f) => f.name == name,
                  orElse: () => FishSpecies(
                    name: name,
                    scientificName: '',
                    regions: [],
                    sizeRange: '',
                    habitat: '',
                    waterType: '',
                    diet: '',
                    commonTackle: '',
                  ),
                ))
            .toList();
      }
    });
  }

  void _selectSpecies(String species) {
    setState(() {
      _selectedSpecies = species;
      _filteredSpecies = [];
    });
    _searchCtrl.text = species;
    _generate();
  }

  Future<void> _generate() async {
    if (_selectedSpecies.isEmpty) return;
    setState(() {
      _loadingRecs = true;
      _suggestions = [];
      _error = null;
    });

    try {
      final recs = await TackleRecommender.recommend(
        targetSpecies: _selectedSpecies,
        weather: _weather,
      );
      if (mounted) {
        setState(() {
          _suggestions = recs;
          _loadingRecs = false;
          if (recs.isEmpty) {
            _error = 'No tackle found for $_selectedSpecies. Try a different species.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRecs = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _addToBox(String name) async {
    // Find the catalog type
    try {
      final type = tackleTypeDatabase.firstWhere((t) => t.name == name);
      final item = TackleItem(
        name: type.name,
        type: type.category,
        targetSpecies: List.from(type.targetSpecies),
        tips: type.tips,
      );
      await DatabaseService.instance.addTackleItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added to your tackle box!')),
        );
        _generate(); // re-generate to update isInMyBox flags
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Pick")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Conditions card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny,
                    size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_capitalize(_season)} • ${_capitalize(_timeOfDay)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loadingWeather
                            ? 'Loading weather…'
                            : _weatherSummary,
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Species selector ──
          Text('What are you targeting today?',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSpeciesChanged,
            decoration: InputDecoration(
              hintText: 'Search for a fish species…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _selectedSpecies.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedSpecies = '';
                          _filteredSpecies = [];
                          _suggestions = [];
                          _error = null;
                        });
                      })
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),

          // ── Species autocomplete ──
          if (_filteredSpecies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _filteredSpecies.map((f) => ListTile(
                  dense: true,
                  leading: Icon(Icons.set_meal,
                      size: 18, color: f.color),
                  title: Text(f.name, style: const TextStyle(fontSize: 14)),
                  subtitle: f.scientificName.isNotEmpty
                      ? Text(f.scientificName,
                          style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic))
                      : null,
                  onTap: () => _selectSpecies(f.name),
                )).toList(),
              ),
            ),

          // ── Generate button ──
          if (_selectedSpecies.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: _loadingRecs ? null : _generate,
                icon: _loadingRecs
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_loadingRecs
                    ? 'Finding the best tackle…'
                    : 'Show Me What to Use'),
              ),
            ),
          ],

          // ── Error ──
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Colors.orange.shade700, fontSize: 13)),
          ],

          // ── Results ──
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Recommended Tackle',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  'Top ${_suggestions.length > 5 ? 5 : _suggestions.length}',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 8),
            ..._suggestions.take(5).map((s) => _SuggestionCard(
                  suggestion: s,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TackleDetailScreen(
                          item: TackleItem(
                            name: s.name,
                            type: s.type,
                            photoPath: s.photoPath,
                            targetSpecies: [_selectedSpecies],
                            tips: s.tips,
                          ),
                        ),
                      ),
                    );
                  },
                  onAdd: s.isInMyBox ? null : () => _addToBox(s.name),
                  imageUrl: s.imageUrl,
                )),
          ],
        ],
      ),
    );
  }

  String _getSeason(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'fall';
    return 'winter';
  }

  String _getTimeOfDay(DateTime date) {
    final h = date.hour;
    if (h >= 5 && h < 8) return 'dawn';
    if (h >= 8 && h < 17) return 'day';
    if (h >= 17 && h < 20) return 'dusk';
    return 'night';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _SuggestionCard extends StatefulWidget {
  final TackleSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final String? imageUrl;

  const _SuggestionCard({
    required this.suggestion,
    required this.onTap,
    this.onAdd,
    this.imageUrl,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  String? _fetchedImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    if (widget.imageUrl != null) {
      _fetchedImageUrl = widget.imageUrl;
      return;
    }
    final url = await TackleImageService.getImageUrl(widget.suggestion.name);
    if (mounted) {
      setState(() => _fetchedImageUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.suggestion;
    final hasPhoto = s.photoPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasPhoto
                        ? Image.file(
                            File(s.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (a, b, c) =>
                                _iconWidget(theme),
                          )
                        : _fetchedImageUrl != null
                            ? Image.network(
                                _fetchedImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (a, b, c) =>
                                    _iconWidget(theme),
                                loadingBuilder: (ctx, child, progress) =>
                                    progress == null
                                        ? child
                                        : _iconWidget(theme),
                              )
                            : _iconWidget(theme),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            if (s.isInMyBox) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green.shade600),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(s.type,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  // Score badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(s.score).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.score.toStringAsFixed(0)}/10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor(s.score),
                      ),
                    ),
                  ),
                ],
              ),
              // Reasons
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: s.reasons.map((r) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 11, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(r,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary)),
                    ],
                  ),
                )).toList(),
              ),
              // Add to box button
              if (widget.onAdd != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add to my tackle box',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(ThemeData theme) {
    return Center(
      child: Text(widget.suggestion.icon,
          style: const TextStyle(fontSize: 24)),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.grey;
  }
}

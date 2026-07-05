import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_config.dart';
import '../services/community_stats_service.dart';
import '../services/pro_service.dart';
import '../services/analytics_service.dart';
import '../services/help_text.dart';

class CommunityStatsScreen extends StatefulWidget {
  const CommunityStatsScreen({super.key});

  @override
  State<CommunityStatsScreen> createState() => _CommunityStatsScreenState();
}

class _CommunityStatsScreenState extends State<CommunityStatsScreen> {
  // Screen states: 'welcome' | 'no_pro' | 'search' | 'loading' | 'results'
  String _screen = 'checking';
  String? _locationName;
  String? _waterBody;
  List<CommunitySpeciesStats> _species = [];

  // Search
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, String>> _searchResults = [];
  Timer? _debounce;
  String _lastQuery = '';

  // State picker
  bool _showStatePicker = false;

  static const _states = [
    'Ontario', 'Quebec', 'British Columbia', 'Alberta', 'Manitoba',
    'Saskatchewan', 'Nova Scotia', 'New Brunswick', 'Newfoundland and Labrador',
    'Prince Edward Island', 'Northwest Territories', 'Nunavut', 'Yukon',
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
    'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia',
    'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
    'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
    'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
    'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey',
    'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
    'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
    'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
    'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
  ];

  @override
  void initState() {
    super.initState();
    _checkPro();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _checkPro() {
    if (ProService.instance.isPro) {
      setState(() => _screen = 'welcome');
    } else {
      setState(() => _screen = 'no_pro');
    }
  }

  // ─── Google Places Search ───────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _lastQuery = query;
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _showStatePicker = false; });
      return;
    }
    if (!ProService.instance.isPro) {
      ProService.showUpgradeDialog(context);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      AnalyticsService.instance.logLakeSearch(query);
    _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    final apiKey = ApiConfig.googleMapsApiKey;
    setState(() { _searching = true; _showStatePicker = false; });
    try {
      // Try Google Places first (best results)
      var results = await _googlePlacesSearch(query, apiKey);
      // If Google finds nothing, try Nominatim as fallback
      if (results.isEmpty) {
        results = await _nominatimLakeSearch(query);
      }
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (_) {
      // Final fallback: try Nominatim
      final results = await _nominatimLakeSearch(query);
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    }
  }

  Future<List<Map<String, String>>> _googlePlacesSearch(
      String query, String apiKey) async {
    if (apiKey.isEmpty) return [];
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeQueryComponent(query)}'
          '&region=us,ca'
          '&key=$apiKey');
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];
      final r = (data['results'] as List<dynamic>?) ?? [];
      return _parsePlacesResults(r);
    } catch (_) { return []; }
  }

  Future<List<Map<String, String>>> _nominatimLakeSearch(String query) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeQueryComponent(query)}'
          '&format=json'
          '&limit=8'
          '&countrycodes=us,ca');
      final resp = await http.get(url,
          headers: {'User-Agent': 'BestFishBuddy/1.0'}).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as List<dynamic>;
      final results = <Map<String, String>>[];
      final seen = <String>{};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final displayName = map['display_name'] as String? ?? '';
        final lat = map['lat'] as String?;
        final lon = map['lon'] as String?;
        if (lat == null || lon == null) continue;
        final parts = displayName.split(',');
        final name = parts[0].trim();
        if (name.isEmpty || seen.contains(name)) continue;
        seen.add(name);
        String? state;
        for (int i = parts.length - 1; i >= 0; i--) {
          final p = parts[i].trim();
          if (_states.contains(p)) { state = p; break; }
        }
        if (state == null) continue;
        String subtitle;
        if (parts.length >= 3) {
          subtitle = '${parts[1].trim()} · $state';
        } else {
          subtitle = state;
        }
        results.add({
          'name': name,
          'state': state,
          'vicinity': subtitle,
          'lat': lat,
          'lng': lon,
        });
      }
      return results;
    } catch (_) { return []; }
  }

  List<Map<String, String>> _parsePlacesResults(List<dynamic> results) {
    final parsed = <Map<String, String>>[];
    final seen = <String>{};
    for (final r in results) {
      final map = r as Map<String, dynamic>;
      final name = map['name'] as String? ?? '';
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      final vicinity = map['formatted_address'] as String? ?? map['vicinity'] as String? ?? '';
      final geo = map['geometry'] as Map?;
      final loc = geo?['location'] as Map?;
      final lat = loc?['lat'] as num?;
      final lng = loc?['lng'] as num?;
      if (lat == null || lng == null) continue;
      final state = _extractState(vicinity);
      if (state == null) continue;
      parsed.add({
        'name': name,
        'state': state,
        'vicinity': vicinity.split(',').take(2).join(',').trim(),
        'lat': lat.toString(),
        'lng': lng.toString(),
      });
    }
    return parsed;
  }

  /// Extract a matching state/province from an address string.
  String? _extractState(String address) {
    final lower = address.toLowerCase();
    for (final s in _states) {
      if (lower.contains(s.toLowerCase())) return s;
    }
    // Try abbreviation matching
    const abbrs = {
      'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas',
      'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware',
      'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho',
      'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas',
      'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
      'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi',
      'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada',
      'NH': 'New Hampshire', 'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York',
      'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma',
      'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
      'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah',
      'VT': 'Vermont', 'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia',
      'WI': 'Wisconsin', 'WY': 'Wyoming',
      'AB': 'Alberta', 'BC': 'British Columbia', 'MB': 'Manitoba',
      'NB': 'New Brunswick', 'NL': 'Newfoundland and Labrador',
      'NS': 'Nova Scotia', 'NT': 'Northwest Territories', 'NU': 'Nunavut',
      'ON': 'Ontario', 'PE': 'Prince Edward Island', 'QC': 'Quebec',
      'SK': 'Saskatchewan', 'YT': 'Yukon',
    };
    for (final e in abbrs.entries) {
      if (lower.contains(e.key.toLowerCase())) return e.value;
    }
    return null;
  }

  void _selectLake(Map<String, String> result) {
    setState(() {
      _waterBody = result['name'];
      _locationName = result['state'];

      _searchResults = [];
      _searchCtrl.text = result['name'] ?? '';
    });
    _loadLakeStats(result['state']!, result['name']!);
  }

  void _selectState(String state) {
    if (!ProService.instance.isPro) {
      ProService.showUpgradeDialog(context);
      return;
    }
    setState(() {
      _waterBody = null;
      _showStatePicker = false;
    });
    _loadStateStats(state);
  }

  // ─── Load Stats ─────────────────────────────────────────────────

  Future<void> _loadStateStats(String state) async {
    setState(() => _screen = 'loading');
    try {
      var stats = await CommunityStatsService.instance.getTopSpecies(state);
      if (stats.isEmpty) stats = CommunityStatsService.instance.getSampleTopSpecies(state);
      if (mounted) {
        setState(() {
          _species = stats;
          _locationName = state;
          _screen = 'results';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _screen = 'welcome');
    }
  }

  Future<void> _refresh() async {
    if (_waterBody != null && _locationName != null) {
      await _loadLakeStats(_locationName!, _waterBody!);
    } else if (_locationName != null) {
      await _loadStateStats(_locationName!);
    }
  }

  Future<void> _loadLakeStats(String state, String lake) async {
    setState(() => _screen = 'loading');
    try {
      // Try lake-specific stats first
      var stats = await CommunityStatsService.instance.getTopSpeciesByWater(state, lake);
      // If none, fall back to state-level
      if (stats.isEmpty) {
        stats = await CommunityStatsService.instance.getTopSpecies(state);
        if (stats.isEmpty) stats = CommunityStatsService.instance.getSampleTopSpecies(state);
      }
      if (mounted) {
        setState(() {
          _species = stats;
          _locationName = state;
          _screen = 'results';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _screen = 'welcome');
    }
  }

  Future<void> _autoDetect() async {
    if (!ProService.instance.isPro) {
      ProService.showUpgradeDialog(context);
      setState(() => _screen = 'welcome');
      return;
    }
    setState(() => _screen = 'loading');
    try {
      final pos = await _getLocation();
      if (pos == null) { if (mounted) setState(() => _screen = 'welcome'); return; }
      final state = await _reverseGeocodeState(pos.latitude, pos.longitude);
      if (state == null) { if (mounted) setState(() => _screen = 'welcome'); return; }
      final water = await _reverseGeocodeWater(pos.latitude, pos.longitude);
      if (water != null && water.isNotEmpty) {
        _waterBody = water;
        await _loadLakeStats(state, water);
      } else {
        await _loadStateStats(state);
      }
    } catch (_) {
      if (mounted) setState(() => _screen = 'welcome');
    }
  }

  // ─── GPS / Geocode ───────────────────────────────────────────────

  Future<Position?> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
    } catch (_) { return null; }
  }

  Future<String?> _reverseGeocodeState(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse'
          '?lat=${lat.toStringAsFixed(4)}&lon=${lng.toStringAsFixed(4)}&format=json&zoom=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BestFishBuddy/1.0'}).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return null;
      final state = addr['state'] as String?;
      final cc = addr['country_code'] as String?;
      if (state == null || cc == null || (cc != 'us' && cc != 'ca')) return null;
      return state;
    } catch (_) { return null; }
  }

  Future<String?> _reverseGeocodeWater(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse'
          '?lat=${lat.toStringAsFixed(4)}&lon=${lng.toStringAsFixed(4)}&format=json&zoom=10');
      final resp = await http.get(url, headers: {'User-Agent': 'BestFishBuddy/1.0'}).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return null;
      for (final key in ['water', 'river', 'lake', 'reservoir', 'bay']) {
        if (addr[key] != null) return addr[key] as String;
      }
      return null;
    } catch (_) { return null; }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreen('community_stats');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people, size: 20),
            SizedBox(width: 8),
            Text('Community Stats'),
          ],
        ),
        actions: [
          if (_species.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search another lake',
              onPressed: () => setState(() { _species = []; _screen = 'welcome'; }),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(theme),
          ),
          helpChip(context, 'community_stats'),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_screen) {
      case 'no_pro': return _buildProGate(theme);
      case 'loading': return const Center(child: Column(mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading...')]));
      case 'results': return _buildResultsView(theme);
      default: return _buildSearchView(theme);
    }
  }

  Widget _buildProGate(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(
            color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.star, size: 40, color: Colors.amber)),
          const SizedBox(height: 24),
          Text('Pro Feature', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Search any lake in Canada and the US to see what fellow anglers are catching, what lures work best, and peak seasons.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: FilledButton.icon(
              onPressed: () => ProService.showUpgradeDialog(context),
              icon: const Icon(Icons.star), label: const Text('Upgrade to Pro')),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchView(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        const SizedBox(height: 16),
        Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.water, size: 36, color: theme.colorScheme.primary))),
        const SizedBox(height: 20),
        Text('Search any lake in Canada & US',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Powered by Google Places — finds any lake, river, or reservoir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        // Search
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search lake, river, or reservoir...',
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: _searching
                ? const Padding(padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() { _searchResults = []; }); })
                    : null,
            filled: true, fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        // Results
        if (_searchResults.isNotEmpty)
          ..._searchResults.map((r) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.water, size: 20, color: theme.colorScheme.primary)),
              title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${r['state']}  ·  ${r['vicinity']}', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              dense: true, onTap: () => _selectLake(r),
            ),
          )),
        if (_searchResults.isEmpty && _lastQuery.isNotEmpty && !_searching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(children: [
                Icon(Icons.search_off, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text("Couldn't find '$_lastQuery'.",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Try a different name, or browse by state/province below.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showStatePicker = true),
            icon: const Icon(Icons.list, size: 18),
            label: const Text('Browse by state/province'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _autoDetect,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use my current location'),
          ),
        ),
        if (_showStatePicker) _buildStatePickerWidget(theme),
        if (!_showStatePicker && _searchResults.isEmpty && _lastQuery.isEmpty)
          _buildSamplePreview(theme),
      ],
    );
  }

  Widget _buildStatePickerWidget(ThemeData theme) {
    final canada = _states.take(13).toList();
    final usa = _states.skip(13).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text('Canada', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6,
        children: canada.map((s) => ActionChip(
          avatar: const Text('🇨🇦', style: TextStyle(fontSize: 14)),
          label: Text(s, style: const TextStyle(fontSize: 12)),
          onPressed: () => _selectState(s),
        )).toList(),
      ),
      const SizedBox(height: 16),
      Text('United States', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6,
        children: usa.map((s) => ActionChip(
          avatar: const Text('🇺🇸', style: TextStyle(fontSize: 14)),
          label: Text(s, style: const TextStyle(fontSize: 12)),
          onPressed: () => _selectState(s),
        )).toList(),
      ),
    ]);
  }

  Widget _buildSamplePreview(ThemeData theme) {
    final sample = CommunityStatsService.instance.getSampleTopSpecies('Ontario');
    if (sample.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text('Preview', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        _buildSpeciesCard(sample.first, theme),
      ]),
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    final isSample = _species.isNotEmpty && _species.first.isSample;
    final hasLakeData = _waterBody != null && _species.isNotEmpty && !_species.first.isSample;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        // ── Header ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (_waterBody != null) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.water, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_waterBody!, textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 4),
                Text(_locationName ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                if (_waterBody != null)
                  InkWell(
                    onTap: () async {
                      final term = _waterBody!.replaceAll(' ', '_');
                      final url = Uri.parse(
                          'https://en.wikipedia.org/wiki/$term');
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new, size: 13, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Text('Learn more on Wikipedia',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
              ] else ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.location_on, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(_locationName ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ],
              const SizedBox(height: 10),
              Text(
                hasLakeData
                    ? 'Fellow anglers at $_waterBody have been catching:'
                    : 'Fellow anglers in $_locationName have been catching:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (isSample)
                Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text('Sample data — real data appears as catches are recorded',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade400, fontStyle: FontStyle.italic))),
              if (!hasLakeData && _waterBody != null)
                Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text('No data yet for $_waterBody — showing $_locationName-wide stats',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade400, fontStyle: FontStyle.italic))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        ..._species.map((s) => _buildSpeciesCard(s, theme)),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() { _species = []; _screen = 'welcome'; }),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search another lake'),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildSpeciesCard(CommunitySpeciesStats stats, ThemeData theme) {
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stats.species, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${stats.totalCatches} catches recorded', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 8),
          if (stats.topLures.isNotEmpty)
            _insightRow(Icons.vrpano, 'Top lures', stats.topLures, theme.colorScheme.primary, muted),
          if (stats.topWeather.isNotEmpty)
            _insightRow(Icons.wb_sunny, 'Conditions', stats.topWeather, Colors.amber.shade700, muted),
          if (stats.topMonths.isNotEmpty)
            _insightRow(Icons.calendar_month, 'Best months', stats.topMonths, Colors.green.shade700, muted),
        ]),
      ),
    );
  }

  Widget _insightRow(IconData icon, String label, List<CountEntry> entries, Color color, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: muted)),
        Expanded(child: Text(entries.map((e) => '${e.label}').join(' · '),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
      ]),
    );
  }
}

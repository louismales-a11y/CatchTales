import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../models/catch.dart';
import '../models/favorite_spot.dart';
import '../services/database_service.dart';
import '../services/pro_service.dart';
import 'spots_screen.dart';
import '../services/analytics_service.dart';

const _defaultCenter = LatLng(39.8283, -98.5795);
const _defaultZoom = 4.0;
const _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Catch> _catchesWithLocation = [];
  List<FavoriteSpot> _spots = [];
  List<PlaceResult> _searchResults = [];
  String? _activeCategory;
  LatLng? _userLocation;
  bool _loading = true, _searching = false, _locRequested = false, _showNauticalChart = false;

  // Offline cache
  late String _cacheDir;
  bool _cacheReady = false;
  bool _downloading = false;
  double _dlProgress = 0;
  int _cachedTiles = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _initCache();
      await loadCatches();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Tile Cache ─────────────────────────────────────────────────────────

  Future<void> _initCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cacheDir = p.join(dir.path, 'map_tiles');
      await Directory(_cacheDir).create(recursive: true);
      // Count existing cached tiles
      final files = await _listCacheFiles();
      _cachedTiles = files.length;
      _cacheReady = true;
    } catch (_) {
      _cacheReady = false;
    }
  }

  Future<List<File>> _listCacheFiles() async {
    final dir = Directory(_cacheDir);
    if (!await dir.exists()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
  }

  String _tileCachePath(int z, int x, int y) {
    return p.join(_cacheDir, '$z', '$x', '$y.png');
  }

  Future<void> _cacheTile(int z, int x, int y) async {
    final path = _tileCachePath(z, x, y);
    final file = File(path);
    if (await file.exists()) return; // Already cached

    final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
      // Ignore network errors during caching
    }
  }

  Future<void> _downloadRegion() async {
    if (_downloading) return;
    setState(() { _downloading = true; _dlProgress = 0; });

    try {
      final center = _mapController.camera.center;
      final minLat = center.latitude - 2, maxLat = center.latitude + 2;
      final minLng = center.longitude - 2, maxLng = center.longitude + 2;
      final minZoom = 5, maxZoom = 13;

      // Calculate total tiles
      int total = 0;
      for (int z = minZoom; z <= maxZoom; z++) {
        final tileMinX = _lngToTileX(minLng, z);
        final tileMaxX = _lngToTileX(maxLng, z);
        final tileMinY = _latToTileY(maxLat, z); // y is inverted
        final tileMaxY = _latToTileY(minLat, z);
        total += ((tileMaxX - tileMinX + 1) * (tileMaxY - tileMinY + 1)).ceil();
      }

      int done = 0;
      for (int z = minZoom; z <= maxZoom; z++) {
        final tileMinX = _lngToTileX(minLng, z);
        final tileMaxX = _lngToTileX(maxLng, z);
        final tileMinY = _latToTileY(maxLat, z);
        final tileMaxY = _latToTileY(minLat, z);

        for (int x = tileMinX; x <= tileMaxX; x++) {
          for (int y = tileMinY; y <= tileMaxY; y++) {
            await _cacheTile(z, x, y);
            done++;
            if (done % 10 == 0 && mounted) {
              setState(() => _dlProgress = done / total);
            }
          }
        }
      }

      final files = await _listCacheFiles();
      if (mounted) {
        setState(() {
          _cachedTiles = files.length;
          _downloading = false;
          _dlProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Downloaded ${files.length} tiles for offline use!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _downloading = false; _dlProgress = 0; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  int _lngToTileX(double lng, int z) =>
      ((lng + 180) / 360 * (1 << z)).floor();
  int _latToTileY(double lat, int z) {
    final latRad = lat * 3.1415926535 / 180;
    return ((1 - log(tan(latRad) + 1 / cos(latRad)) / 3.1415926535) / 2 * (1 << z)).floor();
  }

  String get _cacheLabel {
    if (_cachedTiles == 0) return '';
    final size = _fmtBytes(_cachedTiles * 15000); // ~15KB per tile estimate
    return '$_cachedTiles tiles ($size)';
  }

  String _fmtBytes(int b) =>
      b < 1024 ? '${b}B' : b < 1048576 ? '${(b / 1024).toStringAsFixed(1)}KB' : '${(b / 1048576).toStringAsFixed(1)}MB';

  // ─── Data ───────────────────────────────────────────────────────────────

  Future<void> loadCatches() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final catches = await DatabaseService.instance.getCatches();
      final spots = await DatabaseService.instance.getSpots();
      if (mounted) {
        setState(() {
          _catchesWithLocation = catches.where((c) => c.latitude != null && c.longitude != null).toList();
          _spots = spots; _loading = false;
        });
      }
      _maybeLoc();
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _maybeLoc() async {
    if (_locRequested) return;
    _locRequested = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)));
      if (mounted) setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  LatLng get _center => _catchesWithLocation.isNotEmpty
      ? LatLng(_catchesWithLocation.first.latitude!, _catchesWithLocation.first.longitude!)
      : _userLocation ?? _defaultCenter;

  // ─── Search ─────────────────────────────────────────────────────────────

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty || _apiKey.isEmpty) return;
    setState(() => _searching = true);
    try {
      final c = _mapController.camera.center;
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeQueryComponent(query)}&location=${c.latitude},${c.longitude}&radius=50000&key=$_apiKey');
      final r = await http.get(url);
      if (r.statusCode != 200) { _err('Places API error'); setState(() => _searching = false); return; }
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      if (d['status'] != 'OK' && d['status'] != 'ZERO_RESULTS') { _err('Places API: ${d['status']}'); setState(() => _searching = false); return; }
      final results = (d['results'] as List<dynamic>?)?.map((e) => PlaceResult.fromJson(e)).toList() ?? [];
      if (mounted) setState(() { _searchResults = results; _searching = false; });
      if (results.isNotEmpty) _fitResults(results);
    } catch (e) { _err('Search error'); if (mounted) setState(() => _searching = false); }
  }

  void _fitResults(List<PlaceResult> r) {
    if (r.length == 1) { _mapController.move(LatLng(r.first.lat, r.first.lng), 15); return; }
    double a = r.first.lat, b = r.first.lat, c = r.first.lng, d = r.first.lng;
    for (final x in r) { if (x.lat < a) a = x.lat; if (x.lat > b) b = x.lat; if (x.lng < c) c = x.lng; if (x.lng > d) d = x.lng; }
    _mapController.move(LatLng((a + b) / 2, (c + d) / 2), 10);
  }

  bool _checkProAccess() {
    if (ProService.instance.isPro) return true;
    ProService.showUpgradeDialog(context);
    return false;
  }

  void _onCategoryTap(_SearchCat cat) {
    if (!_checkProAccess()) return;
    if (_activeCategory == cat.label) { setState(() { _activeCategory = null; _searchResults = []; }); return; }
    setState(() => _activeCategory = cat.label);
    _searchCtrl.text = cat.query; _searchPlaces(cat.query);
  }

  void _onSearchSubmit(String v) {
    if (!_checkProAccess()) return;
    setState(() => _activeCategory = null); _focusNode.unfocus(); if (v.trim().isNotEmpty) _searchPlaces(v);
  }

  // ─── Locate ─────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) { _err('Location disabled'); return; }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) { _err('Permission denied'); return; }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
      if (mounted) { final loc = LatLng(pos.latitude, pos.longitude); setState(() => _userLocation = loc); _mapController.move(loc, 15); }
    } catch (e) { _err('Could not get location'); }
  }

  // ─── Spots ──────────────────────────────────────────────────────────────

  void _addSpotAt(LatLng ll) {
    final c = TextEditingController(), s = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Save as Favorite Spot'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Spot name *', hintText: 'e.g. Secret Cove'), textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12), Text('${ll.latitude.toStringAsFixed(4)}, ${ll.longitude.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 12), TextField(controller: s, decoration: const InputDecoration(labelText: 'Best species (optional)'), textCapitalization: TextCapitalization.words),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (c.text.trim().isEmpty) return;
          await DatabaseService.instance.addSpot(FavoriteSpot(name: c.text.trim(), latitude: ll.latitude, longitude: ll.longitude, bestSpecies: s.text.trim().isNotEmpty ? s.text.trim() : null));
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) { final spots = await DatabaseService.instance.getSpots(); setState(() => _spots = spots); }
        }, child: const Text('Save')),
      ],
    ));
  }

  void _openSpotsList() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotsScreen())).then((_) => loadCatches());

  // ─── Directions ─────────────────────────────────────────────────────────

  void _openDirections(PlaceResult p) async {
    // Try Google Maps URL first
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving');
    // Fallback: geo URI (works with any map app)
    final geoUrl = Uri.parse('geo:${p.lat},${p.lng}?q=${p.lat},${p.lng}(${Uri.encodeComponent(p.name)})');
    
    try {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        _err('Could not open maps');
      }
    }
  }

  void _showPlaceSheet(PlaceResult p) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
      final t = Theme.of(ctx);
      return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        Text(p.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (p.rating != null) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), const SizedBox(width: 4), Text('${p.rating}', style: TextStyle(fontSize: 14, color: t.colorScheme.onSurface.withValues(alpha: 0.7))), if (p.userRatingsTotal != null) ...[const SizedBox(width: 4), Text('(${p.userRatingsTotal})', style: TextStyle(fontSize: 13, color: t.colorScheme.onSurface.withValues(alpha: 0.5)))],])],
        if (p.vicinity != null) ...[const SizedBox(height: 4), Row(children: [Icon(Icons.location_on, size: 16, color: t.colorScheme.primary), const SizedBox(width: 4), Expanded(child: Text(p.vicinity!, style: TextStyle(fontSize: 13, color: t.colorScheme.onSurface.withValues(alpha: 0.6))))])],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); _openDirections(p); }, icon: const Icon(Icons.directions, size: 20), label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: t.colorScheme.primary, foregroundColor: t.colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ])));
    });
  }

  void _err(String m) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red.shade700)); }

  // ─── Markers ────────────────────────────────────────────────────────────

  List<Marker> _markers(ThemeData t) {
    final m = <Marker>[];
    for (final c in _catchesWithLocation) {
      m.add(Marker(point: LatLng(c.latitude!, c.longitude!), width: 160, height: 50, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (c.weatherTemp != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.wb_sunny, size: 12, color: Colors.amber), const SizedBox(width: 3), Text('${c.weatherTemp!.round()}°C', style: const TextStyle(fontSize: 10, color: Colors.white))])),
        const SizedBox(height: 2),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: t.colorScheme.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.set_meal, size: 14, color: Colors.white), const SizedBox(width: 4), Text(c.species, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis)])),
      ])));
    }
    for (final s in _spots) {
      m.add(Marker(
        point: LatLng(s.latitude, s.longitude), width: 140, height: 40,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF9C27B0).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star, size: 14, color: Colors.white), const SizedBox(width: 4),
            Flexible(child: Text(s.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ));
    }
    for (final r in _searchResults) {
      m.add(Marker(
        point: LatLng(r.lat, r.lng), width: 180, height: 40,
        child: GestureDetector(
          onTap: () => _showPlaceSheet(r),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on, size: 14, color: Colors.white), const SizedBox(width: 4),
              Flexible(child: Text(r.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ));
    }
    return m;
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]))),
      if (_catchesWithLocation.isEmpty && _searchResults.isEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: t.colorScheme.surface, child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: t.colorScheme.primary), const SizedBox(width: 8),
          Expanded(child: Text('Add catches with GPS location to see markers, or search below', style: TextStyle(fontSize: 13, color: t.colorScheme.onSurface.withValues(alpha: 0.7)))),
        ])),
      Expanded(child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _center, initialZoom: _catchesWithLocation.isNotEmpty ? 10.0 : _defaultZoom, onLongPress: (_, ll) => _addSpotAt(ll)),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bestfishbuddy.bestfishbuddy',
            ),
            MarkerLayer(markers: _markers(t)),
          ],
        ),
        if (_downloading) Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(value: _dlProgress > 0 ? _dlProgress : null, backgroundColor: Colors.black26)),
        Positioned(right: 16, bottom: 30, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_cacheReady) ...[
            FloatingActionButton.small(
              heroTag: 'dl',
              onPressed: _downloading ? null : _downloadRegion,
              backgroundColor: t.colorScheme.surface,
              elevation: 4,
              tooltip: _cachedTiles > 0 ? 'Offline ($_cacheLabel)' : 'Download offline area',
              child: Icon(
                _downloading
                    ? Icons.hourglass_top
                    : _cachedTiles > 0
                        ? Icons.cloud_done
                        : Icons.cloud_download,
                color: t.colorScheme.primary,
                size: 20,
              ),
            ),
            if (_cachedTiles > 0) const SizedBox(height: 12),
          ],
          FloatingActionButton.small(
            heroTag: 'nautical',
            onPressed: () { AnalyticsService.instance.logNauticalChartToggled(!_showNauticalChart); setState(() => _showNauticalChart = !_showNauticalChart); },
            backgroundColor: _showNauticalChart ? t.colorScheme.primary : t.colorScheme.surface,
            elevation: 4,
            tooltip: _showNauticalChart ? 'Hide nautical chart' : 'Show nautical chart (depths, wrecks, buoys)',
            child: Icon(Icons.directions_boat, color: _showNauticalChart ? Colors.white : t.colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'spots',
            onPressed: _openSpotsList,
            backgroundColor: t.colorScheme.surface,
            elevation: 4,
            tooltip: 'Favorite spots',
            child: Icon(Icons.star, color: t.colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'locate',
            onPressed: _goToMyLocation,
            backgroundColor: t.colorScheme.surface,
            elevation: 4,
            tooltip: 'Locate me',
            child: Icon(Icons.my_location, color: t.colorScheme.primary, size: 22),
          ),
        ])),
        Positioned(top: 12, left: 12, right: 12, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Material(elevation: 4, borderRadius: BorderRadius.circular(28), color: t.colorScheme.surface, child: TextField(
            controller: _searchCtrl, focusNode: _focusNode, onSubmitted: _onSearchSubmit, textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: ProService.instance.isPro ? 'Search places...' : '🔒 Search places (Pro)', hintStyle: TextStyle(color: t.colorScheme.onSurface.withValues(alpha: 0.4)),
              prefixIcon: _searching ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : Icon(Icons.search, color: t.colorScheme.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { _searchCtrl.clear(); setState(() { _searchResults = []; _activeCategory = null; }); }) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none), filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ), onChanged: (_) => setState(() {}),
          )),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _categories.map((cat) {
            final active = _activeCategory == cat.label;
            final isPro = ProService.instance.isPro;
            return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              avatar: Icon(isPro ? cat.icon : Icons.lock, size: 16, color: active ? Colors.white : t.colorScheme.primary),
              label: Text(isPro ? cat.label : '${cat.label} 🔒', style: TextStyle(fontSize: 13, color: active ? Colors.white : t.colorScheme.onSurface)),
              selected: active, onSelected: (_) => _onCategoryTap(cat), selectedColor: t.colorScheme.primary, checkmarkColor: Colors.white,
              showCheckmark: false, backgroundColor: t.colorScheme.surface.withValues(alpha: 0.85), side: BorderSide.none,
              elevation: active ? 2 : 1, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
            ));
          }).toList())),
          if (_searchResults.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: t.colorScheme.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
            child: Text('${_searchResults.length} place${_searchResults.length == 1 ? "" : "s"} found', style: TextStyle(fontSize: 12, color: t.colorScheme.onSurface.withValues(alpha: 0.6)))),
        ])),
      ])),
    ]);
  }
}

class _SearchCat {
  final String label, query;
  final IconData icon;
  const _SearchCat(this.label, this.icon, this.query);
}

const _categories = [
  _SearchCat('Boat Launches', Icons.directions_boat_filled, 'boat launch near me'),
  _SearchCat('Bait Shops', Icons.pets, 'bait and tackle shop near me'),
  _SearchCat('Gas Stations', Icons.local_gas_station, 'gas station near me'),
];

class PlaceResult {
  final String placeId, name;
  final String? vicinity;
  final double lat, lng;
  final double? rating;
  final int? userRatingsTotal;
  const PlaceResult({required this.placeId, required this.name, this.vicinity, required this.lat, required this.lng, this.rating, this.userRatingsTotal});
  factory PlaceResult.fromJson(Map<String, dynamic> j) {
    final l = (j['geometry'] as Map?)?['location'] as Map?;
    return PlaceResult(placeId: j['place_id'] as String? ?? '', name: j['name'] as String? ?? '',
        vicinity: j['formatted_address'] as String? ?? j['vicinity'] as String?,
        lat: (l?['lat'] as num?)?.toDouble() ?? 0, lng: (l?['lng'] as num?)?.toDouble() ?? 0,
        rating: (j['rating'] as num?)?.toDouble(), userRatingsTotal: j['user_ratings_total'] as int?);
  }
}

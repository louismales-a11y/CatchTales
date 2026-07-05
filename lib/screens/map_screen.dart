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
import '../models/depth_reading.dart';
import '../services/database_service.dart';
import '../services/pro_service.dart';
import '../services/offline_region_service.dart';
import '../services/api_config.dart';
import 'spots_screen.dart';
import 'offline_maps_screen.dart';


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
  bool _loading = true, _searching = false, _locRequested = false, _showNauticalChart = false, _showDepth = false, _showDepthReadings = false;
  List<DepthReading> _depthReadings = [];
  String? _weatherLayer; // null = off, 'clouds_new', 'precipitation_new', 'temp_new'

  // Region selection
  bool _selectingRegion = false;
  LatLng? _regionStart;
  LatLng? _regionEnd;
  final _regionNameCtrl = TextEditingController();
  bool _panelOpen = false;

  // Offline cache
  late String _cacheDir;
  bool _downloading = false;
  double _dlProgress = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await OfflineRegionService.instance.init();
      await _initCache();
      await loadCatches();
      await _loadDepthReadings();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _regionNameCtrl.dispose();
    super.dispose();
  }

  // ─── Tile Cache ─────────────────────────────────────────────────────────

  Future<void> _initCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cacheDir = p.join(dir.path, 'map_tiles');
      await Directory(_cacheDir).create(recursive: true);
    } catch (_) {}
  }



  // ─── Data ───────────────────────────────────────────────────────────────

  Future<void> _loadDepthReadings() async {
    try {
      final readings = await DatabaseService.instance.getDepthReadings();
      if (mounted) setState(() => _depthReadings = readings);
    } catch (_) {}
  }

  void _logDepthAt(LatLng ll) {
    final depthCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Depth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${ll.latitude.toStringAsFixed(4)}, ${ll.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: depthCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Depth (feet)',
                hintText: 'e.g. 12.5',
                border: OutlineInputBorder(),
                suffixText: 'ft',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final depth = double.tryParse(depthCtrl.text.trim());
              if (depth == null || depth <= 0) return;
              final r = DepthReading(
                latitude: ll.latitude,
                longitude: ll.longitude,
                depthFeet: depth,
              );
              await DatabaseService.instance.addDepthReading(r);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadDepthReadings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

  void _showLocationActions(LatLng ll) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Save as Favorite Spot'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addSpotAt(ll);
                },
              ),
              ListTile(
                leading: Icon(Icons.monitor_weight, color: Colors.blue.shade600),
                title: const Text('Log Depth Here'),
                subtitle: const Text('Enter depth from your fish finder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _logDepthAt(ll);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fabLabel(IconData icon, String label, VoidCallback onTap, ThemeData t, {bool active = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: active ? t.colorScheme.primary : t.colorScheme.surface,
          elevation: 4,
          child: Icon(icon, color: active ? Colors.white : t.colorScheme.primary, size: 20),
        ),
      ],
    );
  }

  // ─── Region Selection ───────────────────────────────────────────────────

  void _onRegionTap(LatLng ll) {
    if (_regionStart == null) {
      setState(() => _regionStart = ll);
    } else if (_regionEnd == null) {
      setState(() => _regionEnd = ll);
      _confirmRegionDownload();
    } else {
      // Reset and start over
      setState(() {
        _regionStart = ll;
        _regionEnd = null;
      });
    }
  }

  Future<void> _confirmRegionDownload() async {
    if (_regionStart == null || _regionEnd == null) return;
    final minLat = min(_regionStart!.latitude, _regionEnd!.latitude);
    final maxLat = max(_regionStart!.latitude, _regionEnd!.latitude);
    final minLng = min(_regionStart!.longitude, _regionEnd!.longitude);
    final maxLng = max(_regionStart!.longitude, _regionEnd!.longitude);
    final estTiles = OfflineRegionService.estimateTileCount(minLat, maxLat, minLng, maxLng);
    final estSize = estTiles * 15000; // ~15KB per tile estimate

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Download Region'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimated: $estTiles tiles (~${OfflineRegionService.fmtBytes(estSize)})'),
              const SizedBox(height: 4),
              Text('Zoom levels 5–13', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              if (_showDepth || _showNauticalChart) ...[const SizedBox(height: 4),
                Row(children: [
                  if (_showDepth) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('+ Depth tiles', style: TextStyle(fontSize: 10, color: Colors.blue.shade700))),
                  const SizedBox(width: 6),
                  if (_showNauticalChart) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('+ Nautical tiles', style: TextStyle(fontSize: 10, color: Colors.teal.shade700))),
                ]),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Region name',
                  hintText: 'e.g. Lake St. Clair',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      setState(() { _selectingRegion = false; _regionStart = null; _regionEnd = null; });
      return;
    }

    await _downloadNamedRegion(name, minLat, maxLat, minLng, maxLng);
  }

  Future<void> _downloadNamedRegion(
      String name, double minLat, double maxLat, double minLng, double maxLng) async {
    if (_downloading) return;
    setState(() { _downloading = true; _dlProgress = 0; });

    final regionId = 'reg_${DateTime.now().millisecondsSinceEpoch}';
    const minZoom = 5, maxZoom = 13;

    try {
      // Calculate total tiles
      int total = 0;
      for (int z = minZoom; z <= maxZoom; z++) {
        final txMin = OfflineRegionService.lngToTileX(minLng, z);
        final txMax = OfflineRegionService.lngToTileX(maxLng, z);
        final tyMin = OfflineRegionService.latToTileY(maxLat, z);
        final tyMax = OfflineRegionService.latToTileY(minLat, z);
        total += ((txMax - txMin + 1) * (tyMax - tyMin + 1));
      }

      // Cache base tiles
      int done = 0;
      int totalBytes = 0;
      final baseDir = p.join(_cacheDir, regionId, 'base');

      for (int z = minZoom; z <= maxZoom; z++) {
        final txMin = OfflineRegionService.lngToTileX(minLng, z);
        final txMax = OfflineRegionService.lngToTileX(maxLng, z);
        final tyMin = OfflineRegionService.latToTileY(maxLat, z);
        final tyMax = OfflineRegionService.latToTileY(minLat, z);

        for (int x = txMin; x <= txMax; x++) {
          for (int y = tyMin; y <= tyMax; y++) {
            final file = File(p.join(baseDir, '$z', '$x', '$y.png'));
            if (!await file.exists()) {
              try {
                final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
                final response = await http.get(Uri.parse(url));
                if (response.statusCode == 200) {
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(response.bodyBytes);
                  totalBytes += response.bodyBytes.length;
                }
              } catch (_) {}
            }
            done++;
            if (done % 10 == 0 && mounted) {
              setState(() => _dlProgress = done / total);
            }
          }
        }
      }

      // Cache depth tiles if overlay was on
      if (_showDepth) {
        await _cacheOverlayTiles(regionId, 'depth', minLat, maxLat, minLng, maxLng,
            'https://tiles.openseamap.org/depth/{z}/{x}/{y}.png');
      }

      // Cache nautical tiles if overlay was on
      if (_showNauticalChart) {
        await _cacheOverlayTiles(regionId, 'nautical', minLat, maxLat, minLng, maxLng,
            'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png');
      }

      // Save region metadata
      final region = OfflineRegion(
        id: regionId,
        name: name,
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        tileCount: done,
        byteSize: totalBytes,
        hasDepth: _showDepth,
        hasNautical: _showNauticalChart,
      );
      await OfflineRegionService.instance.add(region);

      if (mounted) {
        setState(() {
          _downloading = false;
          _dlProgress = 0;
          _selectingRegion = false;
          _regionStart = null;
          _regionEnd = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" downloaded ($done tiles)'),
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

  Future<void> _cacheOverlayTiles(String regionId, String layer,
      double minLat, double maxLat, double minLng, double maxLng, String urlTemplate) async {
    const minZoom = 5, maxZoom = 13;
    final dir = p.join(_cacheDir, regionId, layer);

    for (int z = minZoom; z <= maxZoom; z++) {
      final txMin = OfflineRegionService.lngToTileX(minLng, z);
      final txMax = OfflineRegionService.lngToTileX(maxLng, z);
      final tyMin = OfflineRegionService.latToTileY(maxLat, z);
      final tyMax = OfflineRegionService.latToTileY(minLat, z);

      for (int x = txMin; x <= txMax; x++) {
        for (int y = tyMin; y <= tyMax; y++) {
          final file = File(p.join(dir, '$z', '$x', '$y.png'));
          if (!await file.exists()) {
            try {
              final url = urlTemplate
                  .replaceAll('{z}', '$z')
                  .replaceAll('{x}', '$x')
                  .replaceAll('{y}', '$y');
              final response = await http.get(Uri.parse(url));
              if (response.statusCode == 200) {
                await file.parent.create(recursive: true);
                await file.writeAsBytes(response.bodyBytes);
              }
            } catch (_) {}
          }
        }
      }
    }
  }

  Widget _buildRegionInfo(BuildContext context, ThemeData t) {
    if (_regionStart == null || _regionEnd == null) return const SizedBox.shrink();
    final minLat = min(_regionStart!.latitude, _regionEnd!.latitude);
    final maxLat = max(_regionStart!.latitude, _regionEnd!.latitude);
    final minLng = min(_regionStart!.longitude, _regionEnd!.longitude);
    final maxLng = max(_regionStart!.longitude, _regionEnd!.longitude);
    final estTiles = OfflineRegionService.estimateTileCount(minLat, maxLat, minLng, maxLng);
    final estSize = estTiles * 15000;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: t.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected Region',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('$estTiles tiles (~${OfflineRegionService.fmtBytes(estSize)})',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: _downloading ? null : () => _confirmRegionDownload(),
                    icon: _downloading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, size: 16),
                    label: Text(_downloading ? 'Downloading...' : 'Download',
                        style: const TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_showDepth || _showNauticalChart) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  if (_showDepth)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text('Depth', style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  if (_showNauticalChart)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_boat, size: 12, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text('Nautical', style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
    // Depth readings
    if (_showDepthReadings) {
      for (final d in _depthReadings) {
        m.add(Marker(
          point: LatLng(d.latitude, d.longitude),
          width: 100,
          height: 36,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade600.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_weight, size: 14, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  '${d.depthFeet.toStringAsFixed(1)}ft',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ));
      }
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
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _catchesWithLocation.isNotEmpty ? 10.0 : _defaultZoom,
            onLongPress: (_, ll) => _selectingRegion ? _onRegionTap(ll) : _showLocationActions(ll),
            onTap: (_, ll) {
              if (_selectingRegion) _onRegionTap(ll);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bestfishbuddy.bestfishbuddy',
            ),
            if (_showNauticalChart)
              Opacity(
                opacity: 0.8,
                child: TileLayer(
                  urlTemplate: 'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bestfishbuddy.bestfishbuddy',
                ),
              ),
            if (_showDepth)
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate: 'https://tiles.openseamap.org/depth/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bestfishbuddy.bestfishbuddy',
                ),
              ),
            MarkerLayer(markers: _markers(t)),
            if (_weatherLayer != null)
              Opacity(
                opacity: 0.5,
                child: TileLayer(
                  urlTemplate:
                      'https://tile.openweathermap.org/map/$_weatherLayer/{z}/{x}/{y}.png?appid=${ApiConfig.openWeatherApiKey}',
                  userAgentPackageName: 'com.bestfishbuddy.bestfishbuddy',
                ),
              ),
          ],
        ),
        if (_downloading)
          Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(
              value: _dlProgress > 0 ? _dlProgress : null, backgroundColor: Colors.black26)),
        // Region selection overlay
        if (_selectingRegion && _regionStart != null && _regionEnd != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RegionRectPainter(
                  start: _regionStart!,
                  end: _regionEnd!,
                  color: Colors.blue.withValues(alpha: 0.3),
                  borderColor: Colors.blue,
                ),
              ),
            ),
          ),
        // Region selection info bar
        if (_selectingRegion && _regionStart != null && _regionEnd != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 12,
            right: 12,
            child: _buildRegionInfo(context, t),
          ),
        // Enter region selection hint
        if (_selectingRegion && _regionStart == null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 12,
            right: 12,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.blue.shade300, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap two corners to select a region to download',
                        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sliding FAB panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _panelOpen ? 140 : 0,
                child: ClipRect(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 350),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      _fabLabel(
                        _selectingRegion ? Icons.close : Icons.cloud_download,
                        _selectingRegion ? 'Cancel' : 'Offline',
                        () {
                          if (_selectingRegion) {
                            setState(() { _selectingRegion = false; _regionStart = null; _regionEnd = null; });
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OfflineMapsScreen()));
                          }
                        }, t,
                        active: _selectingRegion,
                      ),
                      const SizedBox(height: 8),
                      _fabLabel(Icons.directions_boat, 'Nautical', () => setState(() => _showNauticalChart = !_showNauticalChart), t,
                          active: _showNauticalChart),
                      const SizedBox(height: 8),
                      _fabLabel(Icons.water, 'Depth', () => setState(() => _showDepth = !_showDepth), t,
                          active: _showDepth),
                      const SizedBox(height: 8),
                      _fabLabel(
                        _weatherLayer == 'clouds_new' ? Icons.wb_cloudy :
                        _weatherLayer == 'precipitation_new' ? Icons.water_drop :
                        _weatherLayer == 'temp_new' ? Icons.thermostat :
                        Icons.wb_cloudy,
                        _weatherLayer == 'clouds_new' ? 'Clouds' :
                        _weatherLayer == 'precipitation_new' ? 'Rain' :
                        _weatherLayer == 'temp_new' ? 'Temp' :
                        'Weather',
                        () {
                          if (_weatherLayer == null) {
                            setState(() => _weatherLayer = 'clouds_new');
                          } else if (_weatherLayer == 'clouds_new') {
                            setState(() => _weatherLayer = 'precipitation_new');
                          } else if (_weatherLayer == 'precipitation_new') {
                            setState(() => _weatherLayer = 'temp_new');
                          } else {
                            setState(() => _weatherLayer = null);
                          }
                        }, t,
                        active: _weatherLayer != null,
                      ),
                      const SizedBox(height: 8),
                      _fabLabel(Icons.star, 'Spots', _openSpotsList, t),
                      const SizedBox(height: 8),
                      _fabLabel(Icons.monitor_weight, 'Depth', () {
                        setState(() => _showDepthReadings = !_showDepthReadings);
                        if (!_showDepthReadings) return;
                        _loadDepthReadings();
                      }, t,
                          active: _showDepthReadings),
                      const SizedBox(height: 8),
                      _fabLabel(Icons.my_location, 'Locate', _goToMyLocation, t),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Handle tab
              GestureDetector(
                onTap: () => setState(() => _panelOpen = !_panelOpen),
                child: Container(
                  width: 22,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(-1, 0))],
                  ),
                  child: Icon(
                    _panelOpen ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
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

/// Paints a translucent rectangle on the map for region selection.
class _RegionRectPainter extends CustomPainter {
  final LatLng start;
  final LatLng end;
  final Color color;
  final Color borderColor;

  _RegionRectPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Note: This is a simplified overlay. In production you'd project
    // LatLng to screen coordinates. For now we fill the entire screen
    // to indicate selection mode is active.
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(0),
    );
    canvas.drawRect(rect.deflate(4).outerRect, paint);
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RegionRectPainter old) =>
      old.start != start || old.end != end;
}

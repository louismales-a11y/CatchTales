import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// A named rectangular region for offline map tile caching.
class OfflineRegion {
  final String id;
  String name;
  double minLat, maxLat, minLng, maxLng;
  int minZoom, maxZoom;
  int tileCount;
  int byteSize;
  DateTime lastDownloaded;
  bool hasDepth;
  bool hasNautical;

  OfflineRegion({
    required this.id,
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.minZoom = 5,
    this.maxZoom = 13,
    this.tileCount = 0,
    this.byteSize = 0,
    DateTime? lastDownloaded,
    this.hasDepth = false,
    this.hasNautical = false,
  }) : lastDownloaded = lastDownloaded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'tileCount': tileCount,
        'byteSize': byteSize,
        'lastDownloaded': lastDownloaded.toIso8601String(),
        'hasDepth': hasDepth,
        'hasNautical': hasNautical,
      };

  factory OfflineRegion.fromJson(Map<String, dynamic> j) => OfflineRegion(
        id: j['id'] as String,
        name: j['name'] as String,
        minLat: (j['minLat'] as num).toDouble(),
        maxLat: (j['maxLat'] as num).toDouble(),
        minLng: (j['minLng'] as num).toDouble(),
        maxLng: (j['maxLng'] as num).toDouble(),
        minZoom: j['minZoom'] as int? ?? 5,
        maxZoom: j['maxZoom'] as int? ?? 13,
        tileCount: j['tileCount'] as int? ?? 0,
        byteSize: j['byteSize'] as int? ?? 0,
        lastDownloaded: DateTime.tryParse(j['lastDownloaded'] as String? ?? '') ?? DateTime.now(),
        hasDepth: j['hasDepth'] as bool? ?? false,
        hasNautical: j['hasNautical'] as bool? ?? false,
      );

  String get sizeLabel {
    final b = byteSize;
    if (b < 1024) return '${b}B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(1)} MB';
  }

  String get tileLabel => '$tileCount tiles';
}

/// Manages saved offline regions.
class OfflineRegionService extends ChangeNotifier {
  static final OfflineRegionService instance = OfflineRegionService._();
  OfflineRegionService._();

  List<OfflineRegion> _regions = [];
  List<OfflineRegion> get regions => List.unmodifiable(_regions);

  // Download progress tracking
  String? _downloadingRegionId;
  double _downloadProgress = 0.0;
  bool get isDownloading => _downloadingRegionId != null;
  String? get downloadingRegionId => _downloadingRegionId;
  double get downloadProgress => _downloadProgress;

  /// Start tracking download progress for a region.
  void startDownload(String regionId) {
    _downloadingRegionId = regionId;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  /// Update download progress (0.0 to 1.0).
  void updateDownloadProgress(double progress) {
    _downloadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Finish tracking download progress.
  void finishDownload() {
    _downloadingRegionId = null;
    _downloadProgress = 1.0;
    notifyListeners();
  }

  late String _filePath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = p.join(dir.path, 'offline_regions.json');
    await _load();
  }

  Future<void> _load() async {
    final file = File(_filePath);
    if (!await file.exists()) return;
    try {
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      _regions = data.map((e) => OfflineRegion.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = File(_filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(_regions.map((r) => r.toJson()).toList()));
  }

  Future<void> add(OfflineRegion region) async {
    _regions.add(region);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _regions.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> update(OfflineRegion region) async {
    final i = _regions.indexWhere((r) => r.id == region.id);
    if (i >= 0) {
      _regions[i] = region;
      notifyListeners();
      await _save();
    }
  }

  Future<void> clearAll() async {
    _regions.clear();
    notifyListeners();
    await _save();
  }

  /// Estimate the number of tiles for a given bounding box and zoom range.
  static int estimateTileCount(double minLat, double maxLat, double minLng, double maxLng,
      {int minZoom = 5, int maxZoom = 13}) {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final txMin = lngToTileX(minLng, z);
      final txMax = lngToTileX(maxLng, z);
      final tyMin = latToTileY(maxLat, z);
      final tyMax = latToTileY(minLat, z);
      total += ((txMax - txMin + 1) * (tyMax - tyMin + 1));
    }
    return total;
  }

  static int lngToTileX(double lng, int z) =>
      ((lng + 180) / 360 * (1 << z)).floor();

  static int latToTileY(double lat, int z) {
    final latRad = lat * 3.1415926535 / 180;
    return ((1 - log(tan(latRad) + 1 / cos(latRad)) / 3.1415926535) / 2 * (1 << z)).floor();
  }

  static String fmtBytes(int b) =>
      b < 1024 ? '${b}B' : b < 1048576 ? '${(b / 1024).toStringAsFixed(1)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';
}

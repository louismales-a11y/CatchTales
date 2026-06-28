import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/catch.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  List<Catch> _catchesWithLocation = [];
  bool _loading = true;
  int _totalCatches = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadCatches());
  }

  Future<void> loadCatches() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final catches = await DatabaseService.instance.getCatches();
      final withLocation = catches
          .where((c) => c.latitude != null && c.longitude != null)
          .toList();
      if (mounted) {
        setState(() {
          _catchesWithLocation = withLocation;
          _totalCatches = catches.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catchesWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No catches with GPS locations yet',
                style:
                    TextStyle(fontSize: 18, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('Add a catch with a GPS location to see it here',
                style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 4),
            Text('$_totalCatches total catches in database',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          _catchesWithLocation.first.latitude!,
          _catchesWithLocation.first.longitude!,
        ),
        initialZoom: 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bestfishbuddy.app',
        ),
        MarkerLayer(
          markers: _catchesWithLocation.map((c) {
            return Marker(
              point: LatLng(c.latitude!, c.longitude!),
              width: 160,
              height: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.weatherTemp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            '${c.weatherTemp!.round()}°C',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.set_meal,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          c.species,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

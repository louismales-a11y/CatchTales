import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/offline_region_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  @override
  void initState() {
    super.initState();
    OfflineRegionService.instance.addListener(_onRegionsChanged);
  }

  @override
  void dispose() {
    OfflineRegionService.instance.removeListener(_onRegionsChanged);
    super.dispose();
  }

  void _onRegionsChanged() => setState(() {});

  Future<void> _refresh() async {
    await OfflineRegionService.instance.init();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteRegion(OfflineRegion region) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Region?'),
        content: Text('Delete cached tiles for "${region.name}" (${region.tileLabel})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (confirmed == true) {
      await OfflineRegionService.instance.remove(region.id);
      await _deleteRegionTiles(region);
    }
  }

  Future<void> _deleteRegionTiles(OfflineRegion region) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final regionDir = Directory(p.join(dir.path, 'map_tiles', region.id));
      if (await regionDir.exists()) {
        await regionDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _clearAll() async {
    final totalTiles = OfflineRegionService.instance.regions.fold<int>(0, (s, r) => s + r.tileCount);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Offline Maps?'),
        content: Text('Delete all $totalTiles cached tiles from all regions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete All'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (confirmed == true) {
      final ids = OfflineRegionService.instance.regions.map((r) => r.id).toList();
      for (final id in ids) {
        await _deleteRegionTiles(OfflineRegion(id: id, name: '', minLat: 0, maxLat: 0, minLng: 0, maxLng: 0));
      }
      await OfflineRegionService.instance.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regions = OfflineRegionService.instance.regions;
    final totalTiles = regions.fold<int>(0, (s, r) => s + r.tileCount);
    final totalBytes = regions.fold<int>(0, (s, r) => s + r.byteSize);
    final svc = OfflineRegionService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Maps')),
      body: Column(
        children: [
          // Download progress bar
          if (svc.isDownloading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text('Downloading map region...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: svc.downloadProgress,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${(svc.downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          Expanded(
            child: regions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_download, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No offline maps', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Go to the Map screen, zoom to an area,\n'
                      'then use the download button to select\n'
                      'and cache a region.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.map, size: 20),
                      label: const Text('Open Map'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_done, size: 48,
                            color: totalTiles > 0 ? Colors.green.shade400 : Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          totalTiles > 0 ? '$totalTiles tiles cached' : 'No cached tiles',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (totalTiles > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            OfflineRegionService.fmtBytes(totalBytes),
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text('${regions.length} region${regions.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Region list
                ...regions.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.map, color: Colors.blue.shade600, size: 22),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.tileLabel} • ${r.sizeLabel}'),
                            if (r.hasDepth || r.hasNautical)
                              Row(
                                children: [
                                  if (r.hasDepth)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4, right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Depth', style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                                    ),
                                  if (r.hasNautical)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Nautical', style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                          onPressed: () => _deleteRegion(r),
                        ),
                        onTap: () => Navigator.pop(context, r),
                      ),
                    )),

                // Clear all button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: totalTiles > 0 ? _clearAll : null,
                    icon: const Icon(Icons.delete_sweep, size: 20),
                    label: const Text('Clear all offline maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }
}

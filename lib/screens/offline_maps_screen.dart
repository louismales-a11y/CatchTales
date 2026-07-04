import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  int _tileCount = 0;
  int _tileSize = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = p.join(dir.path, 'map_tiles');
      final cacheFile = Directory(cacheDir);
      int count = 0;
      int size = 0;
      if (await cacheFile.exists()) {
        final files = cacheFile.listSync(recursive: true).whereType<File>();
        for (final f in files) {
          if (f.path.endsWith('.png')) {
            count++;
            size += await f.length();
          }
        }
      }
      if (mounted) {
        setState(() {
          _tileCount = count;
          _tileSize = size;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Offline Maps?'),
        content: Text('Delete $_tileCount cached tiles ($_fmtBytes(_tileSize))?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory(p.join(dir.path, 'map_tiles'));
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
        await _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline maps cleared'), backgroundColor: Colors.green),
          );
        }
      } catch (_) {}
    }
  }

  String _fmtBytes(int b) =>
      b < 1024 ? '${b}B' : b < 1048576 ? '${(b / 1024).toStringAsFixed(1)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Maps')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_done, size: 48, color: _tileCount > 0 ? Colors.green.shade400 : Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _tileCount > 0 ? '$_tileCount tiles cached' : 'No offline maps',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (_tileCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(_fmtBytes(_tileSize), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _tileCount > 0 ? _clearCache : null,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Clear all offline maps'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.map, size: 20),
                    label: const Text('Back to map'),
                  ),
                ),
                if (_tileCount > 0) ...[
                  const SizedBox(height: 24),
                  Text('Cached areas:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Tiles are organized by zoom level and cover the areas you\'ve downloaded on the map screen.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
    );
  }
}

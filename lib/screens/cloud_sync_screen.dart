import 'package:flutter/material.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import '../services/help_text.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final _cloud = CloudSyncService.instance;
  int _localCount = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final count = await DatabaseService.instance.getCatchCount();
    if (mounted) setState(() => _localCount = count);
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    await _cloud.init();
    setState(() => _busy = false);
    if (mounted) _showResult();
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await _cloud.signOut();
    setState(() => _busy = false);
    if (mounted) _showResult();
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    await _cloud.uploadCatches();
    setState(() => _busy = false);
    if (mounted) _showResult();
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    final count = await _cloud.downloadCatches();
    await _refreshCount();
    setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded $count catches from cloud'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cloud.isAvailable ? 'Synced successfully! ☁️' : 'Cloud sync unavailable'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        actions: [helpButton(context, 'cloud_sync')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _cloud.isAvailable ? Icons.cloud_done : Icons.cloud_off,
                    size: 56,
                    color: _cloud.isAvailable ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cloud.isAvailable ? 'Cloud Connected' : 'Cloud Unavailable',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cloud.isAvailable
                        ? 'Your catches are ready to sync'
                        : 'Firebase not configured — set up google-services.json',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Local count
          Card(
            child: ListTile(
              leading: Icon(Icons.set_meal, color: theme.colorScheme.primary),
              title: const Text('Local Catches'),
              trailing: Text('$_localCount',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: theme.colorScheme.primary)),
            ),
          ),
          const SizedBox(height: 24),

          // Connection buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _cloud.isAvailable && !_busy && !_cloud.isConnected
                        ? _connect
                        : null,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Connect', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _cloud.isAvailable && !_busy && _cloud.isConnected
                        ? _disconnect
                        : null,
                    icon: const Icon(Icons.link_off, size: 18),
                    label: const Text('Disconnect', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sync buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _cloud.isAvailable && !_busy && _cloud.isConnected ? _upload : null,
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: const Text('Upload to Cloud'),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _cloud.isAvailable && !_busy && _cloud.isConnected ? _download : null,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Download from Cloud'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 32),

          // Info
          if (!_cloud.isAvailable)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                'To enable cloud sync, a Firebase project needs to be set up and google-services.json added to the Android project.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

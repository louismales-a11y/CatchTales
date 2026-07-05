import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import '../services/help_text.dart';
import '../services/pro_service.dart';
import '../services/translation_service.dart';
import 'session_screen.dart';

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
    // Re-check connection status
    if (!_cloud.isConnected && _cloud.isAvailable) {
      // Try reconnecting
      Future.microtask(() => _connect());
    }
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
          content: Text(trp('downloadedCatches', {'count': '$count'})),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cloud.isAvailable ? tr('syncedSuccess') : tr('cloudUnavailable')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('cloudSync')),

      ),
      body: Column(
        children: [
          Expanded(
            child: context.watch<ProService>().isPro
                ? _buildCloudContent(theme)
                : _buildUpgradePrompt(theme),
          ),
          helpChip(context, 'cloud_sync'),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud_upload, size: 40, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              tr('cloudSyncIsPro'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tr('cloudSyncProDesc'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => ProService.showUpgradeDialog(context),
                icon: const Icon(Icons.star),
                label: Text(tr('upgradeToPro')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudContent(ThemeData theme) {
    return ListView(
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
                    _cloud.isConnected ? tr('cloudConnected') : _cloud.isAvailable ? tr('connecting') : tr('cloudUnavailable'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _cloud.isConnected ? Colors.green : null),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cloud.isConnected
                        ? tr('readyToSync')
                        : _cloud.lastError.isNotEmpty
                            ? '${tr('error')}: ${_cloud.lastError}'
                            : tr('connecting'),
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
              title: Text(tr('localCatches')),
              trailing: Text('$_localCount',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: theme.colorScheme.primary)),
            ),
          ),
          const SizedBox(height: 24),

          // Fish Together card
          Card(
            child: ListTile(
              leading: Icon(Icons.groups, color: theme.colorScheme.primary),
              title: Text(tr('fishTogether')),
              subtitle: Text(tr('chatShareCatches')),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionScreen())),
            ),
          ),
          const SizedBox(height: 20),

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
                    label: Text(tr('connect'), style: const TextStyle(fontSize: 13)),
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
                    label: Text(tr('disconnect'), style: const TextStyle(fontSize: 13)),
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
              label: Text(tr('uploadToCloud')),
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
              label: Text(tr('downloadFromCloud')),
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
              child: Text(
                tr('cloudSetupInfo'),
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
        ],
      );
  }
}

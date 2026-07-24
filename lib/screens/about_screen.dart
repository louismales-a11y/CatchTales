import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/translation_service.dart';
import '../services/api_config.dart';
import '../services/pro_service.dart';

/// About screen — shows app info, credits, and links.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  bool _checking = false;
  bool _upToDate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  /// Compare two version strings like "v1.8.12" and "v1.8.6".
  bool _isNewerVersion(String tag, String current) {
    final tagParts = tag.replaceAll('v', '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final curParts = current.replaceAll('v', '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final t = i < tagParts.length ? tagParts[i] : 0;
      final c = i < curParts.length ? curParts[i] : 0;
      if (t > c) return true;
      if (t < c) return false;
    }
    return false;
  }

  Future<void> _checkUpdate() async {
    setState(() { _checking = true; _upToDate = false; });
    try {
      // Check the public version endpoint on catchtales.com
      final uri = Uri.parse('https://catchtales.com/version.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tag = data['tag_name'] as String? ?? 'v${data['version'] ?? ''}';

        // Get the direct APK download URL for the current app flavor
        final apks = data['apks'] as Map<String, dynamic>? ?? {};
        final flavor = ApiConfig.appVersion; // 'free', 'pro', or 'dev'
        final apkPath = apks[flavor] as String?;
        final downloadUrl = apkPath != null && apkPath.isNotEmpty
            ? 'https://catchtales.com$apkPath'
            : (data['html_url'] as String? ?? 'https://catchtales.com/download/');

        if (mounted && _isNewerVersion(tag, _version)) {
          final download = await showDialog<bool>(
            context: context, builder: (ctx) => AlertDialog(
              title: Text(tr('updateAvailable')),
              content: Text(trp('updateContent', {'tag': tag, 'version': _version})),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('later'))),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('download'))),
              ],
            ),
          );
          if (download == true && downloadUrl.isNotEmpty) {
            await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
          }
        } else {
          setState(() => _upToDate = true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('checkFailed')), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('checkFailed')), behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('about'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ─── App icon & name ───
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(ApiConfig.appDisplayName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (_version.isNotEmpty)
                  Text(_version, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _checking ? null : _checkUpdate,
                    icon: _checking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.system_update_outlined, size: 18),
                    label: Text(
                      _checking ? 'Checking...' :
                      _upToDate ? tr('upToDate') :
                      tr('checkUpdate'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: _upToDate ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Description ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('aboutDescription'), style: TextStyle(height: 1.6, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Share QR Code ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Share CatchTales', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: QrImageView(
                      data: 'https://catchtales.com/download/CatchTales-v2.14.68-free.apk',
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to download the free version',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Built With ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('builtWith'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _bullets([
                    tr('techFlutter'),
                    tr('techSqlite'),
                    tr('techOsm'),
                    tr('techOwm'),
                    tr('techGooglePlaces'),
                    tr('techStt'),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Sign off ───
          Center(
            child: Text(
              tr('tightLines'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Pro Status ───
          if (ProService.instance.isInitialized)
            Card(
              color: ProService.instance.isPro
                  ? Colors.amber.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      ProService.instance.isPro ? Icons.workspace_premium : Icons.lock_open,
                      size: 20,
                      color: ProService.instance.isPro ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProService.instance.isPro ? 'Pro Active' : 'Free Version',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ProService.instance.isPro ? Colors.amber.shade700 : Colors.grey.shade600,
                            ),
                          ),
                          if (ProService.instance.isPro && ProService.instance.proType != null)
                            Text(
                              ProService.instance.proType == 'lifetime'
                                  ? 'Lifetime license'
                                  : 'Yearly license — expires ${_formatDate(ProService.instance.proExpiresAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // ─── Links ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linkTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => _openUrl('https://catchtales.com/privacy')),
                  const Divider(height: 1),
                  _linkTile(Icons.description_outlined, 'Terms of Service', () => _openUrl('https://catchtales.com/terms')),
                  const Divider(height: 1),
                  _linkTile(Icons.language_outlined, 'Visit Us Online', () => _openUrl('https://www.catchtales.com')),
                  const Divider(height: 1),
                  _linkTile(Icons.mail_outline, 'Contact Us', () => _openUrl('mailto:catchtales@yahoo.com')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Maison Louis Design ───
          Center(
            child: Column(
              children: [
                Image.asset('assets/contact_logo.png', height: 50, width: 50, fit: BoxFit.contain),
                const SizedBox(height: 6),
                Text('Maison Louis Design', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _linkTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'unknown';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {
      // Fallback — just copy to clipboard
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Link copied: $url'),
        ),
      );
    }
  }

  Widget _bullets(List<String> items) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
            Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
          ],
        ),
      )).toList(),
    );
  }
}

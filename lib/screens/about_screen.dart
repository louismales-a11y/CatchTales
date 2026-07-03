import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/help_text.dart';
import '../services/translation_service.dart';
import '../services/pro_service.dart';
import '../services/api_config.dart';

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

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  Future<void> _checkUpdate() async {
    setState(() { _checking = true; _upToDate = false; });
    try {
      final uri = Uri.parse('https://api.github.com/repos/louismales-a11y/BestFishBuddy/releases/latest');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tag = data['tag_name'] as String? ?? '';
        final url = data['html_url'] as String? ?? '';
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
          if (download == true && url.isNotEmpty) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        } else {
          setState(() => _upToDate = true);
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
    final pro = context.watch<ProService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('about')),
        actions: [helpButton(context, 'about')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App icon & name
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo.png',
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text('Best Fish Buddy Pro',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                if (_version.isNotEmpty)
                  Text(_version,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
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
                      _upToDate ? 'Up to date ✓' :
                      'Check for Updates',
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

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('aboutDescription'),
                style: TextStyle(height: 1.6, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),

          // Built with
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('builtWith'),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
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

          // Sign off
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
          // ── Dev Mode Toggle (Developer build only) ──
          if (ApiConfig.isDev) ...[const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('Developer Options',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(pro.isPro ? 'Pro Mode: ON' : 'Pro Mode: OFF',
                          style: TextStyle(
                            fontSize: 14,
                            color: pro.isPro ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: pro.isPro ? FontWeight.w600 : FontWeight.w400,
                          )),
                      const Spacer(),
                      Switch(
                        value: pro.isPro,
                        onChanged: (v) async {
                          if (v) {
                            await ProService.instance.unlockPro();
                          } else {
                            await ProService.instance.resetToFree();
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    pro.isPro
                        ? 'All Pro features unlocked ✓'
                        : 'Free mode active — 10 catch limit, no delete',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          ],
          const SizedBox(height: 24),
          // ── QR Code: Download Free Version ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(tr('shareFreeApp'),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('scanToDownload'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: 'https://tinyurl.com/24572pxx',
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0A0E1A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0A0E1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://tinyurl.com/24572pxx');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(tr('openDownloadPage'), style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _bullets(List<String> items) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: t.colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

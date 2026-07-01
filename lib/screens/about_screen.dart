import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/help_text.dart';

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

  Future<void> _checkUpdate() async {
    setState(() { _checking = true; _upToDate = false; });
    try {
      final uri = Uri.parse('https://api.github.com/repos/louismales-a11y/BestFishBuddy/releases/latest');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tag = data['tag_name'] as String? ?? '';
        final url = data['html_url'] as String? ?? '';
        if (mounted && tag.compareTo(_version) > 0) {
          final download = await showDialog<bool>(
            context: context, builder: (ctx) => AlertDialog(
              title: const Text('Update Available'),
              content: Text('Version $tag is available (current: $_version)\n\nOpen GitHub to download?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Download')),
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
          const SnackBar(content: Text('Could not check for updates'), behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
                Text('Best Fish Buddy',
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
              child: Text(
                'Your hands-free fishing companion.\n'
                'Track catches by voice, snap selfies with your fish, '
                'and never lose a fishing memory.\n\n'
                '🗣️ Voice tally & recording\n'
                '📍 GPS & weather auto-fetch\n'
                '🤳 Selfie camera with countdown\n'
                '🌙 Solunar best fishing times\n'
                '🗺️ Interactive catch map',
                style: TextStyle(height: 1.6, fontSize: 14),
              ),
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
                  Text('Built with',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _bullets([
                    'Flutter & Dart',
                    'SQLite (sqflite)',
                    'OpenStreetMap (flutter_map)',
                    'OpenWeatherMap API',
                    'Google Places API',
                    'Speech-to-text (speech_to_text)',
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign off
          Center(
            child: Text(
              'Tight Lines, Be Safe! 🎣',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/translation_service.dart';
import '../services/api_config.dart';

/// About screen — shows app info, credits, and links.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

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

          // ─── Links ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linkTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => _openUrl('https://www.bestfishbuddy.com/privacy/')),
                  const Divider(height: 1),
                  _linkTile(Icons.description_outlined, 'Terms of Service', () => _openUrl('https://www.bestfishbuddy.com/')),
                  const Divider(height: 1),
                  _linkTile(Icons.mail_outline, 'Contact Us', () => _openUrl('mailto:BestfishBuddy@gmail.com')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Maison Louis Design ───
          Center(
            child: Column(
              children: [
                Image.asset('assets/contact-logo.png', height: 50, width: 50, fit: BoxFit.contain),
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

  Future<void> _openUrl(String url) async {
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

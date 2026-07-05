import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_identity.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String _deviceInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final device = DeviceInfoPlugin();
    String info = '';
    try {
      if (Platform.isAndroid) {
        final android = await device.androidInfo;
        info = '${android.model} (Android ${android.version.release})';
      } else if (Platform.isIOS) {
        final ios = await device.iosInfo;
        info = '${ios.model} (iOS ${ios.systemVersion})';
      }
    } catch (_) {}
    if (mounted) setState(() => _deviceInfo = info);
  }

  Future<String> _buildBody(String subject) async {
    String version = '';
    try {
      final p = await PackageInfo.fromPlatform();
      version = 'v${p.version}';
    } catch (_) {}
    final screen = MediaQuery.of(context).size;
    return '''
--- Auto-generated ---
App: Best Fish Buddy $version
Device: $_deviceInfo
Screen: ${screen.width.toInt()}x${screen.height.toInt()}
Locale: ${WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag()}

--- Describe the issue ---
$subject:

'''; // user types after this
  }

  Future<void> _sendEmail(BuildContext context, String subject) async {
    final body = await _buildBody(subject);
    final uri = Uri.parse(
        'mailto:${AppIdentity.email}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('thanksForFeedback')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating,
              content: Text(tr('noEmailApp'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('contact')),

      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Studio logo
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/contact_logo.png',
                      width: 90, height: 90, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(AppIdentity.studioName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(AppIdentity.email,
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Feedback buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _sendEmail(context, 'Suggest a feature'),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(tr('suggestFeature')),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _sendEmail(context, 'Report a bug'),
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(tr('reportBug')),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Contact info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Email'),
                  subtitle: const Text(AppIdentity.email),
                  onTap: () => _sendEmail(context, ''),
                ),

              ],
            ),
          ),
          // Privacy note
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('privacyDisclaimer'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

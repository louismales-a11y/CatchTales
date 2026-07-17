import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'translation_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

/// Manages Pro/Free feature access.
/// Currently uses SharedPreferences for testing; replace with in-app purchase later.
class ProService extends ChangeNotifier {
  static final ProService instance = ProService._();
  ProService._();

  bool _isPro = false;
  bool _initialized = false;

  bool get isPro => _isPro;
  bool get isInitialized => _initialized;

  /// Maximum catches allowed in free version
  static const int freeCatchLimit = 10;

  /// Maximum tackle items in free version
  static const int freeTackleLimit = 10;

  /// Maximum fish species visible in Fish ID (free)
  static const int freeFishIdLimit = 10;

  /// Load saved Pro status from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;
    _initialized = true;
    notifyListeners();
  }

  /// Unlock Pro (call this when purchase completes).
  Future<void> unlockPro() async {
    AnalyticsService.instance.logProUpgraded();
    _isPro = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);
    // Also update Firestore if user is logged in
    if (AuthService.instance.isLoggedIn) {
      await AuthService.instance.upgradeToPro();
    }
    notifyListeners();
  }

  /// Reset to free (for testing).
  Future<void> resetToFree() async {
    _isPro = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', false);
    notifyListeners();
  }

  /// Check if user can add more catches.
  bool canAddCatch(int currentCount) => _isPro || currentCount < freeCatchLimit;

  /// Check if user can add more tackle items.
  bool canAddTackle(int currentCount) => _isPro || currentCount < freeTackleLimit;

  /// Check if user can view this fish species index (0-based).
  bool canViewFishSpecies(int index) => _isPro || index < freeFishIdLimit;

  /// Stripe Payment Link URL — set this after creating your link
  static const String _payLink = 'https://pay.catchtales.com';

  /// Show upgrade dialog with Stripe Pay Link + Pro code option.
  static void showUpgradeDialog(BuildContext context) {
    AnalyticsService.instance.logProUpgradePrompt();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('upgradeToPro')),
        content: const Text(
          'Unlock unlimited catches, cloud sync, advanced stats, '
          'badges, and more!\n\n'
          'Upgrade instantly — pay online and receive your Pro '
          'code via email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('notNow')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchPayLink(context);
            },
            child: const Text('Buy Pro — \$4.99'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEnterCodeDialog(context);
            },
            child: const Text('I have a Pro Code'),
          ),
        ],
      ),
    );
  }

  /// Open the Stripe Payment Link in the device browser.
  static Future<void> _launchPayLink(BuildContext context) async {
    final uri = Uri.parse(_payLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('Could not open payment page.'),
          ),
        );
      }
    }
  }

  /// Show a dialog to enter a Pro license code.
  static Future<void> _showEnterCodeDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Pro Code'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. PRO-A7X3-K9M2',
            helperText: 'You can enter with or without dashes',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().toUpperCase()),
            child: const Text('Activate'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Normalize: strip dashes/spaces, then reconstruct proper format
    String normalized = result.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (normalized.startsWith('PRO')) {
      normalized = normalized.substring(3);
    }
    // Must have exactly 12 characters (XXXX-XXXX-XXXX without dashes)
    if (normalized.length != 12) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating,
          content: Text('Invalid code format. Please check and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Reconstruct as PRO-XXXX-XXXX-XXXX
    final formatted = 'PRO-${normalized.substring(0, 4)}-${normalized.substring(4, 8)}-${normalized.substring(8, 12)}';

    // Validate the code against Firestore
    final validated = await instance._validateCode(formatted);
    if (!context.mounted) return;

    if (validated) {
      await instance.unlockPro();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, 
          content: Text('Pro unlocked! Thank you for your support!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, 
          content: Text('Invalid or already used code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Validate a Pro code against Firestore.
  /// The code is case-insensitive, stored uppercase.
  /// Accepts codes with or without dashes (e.g. 'PRO-A7X3-K9M2' or 'PROA7X3K9M2').
  Future<bool> _validateCode(String code) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pro_licenses')
          .doc(code)
          .get();

      if (!doc.exists) return false;
      final data = doc.data()!;
      // Code must not be already used
      if (data['used'] == true) return false;

      // Mark as used
      await doc.reference.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}

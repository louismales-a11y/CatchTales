import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'translation_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

/// Manages Pro/Free feature access.
class ProService extends ChangeNotifier {
  static final ProService instance = ProService._();
  ProService._();

  bool _initialized = false;
  /// 'lifetime', 'yearly', or null (free)
  String? _proType;
  /// Expiry timestamp (only for yearly)
  DateTime? _proExpiresAt;

  bool get isInitialized => _initialized;

  /// Whether the user currently has Pro access.
  bool get isPro {
    if (_proType == null) return false;
    if (_proType == 'lifetime') return true;
    if (_proType == 'yearly' && _proExpiresAt != null) {
      return DateTime.now().isBefore(_proExpiresAt!);
    }
    return false;
  }

  /// The type of Pro: 'lifetime', 'yearly', or null.
  String? get proType => _proType;

  /// When yearly Pro expires.
  DateTime? get proExpiresAt => _proExpiresAt;

  /// Maximum catches allowed in free version
  static const int freeCatchLimit = 10;

  /// Maximum tackle items in free version
  static const int freeTackleLimit = 10;

  /// Maximum fish species visible in Fish ID (free)
  static const int freeFishIdLimit = 10;

  /// Load saved Pro status from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _proType = prefs.getString('pro_type');
    final expiresMs = prefs.getInt('pro_expires_at');
    if (expiresMs != null) {
      _proExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresMs);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Unlock Pro with a given type.
  Future<void> unlockPro({String type = 'lifetime'}) async {
    AnalyticsService.instance.logProUpgraded();
    _proType = type;
    if (type == 'yearly') {
      _proExpiresAt = DateTime.now().add(const Duration(days: 365));
    } else {
      _proExpiresAt = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_type', type);
    if (_proExpiresAt != null) {
      await prefs.setInt('pro_expires_at', _proExpiresAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('pro_expires_at');
    }
    // Also update Firestore if user is logged in
    if (AuthService.instance.isLoggedIn) {
      await AuthService.instance.upgradeToPro();
    }
    notifyListeners();
  }

  /// Reset to free.
  Future<void> resetToFree() async {
    _proType = null;
    _proExpiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pro_type');
    await prefs.remove('pro_expires_at');
    notifyListeners();
  }

  /// Check if user can add more catches.
  bool canAddCatch(int currentCount) => isPro || currentCount < freeCatchLimit;

  /// Check if user can add more tackle items.
  bool canAddTackle(int currentCount) => isPro || currentCount < freeTackleLimit;

  /// Check if user can view this fish species index (0-based).
  bool canViewFishSpecies(int index) => isPro || index < freeFishIdLimit;

  /// Stripe Payment Link URL — set this after creating your link
  static const String _payLink = 'https://pay.catchtales.com';

  /// Show upgrade dialog.
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

  /// Show dialog to enter a Pro license code.
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
            helperText: 'Yearly or lifetime code — both work here',
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

    String normalized = result.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (normalized.startsWith('PRO')) {
      normalized = normalized.substring(3);
    }
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
    final formatted = 'PRO-${normalized.substring(0, 4)}-${normalized.substring(4, 8)}-${normalized.substring(8, 12)}';

    // Validate and get the license type
    final resultData = await instance._validateCode(formatted);
    if (!context.mounted) return;

    if (resultData != null) {
      await instance.unlockPro(type: resultData['type'] as String? ?? 'lifetime');
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
  /// Returns the license data (including 'type') if valid, null otherwise.
  Future<Map<String, dynamic>?> _validateCode(String code) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pro_licenses')
          .doc(code)
          .get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['used'] == true) return null;

      // Mark as used
      final licenseType = data['type'] as String? ?? 'lifetime';
      await doc.reference.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return {'type': licenseType};
    } catch (_) {
      return null;
    }
  }
}

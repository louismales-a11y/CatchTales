import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'translation_service.dart';

/// Handles push notifications for weather alerts, solunar reminders, etc.
/// Silent failure — never crashes.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  bool _initialized = false;
  bool _enabled = false;

  /// Whether the user has granted notification permission.
  bool get enabled => _enabled;

  /// Check current permission status.
  Future<bool> checkEnabled() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      _enabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('NotificationService.checkEnabled: $e');
      _enabled = false;
    }
    return _enabled;
  }

  /// Silently sets up FCM infrastructure without requesting permission.
  /// Call [requestPermissionIfNeeded] later at a contextual moment.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final messaging = FirebaseMessaging.instance;

      // Get FCM token (for sending notifications later)
      final token = await messaging.getToken();
      if (token != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await _storeToken(uid, token);
        }
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleMessage);

      // Handle notification taps (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    } catch (e) {
      debugPrint('NotificationService.init: $e');
    }
  }

  /// Shows a contextual dialog explaining why notifications are useful,
  /// then requests system permission. Only shows once automatically;
  /// can be called again from About screen.
  Future<void> requestPermissionIfNeeded(BuildContext context, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && prefs.getBool('notif_prompt_shown') == true) return;
    await prefs.setBool('notif_prompt_shown', true);

    if (!context.mounted) return;

    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_outlined,
                color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Enable Notifications?'),
          ],
        ),
        content: const Text(
          'Get notified for:\n\n'
          '**Weather alerts** — severe storms, high winds, '
          'temperature drops that affect fishing conditions\n\n'
          '**Fish Together** — when a buddy joins your session, '
          'sends a chat message, or shares their GPS location\n\n'
          '**Best fishing times** — daily solunar peak reminders\n\n'
          'You can enable this later in the About screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (allowed == true) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await checkEnabled();
      } catch (e) {
        debugPrint('NotificationService.requestPermission: $e');
      }
    }
  }

  Future<void> _storeToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcm_token': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NotificationService._storeToken: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Notifications are handled by the system UI
  }
}

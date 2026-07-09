import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Local notification service for displaying reminders without a server.
///
/// Used for solunar best fishing time alerts,
/// weather reminders, and general app notifications.
class LocalNotificationService {
  static final LocalNotificationService instance =
      LocalNotificationService._();
  LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _reminderToLogId = 101;
  static const _solunarAlertId = 102;
  static const _weatherAlertId = 103;

  /// Initialize. Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;

    // Init timezone data for scheduled notifications
    tz_data.initializeTimeZones();
  }

  /// Show a simple notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    const androidDetails = AndroidNotificationDetails(
      'catch_tales',
      'CatchTales',
      channelDescription: 'Fishing reminders and alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ── Scheduled Reminders ────────────────────────────────────────────────

  /// Schedule a daily reminder to log today's catches.
  /// Fires at [hour]:[minute] every day.
  Future<void> scheduleDailyReminderToLog({int hour = 19, int minute = 0}) async {
    if (!_initialized) await init();
    
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'catch_tales_reminder',
      'Catch Reminder',
      channelDescription: 'Daily reminder to log your catches',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      _reminderToLogId,
      '🎣 Time to log your catches!',
      'You had a fishing session today — tap to record your catches before you forget.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule a daily solunar best-times notification (morning).
  /// Fires at [hour]:[minute] every day.
  Future<void> scheduleSolunarAlert({int hour = 6, int minute = 0}) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'catch_tales_solunar',
      'Best Fishing Times',
      channelDescription: 'Daily solunar best fishing time alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      _solunarAlertId,
      '🌙 Best Fishing Times Today',
      'Check today\'s solunar periods for the best fishing. Major periods = peak action!',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel the daily reminder.
  Future<void> cancelReminderToLog() async {
    await _plugin.cancel(_reminderToLogId);
  }

  /// Cancel the solunar alert.
  Future<void> cancelSolunarAlert() async {
    await _plugin.cancel(_solunarAlertId);
  }

  /// Cancel a specific notification.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Settings helpers ───────────────────────────────────────────────────

  /// Whether the daily reminder is enabled (stored in SharedPreferences).
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_to_log_enabled') ?? false;
  }

  /// Enable or disable the daily reminder.
  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_to_log_enabled', enabled);
    if (enabled) {
      await scheduleDailyReminderToLog();
    } else {
      await cancelReminderToLog();
    }
  }

  /// Whether the solunar alert is enabled.
  Future<bool> isSolunarAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('solunar_alert_enabled') ?? false;
  }

  /// Enable or disable the solunar alert.
  Future<void> setSolunarAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('solunar_alert_enabled', enabled);
    if (enabled) {
      await scheduleSolunarAlert();
    } else {
      await cancelSolunarAlert();
    }
  }
}

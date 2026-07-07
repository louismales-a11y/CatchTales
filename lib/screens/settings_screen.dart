import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import 'import_export_screen.dart';

/// Settings screen with data transfer, notifications, export, account management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _reminderPrefs = {};

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderPrefs['reminder_to_log_enabled'] = prefs.getBool('reminder_to_log_enabled') ?? false;
    _reminderPrefs['solunar_alert_enabled'] = prefs.getBool('solunar_alert_enabled') ?? false;
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settingsLogOut')),
        content: const Text('Are you sure you want to log out? You can log back in anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('settingsLogOut'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24), SizedBox(width: 8), Text('Delete Account')],
        ),
        content: const Text('Are you sure? This will permanently delete:\n\n'
            '• Your account\n• All your catch records\n• Your profile and settings\n\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete Forever')),
        ],
      ),
    );
    if (confirmed != true) return;
    final typeCtrl = TextEditingController();
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Type 'delete' to confirm"),
        content: TextField(controller: typeCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'delete', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, typeCtrl.text.trim().toLowerCase() == 'delete'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Confirm Delete')),
        ],
      ),
    );
    if (finalConfirm != true) return;
    final success = await AuthService.instance.deleteAccount();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: const Text('Account deleted successfully.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(AuthService.instance.error ?? 'Failed to delete account.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Widget _reminderToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prefKey,
    required VoidCallback onEnable,
    required VoidCallback onDisable,
  }) {
    return StatefulBuilder(
      builder: (ctx, setSt) {
        final enabled = _reminderPrefs[prefKey] ?? false;
        return Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(prefKey, v);
                if (v) { onEnable(); } else { onDisable(); }
                setSt(() {});
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Push Notifications ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      StatefulBuilder(
                        builder: (ctx, setSt) {
                          final enabled = NotificationService.instance.enabled;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: enabled ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              enabled ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: enabled ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                      if (!NotificationService.instance.enabled) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService.instance.requestPermissionIfNeeded(context, force: true);
                          },
                          icon: const Icon(Icons.notifications_active, size: 16),
                          label: Text(tr('settingsEnable'), style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get notified for weather alerts, best fishing times, and Fish Together activity.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Reminder Settings ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(tr('settingsReminders'), style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _reminderToggle(
                    icon: Icons.edit_calendar,
                    title: 'Evening catch reminder',
                    subtitle: 'Remind me to log today\'s catches at 7 PM',
                    prefKey: 'reminder_to_log_enabled',
                    onEnable: () => LocalNotificationService.instance.scheduleDailyReminderToLog(),
                    onDisable: () => LocalNotificationService.instance.cancelReminderToLog(),
                  ),
                  const Divider(height: 16),
                  _reminderToggle(
                    icon: Icons.nights_stay,
                    title: 'Solunar alert',
                    subtitle: 'Daily notification about best fishing times at 6 AM',
                    prefKey: 'solunar_alert_enabled',
                    onEnable: () => LocalNotificationService.instance.scheduleSolunarAlert(),
                    onDisable: () => LocalNotificationService.instance.cancelSolunarAlert(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Export Data ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(tr('settingsExport'), style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Export your catches to share or back up.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportExportScreen())),
                      icon: const Icon(Icons.file_download, size: 18),
                      label: Text(tr('settingsExportOpen'), style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Data Transfer ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(tr('settingsDataTransfer'), style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<ConnectivityService>(
                    builder: (ctx, cs, _) {
                      return Row(
                        children: [
                          Icon(cs.wifiOnly ? Icons.wifi_lock : Icons.wifi, size: 18,
                              color: cs.wifiOnly ? Colors.orange.shade600 : Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('settingsWifiOnly'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(
                                  cs.wifiOnly
                                      ? 'Data transfers (sync, weather, maps) only over WiFi'
                                      : 'Data transfers allowed on mobile data and WiFi',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Switch(value: cs.wifiOnly, onChanged: (v) => cs.setWifiOnly(v)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Log Out ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600))),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(onPressed: _confirmLogout, child: Text(tr('settingsLogOut'))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Delete Account ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.delete_forever_outlined, size: 20, color: Colors.red.shade400),
                      const SizedBox(width: 10),
                      Text(tr('settingsDeleteAccount'), style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete your account and all your data. This cannot be undone.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDeleteAccount,
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: Text(tr('settingsDeleteBtn'), style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

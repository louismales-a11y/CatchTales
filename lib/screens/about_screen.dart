import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'onboarding_screen.dart';
import 'import_export_screen.dart';
import '../services/catches_db_service.dart';
import '../services/notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkNotifStatus();
  }

  Future<void> _checkNotifStatus() async {
    await NotificationService.instance.checkEnabled();
    if (mounted) setState(() {});
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  Future<void> _exportCsv() async {
    try {
      final catches = await CatchesDbService.instance.getCatches();
      if (catches.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('No catches to export'),
          ),
        );
        return;
      }
      // Build CSV
      final buf = StringBuffer();
      buf.writeln('ID,Angler,Species,Location,Lure,Weight,WeightUnit,Length,LengthUnit,'
          'Latitude,Longitude,WeatherTemp,WeatherCondition,Notes,TripName,CaughtAt,CreatedAt');
      for (final c in catches) {
        final esc = (String s) => '"${s.replaceAll('"', '""')}"';
        buf.writeln([
          c.id?.toString() ?? '',
          esc(c.angler),
          esc(c.species),
          esc(c.location),
          esc(c.lure),
          c.weight?.toStringAsFixed(2) ?? '',
          c.weightUnit,
          c.length?.toStringAsFixed(1) ?? '',
          c.lengthUnit,
          c.latitude?.toStringAsFixed(6) ?? '',
          c.longitude?.toStringAsFixed(6) ?? '',
          c.weatherTemp?.toString() ?? '',
          esc(c.weatherCondition ?? ''),
          esc(c.notes ?? ''),
          esc(c.tripName ?? ''),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(c.caughtAt),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(c.createdAt),
        ].join(','));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bestfishbuddy_export.csv');
      await file.writeAsString(buf.toString());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)],
          text: 'Best Fish Buddy catch data export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  Future<void> _exportJson() async {
    try {
      final catches = await CatchesDbService.instance.getCatches();
      if (catches.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('No catches to export'),
          ),
        );
        return;
      }
      final jsonList = catches.map((c) => c.toMap()).toList();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bestfishbuddy_export.json');
      await file.writeAsString(jsonList.toString());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)],
          text: 'Best Fish Buddy catch data export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  Future<void> _exportKml() async {
    try {
      final catches = await CatchesDbService.instance.getCatches();
      final withCoords = catches.where((c) => c.latitude != null).toList();
      if (withCoords.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('No catches with GPS coordinates to export'),
          ),
        );
        return;
      }
      final buf = StringBuffer();
      buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buf.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
      buf.writeln('  <Document>');
      buf.writeln('    <name>Best Fish Buddy - Catch Locations</name>');
      for (final c in withCoords) {
        final dateStr = DateFormat('MMM d, yyyy').format(c.caughtAt);
        buf.writeln('    <Placemark>');
        buf.writeln('      <name>${_xmlEsc(c.species)} by ${_xmlEsc(c.angler)}</name>');
        buf.writeln('      <description>${_xmlEsc(dateStr)}${c.location.isNotEmpty ? ' at ${_xmlEsc(c.location)}' : ''}'
          '${c.weightDisplay.isNotEmpty ? ' - ${_xmlEsc(c.weightDisplay)}' : ''}'
          '${c.lengthDisplay.isNotEmpty ? ' - ${_xmlEsc(c.lengthDisplay)}' : ''}</description>');
        buf.writeln('      <Point>');
        buf.writeln('        <coordinates>${c.longitude},${c.latitude},0</coordinates>');
        buf.writeln('      </Point>');
        buf.writeln('    </Placemark>');
      }
      buf.writeln('  </Document>');
      buf.writeln('</kml>');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bestfishbuddy_catches.kml');
      await file.writeAsString(buf.toString());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)],
          text: 'Best Fish Buddy catch locations');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  String _xmlEsc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll('\'', '&apos;');

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final pro = context.watch<ProService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('about')),
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
          // ── Export Data ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('Export Data',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Download all your catches as CSV or JSON file.',
                    style: TextStyle(fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportCsv(),
                          icon: const Icon(Icons.table_chart, size: 16),
                          label: const Text('CSV',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportJson(),
                          icon: const Icon(Icons.code, size: 16),
                          label: const Text('JSON',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportKml(),
                          icon: const Icon(Icons.public, size: 16),
                          label: const Text('KML',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ImportExportScreen())),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('More',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          // ── Push Notifications ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        NotificationService.instance.enabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        size: 20,
                        color: NotificationService.instance.enabled
                            ? Colors.green.shade600
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Push Notifications',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: NotificationService.instance.enabled
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          NotificationService.instance.enabled ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NotificationService.instance.enabled
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (!NotificationService.instance.enabled) ...[const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService.instance.requestPermissionIfNeeded(context, force: true);
                            await _checkNotifStatus();
                          },
                          icon: const Icon(Icons.notifications_active, size: 16),
                          label: const Text('Enable', style: TextStyle(fontSize: 12)),
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
                    'Get notified for weather alerts (storms, high winds), '
                    'best fishing times, and Fish Together session activity.',
                    style: TextStyle(fontSize: 12, height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Show Walkthrough ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_done', false);
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    useSafeArea: false,
                    builder: (_) => const OnboardingScreen(),
                  );
                  await prefs.setBool('onboarding_done', true);
                },
                child: Row(
                  children: [
                    Icon(Icons.school, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Show Walkthrough',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            'Replay the intro tutorial with all tips',
                            style: TextStyle(fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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

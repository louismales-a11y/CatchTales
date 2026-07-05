import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../services/catches_db_service.dart';
import '../services/translation_service.dart';
import '../models/catch.dart';

enum ExportFormat { csv, json, kml }

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  DateTimeRange? _dateRange;
  ExportFormat _format = ExportFormat.csv;
  bool _exporting = false;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  List<Catch> _filterCatches(List<Catch> all) {
    if (_dateRange == null) return all;
    return all.where((c) =>
        c.caughtAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        c.caughtAt.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final all = await CatchesDbService.instance.getCatches();
      final filtered = _filterCatches(all);
      if (filtered.isEmpty) {
        _showMsg('No catches match the selected date range');
        setState(() => _exporting = false);
        return;
      }
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

      switch (_format) {
        case ExportFormat.csv:
          await _exportCsv(filtered, dir, dateStr);
          break;
        case ExportFormat.json:
          await _exportJson(filtered, dir, dateStr);
          break;
        case ExportFormat.kml:
          await _exportKml(filtered, dir, dateStr);
          break;
      }
    } catch (e) {
      _showMsg('Export failed: $e');
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportCsv(List<Catch> catches, Directory dir, String dateStr) async {
    final file = File('${dir.path}/bestfishbuddy_export_$dateStr.csv');
    final buf = StringBuffer();
    buf.writeln('ID,Angler,Species,Location,Lure,Weight,WeightUnit,Length,LengthUnit,'
        'Latitude,Longitude,WeatherTemp,WeatherCondition,Notes,TripName,CaughtAt,CreatedAt');
    for (final c in catches) {
      final esc = (String s) => '"${s.replaceAll('"', '""')}"';
      buf.writeln([
        c.id?.toString() ?? '',
        esc(c.angler), esc(c.species), esc(c.location), esc(c.lure),
        c.weight?.toStringAsFixed(2) ?? '', c.weightUnit,
        c.length?.toStringAsFixed(1) ?? '', c.lengthUnit,
        c.latitude?.toStringAsFixed(6) ?? '', c.longitude?.toStringAsFixed(6) ?? '',
        c.weatherTemp?.toString() ?? '', esc(c.weatherCondition ?? ''),
        esc(c.notes ?? ''), esc(c.tripName ?? ''),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(c.caughtAt),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(c.createdAt),
      ].join(','));
    }
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Best Fish Buddy CSV export');
  }

  Future<void> _exportJson(List<Catch> catches, Directory dir, String dateStr) async {
    final file = File('${dir.path}/bestfishbuddy_export_$dateStr.json');
    await file.writeAsString(catches.map((c) => c.toMap()).toList().toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Best Fish Buddy JSON export');
  }

  Future<void> _exportKml(List<Catch> catches, Directory dir, String dateStr) async {
    final withCoords = catches.where((c) => c.latitude != null).toList();
    if (withCoords.isEmpty) {
      _showMsg('No catches with GPS coordinates to export as KML');
      return;
    }
    final file = File('${dir.path}/bestfishbuddy_export_$dateStr.kml');
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buf.writeln('  <Document><name>Best Fish Buddy Catches</name>');
    for (final c in withCoords) {
      final d = DateFormat('MMM d, yyyy').format(c.caughtAt);
      buf.writeln('    <Placemark>');
      buf.writeln('      <name>${_esc(c.species)} by ${_esc(c.angler)}</name>');
      buf.writeln('      <description>${_esc(d)}${c.location.isNotEmpty ? ' at ${_esc(c.location)}' : ''}'
          '${c.weightDisplay.isNotEmpty ? ' - ${_esc(c.weightDisplay)}' : ''}'
          '${c.lengthDisplay.isNotEmpty ? ' - ${_esc(c.lengthDisplay)}' : ''}</description>');
      buf.writeln('      <Point><coordinates>${c.longitude},${c.latitude},0</coordinates></Point>');
      buf.writeln('    </Placemark>');
    }
    buf.writeln('  </Document></kml>');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Best Fish Buddy KML export');
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;').replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;').replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  /// Import a GPX file.
  /// File selection is done from the Map screen's GPX Import button.
  /// This screen will navigate to Map for GPX import.
  Future<void> _gotoMapForGpx() async {
    // Navigate back and hint that GPX import is on the map screen
    _showMsg('GPX import is available from the Map screen\'s side panel (GPX Import button)');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    final rangeStr = _dateRange != null
        ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
        : 'All time';

    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export Data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Format selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export Format',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<ExportFormat>(
                    segments: ExportFormat.values.map((fmt) =>
                      ButtonSegment(value: fmt, label: Text(fmt.name.toUpperCase()))
                    ).toList(),
                    selected: {_format},
                    onSelectionChanged: (v) => setState(() => _format = v.first),
                  ),
                  const SizedBox(height: 6),
                  Text(_formatDesc(_format),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date range
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: Text(rangeStr),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateRange,
            ),
          ),
          if (_dateRange != null)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _dateRange = null),
                child: const Text('Clear date filter'),
              ),
            ),

          const SizedBox(height: 20),

          // Export button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download),
              label: Text(_exporting ? 'Exporting...' : 'Export Data'),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),

          // Import section
          Text('Import GPS Track (GPX)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Import a GPX file recorded by your phone or GPS device. '
            'The track will be shown as a blue line on the map.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _gotoMapForGpx,
              icon: const Icon(Icons.route),
              label: const Text('Import GPX File...'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDesc(ExportFormat fmt) {
    switch (fmt) {
      case ExportFormat.csv: return 'Spreadsheet-friendly, all fields';
      case ExportFormat.json: return 'Raw data, good for backups';
      case ExportFormat.kml: return 'GPS coordinates for Google Earth';
    }
  }
}

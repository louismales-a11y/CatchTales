import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/help_text.dart';
import '../services/pro_service.dart';
import '../services/translation_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/catch.dart';
import '../services/badge_service.dart' as badges;
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  int _totalCatches = 0;
  Catch? _biggestWeight;
  Catch? _biggestLength;
  Map<String, int> _speciesBreakdown = {};
  Map<String, int> _catchesByMonth = {};
  Map<String, int> _topAnglers = {};
  Map<String, int> _topLocations = {};
  List<badges.Badge> _badges = [];
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DatabaseService.instance.getCatchCount(),
        DatabaseService.instance.biggestByWeight(),
        DatabaseService.instance.biggestByLength(),
        DatabaseService.instance.speciesBreakdown(),
        DatabaseService.instance.catchesByMonth(),
        DatabaseService.instance.topAnglers(),
        DatabaseService.instance.topLocations(),
        badges.BadgeService.instance.getBadges(),
      ]);
      if (mounted) {
        setState(() {
          _totalCatches = results[0] as int;
          _biggestWeight = results[1] as Catch?;
          _biggestLength = results[2] as Catch?;
          _speciesBreakdown = results[3] as Map<String, int>;
          _catchesByMonth = results[4] as Map<String, int>;
          _topAnglers = results[5] as Map<String, int>;
          _topLocations = results[6] as Map<String, int>;
          _badges = results[7] as List<badges.Badge>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareStats() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/stats.png');
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'My Best Fish Buddy stats! 🎣');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    if (!context.watch<ProService>().isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: Column(
          children: [
            Expanded(
              child: _buildUpgradePrompt(),
            ),
            helpChip(context, 'stats'),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          if (_totalCatches > 0)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share stats',
              onPressed: _shareStats,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _totalCatches == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(tr('noData'), style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text('Add some catches to see stats', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : RepaintBoundary(
              key: _shareKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom + 80),
                children: [
                  // Total catches
                  _StatCard(title: '$_totalCatches', subtitle: 'Total Catches', icon: Icons.set_meal),
                  const SizedBox(height: 8),

                  // Personal Records
                  Text('🏆 Personal Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  if (_biggestWeight != null)
                    _StatCard(
                      title: _biggestWeight!.weightDisplay,
                      subtitle: 'Heaviest — ${_biggestWeight!.species} (${_biggestWeight!.angler})',
                      icon: Icons.monitor_weight,
                    ),
                  if (_biggestLength != null)
                    _StatCard(
                      title: _biggestLength!.lengthDisplay,
                      subtitle: 'Longest — ${_biggestLength!.species} (${_biggestLength!.angler})',
                      icon: Icons.straighten,
                    ),
                  _StatCard(title: '${_speciesBreakdown.length}', subtitle: 'Different Species Caught', icon: Icons.set_meal),
                  const SizedBox(height: 16),

                  // Badges
                  if (_badges.isNotEmpty) ...[
                    Text('⭐ Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _badges.map((b) => _BadgeChip(badge: b)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Species Breakdown
                  if (_speciesBreakdown.isNotEmpty) ...[
                    const Text('Species Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(height: 200, child: _PieChart(data: _speciesBreakdown)),
                    const SizedBox(height: 16),
                  ],

                  // Catches Over Time
                  if (_catchesByMonth.isNotEmpty) ...[
                    const Text('Catches Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(height: 200, child: _BarChart(data: _catchesByMonth)),
                    const SizedBox(height: 16),
                  ],

                  // Personal Bests
                  Text('📈 Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  if (_speciesBreakdown.isNotEmpty) ...[
                    _InsightRow(
                      icon: Icons.trending_up,
                      text: 'Most caught: ${_speciesBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key} (${_speciesBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).value})',
                    ),
                  ],
                  if (_catchesByMonth.isNotEmpty) ...[
                    _InsightRow(
                      icon: Icons.calendar_month,
                      text: 'Best month: ${_catchesByMonth.entries.reduce((a, b) => a.value > b.value ? a : b).key} (${_catchesByMonth.entries.reduce((a, b) => a.value > b.value ? a : b).value} fish)',
                    ),
                  ],
                  if (_topAnglers.isNotEmpty) ...[
                    _InsightRow(
                      icon: Icons.emoji_events,
                      text: 'Top angler: ${_topAnglers.entries.first.key} (${_topAnglers.entries.first.value})',
                    ),
                  ],
                  if (_totalCatches >= 10) ...[
                    _InsightRow(icon: Icons.speed, text: 'Average: ${(_totalCatches / (_catchesByMonth.length > 0 ? _catchesByMonth.length : 1)).toStringAsFixed(1)} fish/month'),
                  ],
                  const SizedBox(height: 24),

                  // Top Anglers
                  if (_topAnglers.isNotEmpty) ...[
                    const Text('Top Anglers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._topAnglers.entries.map((e) => _ListRow(label: e.key, value: '${e.value} fish')),
                    const SizedBox(height: 16),
                  ],

                  // Top Locations
                  if (_topLocations.isNotEmpty) ...[
                    const Text('Top Locations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._topLocations.entries.map((e) => _ListRow(label: e.key, value: '${e.value} fish')),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          helpChip(context, 'stats'),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.bar_chart, size: 40, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              tr('statsIsPro'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tr('statsProDesc'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => ProService.showUpgradeDialog(context),
                icon: const Icon(Icons.star),
                label: Text(tr('upgradeToPro')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final badges.Badge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(badge.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InsightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _StatCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String label;
  final String value;
  const _ListRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, int> data;
  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final colors = [Colors.cyan, Colors.pink, Colors.amber, Colors.green, Colors.purple, Colors.orange, Colors.blue, Colors.red, Colors.teal, Colors.indigo];
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();
    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: List.generate(entries.length, (i) => PieChartSectionData(
              color: colors[i % colors.length],
              value: entries[i].value.toDouble(),
              title: entries[i].value / total * 100 > 5 ? '${(entries[i].value / total * 100).toStringAsFixed(0)}%' : '',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            )),
            sectionsSpace: 2,
            centerSpaceRadius: 30,
          )),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: List.generate(entries.length > 6 ? 6 : entries.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('${entries[i].key} (${entries[i].value})', style: const TextStyle(fontSize: 12)),
            ]),
          )),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final entries = data.entries.toList();
    final maxY = data.values.reduce((a, b) => a > b ? a : b);
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: (maxY * 1.2).ceilToDouble(),
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= entries.length) return const SizedBox();
          final label = entries[i].key.length >= 7 ? entries[i].key.substring(5) : entries[i].key;
          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label, style: const TextStyle(fontSize: 9)));
        }, reservedSize: 20)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (value, meta) {
          if (value == 0) return const SizedBox();
          return Text('${value.toInt()}', style: const TextStyle(fontSize: 9));
        })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(entries.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: entries[i].value.toDouble(), color: Theme.of(context).colorScheme.primary, width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ])),
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/catch.dart';
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
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _totalCatches == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No data yet',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Add some catches to see stats',
                      style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _StatCard(
                  title: '$_totalCatches',
                  subtitle: 'Total Catches',
                  icon: Icons.set_meal,
                ),
                const SizedBox(height: 8),

                // Biggest catches
                if (_biggestWeight != null)
                  _StatCard(
                    title: _biggestWeight!.weightDisplay,
                    subtitle:
                        'Biggest by Weight — ${_biggestWeight!.species} (${_biggestWeight!.angler})',
                    icon: Icons.monitor_weight,
                  ),
                if (_biggestLength != null)
                  _StatCard(
                    title: _biggestLength!.lengthDisplay,
                    subtitle:
                        'Biggest by Length — ${_biggestLength!.species} (${_biggestLength!.angler})',
                    icon: Icons.straighten,
                  ),

                if (_speciesBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Species Breakdown',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _PieChart(data: _speciesBreakdown),
                  ),
                ],

                if (_catchesByMonth.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Catches Over Time',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _BarChart(data: _catchesByMonth),
                  ),
                ],

                if (_topAnglers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Top Anglers',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._topAnglers.entries.map((e) => _ListRow(
                      label: e.key, value: '${e.value} fish')),
                ],

                if (_topLocations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Top Locations',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._topLocations.entries.map((e) => _ListRow(
                      label: e.key, value: '${e.value} fish')),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                )),
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
    final colors = [
      Colors.cyan, Colors.pink, Colors.amber, Colors.green,
      Colors.purple, Colors.orange, Colors.blue, Colors.red,
      Colors.teal, Colors.indigo,
    ];

    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: entry.value.toDouble(),
                  title:
                      percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        // Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(entries.length > 6 ? 6 : entries.length, (i) {
            final entry = entries[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${entry.key} (${entry.value})',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }),
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
    final entries = data.entries.toList();
    final maxY = data.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY * 1.2).ceilToDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox();
                }
                // Show just the month label
                final label = entries[i].key.length >= 7
                    ? entries[i].key.substring(5)
                    : entries[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style: const TextStyle(fontSize: 9)),
                );
              },
              reservedSize: 20,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          final entry = entries[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/help_text.dart';
import '../services/translation_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/catch.dart';
import '../services/catches_db_service.dart';
import 'add_catch_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, int> _heatmap = {};
  List<Catch> _dayCatches = [];
  bool _loadingCatches = false;
  // Stats for the month
  int _monthTotal = 0;
  int _monthSpecies = 0;
  String _topAngler = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadHeatmap(_focusedDay);
    _loadDayCatches(_selectedDay!);
    _loadMonthStats(_focusedDay);
  }

  Future<void> _loadHeatmap(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final data = await CatchesDbService.instance
        .getCatchCountByDateRange(first, last);
    if (mounted) {
      setState(() {
        _heatmap = data;
      });
    }
  }

  Future<void> _loadMonthStats(DateTime month) async {
    final db = CatchesDbService.instance;
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final catches = await db.getCatches();
    final monthCatches = catches.where((c) =>
        c.caughtAt.isAfter(first.subtract(const Duration(days: 1))) &&
        c.caughtAt.isBefore(last.add(const Duration(days: 1)))).toList();
    if (!mounted) return;
    final species = monthCatches.map((c) => c.species.toLowerCase()).toSet().length;
    final anglers = <String, int>{};
    for (final c in monthCatches) {
      anglers[c.angler] = (anglers[c.angler] ?? 0) + 1;
    }
    final top = anglers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _monthTotal = monthCatches.length;
      _monthSpecies = species;
      _topAngler = top.isNotEmpty ? '${top.first.key} (${top.first.value})' : '';
    });
  }

  Future<void> _loadDayCatches(DateTime day) async {
    setState(() => _loadingCatches = true);
    final catches =
        await CatchesDbService.instance.getCatchesByDate(day);
    if (mounted) {
      setState(() {
        _dayCatches = catches;
        _loadingCatches = false;
      });
    }
  }

  int _catchCountForDay(DateTime day) {
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _heatmap[key] ?? 0;
  }

  Color _heatmapColor(int count) {
    if (count == 0) return Colors.transparent;
    if (count == 1) return Colors.green.shade100;
    if (count <= 3) return Colors.green.shade300;
    if (count <= 6) return Colors.green.shade500;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(tr('fishingCalendar')),
),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _loadDayCatches(selected);
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadHeatmap(focused);
                _loadMonthStats(focused);
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: theme.colorScheme.onSurface,
                ),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: theme.colorScheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: theme.colorScheme.primary),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor, width: 0.5),
                  ),
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                selectedTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                cellMargin: const EdgeInsets.all(2),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) =>
                    _heatmapDayCell(day, isToday: false),
                todayBuilder: (context, day, _) =>
                    _heatmapDayCell(day, isToday: true),
                selectedBuilder: (context, day, _) =>
                    _heatmapDayCell(day, isToday: false,
                        selected: true),
              ),
            ),
          ),

          // Month stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCol(Icons.set_meal, '$_monthTotal', tr('catches')),
                _statCol(Icons.set_meal, '$_monthSpecies', tr('species')),
                if (_topAngler.isNotEmpty)
                  _statCol(Icons.emoji_events, _topAngler, tr('topAngler')),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Colors.transparent, tr('none')),
                const SizedBox(width: 4),
                _legendItem(Colors.green.shade100, '1'),
                const SizedBox(width: 4),
                _legendItem(Colors.green.shade300, '2-3'),
                const SizedBox(width: 4),
                _legendItem(Colors.green.shade500, '4-6'),
                const SizedBox(width: 4),
                _legendItem(Colors.green.shade700, '7+'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Day catches
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedDay != null
                      ? dateFormat.format(_selectedDay!)
                      : tr('selectDay'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_dayCatches.isNotEmpty)
                  Text(
                    '${_dayCatches.length} ${tr('catches')}',
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _loadingCatches
                ? const Center(child: CircularProgressIndicator())
                : _dayCatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.set_meal,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(tr('noCatchesDay'),
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadDayCatches(_selectedDay!),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              12, 4, 12, 12),
                          itemCount: _dayCatches.length,
                          itemBuilder: (context, index) {
                            final c = _dayCatches[index];
                            return _CatchTile(catch_: c);
                          },
                        ),
                      ),
          ),
          const SizedBox(height: 4),
          helpChip(context, 'calendar'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _heatmapDayCell(
    DateTime day, {
    bool isToday = false,
    bool selected = false,
  }) {
    final t = Theme.of(context);
    final count = _catchCountForDay(day);
    final bgColor = selected
        ? t.colorScheme.primary
        : isToday
            ? t.colorScheme.primary.withValues(alpha: 0.15)
            : _heatmapColor(count);
    final textColor = selected
        ? Colors.white
        : isToday
            ? t.colorScheme.primary
            : count > 0
                ? (count >= 4 ? Colors.white : Colors.black87)
                : null;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isToday || selected
                ? FontWeight.w700
                : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _statCol(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: theme.colorScheme.primary)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: color == Colors.transparent
                ? Border.all(color: Colors.grey.shade300)
                : null,
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _CatchTile extends StatelessWidget {
  final Catch catch_;

  const _CatchTile({required this.catch_});

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);
    final timeStr = DateFormat('h:mm a').format(catch_.caughtAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => AddCatchScreen(existingCatch: catch_),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary
              .withValues(alpha: 0.12),
          radius: 20,
          child: Icon(Icons.set_meal,
              color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(catch_.species,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${catch_.angler} • $timeStr'
          '${catch_.location.isNotEmpty ? " • ${catch_.location}" : ""}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: catch_.weightDisplay.isNotEmpty
            ? Text(catch_.weightDisplay,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ))
            : null,
      ),
    );
  }
}

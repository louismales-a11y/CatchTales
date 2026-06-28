import 'package:flutter/material.dart';
import '../models/counter.dart';
import '../services/database_service.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  List<FishCounter> _counters = [];
  bool _loading = true;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final counters = await DatabaseService.instance.getCounters();
      if (mounted) {
        setState(() {
          _counters = counters;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAngler() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    _nameCtrl.clear();
    await DatabaseService.instance.addCounter(name);
    if (!mounted) return;
    await _load();
  }

  Future<void> _deleteCounter(FishCounter c) async {
    if (c.id == null) return;
    await DatabaseService.instance.deleteCounter(c.id!);
    if (!mounted) return;
    await _load();
  }

  Future<void> _increment(FishCounter c) async {
    if (c.id == null) return;
    await DatabaseService.instance.incrementCounter(c.id!);
    if (!mounted) return;
    await _load();
  }

  Future<void> _decrement(FishCounter c) async {
    if (c.id == null) return;
    await DatabaseService.instance.decrementCounter(c.id!);
    if (!mounted) return;
    await _load();
  }

  Future<void> _resetAll() async {
    await DatabaseService.instance.resetCounters();
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Cyan accent bar
        Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.cyanAccent],
            ),
          ),
        ),
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text('Anglers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              if (_counters.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('New Trip'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Add angler row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Angler name',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addAngler(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _addAngler,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        // List
        Expanded(
          child: _counters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No anglers yet',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Type a name above and tap Add',
                          style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 4, bottom: 24),
                  itemCount: _counters.length,
                  itemBuilder: (context, index) {
                    final c = _counters[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.angler,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  Text('${c.count} fish',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _decrement(c),
                              iconSize: 26,
                              color: Colors.grey.shade500,
                              visualDensity: VisualDensity.compact,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${c.count}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () => _increment(c),
                              iconSize: 26,
                              color: theme.colorScheme.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18),
                              onPressed: () => _deleteCounter(c),
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.7),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

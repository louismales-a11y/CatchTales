import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/catch.dart';
import '../services/database_service.dart';
import 'add_catch_screen.dart';

class CatchesScreen extends StatefulWidget {
  const CatchesScreen({super.key});

  @override
  State<CatchesScreen> createState() => CatchesScreenState();
}

class CatchesScreenState extends State<CatchesScreen> {
  List<Catch> _catches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadCatches());
  }

  Future<void> loadCatches() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final catches = await DatabaseService.instance.getCatches();
      if (mounted) {
        setState(() {
          _catches = catches;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editCatch(Catch c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCatchScreen(existingCatch: c),
      ),
    );
    if (updated == true) {
      await loadCatches();
    }
  }

  Future<void> _deleteCatch(Catch c) async {
    if (c.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Catch'),
        content: Text('Remove ${c.species} caught by ${c.angler}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteCatch(c.id!);
      await loadCatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.set_meal, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No catches yet!',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Tap + to add your first catch',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadCatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _catches.length,
        itemBuilder: (context, index) {
          final c = _catches[index];
          return _CatchCard(
            catch_: c,
            onTap: () => _editCatch(c),
            onDelete: () => _deleteCatch(c),
          );
        },
      ),
    );
  }
}

class _CatchCard extends StatelessWidget {
  final Catch catch_;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CatchCard({
    required this.catch_,
    required this.onTap,
    required this.onDelete,
  });

  Widget _speciesIcon(ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.set_meal,
          color: theme.colorScheme.primary, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(catch_.caughtAt);
    final timeStr = DateFormat('h:mm a').format(catch_.caughtAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo + species header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo or icon
                  if (catch_.hasPhotos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.file(
                          File(catch_.primaryPhoto!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _speciesIcon(theme),
                        ),
                      ),
                    )
                  else
                    _speciesIcon(theme),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catch_.species,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 2),
                        Text('${catch_.angler} • $dateStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                      ],
                    ),
                  ),
                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Details row
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (catch_.weight != null)
                    _DetailChip(
                      icon: Icons.monitor_weight,
                      text: catch_.weightDisplay,
                    ),
                  if (catch_.length != null)
                    _DetailChip(
                      icon: Icons.straighten,
                      text: catch_.lengthDisplay,
                    ),
                  if (catch_.location.isNotEmpty)
                    _DetailChip(
                      icon: Icons.location_on,
                      text: catch_.location,
                    ),
                  if (catch_.lure.isNotEmpty)
                    _DetailChip(
                      icon: Icons.vpn_key,
                      text: catch_.lure,
                    ),
                  if (catch_.latitude != null)
                    _DetailChip(
                      icon: Icons.gps_fixed,
                      text:
                          '${catch_.latitude!.toStringAsFixed(2)}, ${catch_.longitude!.toStringAsFixed(2)}',
                    ),
                  if (catch_.weatherTemp != null)
                    _DetailChip(
                      icon: Icons.wb_sunny,
                      text:
                          '${catch_.weatherTemp!.round()}°C ${catch_.weatherCondition ?? ''}',
                    ),
                  _DetailChip(
                    icon: Icons.access_time,
                    text: timeStr,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7))),
      ],
    );
  }
}

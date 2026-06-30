import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tackle_item.dart';
import '../services/database_service.dart';
import 'add_tackle_screen.dart';
import 'tackle_catalog_screen.dart';
import 'tackle_detail_screen.dart';
import 'todays_pick_screen.dart';

class TackleBoxScreen extends StatefulWidget {
  const TackleBoxScreen({super.key});

  @override
  State<TackleBoxScreen> createState() => _TackleBoxScreenState();
}

class _TackleBoxScreenState extends State<TackleBoxScreen> {
  List<TackleItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final items = await DatabaseService.instance.getTackleItems();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Add to Tackle Box',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome),
                ),
                title: const Text("Today's Pick"),
                subtitle: const Text('Get weather-aware recommendations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TodaysPickScreen()),
                  ).then((_) => _load());
                },
              ),
              const Divider(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book),
                ),
                title: const Text('Browse Catalog'),
                subtitle: const Text('Pick from common lures and tackle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TackleCatalogScreen()),
                  ).then((_) => _load());
                },
              ),
              const Divider(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Snap a picture of your own tackle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddTackleScreen()),
                  ).then((_) => _load());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(TackleItem item) async {
    if (item.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tackle'),
        content: Text('Remove ${item.name} from your tackle box?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteTackleItem(item.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tackle Box'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add tackle',
            onPressed: _showAddOptions,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Your tackle box is empty',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first tackle',
                          style: TextStyle(
                              color: Colors.grey.shade400)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddOptions,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Tackle'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) =>
                        _TackleCard(
                      item: _items[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TackleDetailScreen(item: _items[index]),
                        ),
                      ),
                      onDelete: () => _delete(_items[index]),
                    ),
                  ),
                ),
    );
  }
}

class _TackleCard extends StatelessWidget {
  final TackleItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TackleCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto =
        item.photoPath != null && File(item.photoPath!).existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo or icon area
            Expanded(
              child: hasPhoto
                  ? Image.file(
                      File(item.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (a, b, c) => _iconPlaceholder(theme),
                    )
                  : _iconPlaceholder(theme),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(item.type,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.set_meal,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/help_text.dart';
import '../services/translation_service.dart';
import '../services/pro_service.dart';
import '../models/tackle_item.dart';
import '../services/tackle_db_service.dart';
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
  List<TackleItem> _allItems = [];
  List<TackleItem> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, name, type

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final items = await TackleDbService.instance.getTackleItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var results = List<TackleItem>.from(_allItems);

    // Search
    final query = _searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      results = results.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          item.targetSpecies.any((s) => s.toLowerCase().contains(query))
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'type':
        results.sort((a, b) => a.type.compareTo(b.type));
        break;
      default: // date
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _filtered = results;
  }

  void _showAddOptions() {
    if (!ProService.instance.isPro && _allItems.length >= ProService.freeTackleLimit) {
      ProService.showUpgradeDialog(context);
      return;
    }
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
              Text(tr('addToTackleBox'),
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
                title: Text(tr('todaysPick')),
                subtitle: Text(tr('todaysPickSub')),
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
                title: Text(tr('browseCatalog')),
                subtitle: Text(tr('browseCatalogSub')),
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
                title: Text(tr('takePhoto')),
                subtitle: Text(tr('takePhotoSub')),
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

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(tr('sortBy'),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(),
            ...[
              {'key': 'date', 'label': 'Date added (newest)'},
              {'key': 'name', 'label': 'Name (A-Z)'},
              {'key': 'type', 'label': 'Type'},
            ].map((opt) => ListTile(
              leading: Icon(
                _sortBy == opt['key']
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _sortBy == opt['key']
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(opt['label']!),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _sortBy = opt['key']!;
                  _applyFilter();
                });
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(TackleItem item) async {
    if (item.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('delete')),
        content: Text(trp('removeItem', {'item': item.name})),
        actions: [
            TextButton.icon(
              icon: const Icon(Icons.help, size: 18),
              label: const Text('Help'),
              onPressed: () => showHelp(context, 'tackle_box'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('delete'),
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await TackleDbService.instance.deleteTackleItem(item.id!);
      _load();
    }
  }

  Future<void> _edit(TackleItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTackleScreen(existingItem: item),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tackleBox')),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add tackle',
            onPressed: _showAddOptions,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                if (_allItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        setState(() {
                          _searchQuery = v;
                          _applyFilter();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tackle box…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _applyFilter();
                                  });
                                })
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                // Free limit banner
                if (!context.watch<ProService>().isPro)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0xFF1A237E),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFD600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trp('freeTackleBanner', {'count': '${_allItems.length}', 'limit': '${ProService.freeTackleLimit}'}),
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Count
                if (_allItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text('${_filtered.length} ${tr('items')}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                        const Spacer(),
                        Text(_sortBy == 'date' ? 'Newest first' : _sortBy,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                // Grid
                Expanded(
                  child: _allItems.isEmpty
                      ? _emptyState()
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(tr('noMatches'),
                                      style: TextStyle(
                                          color: Colors.grey.shade500)),
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
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) =>
                                    _TackleCard(
                                  item: _filtered[index],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TackleDetailScreen(
                                              item: _filtered[index]),
                                    ),
                                  ).then((_) => _load()),
                                  onEdit: () => _edit(_filtered[index]),
                                  onDelete: () => _delete(_filtered[index]),
                                ),
                              ),
                            ),
                ),
              const SizedBox(height: 8),
              helpChip(context, 'tackle_box'),
              const SizedBox(height: 12),
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(tr('tackleBoxEmpty'),
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(tr('tapToAddTackle'),
              style: TextStyle(
                  color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddOptions,
            icon: const Icon(Icons.add),
            label: Text(tr('addTackle')),
          ),
        ],
      ),
    );
  }
}

class _TackleCard extends StatelessWidget {
  final TackleItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TackleCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
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
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 4),
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
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  color: Colors.grey.shade500,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // Delete (Pro only)
                if (ProService.instance.isPro)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: onDelete,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
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

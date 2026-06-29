import 'package:flutter/material.dart';
import '../data/tackle_database.dart';
import '../models/tackle_item.dart';
import '../services/database_service.dart';
import '../services/tackle_image_service.dart';

/// Browse all common tackle types and add them to your personal tackle box.
class TackleCatalogScreen extends StatefulWidget {
  const TackleCatalogScreen({super.key});

  @override
  State<TackleCatalogScreen> createState() => _TackleCatalogScreenState();
}

class _TackleCatalogScreenState extends State<TackleCatalogScreen> {
  /// Cached image URLs so each type fetches once.
  final Map<String, String?> _imageUrls = {};

  /// Group tackle types by category.
  Map<String, List<TackleTypeInfo>> get _grouped {
    final map = <String, List<TackleTypeInfo>>{};
    for (final t in tackleTypeDatabase) {
      map.putIfAbsent(t.category, () => []);
      map[t.category]!.add(t);
    }
    return map;
  }

  Future<void> _fetchImage(TackleTypeInfo info) async {
    if (_imageUrls.containsKey(info.name)) return;
    final url = await TackleImageService.getImageUrl(info.name);
    if (mounted) {
      setState(() => _imageUrls[info.name] = url);
    }
  }

  Future<void> _addToBox(TackleTypeInfo info) async {
    final item = TackleItem(
      name: info.name,
      type: info.category,
      targetSpecies: List.from(info.targetSpecies),
      tips: info.tips,
    );
    await DatabaseService.instance.addTackleItem(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${info.name} added to your tackle box'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    return Scaffold(
      appBar: AppBar(title: const Text('Tackle Catalog')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(entry.key.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    )),
              ),
              ...entry.value.map((t) => _CatalogCard(
                    info: t,
                    imageUrl: _imageUrls[t.name],
                    onImageLoad: () => _fetchImage(t),
                    onAdd: () => _addToBox(t),
                  )),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final TackleTypeInfo info;
  final String? imageUrl;
  final VoidCallback onImageLoad;
  final VoidCallback onAdd;

  const _CatalogCard({
    required this.info,
    required this.imageUrl,
    required this.onImageLoad,
    required this.onAdd,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return _DetailSheet(
              info: info,
              imageUrl: imageUrl,
              onAdd: () {
                onAdd();
                Navigator.pop(ctx);
              },
              scrollCtrl: scrollCtrl,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Trigger image load if not yet loaded
    if (imageUrl == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onImageLoad());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image or emoji
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (a, b, c) => _emojiIcon(theme),
                        loadingBuilder: (ctx, child, progress) =>
                            progress == null ? child : _emojiIcon(theme),
                      )
                    : _emojiIcon(theme),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(info.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ),
              ),
              // Quick add
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onAdd,
                color: theme.colorScheme.primary,
                tooltip: 'Add to my tackle box',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiIcon(ThemeData theme) {
    return Center(
      child: Text(info.icon, style: const TextStyle(fontSize: 28)),
    );
  }
}

/// Full detail bottom sheet.
class _DetailSheet extends StatelessWidget {
  final TackleTypeInfo info;
  final String? imageUrl;
  final VoidCallback onAdd;
  final ScrollController scrollCtrl;

  const _DetailSheet({
    required this.info,
    required this.imageUrl,
    required this.onAdd,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Image / emoji hero
        imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (a, b, c) =>
                      _heroFallback(theme),
                  loadingBuilder: (ctx, child, progress) =>
                      progress == null ? child : _heroFallback(theme),
                ),
              )
            : _heroFallback(theme),
        const SizedBox(height: 16),

        // Name + category
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(info.category,
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        Text(info.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            )),
        const SizedBox(height: 20),

        // Target species
        Text('Target Species',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: info.targetSpecies.map((s) => Chip(
                avatar: const Icon(Icons.set_meal, size: 14),
                label: Text(s, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
        ),
        const SizedBox(height: 20),

        // Tips
        Text('How to Fish It',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tip in info.tips.split('\n\n'))
                if (tip.trim().isNotEmpty) ...[
                  if (tip.startsWith('•') ||
                      tip.startsWith('1') ||
                      tip.startsWith('Best') ||
                      tip.startsWith('Prime') ||
                      tip.startsWith('Pro') ||
                      tip.startsWith('Colors') ||
                      tip.startsWith('Gear') ||
                      tip.startsWith('Sizes') ||
                      tip.startsWith('Rigging') ||
                      tip.startsWith('Technique') ||
                      tip.startsWith('Presentation') ||
                      tip.startsWith('Setup') ||
                      tip.startsWith('Cork') ||
                      tip.startsWith('Trolling') ||
                      tip.startsWith('Matching') ||
                      tip.startsWith('Indicator') ||
                      tip.startsWith('Euro') ||
                      tip.startsWith('Retrieve'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(tip.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          )),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(tip.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          )),
                    ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Add button
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add to My Tackle Box'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _heroFallback(ThemeData theme) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(info.icon, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}

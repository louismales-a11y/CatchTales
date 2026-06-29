import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/fish_image_service.dart';
import '../services/database_service.dart';
import '../models/fish_data.dart';
import '../models/fish_status.dart';
import '../data/fish_database.dart';
import 'add_fish_screen.dart';

class FishIdScreen extends StatefulWidget {
  const FishIdScreen({super.key});

  @override
  State<FishIdScreen> createState() => _FishIdScreenState();
}

class _FishIdScreenState extends State<FishIdScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'All';
  String _selectedWater = 'All';
  List<FishSpecies> _customFish = [];
  Map<String, FishStatus> _statusMap = {};

  final _regions = [
    'All',
    'USA',
    'Canada',
    'Europe',
    'Asia/Pacific',
    'South America',
    'Africa',
    'Australia',
  ];

  final _waterTypes = ['All', 'Freshwater', 'Saltwater', 'Saltwater / Freshwater'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _regions.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedRegion = _regions[_tabCtrl.index]);
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final custom = await DatabaseService.instance.getCustomFish();
    final status = await DatabaseService.instance.getAllFishStatus();
    if (mounted) {
      setState(() {
        _customFish = custom;
        _statusMap = status;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _sortBy = 'name';

  List<FishSpecies> get _filtered {
    final query = _searchQuery.toLowerCase().trim();
    final allFish = [...fishDatabase, ..._customFish];
    var results = allFish.where((f) {
      // Region filter
      final regionMatch =
          _selectedRegion == 'All' || f.regions.contains(_selectedRegion);
      if (!regionMatch) return false;
      // Water type filter
      if (_selectedWater != 'All' && f.waterType != _selectedWater) return false;
      // Search query
      if (query.isEmpty) return true;
      return f.name.toLowerCase().contains(query) ||
          f.scientificName.toLowerCase().contains(query) ||
          f.regions.any((r) => r.toLowerCase().contains(query));
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'name_desc':
        results.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'caught':
        results.sort((a, b) {
          final aC = _statusMap[a.name]?.caughtCount ?? 0;
          final bC = _statusMap[b.name]?.caughtCount ?? 0;
          if (bC != aC) return bC.compareTo(aC);
          return a.name.compareTo(b.name);
        });
        break;
      case 'master':
        results.sort((a, b) {
          final aM = _statusMap[a.name]?.isMaster ?? false;
          final bM = _statusMap[b.name]?.isMaster ?? false;
          if (aM != bM) return aM ? -1 : 1;
          return a.name.compareTo(b.name);
        });
        break;
      case 'favorite':
        results.sort((a, b) {
          final aF = _statusMap[a.name]?.isFavorite ?? false;
          final bF = _statusMap[b.name]?.isFavorite ?? false;
          if (aF != bF) return aF ? -1 : 1;
          return a.name.compareTo(b.name);
        });
        break;
      default: // 'name' ASC
        results.sort((a, b) => a.name.compareTo(b.name));
    }

    return results;
  }

  void _showSortMenu() {
    final popups = <String, String>{
      'name': 'Name (A-Z)',
      'name_desc': 'Name (Z-A)',
      'caught': 'Caught first',
      'master': 'Master first',
      'favorite': 'Favorites first',
    };

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Sort by',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(),
            ...popups.entries.map((e) => ListTile(
                  leading: Icon(
                    _sortBy == e.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _sortBy == e.key
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(e.value),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _sortBy = e.key);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddFish() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddFishScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fish ID'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add a fish',
            onPressed: _openAddFish,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search fish...',
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.primary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          // ── Region tabs ──
          SizedBox(
            height: 40,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
              indicatorColor: theme.colorScheme.primary,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: _regions.map((r) => Tab(text: r)).toList(),
            ),
          ),
          const Divider(height: 1),
          // ── Water type chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _waterTypes.map((w) {
                  final active = _selectedWater == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(w, style: const TextStyle(fontSize: 12)),
                      selected: active,
                      onSelected: (_) => setState(() => _selectedWater = w),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // ── Results count ──
          if (results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text('${results.length} species',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  const Spacer(),
                  Text(_selectedRegion,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ),
          // ── Fish list or empty state ──
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No fish found',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade500)),
                        if (_searchQuery.isNotEmpty)
                          Text('Try a different search term',
                              style:
                                  TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: results.length,
                    itemBuilder: (context, index) => _FishCard(
                      fish: results[index],
                      status: _statusMap[results[index].name],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Fish Card ────────────────────────────────────────────────────────────

class _FishCard extends StatefulWidget {
  final FishSpecies fish;
  final FishStatus? status;
  const _FishCard({required this.fish, this.status});

  @override
  State<_FishCard> createState() => _FishCardState();
}

class _FishCardState extends State<_FishCard> {
  String? _imagePath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final path = await FishImageService.getImagePath(
      commonName: widget.fish.name,
      scientificName: widget.fish.scientificName,
    );
    if (mounted) {
      setState(() {
        _imagePath = path;
        _loading = false;
      });
    }
  }

  Widget _buildThumbnail() {
    final fish = widget.fish;
    if (_loading) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: fish.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.set_meal, color: fish.color, size: 32),
      );
    }
    if (_imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImage(fish),
      );
    }
    return _iconThumb(fish);
  }

  /// Shows the image from local file or falls back to Image.network
  /// if the path is actually a URL (caching failed).
  Widget _buildImage(FishSpecies fish) {
    final path = _imagePath!;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _iconThumb(fish),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _iconThumb(fish);
        },
      );
    }
    return Image.file(
      File(path),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (a, b, c) => _iconThumb(fish),
    );
  }

  Widget _iconThumb(FishSpecies fish) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: fish.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.set_meal, color: fish.color, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fish = widget.fish;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Capture parent before the async gap
          final parent = context.findAncestorStateOfType<_FishIdScreenState>();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => _FishDetailScreen(
                fish: fish,
                status: widget.status,
              ),
            ),
          );
          if (result == true && mounted) {
            _loadImage();
            parent?._loadData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(fish.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              )),
                        ),
                        // Caught indicator
                        if (widget.status != null && widget.status!.caughtCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.check_circle,
                                size: 18, color: Colors.green.shade600),
                          ),
                        // Master indicator
                        if (widget.status != null && widget.status!.isMaster)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(Icons.auto_awesome,
                                size: 16, color: Colors.amber.shade700),
                          ),
                        // Favorite indicator
                        if (widget.status != null && widget.status!.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(Icons.favorite,
                                size: 16, color: Colors.red.shade400),
                          ),
                        // Protected badge
                        if (fish.isProtected)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.shade300, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield,
                                      size: 11, color: Colors.red.shade600),
                                  const SizedBox(width: 2),
                                  Text('Protected',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(fish.scientificName,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.straighten,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(fish.sizeRange,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.terrain,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(fish.habitat,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────

class _FishDetailScreen extends StatefulWidget {
  final FishSpecies fish;
  final FishStatus? status;
  const _FishDetailScreen({
    required this.fish,
    this.status,
  });

  @override
  State<_FishDetailScreen> createState() => _FishDetailScreenState();
}

class _FishDetailScreenState extends State<_FishDetailScreen> {
  Future<String?>? _imagePathFuture;

  @override
  void initState() {
    super.initState();
    _imagePathFuture = FishImageService.getImagePath(
      commonName: widget.fish.name,
      scientificName: widget.fish.scientificName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fish = widget.fish;
    return Scaffold(
      appBar: AppBar(title: Text(fish.name)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          // Hero header — loads fish image (cached locally or from Wikipedia)
          FutureBuilder<String?>(
            future: _imagePathFuture,
            builder: (context, snapshot) {
              final path = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: fish.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: fish.color,
                    ),
                  ),
                );
              }
              if (path != null && path.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildHeroImage(fish, path),
                );
              }
              return _imageFallback(fish);
            },
          ),
          const SizedBox(height: 20),

          // Name & scientific
          Text(fish.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          Text(fish.scientificName,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 16,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              )),
          const SizedBox(height: 16),

          // Region chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fish.regions
                .map((r) => Chip(
                      avatar: const Icon(Icons.public, size: 16),
                      label: Text(r, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Details
          _detailRow(theme, Icons.straighten, 'Size', fish.sizeRange),
          _detailRow(theme, Icons.terrain, 'Habitat', fish.habitat),
          _detailRow(theme, Icons.water_drop, 'Water', fish.waterType),
          _detailRow(theme, Icons.restaurant, 'Diet', fish.diet),
          _detailRow(theme, Icons.build, 'Tackle', fish.commonTackle),

          if (fish.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('About',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(fish.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.8),
                )),
          ],

          if (fish.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Fishing Tips',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...fish.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            )),
                      ),
                    ],
                  ),
                )),
          ],
          // ── Protected banner ──
          if (fish.isProtected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, size: 18, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Protected species — practice catch and release',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Status toggles ──
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusChip(
                label: 'Caught',
                icon: widget.status?.caughtCount != null && widget.status!.caughtCount > 0
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                active: widget.status?.caughtCount != null && widget.status!.caughtCount > 0,
                activeColor: Colors.green,
                onTap: _toggleCaught,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Master',
                icon: widget.status?.isMaster == true
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                active: widget.status?.isMaster == true,
                activeColor: Colors.amber.shade700,
                onTap: _toggleMaster,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Wishlist',
                icon: widget.status?.isFavorite == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                active: widget.status?.isFavorite == true,
                activeColor: Colors.red.shade400,
                onTap: _toggleFavorite,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _toggleCaught() async {
    await DatabaseService.instance.toggleCaught(widget.fish.name);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _toggleMaster() async {
    await DatabaseService.instance.toggleMaster(widget.fish.name);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _toggleFavorite() async {
    await DatabaseService.instance.toggleFavorite(widget.fish.name);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  /// Renders the hero image from a local file path or Wikipedia URL.
  Widget _buildHeroImage(FishSpecies fish, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: fish.color.withValues(alpha: 0.08),
            child: Center(
              child: CircularProgressIndicator(color: fish.color),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) => _imageFallback(fish),
      );
    }
    return Image.file(
      File(path),
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (a, b, c) => _imageFallback(fish),
    );
  }

  Widget _detailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// Compact status toggle chip for caught / master / wishlist.
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: active
            ? activeColor.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 22,
                    color: active
                        ? activeColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? activeColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback widget when no Wikipedia image is available.
Widget _imageFallback(FishSpecies fish) {
  return Container(
    height: 180,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          fish.color.withValues(alpha: 0.2),
          fish.color.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Icon(Icons.set_meal,
          size: 80, color: fish.color.withValues(alpha: 0.6)),
    ),
  );
}


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/help_text.dart';
import 'package:intl/intl.dart';
import '../models/catch.dart';
import '../services/catches_db_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Catch> _catchesWithPhotos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final catches = await CatchesDbService.instance.getCatches();
    if (mounted) {
      setState(() {
        _catchesWithPhotos =
            catches.where((c) => c.hasPhotos).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Gallery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _catchesWithPhotos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No photos yet',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Add a photo when logging a catch',
                          style: TextStyle(
                              color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    padding: const EdgeInsets.all(8),
                    itemCount: _catchesWithPhotos.length,
                    itemBuilder: (context, index) {
                      final c = _catchesWithPhotos[index];
                      return _PhotoThumb(
                        catch_: c,
                        onTap: () => _openViewer(index),
                      );
                    },
                  ),
                ),
    );
  }

  void _openViewer(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          catches: _catchesWithPhotos,
          initialIndex: startIndex,
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatefulWidget {
  final Catch catch_;
  final VoidCallback onTap;

  const _PhotoThumb({required this.catch_, required this.onTap});

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _loadDimensions();
  }

  Future<void> _loadDimensions() async {
    if (widget.catch_.primaryPhoto == null) return;
    try {
      final file = File(widget.catch_.primaryPhoto!);
      if (!await file.exists()) return;
      final decoded = await decodeImageFromList(await file.readAsBytes());
      if (mounted && decoded.width > 0 && decoded.height > 0) {
        setState(() => _aspectRatio = decoded.width / decoded.height);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ar = _aspectRatio ?? 1.0;
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (widget.catch_.primaryPhoto != null)
              Image.file(
                File(widget.catch_.primaryPhoto!),
                width: double.infinity,
                height: 200 / ar.clamp(0.5, 2.0),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            else
              _placeholder(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Text(
                  widget.catch_.species,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.set_meal, color: Colors.grey),
      );
}

// ─── Full-screen Photo Viewer ─────────────────────────────────────────────

class _PhotoViewer extends StatefulWidget {
  final List<Catch> catches;
  final int initialIndex;

  const _PhotoViewer(
      {required this.catches, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.catches[_currentIndex];
    final dateStr = DateFormat('MMM d, yyyy').format(c.caughtAt);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          '${c.species}  •  $dateStr',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text('${_currentIndex + 1}/${widget.catches.length}',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity!.abs() > 500) {
              Navigator.pop(context);
            }
          },
          child: PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.catches.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final catch_ = widget.catches[index];
            return _PhotoPage(catch_: catch_);
            },
          ),
        ),
      ),
          helpChip(context, 'gallery'),
        ],
      ),
    );
  }
}

class _PhotoPage extends StatelessWidget {
  final Catch catch_;

  const _PhotoPage({required this.catch_});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
        color: Colors.grey.shade300, fontSize: 14);

    return Column(
      children: [
        // Photo
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: catch_.primaryPhoto != null
                  ? Image.file(
                      File(catch_.primaryPhoto!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image,
                              size: 64, color: Colors.grey),
                    )
                  : const Icon(Icons.broken_image,
                      size: 64, color: Colors.grey),
            ),
          ),
        ),
        // Info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catch_.species,
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${catch_.angler}  •  ${DateFormat('MMM d, yyyy  h:mm a').format(catch_.caughtAt)}',
                    style: textStyle),
                if (catch_.location.isNotEmpty)
                  Text('📍 ${catch_.location}', style: textStyle),
                if (catch_.weightDisplay.isNotEmpty ||
                    catch_.lengthDisplay.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (catch_.weightDisplay.isNotEmpty)
                          Text('⚖️ ${catch_.weightDisplay}',
                              style: textStyle),
                        if (catch_.weightDisplay.isNotEmpty &&
                            catch_.lengthDisplay.isNotEmpty)
                          const SizedBox(width: 16),
                        if (catch_.lengthDisplay.isNotEmpty)
                          Text('📏 ${catch_.lengthDisplay}',
                              style: textStyle),
                      ],
                    ),
                  ),
                if (catch_.weatherTemp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '🌡️ ${catch_.weatherTemp!.round()}°C ${catch_.weatherCondition ?? ''}',
                        style: textStyle),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

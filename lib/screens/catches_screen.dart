import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/translation_service.dart';
import '../services/pro_service.dart';
import '../services/catches_provider.dart';
import '../models/catch.dart';
import 'add_catch_screen.dart';

class CatchesScreen extends StatefulWidget {
  const CatchesScreen({super.key});

  @override
  State<CatchesScreen> createState() => CatchesScreenState();
}

class CatchesScreenState extends State<CatchesScreen> {
  // Voice state (UI-specific, not in provider)
  late stt.SpeechToText _speech;
  bool _voiceOn = false;
  String _voiceStatus = '';
  String _lastVoiceText = '';

  // Undo support for swipe-to-delete
  Catch? _lastDeleted;

  // Search
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  CatchesProvider get _provider => context.read<CatchesProvider>();

  @override
  void initState() {
    super.initState();
    // Catches already loaded by CatchesProvider in main.dart
    _searchCtrl.addListener(() {
      context.read<CatchesProvider>().setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> loadCatches() => _provider.loadCatches();

  Future<void> _editCatch(Catch c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCatchScreen(existingCatch: c),
      ),
    );
    if (updated == true) {
      await _provider.loadCatches();
    }
  }

  Future<void> _deleteCatch(Catch c) async {
    if (c.id == null) return;
    await _provider.deleteCatch(c.id!);
  }

  Future<void> _deleteWithUndo(Catch c, int index) async {
    if (c.id == null) return;
    // Store for potential undo
    _lastDeleted = c;
    await _provider.deleteCatch(c.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trp('catchDeleted', {'species': c.species})),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: tr('undo'),
          onPressed: () async {
            if (_lastDeleted != null) {
              await _provider.addCatch(_lastDeleted!);
              _lastDeleted = null;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TranslationService>();
    final cp = context.watch<CatchesProvider>();
    if (cp.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        // Green accent bar
        Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.greenAccent],
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
                    trp('freeCatchBanner', {'count': '${cp.count}', 'limit': '${ProService.freeCatchLimit}'}),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        // Search bar
        if (cp.catches.isNotEmpty || cp.searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: tr('searchCatches'),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchFocus.unfocus();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.none,
            ),
          ),
        Expanded(
          child: cp.catches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cp.searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.set_meal,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cp.searchQuery.isNotEmpty
                            ? tr('noSearchResults')
                            : tr('yourFirstCatch'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (cp.searchQuery.isEmpty) ...[                        const SizedBox(height: 8),
                        Text(tr('sampleCatch'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        // Sample catch card with photo
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Photo
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/sample_bass.jpg',
                                    width: 100,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 100,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.set_meal,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Largemouth Bass',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(tr('you'),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _sampleStat(
                                              Icons.monitor_weight, '4.5 kg'),
                                          const SizedBox(width: 12),
                                          _sampleStat(
                                              Icons.straighten, '58 cm'),
                                          const SizedBox(width: 12),
                                          _sampleStat(
                                              Icons.wb_sunny, tr('sunny')),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('📍 Lake Michigan',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(tr('tapPlusVoice'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                onRefresh: loadCatches,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cp.catches.length,
                  itemBuilder: (context, index) {
                    final c = cp.catches[index];
                    final isPro = ProService.instance.isPro;
                    final card = _CatchCard(
                      catch_: c,
                      onTap: () => _editCatch(c),
                      onDelete: () => _deleteCatch(c),
                      onPhotoTap: () => _showPhotoFullScreen(c),
                    );
                    if (isPro) {
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (_) async => true,
                        onDismissed: (_) => _deleteWithUndo(c, index),
                        child: card,
                      );
                    }
                    return Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 20, color: Color(0xFFFFD600)),
                            const SizedBox(width: 8),
                            Text(tr('upgradeToPro'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        // Show upgrade dialog
                        if (!mounted) return false;
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(tr('proFeature')),
                            content: Text(tr('upgradeToDelete')),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(tr('cancel'))),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    // TODO: open Pro purchase screen
                                  },
                                  child: Text(tr('upgrade'),
                                      style: const TextStyle(color: Color(0xFFFFD600)))),
                            ],
                          ),
                        );
                        return false;
                      },
                      child: card,
                    );
                  },
                )
              ),
        ),
        _voiceBar(),
      ],
    );
  }

  // ── Voice ──────────────────────────────────────────────────────

  Future<void> _toggleVoice() async {
    if (_voiceOn) {
      _speech.stop();
      setState(() => _voiceOn = false);
    } else {
      _startVoice();
    }
  }

  Future<void> _startVoice() async {
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 500));
    final available = await _speech.initialize(
      onError: (_) { if (mounted) setState(() => _voiceOn = false); },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _voiceOn = false);
        }
      },
    );
    if (!available) return;
    setState(() => _voiceOn = true);
    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final t = result.recognizedWords.toLowerCase().trim();
        if (t == _lastVoiceText) return;
        _lastVoiceText = t;
        setState(() => _voiceStatus = '🎤 "$t"');
        if (!t.contains('caught')) return;
        final words = t.split(RegExp(r'\s+'));
        final idx = words.indexWhere((w) => w == 'caught');
        if (idx < 0 || idx >= words.length - 1) return;
        final hasSpecies = words.sublist(idx + 1).any((w) =>
            w.length >= 3 && RegExp(r'^[a-z]+$').hasMatch(w));
        if (!hasSpecies) return;
        final name = words.sublist(0, idx).join(' ');
        if (name.isEmpty) return;
        String species = 'fish';
        String? location;
        for (int i = idx + 1; i < words.length; i++) {
          final w = words[i];
          // Check for location keywords: "at", "from", "in", "on"
          if ((w == 'at' || w == 'from' || w == 'in' || w == 'on') &&
              i + 1 < words.length) {
            // Everything after the keyword is the location
            location = words.sublist(i + 1).join(' ');
            break;
          }
          if (species == 'fish' && w.length >= 3 && RegExp(r'^[a-z]+$').hasMatch(w)) {
            species = w;
          }
        }
        _voiceStatus = '🎤 Opening form for $name - $species';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddCatchScreen(
              initialAngler: name,
              initialSpecies: species,
              initialLocation: location,
            ),
          ),
        );
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 10),
      ),
    );
  }

  void _showPhotoFullScreen(Catch c) {
    if (!c.hasPhotos) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: c.primaryPhoto != null
                  ? Image.file(
                      File(c.primaryPhoto!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image, color: Colors.white54, size: 64),
                    )
                  : const Icon(Icons.image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sampleStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }

  /// Add a voice mic button at the bottom of the catches list.
  Widget _voiceBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _voiceStatus,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _voiceOn ? Icons.mic : Icons.mic_none,
              color: _voiceOn ? Colors.red : theme.colorScheme.primary,
            ),
            onPressed: _toggleVoice,
            tooltip: _voiceOn ? tr('muteMic') : tr('voiceRecord'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CatchCard extends StatelessWidget {
  final Catch catch_;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onPhotoTap;

  const _CatchCard({
    required this.catch_,
    required this.onTap,
    required this.onDelete,
    this.onPhotoTap,
  });

  Widget _speciesIcon(ThemeData theme) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.set_meal,
          color: theme.colorScheme.primary, size: 32),
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
                  // Photo or icon — bigger, tappable, with Hero
                  if (catch_.hasPhotos)
                    GestureDetector(
                      onTap: onPhotoTap,
                      child: Hero(
                        tag: 'catch-photo-${catch_.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 100,
                            height: 80,
                            child: Image.file(
                              File(catch_.primaryPhoto!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _speciesIcon(theme),
                            ),
                          ),
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
                  // Delete (Pro only) — kept for non-swipe access
                  if (ProService.instance.isPro)
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

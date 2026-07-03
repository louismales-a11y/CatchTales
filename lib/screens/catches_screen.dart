import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/translation_service.dart';
import '../services/pro_service.dart';
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
  // Voice
  late stt.SpeechToText _speech;
  bool _voiceOn = false;
  String _voiceStatus = '';
  String _lastVoiceText = '';

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
        title: Text(tr('deleteCatch')),
        content: Text(trp('removeCatch', {'species': c.species, 'angler': c.angler})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('delete'), style: const TextStyle(color: Colors.red))),
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
    context.watch<TranslationService>();
    if (_loading) {
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
                    trp('freeCatchBanner', {'count': '${_catches.length}', 'limit': '${ProService.freeCatchLimit}'}),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _catches.isEmpty
              ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('yourFirstCatch'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(tr('sampleCatch'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            // Sample catch card with photo
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.set_meal,
                              color: Theme.of(context).colorScheme.primary, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Largemouth Bass',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(tr('you'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _sampleStat(Icons.monitor_weight, '4.5 kg'),
                              const SizedBox(width: 12),
                              _sampleStat(Icons.straighten, '58 cm'),
                              const SizedBox(width: 12),
                              _sampleStat(Icons.wb_sunny, tr('sunny')),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('📍 Lake Michigan',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      )
              : RefreshIndicator(
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
                          errorBuilder: (_, _, _) => _speciesIcon(theme),
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
                  // Delete (Pro only)
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

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    Future.microtask(() => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speech.stop();
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

  // ── Voice Command ──────────────────────────────────────────────────

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase().trim();
        if (text.isNotEmpty) {
          _lastCommand = text;
          _parseCommand(text);
        }
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
      ),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  /// Parse voice commands like:
  ///   "fish buddy Louis caught one"
  ///   "fish buddy angler name caught one"
  ///   "fish buddy John caught 3"
  ///   "fish buddy Mary caught a big one"  →  increments by 1
  void _parseCommand(String text) {
    // Remove "fish buddy" prefix if present
    String cmd = text;
    for (final prefix in ['fish buddy', 'fishbuddy', 'hey fish buddy', 'ok fish buddy']) {
      if (cmd.startsWith(prefix)) {
        cmd = cmd.substring(prefix.length).trim();
        break;
      }
    }

    // Extract number
    int count = 1;
    final numberWords = {
      'one': 1, '1': 1, 'a': 1, 'an': 1,
      'two': 2, '2': 2, 'three': 3, '3': 3,
      'four': 4, '4': 4, 'five': 5, '5': 5,
      'six': 6, '6': 6, 'seven': 7, '7': 7,
      'eight': 8, '8': 8, 'nine': 9, '9': 9,
      'ten': 10, '10': 10,
    };

    // Look for "caught X" pattern
    final caughtMatch = RegExp(r'caught\s+(\S+)').firstMatch(cmd);
    if (caughtMatch != null) {
      final numWord = caughtMatch.group(1)!.toLowerCase();
      count = numberWords[numWord] ?? 1;
      // Remove "caught X" from the command string
      cmd = cmd.replaceFirst(caughtMatch.group(0)!, '').trim();
      // Also remove trailing words like "big", "huge", "nice", "one" etc
      cmd = cmd.replaceAll(RegExp(r'\b(big|huge|nice|great|one|a|the)\b'), '').trim();
    }

    // Also check for standalone number words
    if (count == 1) {
      for (final entry in numberWords.entries) {
        if (cmd.contains(entry.key)) {
          count = entry.value;
          cmd = cmd.replaceFirst(entry.key, '').trim();
          break;
        }
      }
    }

    // The remaining text should be the angler name
    final anglerName = cmd.replaceAll(RegExp(r'\b(caught|fish|buddy|and|the|for)\b'), '').trim();

    if (anglerName.isEmpty) {
      _showVoiceFeedback('Couldn\'t identify the angler. Try: "fish buddy Louis caught one"');
      return;
    }

    // Find closest matching angler
    final match = _findAngler(anglerName);
    if (match == null) {
      _showVoiceFeedback('No angler found matching "$anglerName"');
      return;
    }

    // Increment
    _incrementBy(match, count);
  }

  FishCounter? _findAngler(String spoken) {
    // Direct match first
    for (final c in _counters) {
      if (c.angler.toLowerCase() == spoken) return c;
    }
    // Contains match
    for (final c in _counters) {
      if (c.angler.toLowerCase().contains(spoken) ||
          spoken.contains(c.angler.toLowerCase())) {
        return c;
      }
    }
    return null;
  }

  void _showVoiceFeedback(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _incrementBy(FishCounter c, int count) async {
    for (int i = 0; i < count; i++) {
      if (c.id == null) return;
      await DatabaseService.instance.incrementCounter(c.id!);
    }
    if (!mounted) return;
    await _load();
    _showVoiceFeedback('✅ ${c.angler} +$count');
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                // Voice command bar
                if (_counters.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isListening
                                ? '🎤 Listening... say "fish buddy [name] caught one"'
                                : _lastCommand.isNotEmpty
                                    ? '🗣️ "$_lastCommand"'
                                    : 'Tap 🎤 to use voice commands',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isListening
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          tooltip: _isListening
                              ? 'Stop listening'
                              : 'Voice command',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
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
                                      fontSize: 18,
                                      color: Colors.grey.shade500)),
                              const SizedBox(height: 8),
                              Text('Type a name above and tap Add',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () => _decrement(c),
                                      iconSize: 26,
                                      color: Colors.grey.shade500,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
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
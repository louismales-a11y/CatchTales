import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/species_tally.dart';
import '../services/database_service.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  List<AnglerBreakdown> _breakdown = [];
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
    Future.microtask(() async {
      await _load();
    });
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
      final breakdown = await DatabaseService.instance.getSpeciesBreakdown();
      if (mounted) {
        setState(() {
          _breakdown = breakdown;
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

  Future<void> _resetAll() async {
    await DatabaseService.instance.resetSpeciesTallies();
    if (!mounted) return;
    await _load();
  }

  Future<void> _deleteAngler(String angler) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Angler'),
        content: Text('Remove $angler and all their catches?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteAngler(angler);
      if (!mounted) return;
      await _load();
    }
  }

  Future<void> _decrementSpecies(String angler, String species) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('species_tallies',
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, species]);
    if (rows.isEmpty) return;
    final id = rows.first['id'] as int;
    final count = rows.first['count'] as int;
    if (count <= 1) {
      await db.delete('species_tallies',
          where: 'id = ?', whereArgs: [id]);
    } else {
      await db.rawUpdate(
        'UPDATE species_tallies SET count = count - 1 WHERE id = ?',
        [id],
      );
    }
    if (!mounted) return;
    await _load();
  }

  // ── Voice Command ──────────────────────────────────────────────────

  /// Tap mic to toggle on/off. Starts a single session — no auto-restart.
  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        // When session ends naturally, just update state — don't restart
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (!available) return;
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (!_isListening) return;
        final text = result.recognizedWords.toLowerCase().trim();
        if (text.contains('fish buddy')) {
          _lastCommand = text;
          _parseCommand(text);
        }
      },
      listenFor: const Duration(minutes: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  /// Parse voice commands:
  ///   "fish buddy Louis caught a pike"
  ///   "fish buddy Louis caught a 9 inch perch"
  ///   "fish buddy Mary caught 3 walleye"
  ///   "fish buddy John caught a 36 inch pike"
  void _parseCommand(String text) {
    String cmd = text;
    for (final prefix in ['fish buddy', 'fishbuddy', 'hey fish buddy', 'ok fish buddy']) {
      if (cmd.startsWith(prefix)) {
        cmd = cmd.substring(prefix.length).trim();
        break;
      }
    }

    // Extract number of fish (default 1)
    int count = 1;
    final numberWords = <String, int>{
      'one': 1, '1': 1, 'a': 1, 'an': 1,
      'two': 2, '2': 2, 'three': 3, '3': 3,
      'four': 4, '4': 4, 'five': 5, '5': 5,
      'six': 6, '6': 6, 'seven': 7, '7': 7,
      'eight': 8, '8': 8, 'nine': 9, '9': 9,
      'ten': 10, '10': 10,
    };

    // Extract size: "X inch" or "X in" or "X foot" or "X ft"
    double? sizeInches;
    final sizeMatch = RegExp(r'(\d+(\.\d+)?)\s*(inch|in|inches|"|foot|ft|feet)').firstMatch(cmd);
    if (sizeMatch != null) {
      final value = double.parse(sizeMatch.group(1)!);
      final unit = sizeMatch.group(3)!.toLowerCase();
      if (unit == 'foot' || unit == 'ft' || unit == 'feet') {
        sizeInches = value * 12;
      } else {
        sizeInches = value;
      }
      // Remove the size text from the command for further parsing
      cmd = cmd.replaceFirst(sizeMatch.group(0)!, '').trim();
    }

    // Look for "caught" to split angler name and species
    final caughtMatch = RegExp(r'caught\s+(\S+)').firstMatch(cmd);
    String? species;
    if (caughtMatch != null) {
      final numOrSpecies = caughtMatch.group(1)!.toLowerCase();
      if (numberWords.containsKey(numOrSpecies)) {
        count = numberWords[numOrSpecies]!;
        final afterNum = cmd.substring(caughtMatch.end).trim();
        species = afterNum.split(RegExp(r'\s+(and|the|big|huge|nice|great)\s+'))[0]
            .split(' ')[0]
            .trim();
        if (species.isEmpty) species = 'fish';
      } else if (numOrSpecies == 'a' || numOrSpecies == 'an') {
        final after = cmd.substring(caughtMatch.end).trim();
        species = after.split(' ')[0].trim();
        if (species.isEmpty) species = 'fish';
        for (final w in ['big', 'huge', 'nice', 'great', 'and', 'the']) {
          if (species == w) {
            species = after.split(' ').length > 1
                ? after.split(' ')[1].trim()
                : 'fish';
            break;
          }
        }
      } else {
        species = numOrSpecies;
      }
    }

    if (species == null || species.isEmpty) {
      species = 'fish';
    }

    // Extract angler name: everything from start to "caught"
    final nameEnd = cmd.indexOf('caught');
    final anglerName = nameEnd > 0
        ? cmd.substring(0, nameEnd).trim()
        : cmd.trim();

    if (anglerName.isEmpty) {
      _showVoiceFeedback('Couldn\'t identify the angler. Try: "fish buddy Louis caught a 9 inch perch"');
      return;
    }

    final match = _findAngler(anglerName);
    if (match == null) {
      _showVoiceFeedback('No angler found matching "$anglerName"');
      return;
    }

    _recordCatch(match, species, count, sizeInches: sizeInches);
  }

  String? _findAngler(String spoken) {
    final names = _breakdown.map((b) => b.angler).toList();
    final s = spoken.toLowerCase().trim();

    // 1. Exact match (case-insensitive)
    for (final name in names) {
      if (name.toLowerCase() == s) return name;
    }

    // 2. Contains match
    for (final name in names) {
      final n = name.toLowerCase();
      if (n.contains(s) || s.contains(n)) return name;
    }

    // 3. Prefix match — first 3+ chars match
    if (s.length >= 3) {
      for (final name in names) {
        final n = name.toLowerCase();
        if (n.startsWith(s) || s.startsWith(n)) return name;
      }
    }

    // 4. Consonant skeleton — strip vowels, compare
    for (final name in names) {
      final n = name.toLowerCase();
      final skeletonS = s.replaceAll(RegExp(r'[aeiouy\s]'), '');
      final skeletonN = n.replaceAll(RegExp(r'[aeiouy\s]'), '');
      if (skeletonS == skeletonN ||
          skeletonS.length >= 3 && skeletonN.startsWith(skeletonS) ||
          skeletonN.length >= 3 && skeletonS.startsWith(skeletonN)) {
        return name;
      }
    }

    // 5. Levenshtein distance — within 2 edits for short names, 3 for longer
    String? best;
    int bestDist = 3;
    for (final name in names) {
      final n = name.toLowerCase();
      final dist = _levenshtein(s, n);
      final maxDist = n.length <= 4 ? 1 : (n.length <= 7 ? 2 : 3);
      if (dist <= maxDist && dist < bestDist) {
        bestDist = dist;
        best = name;
      }
    }
    if (best != null) return best;

    // 6. Common nicknames / aliases
    final aliases = <String, List<String>>{
      'louis': ['louie', 'loui', 'luis', 'lou'],
      'robert': ['rob', 'bob', 'bobby', 'robbie'],
      'william': ['will', 'bill', 'billy', 'willy'],
      'james': ['jim', 'jimmy', 'jamie'],
      'richard': ['rich', 'dick', 'rick', 'ricky'],
      'michael': ['mike', 'mikey', 'mick'],
      'thomas': ['tom', 'tommy', 'thom'],
      'christopher': ['chris', 'topher', 'kris'],
      'joseph': ['joe', 'joey'],
      'david': ['dave', 'davy'],
      'daniel': ['dan', 'danny'],
      'matthew': ['matt', 'matty'],
      'jennifer': ['jen', 'jenny'],
      'elizabeth': ['liz', 'lizzy', 'beth', 'betty'],
      'margaret': ['maggie', 'meg', 'peg'],
      'katherine': ['kate', 'katie', 'katy'],
      'patrick': ['pat', 'patty', 'paddy'],
      'andrew': ['andy', 'andrew', 'drew'],
      'stephen': ['steve', 'steven', 'steph'],
      'jonathan': ['jon', 'john', 'johnny', 'jonny'],
      'samantha': ['sam', 'sammy'],
    };
    for (final entry in aliases.entries) {
      if (entry.value.contains(s) || entry.key == s) {
        // Check if any name matches the alias target or alias itself
        for (final name in names) {
          final n = name.toLowerCase();
          if (n == entry.key || n == s || entry.value.contains(n)) return name;
        }
      }
    }

    return null;
  }

  /// Levenshtein edit distance between two strings.
  int _levenshtein(String a, String b) {
    if (a.length < b.length) {
      final tmp = a; a = b; b = tmp;
    }
    final inf = List.generate(b.length + 1, (i) => i);
    for (int i = 1; i <= a.length; i++) {
      final prev = List.from(inf);
      inf[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        inf[j] = [
          inf[j - 1] + 1,       // insert
          prev[j] + 1,           // delete
          prev[j - 1] + cost,    // substitute
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return inf[b.length];
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

  Future<void> _recordCatch(String angler, String species, int count,
      {double? sizeInches}) async {
    for (int i = 0; i < count; i++) {
      await DatabaseService.instance.incrementSpeciesTally(angler, species,
          sizeInches: sizeInches);
    }
    if (!mounted) return;
    await _load();
    final sizeStr = sizeInches != null
        ? ' ${sizeInches.toStringAsFixed(0)}"'
        : '';
    _showVoiceFeedback('✅ $angler caught $count $species$sizeStr');
  }

  /// Quick-add a species via UI (for when voice isn't convenient).
  Future<void> _quickAdd(String angler) async {
    final species = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('$angler caught…'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Species',
              hintText: 'e.g. Pike, Bass, Perch',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Add')),
          ],
        );
      },
    );
    if (species != null && species.isNotEmpty) {
      await _recordCatch(angler, species, 1);
    }
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
                    if (_breakdown.isNotEmpty)
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
              if (_breakdown.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isListening
                              ? '🎤 Mic active — say "fish buddy [name] caught a [species]"'
                              : _lastCommand.isNotEmpty
                                  ? '🗣️ "$_lastCommand"'
                                  : '🎤 Say "fish buddy…"',
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
                            _toggleListening,
                        tooltip: _isListening
                            ? 'Mute mic'
                            : 'Unmute mic',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // List
              Expanded(
                child: _breakdown.isEmpty
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
                        itemCount: _breakdown.length,
                        itemBuilder: (context, index) {
                          final b = _breakdown[index];
                          return _AnglerCard(
                            breakdown: b,
                            onAdd: () => _quickAdd(b.angler),
                            onDelete: () => _deleteAngler(b.angler),
                            onDecrement: (species) =>
                                _decrementSpecies(b.angler, species),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}

class _AnglerCard extends StatelessWidget {
  final AnglerBreakdown breakdown;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final void Function(String species) onDecrement;

  const _AnglerCard({
    required this.breakdown,
    required this.onAdd,
    required this.onDelete,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = breakdown;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            '${b.total}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(b.angler,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(
          b.species.isEmpty
              ? 'No catches yet'
              : '${b.species.length} species • ${b.total} total',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle, size: 22),
              onPressed: onAdd,
              color: theme.colorScheme.primary,
              tooltip: 'Quick add catch',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
              tooltip: 'Remove angler',
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: b.species.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Say "fish buddy ${b.angler} caught a pike"',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500)),
                ),
              ]
            : [
                // Species tally header
                Row(
                  children: [
                    Text('Species',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500)),
                    const Spacer(),
                    Text('Count',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500)),
                  ],
                ),
                const Divider(height: 8),
                // Species rows
                ...b.species.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.set_meal,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.species,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14)),
                          ),
                          Text('${s.count}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary)),
                          if (s.sizeDisplay.isNotEmpty) ...[const SizedBox(width: 4),
                            Text(s.sizeDisplay,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => onDecrement(s.species),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.remove_circle_outline,
                                  size: 18, color: Colors.red.shade400),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 8),
                Row(
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: theme.colorScheme.primary)),
                    const Spacer(),
                    Text('${b.total}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: theme.colorScheme.primary)),
                  ],
                ),
              ],
      ),
    );
  }
}

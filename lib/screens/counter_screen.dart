import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/species_tally.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import 'add_catch_screen.dart';

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
  String _liveTranscription = '';
  DateTime? _lastCatchTime;
  String _lastCatchKey = '';
  DateTime? _wakeAt;
  Map<String, String> _speciesCorrections = {};
  String? _pendingAngler;
  String? _pendingSpecies;
  int _pendingCount = 0;
  String? _pendingLocation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    Future.microtask(() async {
      await _load();
      await _loadCorrections();
      _startMic();
    });
  }

  /// Load saved species corrections from SharedPreferences.
  Future<void> _loadCorrections() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('species_corrections');
    if (data != null) {
      _speciesCorrections = Map<String, String>.from(
          json.decode(data) as Map);
    }
  }

  /// Save species corrections to SharedPreferences.
  Future<void> _saveCorrections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('species_corrections',
        json.encode(_speciesCorrections));
  }

  /// Start the mic. Uses a long pause timeout so the session stays alive
  /// for a full minute after each utterance — no cycling, no ping noise.
  Future<void> _startMic() async {
    if (_isListening) return;
    final available = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
          // If there's a pending tally, restart mic so user can respond
          if (_pendingCount > 0) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isListening) _startMic();
            });
          }
        }
      },
    );
    if (!available) return;
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords.toLowerCase().trim();
        // Show what the mic hears in the live transcription
        String status = '';
        bool isWaked = false;

        // 🥇 Check for pending tally FIRST (yes/no response to "Record this fish?")
        // This takes priority over everything else.
        if (_pendingCount > 0) {
          final t = text.trim().toLowerCase();
          if (t == 'no' || t == 'nope' || t == 'nah' ||
              t.startsWith('tally') || t == 'just tally' ||
              t == 'keep going' || t == 'next fish') {
            // Explicit "no" → clear pending, stay on counter
            _pendingCount = 0;
            status = ' ✅ Just tally';
            isWaked = true;
          } else if (t == 'yes' || t == 'yeah' || t == 'yep' || t == 'yup' ||
                     t == 'sure' || t == 'ok' || t == 'okay' ||
                     t == 'record' || t.startsWith('log') ||
                     t == 'add' || t == 'save') {
            // Explicit "yes" → open catch form
            isWaked = true;
            _pendingCount = 0;
            _openCatchForm(_pendingAngler!, _pendingSpecies!, 1, location: _pendingLocation);
            setState(() => _liveTranscription = t + ' — opening catch form');
            return;
          }
          // Anything else → ignore, stay pending
        }

        // 🥈 Check for wake word
        if (text.contains('fish') && text.contains('buddy')) {
          _wakeAt = DateTime.now();
          isWaked = true;
          status = ' (🎤 wake!)';
        }
        // 🥉 Check if we're within 5s wake window
        if (!isWaked && _wakeAt != null &&
            DateTime.now().difference(_wakeAt!) < const Duration(seconds: 5)) {
          isWaked = true;
          status = ' (🎤 +5s)';
        }

        if (isWaked && text.contains('caught')) {
          // Check if there's a real species word (≥3 letters) after "caught"
          final words = text.split(RegExp(r'\s+'));
          final idx = words.indexWhere((w) => w == 'caught');
          final hasSpecies = idx >= 0 && idx < words.length - 1 &&
              words.sublist(idx + 1).any((w) =>
                  w.length >= 3 && RegExp(r'^[a-z]+$').hasMatch(w));
          if (!hasSpecies) {
            status = ' (⏳ waiting for species)';
          } else {
            status = ' (⚙️ processing!)';
            _lastCommand = text;
            _parseCommand(text);
          }
        }
        setState(() => _liveTranscription = text + status);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 60),
      ),
    );
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

  Future<void> _addAngler({String? voiceName}) async {
    final name = voiceName ?? _nameCtrl.text.trim();
    if (name.isEmpty) return;
    _nameCtrl.clear();
    await DatabaseService.instance.addCounter(name);
    if (!mounted) return;
    await _load();
    if (voiceName != null) {
      _showVoiceFeedback('✅ Added angler: $name — now say "fish buddy $name caught a pike"');
    }
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

  /// Show a dialog to rename a species (fix STT misrecognitions).
  /// Saves the correction so voice commands auto-correct in the future.
  Future<void> _editSpecies(String angler, String oldSpecies) async {
    final ctrl = TextEditingController(text: oldSpecies);
    final newSpecies = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fix species name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Species',
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
              child: const Text('Save')),
        ],
      ),
    );
    if (newSpecies == null || newSpecies.isEmpty || newSpecies == oldSpecies) return;
    final db = await DatabaseService.instance.database;
    // Check if target species already exists for this angler
    final existing = await db.query('species_tallies',
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, newSpecies]);
    if (existing.isNotEmpty) {
      // Merge: add counts and sizes from old species into new species
      final oldRow = await db.query('species_tallies',
          where: 'angler = ? AND species = ?',
          whereArgs: [angler, oldSpecies]);
      if (oldRow.isNotEmpty) {
        final oldCount = oldRow.first['count'] as int? ?? 0;
        final oldSizes = oldRow.first['sizes'] as String? ?? '';
        final newCount = existing.first['count'] as int? ?? 0;
        final newSizes = existing.first['sizes'] as String? ?? '';
        // Combine sizes (comma-separated) and let the SpeciesTally trim to 5
        final combined = [newSizes, oldSizes]
            .where((s) => s.isNotEmpty)
            .join(',');
        await db.update(
          'species_tallies',
          {'count': newCount + oldCount, 'sizes': combined},
          where: 'angler = ? AND species = ?',
          whereArgs: [angler, newSpecies],
        );
        // Delete the old species row
        await db.delete('species_tallies',
            where: 'angler = ? AND species = ?',
            whereArgs: [angler, oldSpecies]);
      }
    } else {
      // No conflict — simple rename
      await db.update(
        'species_tallies',
        {'species': newSpecies},
        where: 'angler = ? AND species = ?',
        whereArgs: [angler, oldSpecies],
      );
    }
    // Remember this correction for future voice commands
    _speciesCorrections[oldSpecies.toLowerCase()] = newSpecies.toLowerCase();
    await _saveCorrections();
    if (!mounted) return;
    await _load();
  }

  /// Open the full catch form with pre-filled data.
  void _openCatchForm(String angler, String species, int count, {String? location}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCatchScreen(
          initialAngler: angler,
          initialSpecies: species,
          initialLocation: location,
        ),
      ),
    );
  }

  /// Parse "record [name] caught [species]" and open Add Catch form directly.
  void _directRecord(String cmd) {
    // Extract size (if any) — same regex as _parseCommand uses
    final sizeMatch = RegExp(r'(\d+(\.\d+)?)\s*(inch|in|inches|"|foot|ft|feet)').firstMatch(cmd);
    if (sizeMatch != null) {
      cmd = cmd.replaceFirst(sizeMatch.group(0)!, '').trim();
    }

    // Extract number of fish
    int count = 1;
    final numberWords = <String, int>{
      'one': 1, '1': 1, 'a': 1, 'an': 1,
      'two': 2, '2': 2, 'three': 3, '3': 3,
      'four': 4, '4': 4, 'five': 5, '5': 5,
      'six': 6, '6': 6, 'seven': 7, '7': 7,
      'eight': 8, '8': 8, 'nine': 9, '9': 9,
      'ten': 10, '10': 10,
    };

    final caughtMatch = RegExp(r'caught\s+(\S+)').firstMatch(cmd);
    String? species;
    if (caughtMatch != null) {
      final numOrSpecies = caughtMatch.group(1)!.toLowerCase();
      if (numberWords.containsKey(numOrSpecies)) {
        count = numberWords[numOrSpecies]!;
        final afterNum = cmd.substring(caughtMatch.end).trim();
        species = afterNum.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = 'fish';
      } else if (numOrSpecies == 'a' || numOrSpecies == 'an') {
        final after = cmd.substring(caughtMatch.end).trim();
        species = after.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = 'fish';
      } else {
        final after = cmd.substring(caughtMatch.start + 6).trim();
        species = after.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = numOrSpecies;
      }
    }

    if (species == null || species.isEmpty) species = 'fish';

    // Apply learned corrections
    final corrected = _speciesCorrections[species.toLowerCase()];
    if (corrected != null) species = corrected;

    // Extract angler name
    final nameEnd = cmd.indexOf('caught');
    final anglerName = nameEnd > 0
        ? cmd.substring(0, nameEnd).trim()
        : cmd.trim();

    if (anglerName.isEmpty) {
      _showVoiceFeedback('Say "fish buddy record [name] caught [species]"');
      return;
    }

    final match = _findAngler(anglerName);
    if (match == null) {
      _showVoiceFeedback('No angler found matching "$anglerName"');
      return;
    }

    // Extract location from "at X" / "from X" / "in X" / "on X"
    String? location;
    final locationWords = RegExp(r'\b(at|from|in|on)\s+(.+)$').firstMatch(cmd);
    if (locationWords != null) {
      location = locationWords.group(2)!.trim();
    }

    _openCatchForm(match, species, count, location: location);
  }

  // ── Voice Command ──────────────────────────────────────────────────

  /// Tap mic to toggle on/off.
  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      await _startMic();
    }
  }

  /// Parse voice commands:
  ///   "fish buddy Louis caught a pike"
  ///   "fish buddy Louis caught a 9 inch perch"
  ///   "fish buddy Mary caught 3 walleye"
  ///   "fish buddy John caught a 36 inch pike"
  ///   "fish buddy add Louis"
  ///   "fish buddy remove Louis"
  ///   "fish buddy reset"
  ///   "fish buddy help"
  void _parseCommand(String text) {
    String cmd = text;
    for (final prefix in ['fish buddy', 'fishbuddy', 'hey fish buddy', 'ok fish buddy']) {
      if (cmd.startsWith(prefix)) {
        cmd = cmd.substring(prefix.length).trim();
        break;
      }
    }

    // ── Direct catch recording (skip tally, open form) ──
    if (cmd.startsWith('record ')) {
      // e.g. "record jason caught a pike" → open Add Catch form directly
      _directRecord(cmd.substring(7).trim());
      return;
    }

    // ── Admin commands (no angler needed) ──
    // Handle pending "Record this fish?" prompt
    if (_pendingCount > 0) {
      _pendingCount = 0; // clear regardless
      // "yes" → open catch form
      if (cmd == 'yes' || cmd == 'yeah' || cmd == 'yep' || cmd == 'yup' ||
          cmd.startsWith('record') || cmd.startsWith('log') ||
          cmd == 'add to catches' || cmd == 'save catch' ||
          cmd == 'sure' || cmd == 'ok') {
        _openCatchForm(_pendingAngler!, _pendingSpecies!, 1);
        return;
      }
      // Anything else → just tally
      setState(() => _liveTranscription = '✅ Just tally — ready for next fish');
      return; // always return — don't reprocess as a fish command
    }
    if (cmd.startsWith('help') || cmd == 'what can i say' || cmd == 'commands') {
      _showVoiceFeedback('Say "fish buddy [name] caught [species]" or "add [name]" to add angler, "reset" for new trip, "remove [name]" to delete');
      return;
    }
    if (cmd.startsWith('reset') || cmd.startsWith('new trip')) {
      _resetAll();
      return;
    }
    if (cmd.startsWith('add ')) {
      final name = cmd.substring(4).trim();
      if (name.isEmpty) return;
      if (RegExp(r'^(angler|angler named|a new angler|a new person|a new fisherman) (.+)$').hasMatch(name)) {
        final m = RegExp(r'^(angler|angler named|a new angler|a new person|a new fisherman) (.+)$').firstMatch(name);
        _addAngler(voiceName: m!.group(2)!.trim());
      } else {
        _addAngler(voiceName: name);
      }
      return;
    }
    if (cmd.startsWith('remove ')) {
      final name = cmd.substring(7).trim();
      if (name.isEmpty) return;
      final match = _findAngler(name);
      if (match != null) {
        _deleteAngler(match);
      } else {
        _showVoiceFeedback('No angler found matching "$name"');
      }
      return;
    }
    if (cmd.startsWith('delete ')) {
      final name = cmd.substring(7).trim();
      if (name.isEmpty) return;
      final match = _findAngler(name);
      if (match != null) {
        _deleteAngler(match);
      } else {
        _showVoiceFeedback('No angler found matching "$name"');
      }
      return;
    }

    // Look for "caught" to split angler name and species
    // (no size extraction — voice is for quick tally only)
    int count = 1;
    final numberWords = <String, int>{
      'one': 1, '1': 1, 'a': 1, 'an': 1,
      'two': 2, '2': 2, 'three': 3, '3': 3,
      'four': 4, '4': 4, 'five': 5, '5': 5,
      'six': 6, '6': 6, 'seven': 7, '7': 7,
      'eight': 8, '8': 8, 'nine': 9, '9': 9,
      'ten': 10, '10': 10,
    };

    final caughtMatch = RegExp(r'caught\s+(\S+)').firstMatch(cmd);
    String? species;
    if (caughtMatch != null) {
      final numOrSpecies = caughtMatch.group(1)!.toLowerCase();
      if (numberWords.containsKey(numOrSpecies)) {
        count = numberWords[numOrSpecies]!;
        final afterNum = cmd.substring(caughtMatch.end).trim();
        species = afterNum.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = 'fish';
      } else if (numOrSpecies == 'a' || numOrSpecies == 'an') {
        final after = cmd.substring(caughtMatch.end).trim();
        species = after.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = 'fish';
      } else {
        final after = cmd.substring(caughtMatch.start + 6).trim();
        species = after.split(RegExp(r'\s+(and|the|big|huge|nice|great|a|an)\s+'))[0].trim();
        if (species.isEmpty) species = numOrSpecies;
      }
    }

    if (species == null || species.isEmpty) {
      species = 'fish';
    }
    // Apply any learned corrections (e.g. "pipe" → "pike" from past edits)
    final corrected = _speciesCorrections[species.toLowerCase()];
    if (corrected != null) species = corrected;

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

    // Extract location from "at X" / "from X" / "in X" / "on X"
    String? location;
    final locationWords = RegExp(r'\b(at|from|in|on)\s+(.+)$').firstMatch(cmd);
    if (locationWords != null) {
      location = locationWords.group(2)!.trim();
    }

    // New "caught" command replaces any pending record — just tally
    _pendingCount = 0;
    _pendingLocation = location;
    _recordCatch(match, species, count);
  }

  /// Correct common STT misrecognitions for species names using
  /// Levenshtein distance against a known list.
  /// Check if text contains something that sounds like "fish buddy".
  /// Uses Levenshtein distance to handle STT misrecognitions.
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

  Widget _voicePromptText(ThemeData theme) {
    final hasAnglers = _breakdown.isNotEmpty;

    if (_isListening) {
      if (hasAnglers) {
        return Text(
          '🎤 Mic active — say "fish buddy [name] caught a [species]"',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        );
      } else {
        return Text(
          '🎤 Mic active — add an angler first, then say "fish buddy [name] caught a [species]"',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    // Not listening
    if (_lastCommand.isNotEmpty) {
      return Row(
        children: [
          Flexible(
            child: Text(
              '🗣️ "$_lastCommand"',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '— tap mic to speak',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (hasAnglers) {
      return Text(
        '🎤 Say "fish buddy [name] caught [species]" — tap mic to start',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      '🎤 Tap mic, add anglers with "fish buddy add [name]", then record catches!',
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontStyle: FontStyle.italic,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showVoiceFeedback(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _recordCatch(String angler, String species, int count) async {
    final key = '$angler|$species|$count';
    final now = DateTime.now();
    if (key == _lastCatchKey && _lastCatchTime != null &&
        now.difference(_lastCatchTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastCatchKey = key;
    _lastCatchTime = now;

    // Set pending tally BEFORE any async work so "yes" response works
    _pendingAngler = angler;
    _pendingSpecies = species;
    _pendingCount = count;
    setState(() {
      _liveTranscription = '✅ Tally: $angler +$count $species — Record this fish? Say yes or no';
    });

    for (int i = 0; i < count; i++) {
      await DatabaseService.instance.incrementSpeciesTally(angler, species);
    }
    if (!mounted) return;
    await _load();
    // Share to active session if any
    if (SessionService.instance.currentCode != null) {
      SessionService.instance.shareCatch(species, null, null, null);
    }
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
              // Voice command bar — always visible
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _voicePromptText(theme),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          onPressed: _toggleListening,
                          tooltip: _isListening
                              ? 'Mute mic'
                              : 'Unmute mic',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (_liveTranscription.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🔊 "$_liveTranscription"',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Prominent prompt banner when asking "Record this fish?"
              if (_pendingCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      bottom: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline,
                          color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Record $_pendingSpecies? Say "yes" or "no"',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
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
                            const SizedBox(height: 4),
                            Text('or say "fish buddy add [name]" via voice',
                                style: TextStyle(
                                    fontSize: 12,
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
                            onEdit: (species) =>
                                _editSpecies(b.angler, species),
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
  final void Function(String species) onEdit;

  const _AnglerCard({
    required this.breakdown,
    required this.onAdd,
    required this.onDelete,
    required this.onDecrement,
    required this.onEdit,
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
                            child: GestureDetector(
                              onTap: () => onEdit(s.species),
                              child: Text(s.species,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                            ),
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

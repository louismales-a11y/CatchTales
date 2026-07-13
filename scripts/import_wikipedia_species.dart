// ═══════════════════════════════════════════════════════════════════════════
//  Wikipedia Species Importer — v2 (Full Details)
//  Run: dart run scripts/import_wikipedia_species.dart
//
//  Fetches species from Wikipedia categories, pulls infobox data
//  (size, habitat, diet), and generates complete FishSpecies entries
//  with smart defaults for tackle tips based on fish family.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _headers = {
  'User-Agent': 'CatchTales/1.0 (species-importer)',
  'Accept': 'application/json',
};

/// Category → (waterType, regions)
const _categories = {
  'Freshwater_fish_of_Canada': ('Freshwater', ['Canada', 'USA']),
  'Freshwater_fish_of_the_United_States': ('Freshwater', ['USA']),
  'Fish_of_the_Great_Lakes': ('Freshwater', ['USA', 'Canada']),
  'Game_fish': ('Freshwater, Saltwater', ['USA', 'Canada']),
};

Set<String> _existingNames = {};
Set<String> _existingScientific = {};
List<Map<String, dynamic>> _newEntries = [];
int _totalFetched = 0;
int _skippedNoData = 0;

Future<void> main(List<String> args) async {
  final autoMode = args.contains('--auto');

  print('=' * 60);
  print('WIKIPEDIA SPECIES IMPORTER v2');
  print('=' * 60);

  _loadExistingSpecies();

  print('\n📂 Existing: ${_existingNames.length} species');
  print('\n🔍 Scanning Wikipedia categories...\n');

  // Collect all species pages from categories
  final allPages = <String, String>{}; // title -> category source

  for (final entry in _categories.entries) {
    final category = entry.key;
    final pages = await _fetchCategoryPages(category);
    for (final title in pages) {
      // Skip list pages, non-species pages
      if (title.startsWith('List of') || title.startsWith('Category:')) continue;
      if (title.contains('(') && !title.contains('fish')) continue;
      if (title.length < 3) continue;
      allPages[title] = category;
    }
    print('  📚 $category: ${pages.length} total → ${pages.length} species');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  print('\n🔬 ${allPages.length} unique species candidates found');

  // Filter out existing species
  final newSpecies = <MapEntry<String, String>>[];
  for (final entry in allPages.entries) {
    final title = entry.key;
    final normalized = title.toLowerCase().trim();
    bool exists = false;
    for (final name in _existingNames) {
      if (normalized == name || normalized.contains(name) || name.contains(normalized)) {
        // Check if it's a very close match (avoid "trout" matching "brown trout")
        if ((normalized.length > 6 && name.length > 6) &&
            (normalized.contains(name) || name.contains(normalized))) {
          exists = true;
          break;
        }
      }
    }
    if (!exists) {
      newSpecies.add(MapEntry(title, entry.value));
    }
  }

  print('🆕 New species not in database: ${newSpecies.length}\n');

  if (newSpecies.isEmpty) {
    print('✅ Database is up to date!');
    return;
  }

  // Fetch full details for each new species
  print('📥 Fetching Wikipedia details for each species...\n');

  String? currentWaterType;
  for (final entry in newSpecies) {
    final title = entry.key;
    final category = entry.value;
    currentWaterType = _categories[category]!.$1;

    await _fetchSpeciesDetails(title, currentWaterType, category);
    _totalFetched++;

    // Progress
    if (_totalFetched % 10 == 0) {
      print('  ⏳ $_totalFetched / ${newSpecies.length} processed...');
    }

    // Rate limit — 1 request per second max
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Summary
  print('\n' + '=' * 60);
  print('📊 IMPORT SUMMARY');
  print('=' * 60);
  print('  Total candidates: ${newSpecies.length}');
  print('  Successfully fetched: ${_newEntries.length}');
  print('  Skipped (no data): $_skippedNoData');
  print('');

  if (_newEntries.isEmpty) {
    print('❌ No species could be imported.');
    return;
  }

  // Generate the database entries
  print('✏️  Generating FishSpecies entries...\n');
  _generateOutput(autoMode);

  if (autoMode) {
    print('\n✅ Auto-import complete! ${_newEntries.length} species added.');
    print('   Run flutter analyze to verify.');
  } else {
    print('\n📋 Preview mode — first 5 entries shown above.');
    print('   Run with --auto to append them to fish_database.dart');
    print('   or manually copy the entries.');
  }
}

void _loadExistingSpecies() {
  final file = File('lib/data/fish_database.dart');
  if (!file.existsSync()) return;
  final content = file.readAsStringSync();

  for (final m in RegExp(r"name:\s*'([^']+)'").allMatches(content)) {
    _existingNames.add(m.group(1)!.toLowerCase().trim());
  }
  for (final m in RegExp(r"cientificName:\s*'([^']+)'").allMatches(content)) {
    _existingScientific.add(m.group(1)!.toLowerCase().trim());
  }
}

Future<Set<String>> _fetchCategoryPages(String category) async {
  final pages = <String>{};
  String? continueToken;

  try {
    while (true) {
      var url = 'https://en.wikipedia.org/w/api.php'
          '?action=query'
          '&format=json'
          '&list=categorymembers'
          '&cmtitle=Category:$category'
          '&cmlimit=max'
          '&cmtype=page';
      if (continueToken != null) url += '&cmcontinue=$continueToken';

      final resp = await http.get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) break;

      final data = jsonDecode(resp.body);
      final members = data['query']?['categorymembers'] as List? ?? [];

      for (final m in members) {
        final title = m['title'] as String?;
        if (title != null) pages.add(title);
      }

      continueToken = data['continue']?['cmcontinue'] as String?;
      if (continueToken == null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  } catch (e) {
    print('  ⚠️ Error fetching $category: $e');
  }

  return pages;
}

Future<void> _fetchSpeciesDetails(String title, String waterType, String category) async {
  try {
    final encoded = title.replaceAll(' ', '_');
    final url = 'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded';
    final resp = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      _skippedNoData++;
      return;
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final extract = data['extract'] as String? ?? '';
    final scientificName = data['title'] as String? ?? title;
    final imageUrl = (data['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;

    // Check if we already have this scientific name
    if (_existingScientific.contains(scientificName.toLowerCase().trim())) return;

    // Extract description (first 2 sentences or up to 500 chars)
    String description = _extractDescription(extract);

    // Determine size range from description
    String sizeRange = _extractSizeRange(extract, title);

    // Determine habitat from description
    String habitat = _extractHabitat(extract);

    // Determine diet from description
    String diet = _extractDiet(extract);

    // Determine tackle and tips based on fish type
    final tackleInfo = _getTackleInfo(title, extract);
    final tips = _getTips(title, extract, waterType);

    // Determine color based on name hash
    final colorHex = _getColorHex(title);

    // Determine regions from category
    final regions = _categories[category]!.$2;

    _newEntries.add({
      'name': title,
      'scientificName': scientificName,
      'regions': regions,
      'sizeRange': sizeRange,
      'habitat': habitat,
      'waterType': waterType,
      'diet': diet,
      'commonTackle': tackleInfo,
      'description': description,
      'tips': tips,
      'color': colorHex,
    });

  } catch (e) {
    _skippedNoData++;
  }
}

String _extractDescription(String extract) {
  if (extract.isEmpty) return '';
  // Take first 2 sentences
  final sentences = extract.split(RegExp(r'(?<=[.!])\s+'));
  final desc = sentences.take(2).join(' ');
  return desc.length > 500 ? desc.substring(0, 497) + '...' : desc;
}

String _extractSizeRange(String extract, String title) {
  // Look for size patterns in the extract
  final sizePatterns = [
    RegExp(r'(\d+[–\-]\d+\s*(?:cm|mm|m|inches|ft|feet|kg|lb|pounds))', caseSensitive: false),
    RegExp(r'(up to\s+\d+\s*(?:cm|mm|m|kg|lb))', caseSensitive: false),
    RegExp(r'(\d+\s*(?:cm|kg|lb|m)\s+(?:and|to)\s+\d+\s*(?:cm|kg|lb|m))', caseSensitive: false),
    RegExp(r'(grows?\s+to\s+\d+\s*(?:cm|m))', caseSensitive: false),
    RegExp(r'(reaches?\s+\d+\s*(?:cm|m))', caseSensitive: false),
  ];

  for (final pattern in sizePatterns) {
    final match = pattern.firstMatch(extract);
    if (match != null) return match.group(1)!;
  }

  // Default by fish type
  if (title.contains('bass')) return '25–60 cm, up to 5 kg';
  if (title.contains('trout')) return '20–50 cm, up to 3 kg';
  if (title.contains('salmon')) return '40–80 cm, up to 10 kg';
  if (title.contains('catfish') || title.contains('cat fish')) return '30–80 cm, up to 15 kg';
  if (title.contains('pike')) return '40–100 cm, up to 15 kg';
  if (title.contains('perch')) return '15–30 cm, up to 1 kg';
  if (title.contains('sunfish') || title.contains('panfish')) return '10–25 cm, up to 0.5 kg';
  if (title.contains('carp')) return '30–70 cm, up to 10 kg';

  return 'Size varies';
}

String _extractHabitat(String extract) {
  final habitatPatterns = [
    RegExp(r'(?:found|inhabits|lives|occurs)\s+in\s+[^.!]+', caseSensitive: false),
    RegExp(r'(?:freshwater|saltwater|marine|river|lake|stream|pond|ocean|coastal|estuary)[^.!]*', caseSensitive: false),
  ];

  for (final pattern in habitatPatterns) {
    final match = pattern.firstMatch(extract);
    if (match != null) {
      final text = match.group(0)!;
      if (text.length > 15 && text.length < 200) return text;
    }
  }

  return 'Varies by region and season';
}

String _extractDiet(String extract) {
  final dietPatterns = [
    RegExp(r'(?:feeds?\s+on|diet\s+consists?\s+of|eats?|preys?\s+on)[^.!]*', caseSensitive: false),
  ];

  for (final pattern in dietPatterns) {
    final match = pattern.firstMatch(extract);
    if (match != null) return match.group(0)!;
  }

  return 'Small fish, insects, crustaceans';
}

String _getTackleInfo(String name, String extract) {
  final lower = name.toLowerCase();

  if (lower.contains('bass')) return 'Spinnerbaits, crankbaits, plastic worms, topwater lures';
  if (lower.contains('trout')) return 'Spinners, spoons, flies, small crankbaits';
  if (lower.contains('salmon')) return 'Spoons, spinners, plugs, flies, roe';
  if (lower.contains('catfish') || lower.contains('cat fish')) return 'Stinkbaits, cut bait, nightcrawlers, chicken liver';
  if (lower.contains('pike') || lower.contains('muskie') || lower.contains('pickerel')) return 'Large spoons, jerkbaits, bucktails, sucker minnows';
  if (lower.contains('perch')) return 'Small jigs, minnows, worms, small spinners';
  if (lower.contains('crappie') || lower.contains('panfish') || lower.contains('sunfish') || lower.contains('bluegill')) return 'Small jigs, worms, crickets, tiny spinners';
  if (lower.contains('walleye') || lower.contains('sauger')) return 'Jigs, crankbaits, live minnows, nightcrawlers';
  if (lower.contains('carp')) return 'Corn, dough balls, boilies, hair rigs';
  if (lower.contains('gar')) return 'Rope lures, cut bait, live minnows';
  if (lower.contains('bowfin')) return 'Spinnerbaits, live bait, cut bait';
  if (lower.contains('drum') || lower.contains('sheepshead')) return 'Crayfish, shrimp, clams, small jigs';
  if (lower.contains('redfish') || lower.contains('red drum')) return 'Gold spoons, soft plastics, live shrimp, crabs';
  if (lower.contains('snook')) return 'Live bait, soft plastics, topwater plugs, jigs';
  if (lower.contains('tarpon')) return 'Live crabs, jigs, soft plastics, flies';
  if (lower.contains('flounder')) return 'Minnows, shrimp, bucktail jigs, soft plastics';
  if (lower.contains('mackerel') || lower.contains('tuna')) return 'Spoons, jigs, live bait, trolling lures';
  if (lower.contains('grouper')) return 'Live bait, jigs, cut bait, bottom rigs';
  if (lower.contains('snapper')) return 'Squid, cut bait, jigs, live bait';

  return 'Varies — try live bait, jigs, or spoons';
}

List<String> _getTips(String name, String extract, String waterType) {
  final tips = <String>[];
  final lower = name.toLowerCase();

  if (lower.contains('bass')) {
    tips.add('Fish near weed lines and submerged structure');
    tips.add('Early morning and dusk are prime feeding times');
    tips.add('Match lure color to water clarity');
  } else if (lower.contains('trout')) {
    tips.add('Use light tackle for a better fight');
    tips.add('Fish in cooler water temperatures');
    tips.add('Match the hatch — use flies that resemble local insects');
  } else if (lower.contains('salmon')) {
    tips.add('Fish during spawning runs for best action');
    tips.add('Use bright colored lures in murky water');
  } else if (lower.contains('catfish') || lower.contains('cat fish')) {
    tips.add('Fish at night — catfish are most active after dark');
    tips.add('Use stinkbaits or cut bait for best results');
    tips.add('Focus on deep holes and channel bends');
  } else if (lower.contains('pike') || lower.contains('muskie')) {
    tips.add('Use a steel leader — they have sharp teeth');
    tips.add('Fish near weed beds and drop-offs');
    tips.add('Figure-8 retreive at boat side can trigger strikes');
  } else if (lower.contains('walleye')) {
    tips.add('Fish low-light periods — dawn, dusk, and overcast days');
    tips.add('Troll crankbaits along weed edges');
    tips.add('Jig with a minnow on rocky bottoms');
  } else if (lower.contains('panfish') || lower.contains('crappie') || lower.contains('bluegill') || lower.contains('sunfish')) {
    tips.add('Use ultralight tackle for maximum fun');
    tips.add('Fish near docks, fallen trees, and weed beds');
    tips.add('Small hooks with worms or crickets are deadly');
  } else if (lower.contains('carp')) {
    tips.add('Carp are wary — use light line and subtle presentations');
    tips.add('Chum with corn or boilies to attract them');
  } else if (waterType.contains('Saltwater') && !waterType.contains('Freshwater')) {
    tips.add('Check tides — fish are most active on moving tides');
    tips.add('Use fresh local bait for best results');
    tips.add('Match your tackle to the target species size');
  } else {
    tips.add('Try early morning or late evening for best results');
    tips.add('Match your bait to the local forage');
  }

  // Add seasonal tip if extract mentions it
  if (RegExp(r'spawn|spring|summer|winter|fall|autumn', caseSensitive: false).hasMatch(extract)) {
    tips.add('Timing: ${_extractSeasonalTip(extract)}');
  }

  return tips;
}

String _extractSeasonalTip(String extract) {
  final match = RegExp(r'(?:spawn|during\s+(?:spring|summer|winter|fall|autumn))[^.!]*', caseSensitive: false).firstMatch(extract);
  return match?.group(0) ?? 'Check local seasonal patterns';
}

String _getColorHex(String name) {
  // Generate a consistent color based on fish name hash
  final hash = name.hashCode;
  final hue = hash.abs() % 360;
  return _hslToHex(hue.toDouble(), 0.55, 0.40);
}

String _hslToHex(double h, double s, double l) {
  // Convert HSL to RGB hex string
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  double r, g, b;
  if (h < 60) { r = c; g = x; b = 0; }
  else if (h < 120) { r = x; g = c; b = 0; }
  else if (h < 180) { r = 0; g = c; b = x; }
  else if (h < 240) { r = 0; g = x; b = c; }
  else if (h < 300) { r = x; g = 0; b = c; }
  else { r = c; g = 0; b = x; }
  r = ((r + m) * 255).round().clamp(0, 255).toDouble();
  g = ((g + m) * 255).round().clamp(0, 255).toDouble();
  b = ((b + m) * 255).round().clamp(0, 255).toDouble();
  return '${r.toInt().toRadixString(16).padLeft(2, '0')}${g.toInt().toRadixString(16).padLeft(2, '0')}${b.toInt().toRadixString(16).padLeft(2, '0')}';
}

void _generateOutput(bool autoMode) {
  String esc(String s) => s.replaceAll("'", "\\'").replaceAll('\n', ' ').trim();

  final entries = _newEntries.take(autoMode ? _newEntries.length : 5).toList();
  final buf = StringBuffer();
  buf.writeln('// ══════════════════════════════════════════════════════');
  buf.writeln('//  AUTO-GENERATED SPECIES (Wikipedia import)');
  buf.writeln('//  ${DateTime.now().toIso8601String()}');
  buf.writeln('//  \${_newEntries.length} new species');
  buf.writeln('// ══════════════════════════════════════════════════════');
  buf.writeln();
  for (final e in entries) {
    final regions = (e['regions'] as List).map((r) => esc(r as String)).join("', '");
    final tips = (e['tips'] as List).map((t) => esc(t as String)).join("',\n      '");
    buf.writeln("  FishSpecies(");
    buf.writeln("    name: '${esc(e['name'] as String)}',");
    buf.writeln("    scientificName: '${esc(e['scientificName'] as String)}',");
    buf.writeln("    regions: ['$regions'],");
    buf.writeln("    sizeRange: '${esc(e['sizeRange'] as String)}',");
    buf.writeln("    habitat: '${esc(e['habitat'] as String)}',");
    buf.writeln("    waterType: '${esc(e['waterType'] as String)}',");
    buf.writeln("    diet: '${esc(e['diet'] as String)}',");
    buf.writeln("    commonTackle: '${esc(e['commonTackle'] as String)}',");
    buf.writeln('    color: Color(0xFF${e['color']}),');
    buf.writeln("    description: '${esc(e['description'] as String)}',");
    buf.writeln("    tips: ['$tips'],");
    buf.writeln("  ),");
    buf.writeln();
  }
  if (autoMode) {
    final dbFile = File('lib/data/fish_database.dart');
    var dbContent = dbFile.readAsStringSync();
    final insertIdx = dbContent.lastIndexOf('];');
    if (insertIdx >= 0) {
      dbContent = dbContent.substring(0, insertIdx) + '\n${buf.toString()}' + dbContent.substring(insertIdx);
      dbFile.writeAsStringSync(dbContent);
      print('✅ Appended ${entries.length} species to fish_database.dart');
    }
  } else {
    print(buf.toString());
  }
}

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _regions.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedRegion = _regions[_tabCtrl.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FishSpecies> get _filtered {
    final query = _searchQuery.toLowerCase().trim();
    return fishDatabase.where((f) {
      final regionMatch =
          _selectedRegion == 'All' || f.regions.contains(_selectedRegion);
      if (!regionMatch) return false;
      if (query.isEmpty) return true;
      return f.name.toLowerCase().contains(query) ||
          f.scientificName.toLowerCase().contains(query) ||
          f.regions.any((r) => r.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fish ID'),
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
                    itemBuilder: (context, index) =>
                        _FishCard(fish: results[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Fish Card ────────────────────────────────────────────────────────────

class _FishCard extends StatelessWidget {
  final FishSpecies fish;
  const _FishCard({required this.fish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _FishDetailScreen(fish: fish)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: fish.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.set_meal, color: fish.color, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fish.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
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

class _FishDetailScreen extends StatelessWidget {
  final FishSpecies fish;
  const _FishDetailScreen({required this.fish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(fish.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero header
          Container(
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
          const SizedBox(height: 24),
        ],
      ),
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

// ─── Data Model ───────────────────────────────────────────────────────────

class FishSpecies {
  final String name;
  final String scientificName;
  final List<String> regions;
  final String sizeRange;
  final String habitat;
  final String waterType;
  final String diet;
  final String commonTackle;
  final String description;
  final List<String> tips;
  final Color color;

  const FishSpecies({
    required this.name,
    required this.scientificName,
    required this.regions,
    required this.sizeRange,
    required this.habitat,
    required this.waterType,
    required this.diet,
    required this.commonTackle,
    this.description = '',
    this.tips = const [],
    this.color = Colors.blue,
  });
}
// ═══════════════════════════════════════════════════════════════════════════
//  FISH DATABASE — World Species Reference
// ═══════════════════════════════════════════════════════════════════════════

const fishDatabase = <FishSpecies>[
  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  UNITED STATES                                                       ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Largemouth Bass', scientificName: 'Micropterus salmoides',
    regions: ['USA'], sizeRange: '30–60 cm, up to 10 kg',
    habitat: 'Lakes, ponds, rivers', waterType: 'Freshwater',
    diet: 'Fish, frogs, crayfish', commonTackle: 'Spinnerbaits, crankbaits, plastic worms',
    color: Color(0xFF4CAF50),
    description: 'The most popular game fish in the USA. Known for aggressive strikes and acrobatic leaps when hooked. Prefers warm, vegetated waters with plenty of cover like logs and lily pads.',
    tips: ['Fish near weed lines and submerged structure', 'Early morning and dusk are prime feeding times', 'Use darker lures in stained water, natural colors in clear water'],
  ),
  FishSpecies(
    name: 'Smallmouth Bass', scientificName: 'Micropterus dolomieu',
    regions: ['USA', 'Canada'], sizeRange: '25–50 cm, up to 5 kg',
    habitat: 'Clear lakes, rocky rivers', waterType: 'Freshwater',
    diet: 'Crayfish, small fish, insects', commonTackle: 'Tube jigs, crankbaits, drop-shot rigs',
    color: Color(0xFF8D6E63),
    description: 'Considered the hardest fighting bass species pound-for-pound. Bronzy-green with vertical bars. Prefers cooler, clearer water than largemouth.',
    tips: ['Focus on rocky banks and gravel bottoms', 'Crayfish-colored lures are deadly', 'Smallmouth put up an incredible fight on light tackle'],
  ),
  FishSpecies(
    name: 'Spotted Bass', scientificName: 'Micropterus punctulatus',
    regions: ['USA'], sizeRange: '25–50 cm, up to 4 kg',
    habitat: 'Rivers, reservoirs, streams', waterType: 'Freshwater',
    diet: 'Fish, crayfish, insects', commonTackle: 'Crankbaits, spinnerbaits, soft plastics',
    color: Color(0xFF388E3C),
    description: 'Often mistaken for largemouth but has a smaller mouth and rows of dark spots below the lateral line. Aggressive and adaptable.',
    tips: ['Found mostly in flowing waters and current', 'Fish near bluff banks and points', 'Spotted bass tend to school — catch one, more are near'],
  ),
  FishSpecies(
    name: 'Bluegill', scientificName: 'Lepomis macrochirus',
    regions: ['USA', 'Canada'], sizeRange: '15–25 cm, up to 2 kg',
    habitat: 'Ponds, lakes, slow rivers', waterType: 'Freshwater',
    diet: 'Insects, small crustaceans', commonTackle: 'Worms, small jigs, flies',
    color: Color(0xFF2196F3),
    description: 'A panfish favorite for beginners and experts alike. Colorful body with a distinctive dark gill flap. Excellent for kids to catch and makes for great table fare.',
    tips: ['Fish near docks and overhanging trees in summer', 'Use small hooks with live bait for best results', 'They school — if you catch one, more are nearby'],
  ),
  FishSpecies(
    name: 'Crappie', scientificName: 'Pomoxis spp.',
    regions: ['USA'], sizeRange: '20–35 cm, up to 2 kg',
    habitat: 'Lakes, ponds, slow rivers', waterType: 'Freshwater',
    diet: 'Small fish, insects, crustaceans', commonTackle: 'Small jigs, minnows under a bobber',
    color: Color(0xFF66BB6A),
    description: 'Highly popular panfish known for schooling behavior and delicious white meat. Two main species: Black Crappie and White Crappie.',
    tips: ['Fish around submerged brush piles and docks', 'Use light tackle — crappie have soft mouths', 'Spring spawning season is the best time to catch limits'],
  ),
  FishSpecies(
    name: 'Walleye', scientificName: 'Sander vitreus',
    regions: ['USA', 'Canada'], sizeRange: '30–60 cm, up to 8 kg',
    habitat: 'Lakes, rivers, reservoirs', waterType: 'Freshwater',
    diet: 'Small fish, insects', commonTackle: 'Jigs, crankbaits, live minnows, spinner rigs',
    color: Color(0xFF9E9E9E),
    description: 'A prized game fish with excellent eyesight adapted for low light. Named for their opaque, glassy eyes. One of the best-tasting freshwater fish.',
    tips: ['Fish at dawn, dusk, or after dark — their eyes are light-sensitive', 'Troll with bottom-bouncing rigs in deeper lakes', 'Jig with a minnow-tipped jig head near rocky bottoms'],
  ),
  FishSpecies(
    name: 'Sauger', scientificName: 'Sander canadensis',
    regions: ['USA', 'Canada'], sizeRange: '25–45 cm, up to 3 kg',
    habitat: 'Large rivers, reservoirs', waterType: 'Freshwater',
    diet: 'Small fish, insects', commonTackle: 'Jigs, spinners, live minnows',
    color: Color(0xFF78909C),
    description: 'A smaller cousin of the walleye with a more slender body. Distinguished by dark saddle marks on the dorsal fin. Prefers large, turbid rivers.',
    tips: ['Found in big river systems with current', 'Use brighter jigs than you would for walleye', 'Good eating — very similar to walleye'],
  ),
  FishSpecies(
    name: 'Yellow Perch', scientificName: 'Perca flavescens',
    regions: ['USA', 'Canada'], sizeRange: '15–30 cm, up to 2 kg',
    habitat: 'Lakes, ponds, slow rivers', waterType: 'Freshwater',
    diet: 'Small fish, insects, crustaceans', commonTackle: 'Small jigs, worms, minnows',
    color: Color(0xFFFFA000),
    description: 'A popular panfish with golden-yellow body and dark vertical bars. Excellent table fare. Schooling fish found throughout North America.',
    tips: ['Fish in deeper water during summer heat', 'Use small jigs tipped with a minnow', 'Yellow perch are excellent eating — great for fish fries'],
  ),
  FishSpecies(
    name: 'Channel Catfish', scientificName: 'Ictalurus punctatus',
    regions: ['USA', 'Canada'], sizeRange: '30–70 cm, up to 15 kg',
    habitat: 'Rivers, lakes, reservoirs', waterType: 'Freshwater',
    diet: 'Fish, insects, crustaceans, plant matter', commonTackle: 'Chicken liver, stinkbaits, cut bait',
    color: Color(0xFF607D8B),
    description: 'The most common catfish species in North America. Named for their forked tail. Nocturnal bottom-feeders with excellent sense of smell.',
    tips: ['Fish at night for best results', 'Use smelly baits — catfish rely on scent', 'Fish deep channels and holes in rivers'],
  ),
  FishSpecies(
    name: 'Blue Catfish', scientificName: 'Ictalurus furcatus',
    regions: ['USA'], sizeRange: '50–120 cm, up to 50 kg',
    habitat: 'Large rivers, reservoirs', waterType: 'Freshwater',
    diet: 'Fish, mussels, crustaceans', commonTackle: 'Cut bait, live bait, trotlines',
    color: Color(0xFF1565C0),
    description: 'The largest North American catfish species. Bluish-gray body with a distinctly forked tail. Can grow to over 100 pounds in large rivers.',
    tips: ['Fish deep main river channels', 'Use fresh cut bait — shad is excellent', 'Blue cats are powerful fighters — use heavy gear'],
  ),
  FishSpecies(
    name: 'Flathead Catfish', scientificName: 'Pylodictis olivaris',
    regions: ['USA'], sizeRange: '40–100 cm, up to 40 kg',
    habitat: 'Rivers, large streams', waterType: 'Freshwater',
    diet: 'Live fish only', commonTackle: 'Live bait, large hooks, heavy gear',
    color: Color(0xFF8D6E63),
    description: 'A large predatory catfish with a flattened head and yellow-brown body. Unlike other catfish, flatheads prefer live prey and are ambush predators.',
    tips: ['Fish near deep holes and log jams', 'Use live sunfish or goldfish as bait', 'Night fishing is most productive'],
  ),
  FishSpecies(
    name: 'Striped Bass', scientificName: 'Morone saxatilis',
    regions: ['USA'], sizeRange: '40–100 cm, up to 30 kg',
    habitat: 'Coastal waters, rivers, lakes', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Poppers, swimbaits, live eels, heavy spinning gear',
    color: Color(0xFF1565C0),
    description: 'A powerful migratory fish with distinctive horizontal stripes. Anadromous — lives in saltwater but spawns in freshwater. Known for surface blitzes.',
    tips: ['Look for birds diving — they signal baitfish schools', 'Use surfcasting gear from beaches and jetties', 'Live eels are the ultimate bait for trophy stripers'],
  ),
  FishSpecies(
    name: 'White Bass', scientificName: 'Morone chrysops',
    regions: ['USA'], sizeRange: '20–35 cm, up to 3 kg',
    habitat: 'Lakes, rivers, reservoirs', waterType: 'Freshwater',
    diet: 'Small fish, insects', commonTackle: 'Small spinners, jigs, live minnows',
    color: Color(0xFFB0BEC5),
    description: 'A silvery-white schooling fish with faint horizontal stripes. Known for aggressive spring spawning runs up rivers. Excellent fighter on light tackle.',
    tips: ['Spring spawning runs up rivers are prime time', 'Use small shiny lures that imitate shad', 'They school — find one and you will find many'],
  ),
  FishSpecies(
    name: 'Hybrid Striped Bass (Wiper)', scientificName: 'Morone saxatilis × chrysops',
    regions: ['USA'], sizeRange: '35–60 cm, up to 7 kg',
    habitat: 'Lakes, reservoirs', waterType: 'Freshwater',
    diet: 'Fish', commonTackle: 'Swimbaits, jigs, live bait',
    color: Color(0xFF1976D2),
    description: 'A hybrid cross between striped bass and white bass. Combines the size potential of stripers with the hard fight of white bass. Stocked in many reservoirs.',
    tips: ['Look for schools chasing bait on the surface', 'Use lures that imitate shad or alewives', 'Wipers are powerful fighters — they make long runs'],
  ),
  FishSpecies(
    name: 'Muskellunge (Muskie)', scientificName: 'Esox masquinongy',
    regions: ['USA', 'Canada'], sizeRange: '70–130 cm, up to 30 kg',
    habitat: 'Weedy lakes, slow rivers', waterType: 'Freshwater',
    diet: 'Fish, ducks, muskrats', commonTackle: 'Large bucktail spinners, topwater lures, heavy baitcaster',
    color: Color(0xFF33691E),
    description: 'The "fish of 10,000 casts." North America\'s largest pike species. Apex predator known for massive size, elusive nature, and explosive strikes.',
    tips: ['Use a steel leader — they have razor teeth', 'Fish early morning or late evening near weed beds', 'Figure-8 at the boat — many follows happen at boat side'],
  ),
  FishSpecies(
    name: 'Northern Pike', scientificName: 'Esox lucius',
    regions: ['USA', 'Canada', 'Europe'], sizeRange: '50–120 cm, up to 25 kg',
    habitat: 'Weedy lakes, slow rivers', waterType: 'Freshwater',
    diet: 'Fish, frogs, small mammals', commonTackle: 'Spoons, spinnerbaits, jerkbaits with wire leader',
    color: Color(0xFF8BC34A),
    description: 'A fearsome predator with razor-sharp teeth. Known for explosive strikes and powerful runs. Especially abundant in northern waters.',
    tips: ['Fish near weed beds and drop-offs', 'Use steel or titanium leaders to avoid cut lines', 'Figure-8 at the boat — pike often follow lures'],
  ),
  FishSpecies(
    name: 'Chain Pickerel', scientificName: 'Esox niger',
    regions: ['USA'], sizeRange: '30–60 cm, up to 3 kg',
    habitat: 'Weedy ponds, slow streams', waterType: 'Freshwater',
    diet: 'Small fish, frogs', commonTackle: 'Small spoons, spinners, soft plastics',
    color: Color(0xFF558B2F),
    description: 'A smaller member of the pike family with a distinctive chain-like pattern on its sides. Common in eastern US waters. Aggressive for its size.',
    tips: ['Fish near lily pads and weed edges', 'Use a short wire leader — they have sharp teeth', 'They strike hard — set the hook immediately'],
  ),
  FishSpecies(
    name: 'Rainbow Trout', scientificName: 'Oncorhynchus mykiss',
    regions: ['USA', 'Canada', 'Europe', 'Australia'], sizeRange: '25–50 cm, up to 10 kg',
    habitat: 'Cold rivers, lakes, streams', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Spoons, spinners, flies, powerbait',
    color: Color(0xFFFF5722),
    description: 'Beautifully colored trout with a pink/red lateral stripe. Popular for fly fishing and stock programs worldwide. Steelhead is the migratory form.',
    tips: ['Fish early morning or late evening in summer', 'Match the hatch — use flies that resemble local insects', 'In streams, cast upstream and let bait drift naturally'],
  ),
  FishSpecies(
    name: 'Brook Trout', scientificName: 'Salvelinus fontinalis',
    regions: ['USA', 'Canada'], sizeRange: '20–40 cm, up to 5 kg',
    habitat: 'Cold streams, small lakes, ponds', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Small spinners, flies, worms',
    color: Color(0xFFFF6F00),
    description: 'One of the most beautiful freshwater fish. Olive back with red spots, blue halos, and white-edged fins. Requires clean, cold water.',
    tips: ['Fish in small, pristine streams with light tackle', 'Use dry flies in summer, nymphs in spring', 'Brook trout are sensitive to warm water — fish early'],
  ),
  FishSpecies(
    name: 'Brown Trout', scientificName: 'Salmo trutta',
    regions: ['USA', 'Canada', 'Europe', 'Australia'], sizeRange: '25–60 cm, up to 15 kg',
    habitat: 'Rivers, streams, lakes', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Flies, spinners, small crankbaits, worms',
    color: Color(0xFFA0522D),
    description: 'A classic game fish introduced from Europe. Golden-brown with dark spots and red dots. Wary and challenging — the ultimate fly fishing target.',
    tips: ['Approach quietly — brown trout are easily spooked', 'Match the hatch with dry flies in summer', 'Larger browns are nocturnal — fish after dark with streamers'],
  ),
  FishSpecies(
    name: 'Cutthroat Trout', scientificName: 'Oncorhynchus clarkii',
    regions: ['USA', 'Canada'], sizeRange: '20–50 cm, up to 5 kg',
    habitat: 'Cold streams, alpine lakes', waterType: 'Freshwater',
    diet: 'Insects, crustaceans', commonTackle: 'Flies, small spinners, worms',
    color: Color(0xFFE65100),
    description: 'Named for the distinctive red slash under the jaw. Native to the western US and Canada. Many subspecies adapted to different watersheds.',
    tips: ['Native to western mountain streams and lakes', 'Use dry flies in summer — they are eager surface feeders', 'Coastal cutthroat also enter saltwater estuaries'],
  ),
  FishSpecies(
    name: 'Lake Trout', scientificName: 'Salvelinus namaycush',
    regions: ['USA', 'Canada'], sizeRange: '40–80 cm, up to 30 kg',
    habitat: 'Deep, cold lakes', waterType: 'Freshwater',
    diet: 'Small fish, crustaceans', commonTackle: 'Spoons, downriggers, lead core line, live bait',
    color: Color(0xFF37474F),
    description: 'The largest trout species in North America. Lives in deep, cold lakes. Grayish body with light spots. Requires specialized deep-water techniques.',
    tips: ['Troll with downriggers in 15-30m of water during summer', 'Spring and fall — fish shallower near shore', 'Use flashers or dodgers to attract strikes'],
  ),
  FishSpecies(
    name: 'Redfish (Red Drum)', scientificName: 'Sciaenops ocellatus',
    regions: ['USA'], sizeRange: '40–90 cm, up to 20 kg',
    habitat: 'Coastal waters, estuaries, bays', waterType: 'Saltwater',
    diet: 'Crab, shrimp, small fish', commonTackle: 'Soft plastics, spoons, live shrimp on popping cork',
    color: Color(0xFFE53935),
    description: 'A hard-fighting inshore species named for its bronze-red color and distinctive black spot near the tail. Popular along Atlantic and Gulf coasts.',
    tips: ['Look for tailing fish in shallow flats', 'Use gold spoons or paddle-tail soft plastics', 'Incoming tides push redfish into marsh creeks'],
  ),
  FishSpecies(
    name: 'Spotted Seatrout (Speckled Trout)', scientificName: 'Cynoscion nebulosus',
    regions: ['USA'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'Estuaries, bays, coastal waters', waterType: 'Saltwater',
    diet: 'Shrimp, small fish', commonTackle: 'Soft plastics, live shrimp, topwater lures',
    color: Color(0xFF607D8B),
    description: 'A premier inshore game fish along the Gulf and Atlantic coasts. Silvery with distinctive black spots on the back and tail. Excellent table fare.',
    tips: ['Fish grassy flats and oyster bars', 'Use popping corks with live shrimp', 'Early morning topwater action can be explosive'],
  ),
  FishSpecies(
    name: 'Flounder (Southern Flounder)', scientificName: 'Paralichthys lethostigma',
    regions: ['USA'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'Estuaries, bays, coastal waters', waterType: 'Saltwater',
    diet: 'Small fish, shrimp, crabs', commonTackle: 'Soft plastics on jig heads, live minnows',
    color: Color(0xFF795548),
    description: 'A flatfish with both eyes on one side. Lies on the bottom and ambushes prey. Prized for its delicate white meat. Found along Atlantic and Gulf coasts.',
    tips: ['Drag jigs slowly along sandy or muddy bottoms', 'Fish near inlets and channels', 'Flounder migrate — fall is prime time'],
  ),
  FishSpecies(
    name: 'Tarpon', scientificName: 'Megalops atlanticus',
    regions: ['USA', 'South America'], sizeRange: '100–200 cm, up to 120 kg',
    habitat: 'Coastal waters, estuaries, rivers', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, crustaceans', commonTackle: 'Live bait, crabs, large flies, heavy spinning gear',
    color: Color(0xFF0288D1),
    description: 'The "silver king" — one of the most iconic sport fish. Known for spectacular aerial displays with multiple jumps. Can breathe air at the surface.',
    tips: ['Fish near passes and bridges during migration', 'Use circle hooks for safer catch and release', 'Tarpon are protected — use proper handling techniques'],
  ),
  FishSpecies(
    name: 'Snook', scientificName: 'Centropomus undecimalis',
    regions: ['USA'], sizeRange: '40–90 cm, up to 15 kg',
    habitat: 'Estuaries, mangroves, beaches', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, shrimp, crabs', commonTackle: 'Live bait, soft plastics, topwater plugs',
    color: Color(0xFFF9A825),
    description: 'A prized inshore game fish of Florida and the Gulf. Silvery with a distinctive black lateral line. Known for powerful runs around structure.',
    tips: ['Fish around mangrove shorelines and dock pilings', 'Use live pilchards or shrimp', 'Snook season is strictly regulated — know the rules'],
  ),
  FishSpecies(
    name: 'Bonefish', scientificName: 'Albula vulpes',
    regions: ['USA'], sizeRange: '40–75 cm, up to 5 kg',
    habitat: 'Shallow flats, tropical waters', waterType: 'Saltwater',
    diet: 'Crabs, shrimp, worms', commonTackle: 'Flies, small jigs, live shrimp',
    color: Color(0xFFCFD8DC),
    description: 'The "grey ghost of the flats." One of the fastest fish on the flats. Extremely wary with incredible speed — makes long, powerful runs.',
    tips: ['Fish shallow flats at high tide', 'Use polarized sunglasses to spot tailing fish', 'Bonefish are catch and release — handle with care'],
  ),
  FishSpecies(
    name: 'Permit', scientificName: 'Trachinotus falcatus',
    regions: ['USA'], sizeRange: '50–100 cm, up to 20 kg',
    habitat: 'Shallow flats, reefs, wrecks', waterType: 'Saltwater',
    diet: 'Crabs, shrimp, mollusks', commonTackle: 'Crab flies, live crabs, jigs',
    color: Color(0xFF5C6BC0),
    description: 'Considered the ultimate flats challenge. Tall, silver body with a forked tail. Incredible power and wariness make them a trophy for any angler.',
    tips: ['Use live crabs for best results', 'Permit have soft mouths — set the hook gently', 'Fish the flats during spawning season (spring-summer)'],
  ),
  FishSpecies(
    name: 'Cobia', scientificName: 'Rachycentron canadum',
    regions: ['USA'], sizeRange: '60–130 cm, up to 40 kg',
    habitat: 'Coastal waters, wrecks, buoys', waterType: 'Saltwater',
    diet: 'Fish, crabs, squid', commonTackle: 'Live bait, jigs, bucktails',
    color: Color(0xFF4E342E),
    description: 'A dark brown torpedo-shaped fish with a single row of dorsal finlets. Often follows sharks and rays. Excellent table fare.',
    tips: ['Look for cobia around buoys and floating debris', 'Use live eels or crabs for best results', 'They often swim near the surface — sight fishing is common'],
  ),
  FishSpecies(
    name: 'King Mackerel (Kingfish)', scientificName: 'Scomberomorus cavalla',
    regions: ['USA'], sizeRange: '60–120 cm, up to 20 kg',
    habitat: 'Coastal waters, reefs', waterType: 'Saltwater',
    diet: 'Fish, squid', commonTackle: 'Trolling lures, live bait, wire leader',
    color: Color(0xFF0277BD),
    description: 'A fast, powerful pelagic fish with a streamlined body and sharp teeth. Known for blistering runs and is a top target for offshore trollers.',
    tips: ['Use wire leader — their teeth cut regular line', 'Troll with spoons or live bait near reefs', 'Kingfish are excellent smoked or grilled'],
  ),
  FishSpecies(
    name: 'Spanish Mackerel', scientificName: 'Scomberomorus maculatus',
    regions: ['USA'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'Coastal waters, bays', waterType: 'Saltwater',
    diet: 'Small fish, shrimp', commonTackle: 'Small spoons, jigs, live bait',
    color: Color(0xFF4FC3F7),
    description: 'A smaller mackerel with yellow spots and sharp teeth. Schooling fish that provides fast action on light tackle. Excellent table fare.',
    tips: ['Look for diving birds feeding on baitfish', 'Use small shiny lures with fast retrieve', 'Spanish mackerel are great grilled or smoked'],
  ),
  FishSpecies(
    name: 'Mahi Mahi (Dorado)', scientificName: 'Coryphaena hippurus',
    regions: ['USA', 'Asia/Pacific', 'Australia'], sizeRange: '60–120 cm, up to 20 kg',
    habitat: 'Offshore waters, floating debris', waterType: 'Saltwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Trolling lures, live bait, fly',
    color: Color(0xFFFFD600),
    description: 'One of the most colorful fish in the sea — brilliant blue, green, and gold. Found around floating debris and weed lines. Acrobatic fighters.',
    tips: ['Look for floating logs, pallets, or weed lines', 'Use brightly colored trolling lures', 'Mahi mahi change color rapidly when caught — amazing to watch'],
  ),
  FishSpecies(
    name: 'Bluefin Tuna', scientificName: 'Thunnus thynnus',
    regions: ['USA', 'Europe'], sizeRange: '100–300 cm, up to 450 kg',
    habitat: 'Open ocean', waterType: 'Saltwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Heavy trolling gear, stand-up rods, live bait',
    color: Color(0xFF0D47A1),
    description: 'The king of tuna. A massive, powerful pelagic fish that can weigh over 1,000 pounds. Prized for sushi. One of the most challenging sport fish.',
    tips: ['Use heavy tackle — these fish are incredibly powerful', 'Troll with large lures or live bait', 'Bluefin command premium prices — tag and release recommended'],
  ),
  FishSpecies(
    name: 'Yellowfin Tuna', scientificName: 'Thunnus albacares',
    regions: ['USA', 'Asia/Pacific', 'Australia'], sizeRange: '60–180 cm, up to 100 kg',
    habitat: 'Open ocean', waterType: 'Saltwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Trolling lures, poppers, live bait',
    color: Color(0xFFFFD600),
    description: 'A fast, powerful tuna with bright yellow fins and a metallic blue back. Known for blistering runs and excellent table quality.',
    tips: ['Look for breaking fish and diving birds', 'Use chunk bait to chum them to the boat', 'Yellowfin are premier sushi-grade fish'],
  ),
  FishSpecies(
    name: 'Sailfish', scientificName: 'Istiophorus platypterus',
    regions: ['USA', 'Asia/Pacific', 'Africa'], sizeRange: '150–250 cm, up to 60 kg',
    habitat: 'Offshore tropical and subtropical waters', waterType: 'Saltwater',
    diet: 'Fish, squid', commonTackle: 'Trolling lures, live bait, fly',
    color: Color(0xFF1565C0),
    description: 'The fastest fish in the ocean with a massive dorsal sail. Known for spectacular jumps and tail-walking. A bucket-list species for offshore anglers.',
    tips: ['Troll with ballyhoo or artificial lures', 'Kite fishing is very effective', 'Practice catch and release — sailfish are a valuable resource'],
  ),
  FishSpecies(
    name: 'Blue Marlin', scientificName: 'Makaira nigricans',
    regions: ['USA', 'Asia/Pacific', 'Africa'], sizeRange: '200–400 cm, up to 500 kg',
    habitat: 'Open ocean', waterType: 'Saltwater',
    diet: 'Fish, squid', commonTackle: 'Heavy trolling gear, live bait',
    color: Color(0xFF0D47A1),
    description: 'The ultimate trophy fish. A massive, cobalt-blue billfish that can weigh over 1,000 pounds. Known for incredible fights lasting hours.',
    tips: ['Use heavy trolling tackle with large lures', 'Blue marlin are often found near temperature breaks', 'Tag and release is critical for conservation'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  CANADA                                                              ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Arctic Char', scientificName: 'Salvelinus alpinus',
    regions: ['Canada'], sizeRange: '30–70 cm, up to 10 kg',
    habitat: 'Arctic waters, deep cold lakes', waterType: 'Freshwater / Saltwater',
    diet: 'Small fish, zooplankton, insects', commonTackle: 'Spoons, small jigs, flies',
    color: Color(0xFFFF4081),
    description: 'The most northerly freshwater fish. Related to trout and salmon. Stunning red-orange belly during spawning season.',
    tips: ['Best fished from July to September in northern rivers', 'Brightly colored lures work well in clear Arctic water', 'Fly fishing with streamers is productive'],
  ),
  FishSpecies(
    name: 'Sturgeon (Lake Sturgeon)', scientificName: 'Acipenser fulvescens',
    regions: ['Canada', 'USA'], sizeRange: '100–200 cm, up to 100 kg',
    habitat: 'Large lakes and rivers', waterType: 'Freshwater',
    diet: 'Bottom invertebrates, small fish', commonTackle: 'Heavy rod, large hooks, cut bait, worms',
    color: Color(0xFF5D4037),
    description: 'A living fossil — virtually unchanged for 200 million years. Canada\'s largest freshwater fish. Protected in many areas; catch and release only.',
    tips: ['Fish deep holes in large rivers like the Fraser', 'Use heavy tackle — sturgeon are incredibly strong', 'Check local regulations — many areas have strict rules'],
  ),
  FishSpecies(
    name: 'Arctic Grayling', scientificName: 'Thymallus arcticus',
    regions: ['Canada', 'USA'], sizeRange: '20–40 cm, up to 2 kg',
    habitat: 'Cold northern rivers and lakes', waterType: 'Freshwater',
    diet: 'Insects, crustaceans', commonTackle: 'Small spinners, dry flies, nymphs',
    color: Color(0xFF26A69A),
    description: 'A beautiful northern fish with a large, sail-like dorsal fin marked with iridescent spots. Thrives in clean, cold waters.',
    tips: ['Found in clear northern rivers and lakes', 'Use small dark-colored flies or spinners', 'Grayling rise eagerly to dry flies in summer'],
  ),
  FishSpecies(
    name: 'Burbot (Eelpout)', scientificName: 'Lota lota',
    regions: ['Canada', 'USA', 'Europe'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'Deep, cold lakes and rivers', waterType: 'Freshwater',
    diet: 'Small fish, insects', commonTackle: 'Jigs, live bait, set lines',
    color: Color(0xFF546E7A),
    description: 'The only freshwater cod species. A cold-water predator with a long, eel-like body and a single chin barbel. Active under ice in winter.',
    tips: ['Fish through the ice in winter', 'Burbot are nocturnal — fish at night', 'Known as "poor man\'s lobster" — excellent eating'],
  ),
  FishSpecies(
    name: 'Lake Whitefish', scientificName: 'Coregonus clupeaformis',
    regions: ['Canada', 'USA'], sizeRange: '30–50 cm, up to 5 kg',
    habitat: 'Deep, cold lakes', waterType: 'Freshwater',
    diet: 'Zooplankton, insect larvae', commonTackle: 'Small jigs, flies, set lines',
    color: Color(0xFFB2DFDB),
    description: 'A silvery-white fish important to both commercial and recreational fisheries. Schooling fish found in deep, cold lakes across Canada.',
    tips: ['Fish in deep water during summer (20-40m)', 'Use small jigs tipped with a minnow', 'Whitefish roe is prized for caviar'],
  ),
  FishSpecies(
    name: 'Chinook Salmon (King)', scientificName: 'Oncorhynchus tshawytscha',
    regions: ['Canada', 'USA', 'Asia/Pacific'], sizeRange: '60–120 cm, up to 40 kg',
    habitat: 'Pacific Ocean, rivers', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Spoons, flashers, roe, plugs',
    color: Color(0xFFC62828),
    description: 'The largest Pacific salmon species. Deep red flesh prized for eating. Known for powerful runs and impressive size during spawning runs.',
    tips: ['Fish river mouths during spawning runs', 'Use downriggers for trolling in lakes', 'Chinook are the most prized salmon for table fare'],
  ),
  FishSpecies(
    name: 'Coho Salmon (Silver)', scientificName: 'Oncorhynchus kisutch',
    regions: ['Canada', 'USA', 'Asia/Pacific'], sizeRange: '40–70 cm, up to 8 kg',
    habitat: 'Pacific Ocean, rivers', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Spoons, spinners, flies, plugs',
    color: Color(0xFFE53935),
    description: 'A medium-sized Pacific salmon known for acrobatic leaps. Silver body with a dark back. Highly prized by sport anglers for their fighting ability.',
    tips: ['Coho are aggressive — they hit lures readily', 'Use brightly colored lures in rivers', 'They are excellent jumpers — be ready for aerial displays'],
  ),
  FishSpecies(
    name: 'Pink Salmon (Humpback)', scientificName: 'Oncorhynchus gorbuscha',
    regions: ['Canada', 'USA', 'Asia/Pacific'], sizeRange: '30–60 cm, up to 3 kg',
    habitat: 'Pacific Ocean, rivers', waterType: 'Saltwater / Freshwater',
    diet: 'Small fish, crustaceans', commonTackle: 'Small spinners, spoons, flies',
    color: Color(0xFFF48FB1),
    description: 'The smallest and most abundant Pacific salmon. Develops a distinctive hump on the back during spawning. Mild flavor.',
    tips: ['Pink salmon run in odd-numbered years in many areas', 'Use small pink or chartreuse lures', 'They are the easiest salmon to catch — great for beginners'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  EUROPE                                                              ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'European Perch', scientificName: 'Perca fluviatilis',
    regions: ['Europe'], sizeRange: '15–40 cm, up to 4 kg',
    habitat: 'Lakes, ponds, slow rivers', waterType: 'Freshwater',
    diet: 'Small fish, insects, crustaceans', commonTackle: 'Small spinners, worms, jigheads',
    color: Color(0xFFFF9800),
    description: 'A common European game fish with distinctive dark vertical stripes on a greenish body. Schooling fish that provides excellent sport on light tackle.',
    tips: ['Look for perch near underwater structures and weed edges', 'Use small lures — perch have small mouths', 'They school by size — keep fishing once you catch one'],
  ),
  FishSpecies(
    name: 'Common Carp', scientificName: 'Cyprinus carpio',
    regions: ['Europe', 'Asia/Pacific', 'USA', 'Canada'], sizeRange: '30–80 cm, up to 40 kg',
    habitat: 'Lakes, rivers, ponds', waterType: 'Freshwater',
    diet: 'Plant matter, insects, crustaceans', commonTackle: 'Boilies, corn, dough balls, hair rigs',
    color: Color(0xFF9E9E9E),
    description: 'One of the hardest fighting freshwater fish. Gold or bronze colored with large scales. Highly prized by specimen anglers across Europe.',
    tips: ['Use hair rigs with boilies for specimen carp', 'Carp are wary — use light line and subtle presentation', 'Fish during warm months when carp are most active'],
  ),
  FishSpecies(
    name: 'Zander', scientificName: 'Sander lucioperca',
    regions: ['Europe'], sizeRange: '30–70 cm, up to 15 kg',
    habitat: 'Lakes, rivers, canals', waterType: 'Freshwater',
    diet: 'Small fish', commonTackle: 'Jigs, hard lures, dead bait, drop-shot rigs',
    color: Color(0xFF78909C),
    description: 'Europe\'s premier predatory game fish. Related to walleye with similar eyesight adaptations. Highly prized for both sport and table quality.',
    tips: ['Fish at dawn, dusk, and nighttime', 'Use dark-colored soft plastics on jig heads', 'Drop-shot rigging is very effective for finicky zander'],
  ),
  FishSpecies(
    name: 'Wels Catfish', scientificName: 'Silurus glanis',
    regions: ['Europe'], sizeRange: '100–250 cm, up to 100 kg',
    habitat: 'Large rivers, lakes', waterType: 'Freshwater',
    diet: 'Fish, frogs, water birds', commonTackle: 'Large live bait, dead bait, heavy gear',
    color: Color(0xFF263238),
    description: 'Europe\'s largest freshwater fish. A massive, dark-colored catfish that can reach over 2 meters. Ambush predator with legendary strength.',
    tips: ['Fish deep holes at night', 'Use large live bait like bream or roach', 'Wels catfish are most active in warm summer months'],
  ),
  FishSpecies(
    name: 'Tench', scientificName: 'Tinca tinca',
    regions: ['Europe'], sizeRange: '20–40 cm, up to 5 kg',
    habitat: 'Weedy lakes, slow rivers', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, plant matter', commonTackle: 'Worms, bread, sweetcorn, swimfeeders',
    color: Color(0xFF558B2F),
    description: 'A stout, olive-green fish with small scales and red eyes. Known as the "doctor fish" in folklore. A popular coarse angling target in Europe.',
    tips: ['Fish on the bottom in weedy areas', 'Use sweetcorn or worm baits', 'Tench are most active in warm weather'],
  ),
  FishSpecies(
    name: 'Roach', scientificName: 'Rutilus rutilus',
    regions: ['Europe'], sizeRange: '15–30 cm, up to 2 kg',
    habitat: 'Lakes, rivers, canals', waterType: 'Freshwater',
    diet: 'Insects, plant matter, crustaceans', commonTackle: 'Float fishing with maggots, bread, sweetcorn',
    color: Color(0xFFE53935),
    description: 'One of the most common coarse fish in Europe. Silver body with red fins. Popular with match anglers and a great fish for beginners.',
    tips: ['Use a simple float rig with maggots', 'Roach feed in all seasons', 'Fish near features like reeds and overhanging trees'],
  ),
  FishSpecies(
    name: 'European Bream (Common Bream)', scientificName: 'Abramis brama',
    regions: ['Europe'], sizeRange: '25–50 cm, up to 5 kg',
    habitat: 'Lakes, slow rivers, canals', waterType: 'Freshwater',
    diet: 'Insect larvae, worms, mollusks', commonTackle: 'Feeder rods, groundbait, maggots, worms',
    color: Color(0xFFA1887F),
    description: 'A deep-bodied, silvery fish with a bronze tint. Schooling fish that feeds in groups. A staple of European coarse fishing.',
    tips: ['Use groundbait to attract a shoal', 'Fish on the bottom with a feeder rig', 'Bream feed hardest in summer evenings'],
  ),
  FishSpecies(
    name: 'Chub', scientificName: 'Squalius cephalus',
    regions: ['Europe'], sizeRange: '25–50 cm, up to 5 kg',
    habitat: 'Rivers, streams', waterType: 'Freshwater',
    diet: 'Insects, fruit, small fish, crustaceans', commonTackle: 'Float fishing, spinners, bread, cheese',
    color: Color(0xFF8D6E63),
    description: 'A thick-bodied river fish with a large mouth. An opportunistic feeder known for taking a wide variety of baits, including cheese and fruit.',
    tips: ['Chub feed throughout the day', 'Float a piece of bread crust downstream', 'They are wary — use fine line and careful presentation'],
  ),
  FishSpecies(
    name: 'Barbel', scientificName: 'Barbus barbus',
    regions: ['Europe'], sizeRange: '30–80 cm, up to 7 kg',
    habitat: 'Fast-flowing rivers', waterType: 'Freshwater',
    diet: 'Bottom invertebrates, small fish', commonTackle: 'Feeder rigs, heavy line, maggots, worms',
    color: Color(0xFF8D6E63),
    description: 'A powerful river fish with a streamlined body and four barbels around the mouth. Known for incredible fights in fast current.',
    tips: ['Fish on the bottom in fast-flowing gravel runs', 'Use heavy leads to hold bottom in current', 'Barbel are nocturnal feeders — night sessions can be productive'],
  ),
  FishSpecies(
    name: 'Grayling (European)', scientificName: 'Thymallus thymallus',
    regions: ['Europe'], sizeRange: '20–40 cm, up to 2 kg',
    habitat: 'Clean, fast-flowing rivers', waterType: 'Freshwater',
    diet: 'Insects, crustaceans', commonTackle: 'Flies, small spinners',
    color: Color(0xFF26A69A),
    description: 'Known as the "lady of the stream." Beautiful fish with a large, iridescent dorsal fin. Thrives in pristine, well-oxygenated rivers.',
    tips: ['Use small nymphs and dry flies', 'Grayling can be caught year-round', 'They rise to a dry fly in winter when trout are inactive'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  ASIA / PACIFIC                                                      ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Asian Seabass (Barramundi)', scientificName: 'Lates calcarifer',
    regions: ['Asia/Pacific', 'Australia'], sizeRange: '50–120 cm, up to 60 kg',
    habitat: 'Rivers, estuaries, coastal waters', waterType: 'Saltwater / Freshwater',
    diet: 'Fish, crustaceans', commonTackle: 'Soft plastics, hard-bodied lures, live bait',
    color: Color(0xFF00BCD4),
    description: 'A highly prized sport fish across Asia and Australia. Silver bodied with a distinctive concave head. Catadromous — lives in fresh water, spawns in salt.',
    tips: ['Fish around structure like mangroves and rock bars', 'Barramundi are ambush predators — work lures slowly', 'Catch and release is encouraged for larger specimens'],
  ),
  FishSpecies(
    name: 'Japanese Amberjack (Hamachi)', scientificName: 'Seriola quinqueradiata',
    regions: ['Asia/Pacific'], sizeRange: '40–100 cm, up to 10 kg',
    habitat: 'Coastal waters, offshore reefs', waterType: 'Saltwater',
    diet: 'Fish, squid, crustaceans', commonTackle: 'Popping lures, jigs, live bait',
    color: Color(0xFFFFD600),
    description: 'Popular in Japanese cuisine as hamachi/sushi grade. Known for blistering runs and dogged fights.',
    tips: ['Use poppers and stickbaits for topwater action', 'Fish near reefs and drop-offs during summer', 'Heavy tackle recommended — they are powerful fighters'],
  ),
  FishSpecies(
    name: 'Giant Trevally (GT)', scientificName: 'Caranx ignobilis',
    regions: ['Asia/Pacific', 'Australia'], sizeRange: '60–150 cm, up to 80 kg',
    habitat: 'Reefs, atolls, coastal waters', waterType: 'Saltwater',
    diet: 'Fish, crustaceans, squid', commonTackle: 'Poppers, stickbaits, heavy jigs, 80lb+ braid',
    color: Color(0xFF1B5E20),
    description: 'The ultimate saltwater hardcore fish. Bronze-backed giant that crushes surface poppers. Known for explosive strikes and unstoppable power.',
    tips: ['Cast poppers into breaking surf and reef washes', 'Use 80-130lb braid with 100-150lb leader', 'Strike hard and fast — GTs hit and turn immediately'],
  ),
  FishSpecies(
    name: 'Snakehead', scientificName: 'Channa spp.',
    regions: ['Asia/Pacific'], sizeRange: '30–80 cm, up to 10 kg',
    habitat: 'Swamps, canals, ponds, rivers', waterType: 'Freshwater',
    diet: 'Fish, frogs, insects', commonTackle: 'Frogs, spinnerbaits, topwater lures',
    color: Color(0xFF4E342E),
    description: 'An aggressive air-breathing predator native to Asia. Can survive out of water for days. Known for powerful strikes and weed-bed ambushes.',
    tips: ['Topwater frog lures are deadly in lily pads', 'Fish shallow, vegetated areas', 'They guard their young — if you see fry, adults are nearby'],
  ),
  FishSpecies(
    name: 'Mahseer', scientificName: 'Tor spp.',
    regions: ['Asia/Pacific'], sizeRange: '50–150 cm, up to 50 kg',
    habitat: 'Fast-flowing rivers, foothill streams', waterType: 'Freshwater',
    diet: 'Fruit, insects, crustaceans, small fish', commonTackle: 'Large spoons, spinners, fruit baits',
    color: Color(0xFFD4A017),
    description: 'A legendary game fish of South and Southeast Asia. Large-scaled with a golden-bronze body. Known as the "tiger of the Himalayas."',
    tips: ['Use fruit baits like mahua oil cake', 'Fish in fast-flowing river stretches', 'Mahseer are powerful fighters — use heavy tackle'],
  ),
  FishSpecies(
    name: 'Milkfish', scientificName: 'Chanos chanos',
    regions: ['Asia/Pacific'], sizeRange: '60–120 cm, up to 15 kg',
    habitat: 'Coastal waters, estuaries', waterType: 'Saltwater / Freshwater',
    diet: 'Algae, plankton, small invertebrates', commonTackle: 'Bread bait, small hooks, light spinning gear',
    color: Color(0xFF80DEEA),
    description: 'A silvery, streamlined fish important to aquaculture in Southeast Asia. Known for its delicate flavor and bony flesh.',
    tips: ['Use bread paste or algae-based baits', 'Milkfish are challenge to catch on light tackle', 'Popular in Filipino and Indonesian cuisine'],
  ),
  FishSpecies(
    name: 'Giant Snakehead', scientificName: 'Channa micropeltes',
    regions: ['Asia/Pacific'], sizeRange: '50–100 cm, up to 20 kg',
    habitat: 'Rivers, lakes, canals', waterType: 'Freshwater',
    diet: 'Fish, frogs, birds', commonTackle: 'Large frogs, swimbaits, topwater lures',
    color: Color(0xFF37474F),
    description: 'The largest snakehead species. Aggressive predator with a dark body and striking red/orange markings when young. A fearsome fighter.',
    tips: ['Use large topwater lures and frogs', 'Fish near weedy margins and lily pads', 'They guard their fry aggressively — approach with caution'],
  ),
  FishSpecies(
    name: 'Siamese Carp (Giant Carp)', scientificName: 'Catlocarpio siamensis',
    regions: ['Asia/Pacific'], sizeRange: '100–200 cm, up to 200 kg',
    habitat: 'Large rivers and lakes in Southeast Asia', waterType: 'Freshwater',
    diet: 'Algae, plankton, fruit', commonTackle: 'Specialized gear, fruit baits, dough balls',
    color: Color(0xFF8D6E63),
    description: 'The largest carp species in the world. Can grow over 2 meters and weigh 200 kg. Critically endangered due to habitat loss.',
    tips: ['Found in the Mekong River system', 'Use fruit-based baits', 'Strictly protected — catch and release only'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  SOUTH AMERICA                                                       ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Peacock Bass', scientificName: 'Cichla spp.',
    regions: ['South America', 'USA'], sizeRange: '30–70 cm, up to 12 kg',
    habitat: 'Amazon basin rivers, lakes', waterType: 'Freshwater',
    diet: 'Fish, crustaceans', commonTackle: 'Topwater lures, swimbaits, jerkbaits',
    color: Color(0xFFFFEB3B),
    description: 'A vibrant South American game fish named for the eye-spot on its tail. Extremely aggressive and powerful. Successfully introduced to Florida.',
    tips: ['Surface lures drive them crazy — explosive strikes', 'Fish near submerged logs and rock piles', 'Use braided line for better control in heavy cover'],
  ),
  FishSpecies(
    name: 'Arapaima', scientificName: 'Arapaima gigas',
    regions: ['South America'], sizeRange: '200–300 cm, up to 200 kg',
    habitat: 'Amazon River basin', waterType: 'Freshwater',
    diet: 'Fish', commonTackle: 'Large lures, live bait, heavy tackle',
    color: Color(0xFF795548),
    description: 'One of the largest freshwater fish in the world. Can breathe air using its swim bladder. Ancient-looking with a massive, armored body.',
    tips: ['Watch for surface rolls — they breathe air every 5-15 minutes', 'Use extremely heavy tackle (100lb+ line)', 'Catch and release is critical — populations are threatened'],
  ),
  FishSpecies(
    name: 'Payara (Vampire Fish)', scientificName: 'Hydrolycus scomberoides',
    regions: ['South America'], sizeRange: '40–90 cm, up to 10 kg',
    habitat: 'Amazon and Orinoco river basins', waterType: 'Freshwater',
    diet: 'Fish', commonTackle: 'Large spoons, swimbaits, wire leader',
    color: Color(0xFF263238),
    description: 'The vampire fish of the Amazon. Named for two massive fangs protruding from its lower jaw. A silver torpedo with incredible ferocity.',
    tips: ['Use fast-moving lures — payara are visual predators', 'Wire leader is mandatory — those fangs cut everything', 'Fish near rapids and fast-flowing water'],
  ),
  FishSpecies(
    name: 'Golden Dorado', scientificName: 'Salminus brasiliensis',
    regions: ['South America'], sizeRange: '40–100 cm, up to 20 kg',
    habitat: 'Rivers in the Paraná and Uruguay basins', waterType: 'Freshwater',
    diet: 'Fish', commonTackle: 'Surface lures, spoons, large streamer flies',
    color: Color(0xFFFFC107),
    description: 'The "tiger of the rivers." A brilliant gold-colored predator that attacks surface lures with explosive fury.',
    tips: ['Use bright, flashy lures that create surface disturbance', 'Fish near rapids, tailraces, and river confluences', 'They travel in packs — stay alert after a catch'],
  ),
  FishSpecies(
    name: 'Redtail Catfish', scientificName: 'Phractocephalus hemioliopterus',
    regions: ['South America'], sizeRange: '60–120 cm, up to 40 kg',
    habitat: 'Amazon and Orinoco river basins', waterType: 'Freshwater',
    diet: 'Fish, crustaceans, fruit', commonTackle: 'Large live bait, cut bait, heavy gear',
    color: Color(0xFFD32F2F),
    description: 'A striking catfish with a dark body and bright red tail. One of the most popular Amazonian fish. Grows large and fights incredibly hard.',
    tips: ['Fish deep holes and main river channels', 'Use large chunks of cut bait', 'Redtails are powerful — use sturdy tackle'],
  ),
  FishSpecies(
    name: 'Pacu', scientificName: 'Piaractus brachypomus',
    regions: ['South America'], sizeRange: '30–70 cm, up to 15 kg',
    habitat: 'Amazon and Orinoco river basins', waterType: 'Freshwater',
    diet: 'Fruit, nuts, plant matter', commonTackle: 'Fruit baits, dough balls, small lures',
    color: Color(0xFF424242),
    description: 'A relative of the piranha with distinctive human-like teeth adapted for crushing nuts and fruit. Stocked in waters worldwide.',
    tips: ['Use fruit baits like berries or melon', 'Pacu have powerful jaws — use a wire trace', 'They are often caught in warm-water discharges'],
  ),
  FishSpecies(
    name: 'Tambqui', scientificName: 'Colossoma macropomum',
    regions: ['South America'], sizeRange: '60–100 cm, up to 30 kg',
    habitat: 'Amazon River basin', waterType: 'Freshwater',
    diet: 'Fruit, seeds, nuts', commonTackle: 'Fruit lures, dough baits, heavy gear',
    color: Color(0xFF212121),
    description: 'The largest characin fish in the Amazon. Dark body with a silvery belly. An important food fish that can weigh over 30 kg.',
    tips: ['Fish near flooded forests during high water', 'Use fruit baits like palm nuts', 'Tambaqui are powerful — use heavy tackle'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  AFRICA                                                              ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Nile Perch', scientificName: 'Lates niloticus',
    regions: ['Africa'], sizeRange: '60–150 cm, up to 200 kg',
    habitat: 'African lakes, rivers', waterType: 'Freshwater',
    diet: 'Fish, crustaceans', commonTackle: 'Large lures, live bait, heavy trolling gear',
    color: Color(0xFF1565C0),
    description: 'A massive freshwater predator native to African lakes and rivers. Introduced to Lake Victoria where it transformed the ecosystem.',
    tips: ['Fish deep drop-offs and submerged river channels', 'Use large lures — they hunt fish up to half their size', 'Trolling with deep-diving plugs is effective'],
  ),
  FishSpecies(
    name: 'Tigerfish', scientificName: 'Hydrocynus spp.',
    regions: ['Africa'], sizeRange: '30–80 cm, up to 15 kg',
    habitat: 'African rivers, lakes', waterType: 'Freshwater',
    diet: 'Fish', commonTackle: 'Spinners, spoons, wire leaders',
    color: Color(0xFFFF6F00),
    description: 'Named for its razor-sharp teeth and striped body. One of the most ferocious freshwater fish. Known for aerial displays when hooked.',
    tips: ['Use wire leaders — their teeth cut regular line', 'Fast-moving lures trigger aggressive strikes', 'Fish near rapids and river confluences'],
  ),
  FishSpecies(
    name: 'African Sharptooth Catfish', scientificName: 'Clarias gariepinus',
    regions: ['Africa'], sizeRange: '40–100 cm, up to 25 kg',
    habitat: 'Rivers, lakes, swamps', waterType: 'Freshwater',
    diet: 'Fish, insects, plant matter, carrion', commonTackle: 'Worms, fish bait, chicken liver',
    color: Color(0xFF455A64),
    description: 'A hardy, widespread African catfish. Can breathe air and survive in low-oxygen water. Dark grey to black. Grows large and fights hard.',
    tips: ['Fish at night using strong-smelling baits', 'Found in almost any freshwater body across Africa', 'They can be invasive — check local regulations'],
  ),
  FishSpecies(
    name: 'Vundu Catfish', scientificName: 'Heterobranchus longifilis',
    regions: ['Africa'], sizeRange: '80–150 cm, up to 50 kg',
    habitat: 'Large African rivers', waterType: 'Freshwater',
    diet: 'Fish, crustaceans', commonTackle: 'Large live bait, heavy gear',
    color: Color(0xFF3E2723),
    description: 'One of Africa\'s largest freshwater fish. A massive catfish found in the Zambezi and Congo rivers. Legendary for its strength.',
    tips: ['Fish deep pools and main river channels', 'Use large live bait', 'Vundu are most active at night'],
  ),
  FishSpecies(
    name: 'African Pike (Goliath Pike)', scientificName: 'Hepsetus odoe',
    regions: ['Africa'], sizeRange: '30–50 cm, up to 3 kg',
    habitat: 'African rivers, lakes', waterType: 'Freshwater',
    diet: 'Fish, frogs', commonTackle: 'Spoons, spinners, live bait',
    color: Color(0xFF4CAF50),
    description: 'A predatory fish similar in appearance to the true pike. Found in freshwater systems across western and central Africa.',
    tips: ['Fish near weedy areas and submerged logs', 'Use flashy lures that imitate small fish', 'Check local regulations for specific areas'],
  ),
  FishSpecies(
    name: 'Nile Tilapia', scientificName: 'Oreochromis niloticus',
    regions: ['Africa', 'Asia/Pacific', 'USA'], sizeRange: '20–40 cm, up to 4 kg',
    habitat: 'Lakes, rivers, ponds', waterType: 'Freshwater',
    diet: 'Algae, plant matter, insects', commonTackle: 'Worms, bread, small hooks',
    color: Color(0xFF80DEEA),
    description: 'One of the most important food fish worldwide. Pinkish body. Widely farmed but also popular with sport anglers in warm waters.',
    tips: ['Fish shallow warm water near banks', 'Use bread paste or small worms', 'Tilapia are powerful fighters on light tackle'],
  ),
  FishSpecies(
    name: 'Yellowfish (Large Mouth)', scientificName: 'Labeobarbus kimberleyensis',
    regions: ['Africa'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'African rivers', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Flies, small spinners, worms',
    color: Color(0xFFFDD835),
    description: 'A popular African game fish with a golden-yellow body. Known for its fighting ability in fast water. Found in many South African rivers.',
    tips: ['Use nymph patterns for fly fishing', 'Fish in fast-flowing riffles', 'Yellowfish are catch and release in many areas'],
  ),

  // ╔════════════════════════════════════════════════════════════════════════╗
  // ║  AUSTRALIA                                                           ║
  // ╚════════════════════════════════════════════════════════════════════════╝
  FishSpecies(
    name: 'Murray Cod', scientificName: 'Maccullochella peelii',
    regions: ['Australia'], sizeRange: '50–120 cm, up to 110 kg',
    habitat: 'Murray-Darling River system', waterType: 'Freshwater',
    diet: 'Fish, frogs, crayfish, water birds', commonTackle: 'Large lures, spinnerbaits, live bait',
    color: Color(0xFF33691E),
    description: 'Australia\'s largest freshwater fish. A dark green mottled predator that can live for 50+ years. Sacred to Indigenous Australians.',
    tips: ['Fish near fallen timber and undercut banks', 'Use large, slow-moving lures at dawn and dusk', 'Strict catch limits — practice catch and release'],
  ),
  FishSpecies(
    name: 'Flathead', scientificName: 'Platycephalus spp.',
    regions: ['Australia', 'Asia/Pacific'], sizeRange: '30–80 cm, up to 5 kg',
    habitat: 'Estuaries, coastal bays, sandy bottoms', waterType: 'Saltwater',
    diet: 'Small fish, prawns, crabs', commonTackle: 'Soft plastics, bait on a running rig',
    color: Color(0xFFA1887F),
    description: 'A bottom-dwelling ambush predator with a flat, triangular head. Excellent eating quality. One of the most popular targets for Australian anglers.',
    tips: ['Drag soft plastics slowly along sandy bottoms', 'Fish incoming tides in estuaries', 'Fillets are white, flaky and delicious'],
  ),
  FishSpecies(
    name: 'Australian Salmon', scientificName: 'Arripis trutta',
    regions: ['Australia'], sizeRange: '30–60 cm, up to 5 kg',
    habitat: 'Coastal waters, surf beaches, bays', waterType: 'Saltwater',
    diet: 'Small fish, krill, prawns', commonTackle: 'Metal slugs, pilchards, surfcasting gear',
    color: Color(0xFF42A5F5),
    description: 'Not a true salmon but a highly popular Australian sport fish. Greenish-blue back with silver belly. Known for schooling behavior and powerful runs.',
    tips: ['Surfcast from beaches using bait or metal lures', 'Look for birds working — salmon push baitfish to the surface', 'They school by size — catch one and you\'ll likely catch more'],
  ),
  FishSpecies(
    name: 'Mangrove Jack', scientificName: 'Lutjanus argentimaculatus',
    regions: ['Australia', 'Asia/Pacific'], sizeRange: '40–80 cm, up to 8 kg',
    habitat: 'Mangroves, estuaries, coastal reefs', waterType: 'Saltwater',
    diet: 'Fish, crabs, prawns', commonTackle: 'Live bait, soft plastics, hard-bodied lures',
    color: Color(0xFFD32F2F),
    description: 'A powerful reddish fish that lives among mangrove roots. Known for aggressive strikes and immediate dives back into cover.',
    tips: ['Cast lures right up to mangrove roots', 'Use braided line to pull them out of structure', 'Incoming tide pushes them into the mangroves to feed'],
  ),
  FishSpecies(
    name: 'Snapper (Pink Snapper)', scientificName: 'Pagrus auratus',
    regions: ['Australia', 'Asia/Pacific'], sizeRange: '40–90 cm, up to 15 kg',
    habitat: 'Coastal reefs, rocky bottoms', waterType: 'Saltwater',
    diet: 'Fish, crabs, squid', commonTackle: 'Pilchards, squid, soft plastics, baitrunners',
    color: Color(0xFFF44336),
    description: 'One of Australia\'s most popular and best-tasting reef fish. Pinkish-silver body with a distinctive hump on the head of larger specimens.',
    tips: ['Fish near reef edges and rocky bottoms', 'Use fresh pilchards or squid strips', 'Snapper are cautious — use light leader for wary fish'],
  ),
  FishSpecies(
    name: 'Australian Bass', scientificName: 'Macquaria novemaculeata',
    regions: ['Australia'], sizeRange: '25–50 cm, up to 3 kg',
    habitat: 'Coastal rivers, streams, dams', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Surface lures, soft plastics, hard-bodied lures',
    color: Color(0xFF2E7D32),
    description: 'A popular native freshwater sport fish. Greenish-brown above, silver below. Known for explosive surface strikes in rivers.',
    tips: ['Fish surface lures at dawn and dusk', 'They migrate downstream in winter, upstream in spring', 'Use light tackle for the best sport'],
  ),
  FishSpecies(
    name: 'Golden Perch (Yellowbelly)', scientificName: 'Macquaria ambigua',
    regions: ['Australia'], sizeRange: '25–50 cm, up to 5 kg',
    habitat: 'Rivers, lakes, reservoirs', waterType: 'Freshwater',
    diet: 'Insects, crustaceans, small fish', commonTackle: 'Spinners, soft plastics, worms, yabbies',
    color: Color(0xFFFFC107),
    description: 'A golden-yellow native fish found throughout the Murray-Darling system. Highly regarded for sport and eating quality.',
    tips: ['Use yabbies or shrimp for bait', 'Fish near structure like fallen timber', 'Golden perch are most active in warmer months'],
  ),
  FishSpecies(
    name: 'Barramundi Cod (Giant Grouper)', scientificName: 'Epinephelus lanceolatus',
    regions: ['Australia', 'Asia/Pacific'], sizeRange: '100–300 cm, up to 300 kg',
    habitat: 'Coastal reefs, caves, wrecks', waterType: 'Saltwater',
    diet: 'Fish, crustaceans, sharks', commonTackle: 'Heavy tackle, large live bait, jigs',
    color: Color(0xFF4E342E),
    description: 'The largest grouper species in the world. Can reach over 3 meters and 300 kg. A protected species in Australian waters.',
    tips: ['Found in deep offshore reefs and caves', 'Use extremely heavy tackle', 'Protected in Australia — catch and release only'],
  ),
  FishSpecies(
    name: 'Tailor', scientificName: 'Pomatomus saltatrix',
    regions: ['Australia', 'Africa', 'USA'], sizeRange: '25–60 cm, up to 5 kg',
    habitat: 'Surf beaches, coastal waters', waterType: 'Saltwater',
    diet: 'Small fish', commonTackle: 'Metal lures, pilchards, surf rods',
    color: Color(0xFF1E88E5),
    description: 'A fast, schooling fish with razor-sharp teeth. Known for feeding frenzies — tailor will bite through rigs and attack anything shiny.',
    tips: ['Use wire trace — tailor cut through line', 'Fish surf beaches at dawn and dusk', 'They often feed on the surface — look for splashing'],
  ),
  FishSpecies(
    name: 'Mulloway (Jewfish)', scientificName: 'Argyrosomus japonicus',
    regions: ['Australia', 'Africa'], sizeRange: '50–120 cm, up to 30 kg',
    habitat: 'Surf beaches, estuaries, coastal waters', waterType: 'Saltwater',
    diet: 'Fish, crabs, prawns', commonTackle: 'Live bait, soft plastics, surf rods',
    color: Color(0xFFB0BEC5),
    description: 'The largest Australian estuarine fish. A silvery, drum-like fish known for its wariness and powerful runs. A bucket-list species for surf anglers.',
    tips: ['Fish surf gutters and river mouths', 'Use live bait or large soft plastics at night', 'Mulloway are wary — use light leader and careful presentation'],
  ),
  FishSpecies(
    name: 'Bream (Yellowfin Bream)', scientificName: 'Acanthopagrus australis',
    regions: ['Australia'], sizeRange: '20–35 cm, up to 2 kg',
    habitat: 'Estuaries, coastal rivers, lakes', waterType: 'Saltwater / Freshwater',
    diet: 'Crabs, worms, mollusks, small fish', commonTackle: 'Light line, small hooks, soft plastics',
    color: Color(0xFF78909C),
    description: 'One of Australia\'s most popular estuary fish. Silver with yellow fins and a dark patch behind the head. Wary and challenging on light tackle.',
    tips: ['Use light leader (4-6lb) and small hooks', 'Fish near structure like wharves and rock walls', 'Bream have excellent eyesight — use careful presentation'],
  ),
  FishSpecies(
    name: 'Whiting (Sand Whiting)', scientificName: 'Sillago ciliata',
    regions: ['Australia'], sizeRange: '20–40 cm, up to 1 kg',
    habitat: 'Sandy beaches, estuaries, bays', waterType: 'Saltwater',
    diet: 'Worms, crustaceans, small mollusks', commonTackle: 'Light gear, small hooks, beachworms',
    color: Color(0xFFD7CCC8),
    description: 'A silvery, slender fish found on sandy bottoms. One of the best-eating fish in Australia. Highly prized by beach and estuary anglers.',
    tips: ['Use beachworms or pipis for bait', 'Fish on sandy flats at high tide', 'Whiting are shy — use light leader'],
  ),
];

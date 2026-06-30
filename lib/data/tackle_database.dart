/// Predefined tackle types with target species and usage tips.
class TackleTypeInfo {
  final String name;
  final String category;
  final String description;
  final List<String> targetSpecies;
  final String tips;
  final String icon; // emoji fallback

  /// Best seasons for this lure (spring, summer, fall, winter).
  final List<String> bestSeasons;

  /// Best times of day (dawn, day, dusk, night).
  final List<String> bestTimeOfDay;

  const TackleTypeInfo({
    required this.name,
    required this.category,
    required this.description,
    required this.targetSpecies,
    required this.tips,
    this.icon = '🎣',
    this.bestSeasons = const ['spring', 'summer', 'fall', 'winter'],
    this.bestTimeOfDay = const ['dawn', 'day', 'dusk', 'night'],
  });
}

/// Built-in database of common lure / tackle types.
const tackleTypeDatabase = <TackleTypeInfo>[
  // ═════════════════════════════════════════════════════════════════════
  //  SPINNERBAITS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Spinnerbait',
    category: 'Spinnerbait',
    description: 'A safety-pin shaped lure with one or two spinning metal blades '
        'that flash and vibrate, and a skirted jig head with a hidden hook. '
        'The blades create thumping vibration and flash that fish detect through '
        'their lateral lines, making spinnerbaits deadly in stained or muddy water. '
        'Available in single-blade (Colorado) for slow, thumpy retrieves or '
        'double-blade (Indiana/Willow) for faster, flashier presentations.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Northern Pike', 'Muskellunge', 'Chain Pickerel',
      'Pickerel', 'Redfish', 'Snook',
    ],
    tips: 'Best seasons: Spring through fall — especially prespawn and postspawn when bass are aggressive. '
        'Best conditions: Stained or muddy water, overcast days, wind-chopped water. The vibration helps fish find it when visibility is low.\n\n'
        'Retrieve techniques:\n'
        '• Slow roll — reel just fast enough to spin the blade, bumping the bottom. Best in cold water (under 15°C).\n'
        '• Burn and kill — reel fast then stop suddenly, letting it fall on slack line. Strikes often come on the fall.\n'
        '• Yo-yo — lift rod tip sharply, let it fall back. Great for working deep weed edges.\n\n'
        'Colors: White/chartreuse for stained water, black/blue for dark water, natural shad for clear water.\n\n'
        'Gear: 7\' medium-heavy rod, 12-17 lb fluorocarbon or 30-40 lb braid. A trailer hook adds hook-ups on short-striking fish.\n\n'
        'Best locations: Weed lines, lily pad edges, submerged timber, docks, and riprap banks.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🔄',
  ),
  TackleTypeInfo(
    name: 'Buzzbait',
    category: 'Spinnerbait',
    description: 'A specialised topwater spinnerbait with a large propeller-style '
        'blade mounted above the hook that churns and sputters across the surface '
        'like a fleeing baitfish or frog. The blade creates a distinctive buzzing '
        'sound and V-shaped wake that triggers explosive reaction strikes. '
        'One of the most exciting ways to catch bass because you see the entire strike.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Northern Pike',
      'Chain Pickerel',
    ],
    tips: 'Best seasons: Late spring through early fall — when water temps exceed 18°C. '
        'Prime time: Early morning, dusk, and overcast days. Night fishing with black buzzbaits is extremely effective in summer.\n\n'
        'Retrieve technique: Keep the rod tip up at 45° and reel steadily — the blade MUST stay on the surface to make noise. '
        'Vary the speed: fast creates more commotion, slow creates a wider wake. '
        'When a fish strikes, DO NOT set the hook immediately — wait 1-2 seconds until you feel the weight. '
        'Buzzbaits have a single hook and fish often swipe at it first before actually eating it.\n\n'
        'Colors: White is universal. Black for night fishing. Chartreuse for stained water.\n\n'
        'Gear: 7\' to 7\'6" medium-heavy rod, 17-20 lb fluorocarbon or 30-40 lb braid. '
        'The longer rod helps with hook sets and casting distance.\n\n'
        'Best locations: Weed flats, lily pads, shallow shorelines, and around boat docks.',
bestSeasons: ['spring', 'summer', 'fall'],
    bestTimeOfDay: ['dawn', 'dusk', 'night'],
        icon: '💨',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  CRANKBAITS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Crankbait',
    category: 'Crankbait',
    description: 'A hard-bodied lure with a plastic lip (billing) that makes it dive '
        'and wobble on retrieve, imitating a distressed or injured baitfish. '
        'Crankbaits come in three main types: shallow-diver (0-1.5m), medium-diver (2-4m), '
        'and deep-diver (4-8m+). The square-bill crankbait is a specialised version with '
        'a square lip that deflects off rocks and wood without snagging — making it ideal '
        'for fishing around cover. Round-bill crankbaits have a tighter wobble and track '
        'straighter, better for open water and deeper diving.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Walleye',
      'Northern Pike', 'Striped Bass', 'White Bass',
      'Spotted Bass',
    ],
    tips: 'Best seasons: Spring and fall are prime — fish are feeding heavily and relate to crankbait depths. '
        'Summer: fish deeper diving crankbaits along thermoclines and drop-offs. Winter: slow-rolled shallow divers on warm days.\n\n'
        'Retrieve techniques:\n'
        '• Steady retrieve — simple and effective. Match speed to water temperature (slower in cold).\n'
        '• Stop-and-go — reel 5-6 turns, pause 2-3 seconds. Strikes often come during the pause.\n'
        '• Deflect — crankbaits with square bills are designed to bang off cover. Deflect off rocks and wood to trigger reaction strikes.\n\n'
        'Matching depth: The bill determines max depth. Let out extra line after the cast to reach full depth — count it down. '
        'You want the crankbait to just tick the bottom occasionally.\n\n'
        'Colors: Crawfish patterns (red/orange/brown) for spring and rocky bottoms. '
        'Shad patterns (silver/white/chartreuse) for open water. Firetiger for stained water.\n\n'
        'Gear: 7\' to 7\'6" medium-action rod for casting, 12-17 lb fluorocarbon line '
        '(fluoro sinks and helps crankbaits dive deeper). Use a moderate-action rod that loads up on the hook set.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🏊',
  ),
  TackleTypeInfo(
    name: 'Lipless Crankbait',
    category: 'Crankbait',
    description: 'A sinking, vibrating lure with no diving bill — just a solid body '
        'with a flat face that creates tight vibration on retrieve. '
        'Also called a "rat-L-trap" or "vibe". Because it has no bill, it sinks freely '
        'and can be fished at any depth by counting it down. The tight, high-frequency '
        'rattle mimics a fleeing baitfish and is excellent for calling fish from a distance. '
        'One of the best "search baits" for covering water fast.',
    targetSpecies: [
      'Largemouth Bass', 'Striped Bass', 'White Bass',
      'Walleye', 'Redfish', 'Speckled Trout',
      'Bluefish',
    ],
    tips: 'Best seasons: Spring and fall when fish are schooled up on baitfish. '
        'Deadly for fall feeding frenzies when bass are chasing shad on flats.\n\n'
        'Retrieve techniques:\n'
        '• Yo-yo — cast, let it sink to desired depth, then sharply lift rod tip and let it flutter back. '
        'Most strikes happen on the fall. Count it down: 1 second per foot of depth.\n'
        '• Steady burn — fast retrieve just below the surface for aggressive fish.\n'
        '• Stop-and-go — reel fast, pause, let it sink. Covers the water column.\n\n'
        'Pro tip: Downsize in clear water (1/4 oz), upsize in stained water or wind (1/2-3/4 oz). '
        'Red or orange hooks are a factory option — they add a triggering flash.\n\n'
        'Colors: Chrome/blue, gold/black, and red crawfish are staples. Match the local baitfish.\n\n'
        'Gear: 7\' medium-heavy rod, 12-17 lb fluorocarbon. Casting allows precise depth control. '
        'Braided line with a fluorocarbon leader works well for feeling the vibration.',
bestSeasons: ['spring', 'fall'],
        icon: '📳',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  JIGS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Jig',
    category: 'Jig',
    description: 'A lead head moulded onto a hook, typically dressed with a rubber '
        'or silicone skirt and often tipped with a soft plastic trailer. Jigs are '
        'extremely versatile — they can be hopped, dragged, swam, or pitched. '
        'The jig imitates a crawfish, baitfish, or leech depending on how it\'s worked. '
        'They excel in cold water when fish are sluggish and want a slow, easy meal. '
        'Jigs are also one of the best lures for catching larger-than-average fish '
        'because they present a substantial meal that bigger fish prefer.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Walleye', 'Northern Pike', 'Channel Catfish',
      'Blue Catfish',
    ],
    tips: 'Best seasons: Year-round. Jigs shine in cold water (under 12°C) when fish are slow '
        'and want easy targets. Also excellent in prespawn when crawfish are active.\n\n'
        'Retrieve techniques:\n'
        '• Drag and hop — cast to cover, let it sink on semi-slack line (feel the tick), '
        'hop it 6-12 inches by lifting rod tip, let it fall back on tight line. '
        'Strikes are subtle — usually just a mushy feeling or line twitch.\n'
        '• Swim jig — reel steadily just above the bottom with a compact trailer (swim bait or chunk).\n'
        '• Pitch and flip — pitch into heavy cover and let it fall on tight line. '
        'Braided line helps pull fish out of thick stuff.\n\n'
        'Pro tip: Trim the skirt to just past the hook bend — it improves hook-ups. '
        'Add a rattle bead for noise in stained water. Use a chunk-style trailer in warm water, '
        'a creature bait in cold water.\n\n'
        'Colors: Brown/purple (crawfish), green pumpkin (universal), black/blue (dark water).\n\n'
        'Gear: 7\' to 7\'6" heavy-action rod for flipping, 15-20 lb fluorocarbon or 40-50 lb braid. '
        'Sensitive rod tip is critical for feeling subtle bites.',
    icon: '🪨',
  ),
  TackleTypeInfo(
    name: 'Football Jig',
    category: 'Jig',
    description: 'A specialised jig with a wide, football-shaped lead head that '
        'rocks side-to-side on the bottom without tipping over. The wide design '
        'keeps the hook upright as it\'s dragged over rocks and gravel, preventing '
        'snags while presenting the trailer naturally. Purpose-built for fishing '
        'rocky bottoms, chunk rock banks, gravel points, and riprap. '
        'The football shape also creates a subtle side-to-side wobble that mimics '
        'a crawfish moving defensively across the bottom.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Walleye',
    ],
    tips: 'Best seasons: Spring (prespawn) and fall when bass relate to rocky structure. '
        'Also effective in summer on deep rock piles and ledges.\n\n'
        'Retrieve: Drag it slowly across the bottom — do not hop it aggressively. '
        'The football head should tick and wobble over rocks. Keep your rod tip low and '
        'maintain bottom contact. Most strikes feel like a mushy bump or slight weight.\n\n'
        'Trailers: Use a crawfish-style trailer (Zoom Super Chunk, Strike King Rage Craw) '
        'in green pumpkin or brown. Trim the trailer to about 2.5-3" for best action.\n\n'
        'Colors: Brown/purple or green pumpkin for clear water. Black/blue for stained water.\n\n'
        'Gear: 7\'2" to 7\'6" heavy-action rod, 15-20 lb fluorocarbon line. '
        'The heavy rod is needed for solid hook sets through the jig\'s thick head.',
bestSeasons: ['spring', 'fall'],
        icon: '⚽',
  ),
  TackleTypeInfo(
    name: 'Finesse Jig',
    category: 'Jig',
    description: 'A compact, lighter jig (1/8 to 3/8 oz) with a smaller profile '
        'and finer skirt fibres. Designed for clear water, high-pressure fisheries, '
        'and finicky fish that have seen every lure. The smaller profile looks more '
        'natural and subtle. Finesse jigs excel when standard jigs are too bulky '
        'and fish won\'t commit. They can be skipped under docks and overhangs more '
        'easily than bulkier jigs.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Crappie', 'Rock Bass',
    ],
    tips: 'Best seasons: Late summer through winter when fishing pressure is high '
        'and water is clear. Deadly on smallmouth in clear rocky lakes.\n\n'
        'Retrieve: Drag slowly with subtle hops. Keep it low and slow. '
        'Use a lighter trailer (2.5" or smaller). Dead-stick it — let it sit motionless '
        'for 10-15 seconds between moves. Many strikes happen when the jig is sitting still.\n\n'
        'Colors: Green pumpkin, watermelon, smoked pearl — natural tones for clear water.\n\n'
        'Gear: 6\'6" to 7\' medium-light rod, 8-12 lb fluorocarbon line. '
        'Light line lets the jig fall more naturally and fits through lighter cover. '
        'A sensitive rod is crucial for detecting subtle bites.',
bestSeasons: ['summer', 'fall', 'winter'],
        icon: '🪶',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  SOFT PLASTICS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Plastic Worm',
    category: 'Soft Plastic',
    description: 'A soft plastic worm that can be rigged in multiple ways — Texas rig '
        '(weedless with a bullet weight), Carolina rig (weight above a swivel with leader), '
        'wacky rig (hook through the middle), or on a jig head. Plastic worms are arguably '
        'the most versatile and effective bass lure ever created. They imitate leeches, '
        'crawfish, worms, and even small snakes depending on colour and rigging. '
        'The soft texture makes fish hold on longer, giving you more time to set the hook.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Northern Pike', 'Channel Catfish',
    ],
    tips: 'Best seasons: Year-round. Worms work in every season and water temperature.\n\n'
        'Rigging techniques:\n'
        '• Texas rig — bullet weight pegged or free, hook buried in the worm. Weedless — good for heavy cover.\n'
        '• Carolina rig — 1-2 oz weight above a swivel, 2-4 ft leader. Best for dragging across open flats and deep water.\n'
        '• Wacky rig — hook through the middle. Incredible action on the fall. Best in clear water around docks.\n'
        '• Weightless — no weight, let it sink slowly. Great for shallow spawning beds.\n\n'
        'Retrieve: Drag slowly and pause frequently. Bass often pick the worm up on the pause — '
        'if you feel anything unusual, reel down and set the hook. Watch your line for sideways movement.\n\n'
        'Colors: Green pumpkin (universal), watermelon/red flake (clear water), '
        'black/blue (stained water), junebug (dark water), pumpkin/chartreuse (murky).\n\n'
        'Gear: 7\' medium-heavy rod, 12-17 lb fluorocarbon for Texas rig, '
        '15-20 lb for Carolina rig. Braid with fluoro leader for heavy cover.',
    icon: '🐛',
  ),
  TackleTypeInfo(
    name: 'Soft Plastic Jerkbait',
    category: 'Soft Plastic',
    description: 'A paddle-tail or shad-shaped soft plastic rigged on a jig head '
        'that swims with a lifelike side-to-side action on a steady retrieve. '
        'The paddletail creates a thumping vibration that fish feel with their lateral line, '
        'making them easy for fish to locate even in dirty water. These are among the '
        'easiest lures to fish effectively — cast and reel — yet they catch everything '
        'from panfish to trophy bass. Also called "swimbaits" in smaller sizes.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Striped Bass',
      'Redfish', 'Speckled Trout', 'Snook', 'Mahi Mahi',
      'Walleye', 'Flounder',
    ],
    tips: 'Best seasons: Spring through fall. Most consistent year-round lure.\n\n'
        'Rigging: Use a light wire jig head (1/8 to 1/4 oz) for shallow water, '
        'heavier (3/8 to 1/2 oz) for deeper water or current. Match the jig head size to the bait.\n\n'
        'Retrieve: Steady retrieve at moderate speed. Add occasional rod-tip twitches '
        'for erratic action. In cold water, slow down the retrieve significantly. '
        'Let it fall on a semi-slack line after the cast — strikes often come on the initial fall.\n\n'
        'Sizes: 2.5-3" for panfish and trout, 4-5" for bass, 6-8" for stripers and saltwater.\n\n'
        'Colors: White/silver (baitfish), pearl/glitter (clear water), chartreuse (stained), '
        'and natural shad patterns. In saltwater, white is the universal colour.\n\n'
        'Gear: 6\'6" to 7\' medium rod, 10-15 lb fluorocarbon or braid. '
        'The rod should have a moderate tip for casting lighter jig heads.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🐟',
  ),
  TackleTypeInfo(
    name: 'Creature Bait',
    category: 'Soft Plastic',
    description: 'An irregularly shaped soft plastic with multiple appendages that '
        'mimics crawfish, lizards, salamanders, or large aquatic insects. '
        'The arms and claws flutter and kick on the fall, creating a lifelike '
        'presentation that triggers feeding instincts. Creature baits excel around '
        'rocks, docks, and laydowns where crawfish naturally live. '
        'They also work well flipped into heavy cover because the appendages '
        'deflect off branches and make commotion on the way down.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Spotted Bass',
      'Channel Catfish',
    ],
    tips: 'Best seasons: Spring (crawfish season) and summer. Also deadly during the prespawn '
        'when bass are gorging on crawfish.\n\n'
        'Rigging: Texas rig with 3/16 to 3/8 oz bullet weight (pegged or free). '
        'The weight should be heavy enough to penetrate cover but light enough to fall slowly.\n\n'
        'Retrieve: Hop it along the bottom with 6-12" lifts. Let it sit between hops. '
        'Crawfish naturally move in short bursts, then pause defensively. '
        'The pause is when most strikes occur — be ready.\n\n'
        'Colors: Green pumpkin, brown/purple, black/blue. Red accents (claws) are a plus in spring.\n\n'
        'Gear: 7\' to 7\'6" heavy-action rod, 15-20 lb fluorocarbon or 40-50 lb braid. '
        'Heavy gear is needed for solid hook sets through the thick plastic and cover.',
bestSeasons: ['spring', 'summer'],
        icon: '🦎',
  ),
  TackleTypeInfo(
    name: 'Drop Shot Rig',
    category: 'Soft Plastic',
    description: 'A finesse rig where the weight is tied at the end of the line, '
        'with the hook tied 12-24 inches above it using a Palomar knot. The weight '
        'sits on the bottom while the bait suspends above it, quivering in place. '
        'The drop shot is among the most effective presentations for deep, clear water '
        'and heavily pressured fish that have seen every other rig. '
        'It presents the bait naturally because the line comes from above, '
        'not from the side like a traditional jig head.',
    targetSpecies: [
      'Smallmouth Bass', 'Largemouth Bass', 'Spotted Bass',
      'Walleye', 'Yellow Perch', 'Crappie',
      'Lake Trout',
    ],
    tips: 'Best seasons: Summer when fish are deep (10-30 ft). Also effective in clear water year-round. '
        'The drop shot excels when fish are suspended off the bottom and won\'t chase.\n\n'
        'Rigging: '
        '1. Tie a Palomar knot with a long tag end (12-24"). '
        '2. Pass the tag end back through the hook eye. '
        '3. Tie the weight to the tag end. '
        '4. Use a finesse worm (4") or minnow bait. '
        '5. Hook the bait through the nose — it must hang perfectly straight.\n\n'
        'Retrieve: Once the weight hits bottom, shake the rod tip gently — '
        'the bait should quiver without moving the weight. '
        'Lift the weight 6-12 inches and let it settle. '
        'Most bites feel like a tap or the weight suddenly feeling lighter.\n\n'
        'Colors: Natural shades — green pumpkin, morning dawn, watermelon. '
        'Use lighter colours in clearer water.\n\n'
        'Gear: 6\'8" to 7\'2" medium-light spinning rod, 6-10 lb fluorocarbon line. '
        'A sensitive rod tip is critical for feeling subtle drop shot bites. '
        'Use a #1 or #2 hook for finesse worms.',
bestSeasons: ['summer'],
        icon: '📏',
  ),
  TackleTypeInfo(
    name: 'Ned Rig',
    category: 'Soft Plastic',
    description: 'A short, finesse soft plastic (usually a "Zinker" or "Finesse TRD") '
        'on a light mushroom-head jig with a flat bottom. The flat head lets the bait '
        'stand upright on the bottom, wobbling subtly with any water movement. '
        'The Ned rig took the fishing world by storm in the 2010s for its incredible '
        'effectiveness on pressured smallmouth and largemouth in clear water. '
        'It\'s maddeningly simple yet devastatingly effective when nothing else works.',
    targetSpecies: [
      'Smallmouth Bass', 'Largemouth Bass', 'Spotted Bass',
      'Walleye', 'Crappie', 'Yellow Perch',
    ],
    tips: 'Best seasons: Year-round, but truly shines in cold water (under 10°C) when fish '
        'are sluggish and won\'t chase. Also deadly in high-pressure fisheries.\n\n'
        'Rigging: Thread the bait onto the jig head so it sits flush with the bottom. '
        'Trim the bait shorter if fish are short-striking — a 2" bait often out-fishes a 3".\n\n'
        'Retrieve: Cast, let it sink on semi-slack line, then drag or hop it very slowly. '
        'The magic is in the pause — let it sit for 10-20 seconds between moves. '
        'Watch your line for any tick or twitch. Most strikes are incredibly subtle — '
        'the line just moves sideways or feels heavy.\n\n'
        'Colors: Green pumpkin (best overall), hot craw, and purple. '
        'Use darker colours in stained water.\n\n'
        'Gear: 6\'6" to 7\' medium-light spinning rod, 6-10 lb fluorocarbon. '
        'You NEED fluorocarbon — it sinks and keeps the bait in contact with the bottom. '
        'The rod should be very sensitive to detect light bites.',
    icon: '🧷',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  TOPWATER
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Popper',
    category: 'Topwater',
    description: 'A concave-faced topwater lure that creates a loud "pop" and spray '
        'when twitched, followed by a resting pause. The pop mimics a baitfish '
        'struggling on the surface, attracting fish from below. The pause is critical — '
        'most strikes happen 2-5 seconds after the pop when fish track the disturbance '
        'and attack. Poppers work best in calm water where the surface disturbance '
        'travels farther and fish can pinpoint the sound.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Northern Pike',
      'Striped Bass', 'Snook', 'Redfish',
    ],
    tips: 'Best seasons: Late spring through early fall. Water temps above 18°C. '
        'Prime times: Early morning (dawn to 9am) and early evening (5pm to dusk). '
        'Overcast days can extend topwater action all day.\n\n'
        'Retrieve: Cast near cover, let it sit until ripples dissipate, then pop with '
        'a sharp rod-tip twitch. Pause 3-5 seconds between pops. The cadence matters: '
        'pop-pop-pause, pop-pause, or pop-pop-pop-pause. Experiment until you find what they want.\n\n'
        'Pro tip: If a fish strikes and misses, don\'t reel in — pop it again immediately. '
        'They often come back for a second strike.\n\n'
        'Colors: Bone or white (universal), black (night fishing), frog patterns (vegetation).\n\n'
        'Gear: 6\'6" to 7\' medium rod, 12-17 lb fluorocarbon or monofilament '
        '(mono floats and helps topwater action). A moderate-fast action rod helps prevent tearing the hooks out.',
bestSeasons: ['spring', 'summer', 'fall'],
    bestTimeOfDay: ['dawn', 'dusk'],
        icon: '💥',
  ),
  TackleTypeInfo(
    name: 'Walking Bait',
    category: 'Topwater',
    description: 'A cigar-shaped topwater lure designed to "walk the dog" — zig-zag '
        'across the surface with a side-to-side sliding motion when retrieved with '
        'a rhythmic rod-tip twitching technique. The erratic, wounded-baitfish action '
        'drives predatory fish crazy. Walking baits excel over open water, grass flats, '
        'and along weed edges. The Zara Spook is the most famous walking bait ever made.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Striped Bass',
      'Snook', 'Redfish', 'Speckled Trout',
      'Northern Pike',
    ],
    tips: 'Best seasons: Summer and early fall — warm water, aggressive fish. '
        'Also effective during the fall baitfish migration. '
        'Works best in calm water conditions (light wind or less).\n\n'
        'Walk-the-dog technique: '
        '1. Cast and point rod tip at the water. '
        '2. Snap the rod tip down 6-12 inches while simultaneously reeling slack. '
        '3. The bait should dart sideways. '
        '4. Repeat in a steady rhythm — the bait walks in a zig-zag. '
        '5. Vary speed: fast walking triggers reaction, slow walking triggers follows.\n\n'
        'Pro tip: If fish follow but don\'t strike, speed up or change direction. '
        'If they boil behind it, pause — they often eat it when it stops.\n\n'
        'Colors: Bone/silver, bright chartreuse, or black for night.\n\n'
        'Gear: 7\' medium-heavy rod with a moderate-fast action, '
        '14-17 lb monofilament (mono floats and aids the walking action). Braid also works but requires rod-tip adjustments.',
bestSeasons: ['summer', 'fall'],
        icon: '🚶',
  ),
  TackleTypeInfo(
    name: 'Frog',
    category: 'Topwater',
    description: 'A hollow-bodied, weedless soft plastic frog designed to be fished '
        'over the thickest vegetation — lily pads, hydrangea, matted grass, and slop '
        'where no other lure can go. The legs kick and churn on retrieve, imitating '
        'a frog or mouse struggling across the surface. The hook is recessed into the '
        'body, making it completely weedless. Frog fishing is some of the most exciting '
        'action in freshwater fishing — fish blow up through heavy cover to crush it.',
    targetSpecies: [
      'Largemouth Bass', 'Northern Pike', 'Chain Pickerel',
      'Muskellunge',
    ],
    tips: 'Best seasons: Summer (June-September) when vegetation is thick and fish are holding in it. '
        'Early morning, dusk, and overcast days are best. Frogs also work at night.\n\n'
        'Retrieve: Cast onto the vegetation, let it sit for a moment, then "walk" it '
        'across the top like a walking bait — rod-tip snaps with reel turns. '
        'Vary the speed: fast skittering across pads, or slow chugging through openings.\n\n'
        'Critical rule: WHEN A FISH BLOWS UP ON YOUR FROG, DO NOT SET THE HOOK IMMEDIATELY. '
        'Count to two-Mississippi, then drive the hooks home. Fish often miss on the first explosion '
        'or just stun the frog. Give them time to actually eat it.\n\n'
        'Modifications: Bend the hooks out slightly for better hook-up ratio. '
        'Soak the frog in warm water to soften the body — makes the hooks penetrate easier.\n\n'
        'Colors: Black (best overall, especially at night), white (clear water), '
        'green/brown (natural), and chartreuse (stained water).\n\n'
        'Gear: 7\'6" to 8\' heavy-action rod, 50-65 lb braided line. '
        'You need heavy braid to cut through vegetation and haul fish out of cover. '
        'A stiff rod is needed for long hook sets through the soft frog body.',
bestSeasons: ['summer'],
    bestTimeOfDay: ['dawn', 'dusk', 'night'],
        icon: '🐸',
  ),
  TackleTypeInfo(
    name: 'Prop Bait',
    category: 'Topwater',
    description: 'A topwater lure with one or two small metal propellers on the front '
        'and/or rear that spin and churn when retrieved, creating a distinctive buzzing '
        'sound and surface wake. The propellers throw water and make commotion similar '
        'to a struggling insect or small baitfish. Prop baits work well in calm water '
        'where the disturbance carries. The classic Devil\'s Horse and Tiny Torpedo '
        'are legendary prop baits that have been catching fish for decades.',
    targetSpecies: [
      'Largemouth Bass', 'Smallmouth Bass', 'Northern Pike',
      'Chain Pickerel', 'Striped Bass',
    ],
    tips: 'Best seasons: Summer evenings and early mornings. Excellent in calm, slick-calm water '
        'where the propeller noise travels well. Also effective on moonlit nights.\n\n'
        'Retrieve: Steady slow retrieve keeps the props churning. Twitch and pause for erratic action. '
        'The rear propeller creates more disturbance, the front propeller adds flash. '
        'Vary the speed until you find the cadence that triggers strikes.\n\n'
        'Pro tip: Replace the stock treble hooks with larger ones for better hook-ups. '
        'The rear treble often tangles with the rear propeller — bend it slightly outward.\n\n'
        'Colors: Silver/black, frog patterns, and bright chartreuse.\n\n'
        'Gear: 6\'6" to 7\' medium rod, 12-17 lb monofilament. Mono floats and dampens '
        'the action for a more natural presentation.',
bestSeasons: ['summer'],
    bestTimeOfDay: ['dusk', 'night'],
        icon: '🛩️',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  SPOONS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Spoon',
    category: 'Spoon',
    description: 'A concave metal lure shaped like a spoon bowl that wobbles, '
        'flashes, and vibrates on retrieve. The flash and vibration mimic a fleeing '
        'baitfish, triggering reaction strikes. Spoons are among the oldest artificial '
        'lures and remain deadly for a wide range of species. They come in casting '
        'spoons (cast and retrieve) and trolling spoons (towed behind a boat). '
        'The classic Johnson Silver Minnow is one of the most famous weedless spoons.',
    targetSpecies: [
      'Northern Pike', 'Muskellunge', 'Walleye', 'Lake Trout',
      'Rainbow Trout', 'Brook Trout', 'Redfish',
      'Bluefish', 'Striped Bass', 'Coho Salmon',
    ],
    tips: 'Best seasons: Spring through fall for most species. '
        'Spoons are excellent in fall when pike and trout are feeding heavily. '
        'Trolling spoons work year-round for lake trout and salmon.\n\n'
        'Retrieve techniques:\n'
        '• Cast and flutter — let the spoon flutter down on semi-slack line. '
        'Many strikes happen on the initial fall.\n'
        '• Lift and drop — lift rod tip 2-3 ft, let spoon flutter back. '
        'This yo-yo action is devastating for suspended fish.\n'
        '• Steady retrieve — simple and effective for covering water.\n\n'
        'Weedless spoons (like Johnson Silver Minnow): add a soft plastic trailer '
        'to increase action and slow the fall. Fish through the thickest lily pads.\n\n'
        'Colors: Silver (clear water), gold (stained water), nickel/blue, '
        'and copper (deep water). Half-and-half (silver/gold) is versatile.\n\n'
        'Gear: 6\'6" to 7\' medium-heavy rod, 12-20 lb fluorocarbon or braid. '
        'For pike and muskie, use a steel or titanium leader to prevent cut-offs.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🥄',
  ),
  TackleTypeInfo(
    name: 'Jigging Spoon',
    category: 'Spoon',
    description: 'A heavy metal spoon designed specifically for vertical jigging '
        'in deep water. Jigging spoons are thicker and heavier than casting spoons '
        'so they sink fast and flutter erratically on the fall. They are dropped '
        'straight down to the fish and worked vertically rather than cast. '
        'Essential for deep lake trout, walleye on structure, and ice fishing. '
        'The flutter fall triggers reaction strikes from fish holding deep.',
    targetSpecies: [
      'Lake Trout', 'Walleye', 'Striped Bass',
      'Bluefin Tuna', 'Yellowfin Tuna',
      'Salmon',
    ],
    tips: 'Best seasons: Summer when fish hold deep (20-50 ft). '
        'Ice fishing — jigging spoons are the #1 lure for lake trout and walleye through the ice. '
        'Also effective year-round for deep structure.\n\n'
        'Technique: '
        '1. Drop to the bottom or to the depth where fish are holding. '
        '2. Lift rod tip sharply 2-4 ft. '
        '3. Follow the spoon back down with your rod tip as it flutters. '
        '4. Watch your line — strikes happen on the fall and look like line twitching or stopping.\n\n'
        'Pro tip: Add a minnow head or strip of bait to the hook for reluctant fish. '
        'The scent and taste triggers fish to hold on longer.\n\n'
        'Sizes: 1/4 oz for walleye, 1/2-1 oz for lake trout, 2-4 oz for tuna and deep water.\n\n'
        'Colors: Silver, glow (for deep water and ice), gold, and chartreuse.\n\n'
        'Gear: 6\'6" to 7\' medium-heavy to heavy rod, 15-30 lb braid. '
        'Braid eliminates stretch for better sensitivity and hook sets at depth. '
        'A high-speed reel (6:1+) helps quickly regain line.',
bestSeasons: ['summer', 'winter'],
        icon: '⬇️',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  LIVE BAIT RIGS
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Live Bait Rig',
    category: 'Live Bait',
    description: 'A basic hook-and-weight rig for presenting live bait naturally. '
        'Typically consists of a hook tied to a leader, with a weight above a swivel '
        'so the fish can take the bait without feeling the weight. '
        'Using live bait is often the most effective way to catch fish, especially '
        'in cold water or high-pressure fisheries where fish are wary of artificials. '
        'Common live baits include nightcrawlers, minnows, shiners, leeches, '
        'crayfish, shrimp, and cut bait.',
    targetSpecies: [
      'Walleye', 'Channel Catfish', 'Blue Catfish', 'Crappie',
      'Yellow Perch', 'Redfish', 'Speckled Trout',
      'Flounder', 'Bluegill',
    ],
    tips: 'Best seasons: Year-round. Live bait works in every season and condition. '
        'Especially effective when fish are in a negative mood or during cold fronts.\n\n'
        'Rigging tips:\n'
        '• Slip sinker rig (most versatile) — egg sinker slides on main line above a swivel, '
        'with 18-36" leader to the hook. Fish can take bait and run without feeling weight.\n'
        '• Carolina rig — heavier weight (3/4-2 oz) above swivel with longer leader (2-4 ft). '
        'Best for surf fishing and deep water.\n'
        '• Split shot rig — light weight pinched on the line 12-18" above the hook. '
        'Best for panfish and shallow water.\n\n'
        'Hook selection: Use circle hooks for catch-and-release (they hook in the corner of the mouth). '
        'Use J-hooks for live minnows (hook through the lips or back). '
        'Match hook size to bait size — the hook point should be exposed.\n\n'
        'Bait selection: Nightcrawlers for catfish and panfish. Shiners for bass. '
        'Minnows for walleye and crappie. Leeches for walleye. Shrimp for saltwater.\n\n'
        'Gear: 6\'6" to 7\' medium rod, 10-17 lb monofilament or fluorocarbon. '
        'A sensitive rod tip helps detect subtle live-bite taps.',
    icon: '🪱',
  ),
  TackleTypeInfo(
    name: 'Carolina Rig',
    category: 'Live Bait',
    description: 'A specialised bottom rig where a heavy egg sinker (3/4-2 oz) slides '
        'freely on the main line above a barrel swivel, with a 2-4 ft fluorocarbon '
        'leader to the hook. The weight ticks and taps along the bottom while the bait '
        'floats naturally above it. The Carolina rig excels at covering deep flats, '
        'points, and channels. It\'s especially effective for suspending soft plastics '
        'above grass beds and presenting baits naturally in deep, clear water.',
    targetSpecies: [
      'Largemouth Bass', 'Striped Bass', 'Redfish',
      'Flounder', 'Channel Catfish',
    ],
    tips: 'Best seasons: Late spring through fall when fish are on deep flats and points. '
        'Also effective for summer deep-water patterns (15-30 ft).\n\n'
        'Rigging: '
        '1. Thread egg sinker onto main line. '
        '2. Tie a barrel swivel. '
        '3. Tie 2-4 ft leader to the other end of swivel. '
        '4. Tie hook (3/0 to 5/0) with your favourite soft plastic. '
        '5. Peg the weight with a toothpick if you want it fixed (rarely done).\n\n'
        'Retrieve: Drag it slowly — lift rod tip to move the weight 6-12 inches, '
        'then let it settle. The weight should tick along the bottom. '
        'Watch your line for any tick or twitch. Most strikes are subtle.\n\n'
        'Bait selection: Soft plastic lizards, worms, and creatures. '
        'Use a 6-8" worm for bass, smaller for panfish. '
        'Green pumpkin and watermelon are staple colours.\n\n'
        'Gear: 7\' to 7\'6" medium-heavy rod, 12-17 lb fluorocarbon main line, '
        '10-15 lb fluorocarbon leader. A longer rod helps with casting heavy weights.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🔗',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  ICE FISHING
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Ice Jig',
    category: 'Ice Fishing',
    description: 'A tiny, lightweight jig (1/80 to 1/16 oz) designed for fishing '
        'through ice holes. Usually tipped with a wax worm, spike (maggot), '
        'or small minnow head. Ice jigs come in wild colours and shapes — '
        'ratsos, forage minnows, tungsten jigs, and tear-drop shapes. '
        'Tungsten jigs are popular because they drop faster and transmit vibration better. '
        'Ultra-light rods with spring bobbers are used to detect the subtle bites.',
    targetSpecies: [
      'Yellow Perch', 'Walleye', 'Crappie', 'Bluegill',
      'Lake Trout', 'Northern Pike',
    ],
    tips: 'Best seasons: Winter, obviously! Ice fishing season (typically December-March '
        'depending on location). First ice and last ice are usually the most productive.\n\n'
        'Technique: '
        '1. Drop the jig to just above the bottom. '
        '2. Jig with short, sharp lifts (1-6 inches). '
        '3. Let it sit completely still for 10-30 seconds between jigging sequences. '
        '4. Watch the spring bobber — the slightest twitch means a bite.\n\n'
        'Pro tip: Pound the bottom a few times to create a puff of sediment — '
        'this attracts fish to the area, then present your jig just above the cloud.\n\n'
        'Tipping baits: Wax worms for panfish, spikes for perch, '
        'minnow heads for walleye and lake trout. Always keep baits lively.\n\n'
        'Electronics: A flasher or fish finder is worth its weight in gold — '
        'you can see your jig and the fish\'s reaction in real-time.\n\n'
        'Gear: 24-32" ultra-light ice rod, 2-4 lb monofilament or fluorocarbon. '
        'A spring bobber on the rod tip is essential for detecting light bites.',
bestSeasons: ['winter'],
        icon: '🧊',
  ),
  TackleTypeInfo(
    name: 'Tip-Up Rig',
    category: 'Ice Fishing',
    description: 'A mechanical flag rig set up over an ice hole that pops up when '
        'a fish takes the bait. The tip-up has a spool of line below the ice and a '
        'flag on a spring arm above the ice. When a fish pulls line, the flag releases '
        'and pops up — signalling a strike from dozens of yards away. '
        'Tip-ups allow you to fish multiple holes simultaneously and are the primary '
        'method for targeting pike, walleye, and lake trout through the ice.',
    targetSpecies: [
      'Northern Pike', 'Walleye', 'Lake Trout',
      'Chain Pickerel', 'Whitefish',
    ],
    tips: 'Best seasons: Ice fishing season — midwinter through late ice. '
        'Tip-ups excel for pike because they present live bait naturally.\n\n'
        'Setup: '
        '1. Drill a hole and set the tip-up across it. '
        '2. Set the bait 1-3 ft off the bottom using a small float on the leader. '
        '3. Use live shiners, suckers, or chubs as bait (4-8" for pike). '
        '4. Set the spool tension so a fish can take line without feeling resistance.\n\n'
        'When the flag goes up: Walk (don\'t run) to the hole. '
        'Let the fish run for 5-10 seconds before setting the hook. '
        'If you set too early, you\'ll pull the bait away from the fish.\n\n'
        'Pro tip: Use a quick-strike rig (two hooks) for pike to improve hook-ups. '
        'Darken your hole with snow or a hole cover to reduce light penetration.\n\n'
        'Gear: Standard tip-up with 30-50 lb Dacron line on the spool, '
        '12-18" leader of 30-50 lb fluorocarbon or wire (for pike). '
        'Use a quick-strike rig for pike and a single hook for walleye.',
bestSeasons: ['winter'],
        icon: '🚩',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  FLY FISHING
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Dry Fly',
    category: 'Fly Fishing',
    description: 'A floating fly that imitates an adult insect resting on the water '
        'surface — mayflies, caddisflies, stoneflies, and terrestrials (ants, beetles, hoppers). '
        'Dry fly fishing is the most visual and arguably most rewarding form of fly fishing — '
        'you see the fish rise and take your fly. The fly is dressed with hackle and '
        'elk hair or deer hair to keep it floating. Success depends on matching the '
        'size, shape, and colour of the insects currently hatching ("matching the hatch").',
    targetSpecies: [
      'Rainbow Trout', 'Brown Trout', 'Brook Trout',
      'Cutthroat Trout', 'Arctic Grayling',
      'Smallmouth Bass',
    ],
    tips: 'Best seasons: Late spring through early fall when insect hatches are active. '
        'Prime times: Early morning (mayfly hatches) and evening (caddis hatches). '
        'Summer afternoons are great for terrestrial patterns (hoppers, ants).\n\n'
        'Matching the hatch:\n'
        '1. Observe the water — look for rising fish and adult insects in the air. '
        '2. Catch an insect to identify size and colour. '
        '3. Select a fly of similar size (hook size), profile, and colour. '
        '4. Fish size 12-16 for most mayflies, size 16-20 for midges, size 8-12 for hoppers.\n\n'
        'Presentation: '
        'Cast 2-4 ft above the rising fish. Mend line to achieve a dead-drift '
        '(the fly floats naturally with the current, no drag). '
        'Set the hook gently with a sideways sweep when you see the rise.\n\n'
        'Gear: 8\'6" to 9\' 4-6 weight fly rod, weight-forward floating line. '
        'A 9-12 ft 4X-6X leader tapers to a fine tippet for delicate presentations.',
bestSeasons: ['spring', 'summer', 'fall'],
    bestTimeOfDay: ['dawn', 'day', 'dusk'],
        icon: '🪰',
  ),
  TackleTypeInfo(
    name: 'Nymph',
    category: 'Fly Fishing',
    description: 'A weighted subsurface fly that imitates aquatic insect larvae '
        '(nymphs) living under the water — the immature stage of mayflies, stoneflies, '
        'caddisflies, and midges. Nymphs make up 80-90% of a trout\'s diet, so '
        'nymph fishing is the most consistently productive fly fishing method. '
        'Nymphs are fished below an indicator (strike indicator / bobber) or '
        'on a dead-drift with a tight line (Euro-nymphing).',
    targetSpecies: [
      'Rainbow Trout', 'Brown Trout', 'Brook Trout',
      'Cutthroat Trout', 'Steelhead',
      'Arctic Grayling',
    ],
    tips: 'Best seasons: Year-round — nymphs work in every season. '
        'Especially effective in early spring before hatches start and in winter '
        'when trout feed almost exclusively on nymphs.\n\n'
        'Indicator nymphing: '
        '1. Attach a strike indicator 1.5-2x the water depth above the fly. '
        '2. Add split shot 12-18" above the fly to get it down. '
        '3. Cast upstream and dead-drift through likely holding water. '
        '4. Watch the indicator — any pause, twitch, or sideways movement = set the hook.\n\n'
        'Euro-nymphing (tight-line): Use long leader (12-20 ft) with heavy nymphs. '
        'Keep the line tight and watch the sighter (coloured leader section). '
        'No indicator needed — any hesitation or twitch in the sighter = fish.\n\n'
        'Essential patterns: Pheasant Tail (size 14-18), Hare\'s Ear (12-16), '
        'Prince Nymph (12-14), Copper John (14-18), Zebra Midge (18-22).\n\n'
        'Gear: 9\' to 10\' 3-5 weight fly rod, weight-forward floating line. '
        'Euro-nymphing uses a longer rod (10-11\') with a specialised leader setup.',
    icon: '🪰',
  ),
  TackleTypeInfo(
    name: 'Streamer',
    category: 'Fly Fishing',
    description: 'A larger fly (2-8" long) that imitates baitfish, leeches, crayfish, '
        'or other large prey. Streamers are fished with an active strip retrieve rather '
        'than a dead-drift. They trigger reaction strikes from predatory fish. '
        'Streamer fishing covers water quickly and targets larger fish. '
        'Woolly Bugger is the most famous and versatile streamer pattern — '
        'it imitates a leech, baitfish, or crayfish depending on colour and retrieve.',
    targetSpecies: [
      'Rainbow Trout', 'Brown Trout', 'Northern Pike',
      'Muskellunge', 'Smallmouth Bass',
      'Striped Bass', 'Brook Trout',
    ],
    tips: 'Best seasons: Spring and fall when larger fish are feeding aggressively. '
        'Streamers are also effective in high water when baitfish get washed into currents. '
        'Night streamer fishing in summer can produce trophy brown trout.\n\n'
        'Retrieve: '
        '• Strip retrieve — pull line in short (4-12") strips with pauses between. '
        'The fly darts and pauses like a fleeing baitfish.\n'
        '• Swing — cast across stream and let the current swing the fly. '
        'Classic technique for Atlantic salmon and steelhead.\n'
        '• Figure-8 — slow, steady retrieve for cold water or finicky fish.\n\n'
        'Essential patterns: Woolly Bugger (olive, black, white — size 4-10), '
        'Muddler Minnow (size 4-8), Clouser Minnow (size 2-6), Zonker, '
        'and articulated streamers (6-8") for pike and muskie.\n\n'
        'Gear: 8\'6" to 9\' 6-8 weight fly rod, intermediate or sinking tip line. '
        'For pike/muskie: 9-10" 8-10 wt rod, wire leader, heavy-duty reel.',
bestSeasons: ['spring', 'fall'],
        icon: '🐟',
  ),

  // ═════════════════════════════════════════════════════════════════════
  //  SALTWATER
  // ═════════════════════════════════════════════════════════════════════
  TackleTypeInfo(
    name: 'Popping Cork Rig',
    category: 'Saltwater',
    description: 'A floating cork with a concave face (the "popping cork") rigged '
        'above a leader with a hook and bait or soft plastic below. When twitched, '
        'the cork "pops" and splashes — attracting fish with sound. The bait below '
        'the cork is presented naturally at a controlled depth. '
        'This is the single most effective inshore saltwater rig for redfish, '
        'speckled trout, and snook in shallow water.',
    targetSpecies: [
      'Redfish', 'Speckled Trout', 'Snook', 'Flounder',
    ],
    tips: 'Best seasons: Spring through fall in shallow estuaries and grass flats. '
        'Incoming tide over grass flats is the absolute best time.\n\n'
        'Rigging: '
        '1. Tie popping cork to main line. '
        '2. Add 18-36" fluorocarbon leader (20-30 lb). '
        '3. Tie a hook (2/0 to 4/0) or jig head. '
        '4. Tip with live shrimp, soft plastic, or cut bait.\n\n'
        'Retrieve: Pop the cork with sharp rod-tip twitches — pop-pop-pause. '
        'The pause lets the bait sink and triggers strikes. Vary the cadence until fish respond. '
        'Watch the cork — if it moves sideways or disappears underwater, set the hook.\n\n'
        'Cork types: Rattling corks have built-in beads that make noise. '
        'Slotted corks let you adjust leader length. '
        'Use a 1/4 oz cork for shallow water (1-3 ft), 3/8-1/2 oz for deeper.\n\n'
        'Gear: 7\' medium-heavy spinning rod, 15-20 lb braided main line, '
        '20-30 lb fluorocarbon leader. A high-speed reel helps pick up line quickly.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🪸',
  ),
  TackleTypeInfo(
    name: 'Bucktail Jig',
    category: 'Saltwater',
    description: 'A lead-head jig dressed with bucktail (deer hair) and often '
        'synthetic flash fibres. One of the oldest and most dependable saltwater lures. '
        'The bucktail breathes and pulses on the drop, imitating a baitfish or squid. '
        'Bucktail jigs can be hopped along the bottom, swam at mid-depth, '
        'or cast and retrieved. They work in both surf and bays year-round. '
        'White is the most famous colour — "white bucktail" is universally recognised '
        'as a striped bass killer.',
    targetSpecies: [
      'Striped Bass', 'Bluefish', 'Flounder', 'Redfish',
      'Cobia', 'King Mackerel', 'Spanish Mackerel',
      'Snook',
    ],
    tips: 'Best seasons: Year-round — bucktails work in every season. '
        'Spring and fall striped bass runs are prime time. '
        'Summer for flounder on the flats. Winter for deep-water holdovers.\n\n'
        'Retrieve: '
        '• Hop along the bottom — lift rod tip, let it fall back. Effective for flounder and stripers.\n'
        '• Slow swim — steady retrieve just off the bottom. Great for redfish and trout.\n'
        '• Fast retrieve — aggressive action for bluefish and mackerel.\n\n'
        'Pro tip: Add a soft plastic trailer (Gulp!, paddle tail) for extra scent and action. '
        'Use a stinger hook (small treble attached to the main hook) for short-striking fish.\n\n'
        'Sizes: 1/4-1/2 oz for inshore, 3/4-2 oz for surf and deep water.\n\n'
        'Colors: White (universal), chartreuse/white (stained water), '
        'all-yellow (flounder), and all-black (night fishing).\n\n'
        'Gear: 7\' to 8\' medium-heavy spinning rod, 15-30 lb braid. '
        'A fast-action rod provides good hook-setting power.',
    icon: '🪮',
  ),
  TackleTypeInfo(
    name: 'Trolling Spoon',
    category: 'Saltwater',
    description: 'A large metal spoon designed to be trolled behind a moving boat '
        'at speeds of 4-10 knots. The spoon wobbles and flashes, imitating a fleeing '
        'baitfish. Trolling spoons come in various sizes (4-12") and weights '
        '(1-8 oz) depending on target species and trolling depth. '
        'They are the go-to lure for offshore trolling for tuna, mackerel, '
        'and mahi mahi, as well as inshore trolling for striped bass and bluefish.',
    targetSpecies: [
      'King Mackerel', 'Spanish Mackerel', 'Mahi Mahi',
      'Bluefin Tuna', 'Yellowfin Tuna', 'Sailfish',
      'Striped Bass', 'Bluefish',
    ],
    tips: 'Best seasons: Late spring through fall when pelagic species are migrating. '
        'Tuna: summer through early fall. Mackerel: spring and fall runs.\n\n'
        'Trolling setup: '
        '• Use Planer boards or downriggers to reach desired depth. '
        '• Let out 50-150 ft of line behind the boat depending on depth and speed. '
        '• Trolling speed: 5-8 knots for most species, slower for striped bass.\n\n'
        'Pro tips: '
        '• Use wire or heavy fluorocarbon leader (40-80 lb) for toothy species. '
        '• Vary the distance behind the boat and the trolling speed until you find fish. '
        '• Use a stinger hook (daisy chain) for short-striking fish like mackerel.\n\n'
        'Spoon sizes: 3-4" for Spanish mackerel, 6-8" for king mackerel and mahi, '
        '8-12" for tuna and sailfish.\n\n'
        'Colors: Silver (best all-around), gold (stained water), chartreuse, '
        'and green/blue combinations for clear tropical water.\n\n'
        'Gear: Trolling rod (7-8\') with conventional reel, 30-50 lb braid. '
        'Use a wind-on leader for tuna. Heavy-duty outrigger clips for multiple lines.',
bestSeasons: ['spring', 'summer', 'fall'],
        icon: '🚤',
  ),
];

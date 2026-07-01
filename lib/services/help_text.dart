import 'package:flutter/material.dart';

/// Shows a help bottom sheet for the given [feature].
void showHelp(BuildContext context, String feature) {
  final entry = _helpEntries[feature];
  if (entry == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.of(ctx).padding.bottom + 40),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(entry.icon, size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(entry.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            entry.body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (entry.tips != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.tips!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Call this from any AppBar actions list to add a help button.
Widget helpButton(BuildContext context, String feature) {
  return IconButton(
    icon: const Icon(Icons.help_outline, size: 20),
    tooltip: 'How to use',
    onPressed: () => showHelp(context, feature),
  );
}

class _HelpEntry {
  final IconData icon;
  final String title;
  final String body;
  final String? tips;

  const _HelpEntry({
    required this.icon,
    required this.title,
    required this.body,
    this.tips,
  });
}

const _helpEntries = <String, _HelpEntry>{
  'catches': _HelpEntry(
    icon: Icons.set_meal,
    title: 'Catches',
    body: 'This is your fishing log — every catch you\'ve recorded '
        'appears here as a card with the species, angler, weight, length, '
        'location, weather, and photo.\n\n'
        '📱 **Manual:**\n'
        '• Tap a card to edit its details\n'
        '• Tap the + button to add a new catch\n'
        '• Swipe down to refresh\n'
        '• Tap the delete icon to remove a catch\n\n'
        '🎤 **Voice on this screen:**\n'
        '• Tap the **🎤 mic** at the bottom of the list\n'
        '• Say **\"[name] caught [species]\"** (no wake word needed)\n'
        '  Example: \"jason caught a 5 lb pike at Lake Erie\"\n'
        '• Add **location** with **at**, **from**, **in**, or **on**\n'
        '• Form opens with angler, species, location pre-filled\n'
        '• GPS coordinates auto-fetch in the background\n'
        '• Then say **\"photo\"**, **\"weighs...\"**, **\"length...\"**, **\"save\"**\n\n'
        '🎤 **Voice (from Counter tab):**\n'
        '1. Go to the **Counter** tab for tally-first workflow\n'
        '2. Say **\"fish buddy [name] caught [species]\"**\n'
        '3. Say **\"yes\"** when asked to log it',
    tips: 'Before your first catch, a sample card shows what a completed entry looks '
        'like with photo and details. It disappears once you record your first real catch!\n'
        'Location can be a lake/river name (\"at Lake St. Clair\") — GPS coordinates '
        'are auto-added too. All hands-free!',
  ),
  'counter': _HelpEntry(
    icon: Icons.people,
    title: 'Angler Counter & Voice Commands',
    body: 'Keep a running count of fish caught per angler during a fishing trip — '
        'fully hands-free with voice!\n\n'
        '📱 **Manual:**\n'
        '• Type an angler\'s name and tap "Add"\n'
        '• Tap + on a species to add one, or the - to remove\n'
        '• Tap "New Trip" to reset all counters to zero\n'
        '• Delete an angler with the trash icon\n'
        '• **Tap any species name** to edit/fix it (e.g. "pipe" → "pike")\n\n'
        '🎤 **Voice (hands-free):**\n'
        '• Tap the mic button to activate (turns red)\n'
        '• Say **"fish buddy [name] caught [species]"** to tally\n'
        '  Example: "fish buddy jason caught a pike"\n'
        '• The app asks **"Record this fish?"** — say **"yes"** or **"no"**\n'
        '• **"yes"** → opens Add Catch form with details pre-filled\n'
        '• **"no"** → just tally, ready for next fish\n'
        '• Say another "fish buddy…" command to tally the next fish\n'
        '• **Direct record**: say **"fish buddy record [name] caught [species]"**'
        ' to skip tally and open the form immediately\n'
        '• Add **location** with **at**, **from**, **in**, or **on**'
        ' (e.g. "jason caught a pike at Lake Michigan")',
    tips: 'The app learns from your edits! Fix a species name once (tap to edit)\n'
        'and future voice commands auto-correct. Example: edit "pipe" → "pike"\n'
        'once, then saying "fish buddy jason caught a pipe" auto-records as "pike".\n'
        'Only the 5 largest sizes are kept per species.\n'
        'Add location to any voice command with at/from/in/on.',
  ),
  'add_catch': _HelpEntry(
    icon: Icons.add_circle_outline,
    title: 'Add Catch (Voice Ready)',
    body: 'Record a full catch with photo, weight, length, location, and weather.\n'
        'GPS coordinates **auto-fetch** when the form opens!\n\n'
        '📱 **Manual:**\n'
        '• Fill in angler, species, location, lure, weight, length\n'
        '• Tap the photo area to take or choose a photo\n'
        '• GPS and weather auto-fill — no tapping needed\n'
        '• Tap "Save Catch" when done\n\n'
        '🎤 **Voice (hands-free):**\n'
        'Tap the **red mic button** at bottom-right, then say:\n'
        '• **"photo"** — opens selfie camera (front-facing, 3-2-1 countdown)\n'
        '• **"weighs 5 lb"** — fills the weight field\n'
        '• **"length 20 inches"** — fills the length field\n'
        '• **"save"** — saves the catch with auto GPS and weather\n'
        'The mic stays active — just say your next command!',
    tips: 'The selfie camera uses the front camera so you can hold the fish and snap. '
        'GPS and weather are automatic — just say "save" and everything is included!\n'
        'All voice commands work on all three screens: Catches, Counter, and this form.',
  ),
  'map': _HelpEntry(
    icon: Icons.map,
    title: 'Map',
    body: 'See all your catches plotted on a map. Each pin represents '
        'a catch location with the species name.\n\n'
        '• Tap a pin to see the species and angler\n'
        '• The map updates automatically when you add new catches\n'
        '• Pinch to zoom and pan around',
  ),
  'fish_id': _HelpEntry(
    icon: Icons.menu_book,
    title: 'Fish ID Field Guide',
    body: 'A comprehensive database of fish species with photos, '
        'descriptions, and fishing tips.\n\n'
        '• Search by common name, scientific name, or region\n'
        '• Filter by region tabs or water type chips\n'
        '• Sort by name, caught count, mastered, or favorites\n'
        '• Tap any fish to see full details, Wikipedia photo, and tips\n'
        '• Mark fish as caught, mastered, or add to wishlist\n'
        '• Tap + to add a custom fish species',
    tips: 'Use the sort feature to prioritise fish you haven\'t caught yet. '
        'Marking fish as "Mastered" tracks the species you\'ve become an expert at catching.',
  ),
  'add_fish': _HelpEntry(
    icon: Icons.add_circle_outline,
    title: 'Add a Fish',
    body: 'Add a custom fish species to the field guide.\n\n'
        '• Enter the common name (required)\n'
        '• Type a name and wait — the app auto-looks up Wikipedia for '
        'scientific name and description\n'
        '• Or tap the ✨ wand button to look up manually\n'
        '• Fill in region, water type, size, habitat, diet, tackle\n'
        '• Add a description and fishing tips\n'
        '• Tap "Add Fish" to save it to your custom list',
  ),
  'weather': _HelpEntry(
    icon: Icons.wb_sunny,
    title: 'Weather & Forecast',
    body: 'Current weather conditions and a 5-day forecast for your location.\n\n'
        '• Requires location access to get local weather\n'
        '• Shows temperature, conditions, humidity, and wind\n'
        '• The 5-day forecast gives you daily highs, lows, and conditions',
  ),
  'solunar': _HelpEntry(
    icon: Icons.nights_stay,
    title: 'Best Fishing Times',
    body: 'Solunar-based predictions for the best fishing periods today.\n\n'
        '⭐ **Today\'s Rating** — 0-10 score based on solunar & daylight overlap\n'
        '🌡️ **Current Conditions** — temp, wind direction with arrows, gusts, humidity, pressure\n'
        '🌙 **Moon Phase** — phase name, illumination %, age in days\n'
        '🌅 **Sunrise / Sunset** — approximated from your GPS location\n'
        '🌙 **Moonrise / Moonset** — displayed alongside solar times\n'
        '📊 **24-Hour Timeline** — visual bar showing major/minor periods\n'
        '• Major periods (2 hours each) — moon overhead & underfoot\n'
        '• Minor periods (1 hour each) — moonrise & moonset'
,    tips: 'Wind direction arrows help you choose which side of the lake to fish. '
        'Fish during major periods for the best results. '
        'New moon and full moon phases produce the most active feeding periods. '
        'Combine solunar times with dawn/dusk for peak action.',
  ),
  'calendar': _HelpEntry(
    icon: Icons.calendar_month,
    title: 'Calendar',
    body: 'View your catch history on a calendar heatmap.\n\n'
        '• Days with catches are highlighted — darker = more catches\n'
        '• Tap a day to see the catches recorded on that date\n'
        '• Use the month arrows to navigate between months',
  ),
  'gallery': _HelpEntry(
    icon: Icons.photo_library,
    title: 'Photo Gallery',
    body: 'Browse all photos from your catches in a grid view.\n\n'
        '• Tap any photo to view it full-screen\n'
        '• Photos are organised by the date they were taken',
  ),
  'stats': _HelpEntry(
    icon: Icons.bar_chart,
    title: 'Statistics & Achievements',
    body: 'See your fishing stats, personal records, and achievements.\n\n'
        '📊 **Stats:**\n'
        '• Total catch count\n'
        '• Species breakdown chart\n'
        '• Catches by month bar chart\n'
        '• Top anglers and locations\n'
        '• Heaviest & longest catches\n\n'
        '🏆 **Personal Records:**\n'
        '• Most caught species\n'
        '• Best month ever\n'
        '• Average fish per month\n\n'
        '⭐ **Achievements (Badges):**\n'
        '• First Catch, Double Digits, One-Trip Wonder\n'
        '• Species Collector / Hunter / Master\n'
        '• Master Angler, Legendary Angler\n'
        '• Big Catch, Monster Catch, Top Rod\n'
        'Earned automatically as you fish!\n\n'
        '📤 **Share** — tap the share icon to share your stats as an image',
  ),
  'tackle_box': _HelpEntry(
    icon: Icons.inventory_2,
    title: 'Tackle Box',
    body: 'Your personal collection of fishing tackle.\n\n'
        '• Tap + to add new tackle (3 ways):\n'
        '   🌟 Today\'s Pick — weather-based recommendations\n'
        '   📖 Browse Catalog — 30+ common lures & rigs\n'
        '   📸 Take Photo — snap your own tackle\n\n'
        '• Tap a tackle card to see full details, target species, and tips\n'
        '• Edit or delete with the icons on each card\n'
        '• Search and sort to find tackle quickly',
    tips: 'Build your tackle box from the catalog first — '
        'each entry comes pre-loaded with target species and fishing tips. '
        'Then add your own custom tackle with photos.',
  ),
  'todays_pick': _HelpEntry(
    icon: Icons.auto_awesome,
    title: 'Today\'s Pick',
    body: 'Get weather-aware tackle recommendations for your target species.\n\n'
        '1. Search for a fish species you want to catch\n'
        '2. Tap "Show Me What to Use"\n'
        '3. The app considers: season, time of day, current weather\n'
        '4. It scores each lure (0-10) and shows the best options\n'
        '5. Suggestions from your tackle box appear first (with ✓)\n'
        '6. Tap "Add to my tackle box" on catalog suggestions',
    tips: 'Cold weather (under 12°C)? Jigs and slow presentations score higher. '
        'Warm weather? Topwater and spinnerbaits get a boost. '
        'Overcast days are prime for topwater lures.',
  ),
  'catalog': _HelpEntry(
    icon: Icons.menu_book,
    title: 'Tackle Catalog',
    body: 'Browse 30+ common lure and tackle types, each with detailed '
        'information to help you fish them effectively.\n\n'
        '• Types are grouped by category (Spinnerbaits, Crankbaits, Jigs, etc.)\n'
        '• Tap any card to see full details, target species, and tips\n'
        '• Tap the + icon to add it to your tackle box\n'
        '• You\'ll be prompted to give it a custom name '
        '(e.g. "White Spinnerbait" vs "Chartreuse Spinnerbait")',
  ),
  'add_tackle': _HelpEntry(
    icon: Icons.camera_alt,
    title: 'Add Tackle',
    body: 'Add a custom tackle item with a photo.\n\n'
        '• Tap the camera area to take a photo of your lure\n'
        '• Tap "Select tackle type" to choose from the catalog\n'
        '• Selecting a type auto-fills: name, target species, and tips\n'
        '• Edit the species list to match your specific lure\n'
        '• Tap "Add to Tackle Box" to save it',
  ),
  'prepare': _HelpEntry(
    icon: Icons.checklist,
    title: 'Prepare for Fishing',
    body: 'A pre-trip checklist to make sure you\'re ready.\n\n'
        '✅ **Add Anglers** — tap for instructions on adding anglers\n'
        '✅ **Check Weather** — opens the 5-day forecast\n'
        '⭐ **Best Fishing Times** — today\'s solunar rating\n'
        '✅ **Set Up Tackle** — view and organize your tackle box\n'
        '✅ **Review Fish ID** — browse the fish field guide\n'
        '✅ **Check Map & Spots** — review saved fishing spots\n\n'
        '🎣 **Start New Trip** — resets all tallies and counters',
    tips: 'Items auto-check based on your data (e.g. anglers check once added). '
        'Use the summary card at the bottom to see your readiness at a glance.',
  ),
  'regulations': _HelpEntry(
    icon: Icons.description_outlined,
    title: 'Fishing Regulations',
    body: 'View official fishing regulations for all Canadian provinces and territories.\n\n'
        '• **Manitoba** (home province) — highlighted at top\n'
        '• **Provinces** — Ontario, Saskatchewan, Alberta, BC, Quebec\n'
        '• **Territories** — Yukon, NWT, Nunavut\n'
        '• **Atlantic** — New Brunswick, Nova Scotia, PEI, Newfoundland\n\n'
        'Tap any province to open its official fishing guide PDF in your browser.\n'
        'Always check local regulations before fishing — limits, sizes, and seasons vary.',
    tips: 'Regulations change annually. The links open the official government pages, so they\'re always up to date.',
  ),
  'about': _HelpEntry(
    icon: Icons.info_outline,
    title: 'About',
    body: 'App version, description, and tech stack information.\n\n'
        '• App version number\n'
        '• Feature overview\n'
        '• Built with: Flutter, Dart, SQLite, OpenStreetMap, more\n\n'
        'Tight Lines, Be Safe! 🎣',
  ),
  'cloud_sync': _HelpEntry(
    icon: Icons.cloud_outlined,
    title: 'Cloud Sync & Fish Together',
    body: 'Backup, sync, and fish with friends — all through the cloud.\n\n'
        '☁️ **Cloud Sync:**\n'
        '• **Upload to Cloud** — sends all catches to Firebase\n'
        '• **Download from Cloud** — pulls catches and merges locally\n'
        '• **Connect / Disconnect** — manual control\n'
        '• Anonymous auth — no login required\n'
        '• Photos not yet synced\n\n'
        '🎣 **Fish Together:**\n'
        '• **Start a Session** — get a shareable code (e.g. PIKE-73)\n'
        '• **Join a Session** — enter a buddy\'s code\n'
        '• **Real-time chat** — messages appear instantly\n'
        '• **Auto-share catches** — tallying posts to the session feed\n'
        '• **📍 Share Location** — sends GPS to the chat\n'
        '• **🚨 Emergency** — sends alert with coordinates\n'
        '• **Tap coordinates** — opens directions in maps',
    tips: 'Sync before switching devices. For sessions, share your code with a buddy '
        'and you\'re connected instantly — works across any distance! '
        'Location sharing requires GPS permission.',
  ),
  'contact': _HelpEntry(
    icon: Icons.mail_outline,
    title: 'Contact',
    body: 'Get in touch with Maison Louis Design.\n\n'
        '💡 **Suggest a Feature** — opens your email app with subject pre-filled\n'
        '🐛 **Report a Bug** — opens email with device info auto-included\n'
        '   (model, OS, app version, screen size) to help diagnose issues\n\n'
        'Your privacy is respected — no personal data is collected or shared.',
    tips: 'Bug reports auto-include your device model and app version so issues '
        'can be fixed faster. You control what additional info to write.',
  ),
};

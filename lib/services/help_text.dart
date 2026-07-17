import 'package:flutter/material.dart';
import 'translation_service.dart';

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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: Text(tr('gotIt')),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Colored, labeled help chip to place inside the page body.
/// Use this instead of [helpButton] for better visibility.
Widget helpChip(BuildContext context, String feature) {
  final color = Colors.red.shade600;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => showHelp(context, feature),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help, size: 22, color: color),
                const SizedBox(width: 10),
                Text(
                  tr('help'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Call this from any AppBar actions list to add a help button.
/// Consider using [helpChip] in the page body instead.
Widget helpButton(BuildContext context, String feature) {
  return IconButton(
    icon: const Icon(Icons.help_outline, size: 20),
    tooltip: tr('helpTooltip'),
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

Map<String, _HelpEntry> get _helpEntries => <String, _HelpEntry>{
  'catches': _HelpEntry(
    icon: Icons.set_meal,
    title: tr('helpCatches'),
    body: tr('helpBodyCatches'),
    tips: 'Before your first catch, a sample card shows what a completed entry looks '
        'like with photo and details. It disappears once you record your first real catch!\n'
        'Location can be a lake/river name (\"at Lake St. Clair\") — GPS coordinates '
        'are auto-added too. All hands-free!',
  ),
  'counter': _HelpEntry(
    icon: Icons.people,
    title: tr('helpCounter'),
    body: tr('helpBodyCounter'),
    tips: 'The app learns from your edits! Fix a species name once (tap to edit)\n'
        'and future voice commands auto-correct. Example: edit "pipe" → "pike"\n'
        'once, then saying "fish buddy jason caught a pipe" auto-records as "pike".\n'
        'Only the 5 largest sizes are kept per species.\n'
        'Add location to any voice command with at/from/in/on.',
  ),
  'add_catch': _HelpEntry(
    icon: Icons.add_circle_outline,
    title: tr('helpAddCatch'),
    body: tr('helpBodyAddCatch'),
    tips: 'The selfie camera uses the front camera so you can hold the fish and snap. '
        'GPS and weather are automatic — just say "save" and everything is included!\n'
        'All voice commands work on all three screens: Catches, Counter, and this form.',
  ),
  'map': _HelpEntry(
    icon: Icons.map,
    title: tr('helpMap'),
    body: tr('helpBodyMap'),
  ),
  'fish_id': _HelpEntry(
    icon: Icons.menu_book,
    title: tr('helpFishId'),
    body: tr('helpBodyFishId'),
    tips: 'Use the sort feature to prioritise fish you haven\'t caught yet. '
        'Marking fish as "Mastered" tracks the species you\'ve become an expert at catching.',
  ),
  'add_fish': _HelpEntry(
    icon: Icons.add_circle_outline,
    title: tr('helpAddFish'),
    body: tr('helpBodyAddFish'),
  ),
  'weather': _HelpEntry(
    icon: Icons.wb_sunny,
    title: tr('helpWeather'),
    body: tr('helpBodyWeather'),
  ),
  'solunar': _HelpEntry(
    icon: Icons.nights_stay,
    title: tr('helpSolunar'),
    body: tr('helpBodySolunar'),    tips: 'Wind direction arrows help you choose which side of the lake to fish. '
        'Fish during major periods for the best results. '
        'New moon and full moon phases produce the most active feeding periods. '
        'Combine solunar times with dawn/dusk for peak action.',
  ),
  'calendar': _HelpEntry(
    icon: Icons.calendar_month,
    title: tr('helpCalendar'),
    body: tr('helpBodyCalendar'),
  ),
  'gallery': _HelpEntry(
    icon: Icons.photo_library,
    title: tr('helpGallery'),
    body: tr('helpBodyGallery'),
  ),
  'stats': _HelpEntry(
    icon: Icons.bar_chart,
    title: tr('helpStats'),
    body: tr('helpBodyStats'),
  ),
  'tackle_box': _HelpEntry(
    icon: Icons.inventory_2,
    title: tr('helpTackleBox'),
    body: tr('helpBodyTackleBox'),
    tips: 'Build your tackle box from the catalog first — '
        'each entry comes pre-loaded with target species and fishing tips. '
        'Then add your own custom tackle with photos.',
  ),
  'todays_pick': _HelpEntry(
    icon: Icons.auto_awesome,
    title: tr('helpTodaysPick'),
    body: tr('helpBodyTodaysPick'),
    tips: 'Cold weather (under 12°C)? Jigs and slow presentations score higher. '
        'Warm weather? Topwater and spinnerbaits get a boost. '
        'Overcast days are prime for topwater lures.',
  ),
  'catalog': _HelpEntry(
    icon: Icons.menu_book,
    title: tr('helpCatalog'),
    body: tr('helpBodyCatalog'),
  ),
  'add_tackle': _HelpEntry(
    icon: Icons.camera_alt,
    title: tr('helpAddTackle'),
    body: tr('helpBodyAddTackle'),
  ),
  'prepare': _HelpEntry(
    icon: Icons.checklist,
    title: tr('helpPrepare'),
    body: tr('helpBodyPrepare'),
    tips: 'Items auto-check based on your data (e.g. anglers check once added). '
        'Use the summary card at the bottom to see your readiness at a glance.',
  ),
  'about': _HelpEntry(
    icon: Icons.info_outline,
    title: tr('helpAbout'),
    body: tr('helpBodyAbout'),
  ),
  'cloud_sync': _HelpEntry(
    icon: Icons.cloud_outlined,
    title: tr('helpCloudSync'),
    body: tr('helpBodyCloudSync'),
    tips: 'Sync before switching devices. For sessions, share your code with a buddy '
        'and you\'re connected instantly — works across any distance! '
        'Room owners can tap the people icon → Clear Chat to delete all messages. '
        'Long-press any message (including system messages) to delete — owners can delete anything. '
        'Location sharing requires GPS permission.',
  ),
  'settings': _HelpEntry(
    icon: Icons.settings_outlined,
    title: 'Settings',
    body: 'The Settings screen lets you manage your account, notifications, data, and preferences.\n\n'
        ' **Push Notifications** — Enable to receive weather alerts, best fishing time reminders, '
        'and Fish Together activity notifications.\n\n'
        '⏰ **Reminder Settings** — Schedule daily reminders to log your catches at 7 PM, '
        'or get a morning solunar alert at 6 AM with the best fishing times for the day.\n\n'
        ' **Export Data** — Export your catches as CSV (spreadsheets), JSON (backup), '
        'or KML (Google Earth) to share or back up your data.\n\n'
        ' **WiFi-only Mode** — Toggle this on to only allow data transfers (cloud sync, '
        'weather updates, map downloads) over WiFi, saving your mobile data.\n\n'
        ' **Log Out** — Sign out of your account. You can log back in anytime.\n\n'
        '️ **Delete Account** — Permanently delete your account and all your data. '
        'For security, you may need to log out and log back in before deleting.',
    tips: 'WiFi-only mode is great for saving mobile data when you\'re out on the water! '
        'Cloud sync will queue until you\'re back on WiFi.',
  ),
  'hands_free': _HelpEntry(
    icon: Icons.phonelink_setup,
    title: 'Hands-Free Setup',
    body: 'Get the most out of voice controls and the selfie camera by setting up your device thoughtfully.\n\n'
        ' **Easy Reach**\n'
        'Place your phone where you can reach it while holding a catch — within arm\'s length. '
        'You should be able to tap the screen or speak a command without putting down your rod.\n\n'
        ' **Camera Aim**\n'
        'Point the camera at the spot where you\'ll hold up fish for photos. '
        'Test the angle: when you hold a catch up, the camera should see both you and the fish. '
        'Adjust the phone\'s tilt so it\'s not shooting up your nose or pointing at the sky.\n\n'
        ' **Voice Pickup**\n'
        'Make sure the phone can hear you over wind, waves, engine noise, or auger. '
        'Say \"record\" from your fishing position — if it doesn\'t respond, move the phone closer.\n\n'
        ' **Test Before You Fish**\n'
        'Try different locations before you start:\n'
        '  • On a boat — dash, console, cupholder, or a RAM mount\n'
        '  • Ice fishing — on the shelter bench, a bucket, or hung from a string\n'
        '  • Shore fishing — propped on a rock, in a pack, or on a tripod\n\n'
        'A minute of setup saves frustration later. Find your spot and get the most out of CatchTales!',
    tips: 'If voice isn\'t working, try moving the phone closer or using a windscreen. '
        'For photos, a small tripod or phone mount with a gooseneck arm gives you the best angles.',
  ),
  'contact': _HelpEntry(
    icon: Icons.mail_outline,
    title: tr('helpContact'),
    body: tr('helpBodyContact'),
    tips: 'Bug reports auto-include your device model and app version so issues '
        'can be fixed faster. You control what additional info to write.',
  ),
  'import_export': _HelpEntry(
    icon: Icons.file_download,
    title: 'Export & Import Data',
    body: 'Export your catches as CSV, JSON, or KML files.\n\n'
        ' **CSV (Excel/Sheets)**\n'
        'Opens in any spreadsheet app. All fields included: species, weight, length, '
        'GPS coordinates, weather, notes, and more.\n'
        '• Use when: You want to analyze your data, sort by species, '
        'or create custom reports in Excel or Google Sheets.\n\n'
        ' **JSON (Backup)**\n'
        'Raw structured data — perfect for backups or transferring to another app.\n'
        '• Use when: You want a complete backup of all your catches, '
        'or plan to import them into another system.\n\n'
        ' **KML (Google Earth)**\n'
        'GPS coordinates formatted for Google Earth. See all your catch locations on a map.\n'
        '• Only includes catches with GPS coordinates.\n'
        '• Use when: You want to visualize where you\'ve been fishing, '
        'plan trips around productive spots, or share locations with friends.\n\n'
        ' **Date Range Filter**\n'
        'Filter by date range to export only specific trips or time periods.\n'
        'Useful for sharing a single trip\'s data or creating end-of-season reports.',
  ),
  'trips': _HelpEntry(
    icon: Icons.directions_boat_filled,
    title: tr('helpTrips'),
    body: tr('helpBodyTrips'),
  ),
  'community_stats': _HelpEntry(
    icon: Icons.people,
    title: tr('helpCommunityStats'),
    body: tr('helpBodyCommunityStats'),
    tips: 'Search results are powered by Google Places. Data is aggregated anonymously from '
        'fellow anglers — no personal information or exact locations are shared. '
        'Results improve as more anglers record their catches!',
  ),
  'brag_board': _HelpEntry(
    icon: Icons.emoji_events,
    title: ' Brag Board',
    body: 'Share your catches with the CatchTales community!\n\n'
        ' **Post a Catch** — Tap the camera icon to add a photo, species, location, '
        'and more info. You can crop the photo to remove unwanted background.\n\n'
        '️ **Like & Comment** — Tap a post to open details, then like or comment. '
        'Reply to comments by tapping "Reply".\n\n'
        ' **Trending** — Toggle between Latest and Hot to see the most engaged posts.\n\n'
        ' **Species Badges** — Rare or trophy fish get special badges like  Trophy or  Ancient.\n\n'
        ' **Share** — Open a post and tap the share icon to share it outside the app.\n\n'
        ' **Report** — Long-press a post or use the menu to report inappropriate content.',
    tips: 'Be respectful! The brag board is a community space. '
        'Report any content that violates fishing etiquette or is inappropriate.',
  ),
};

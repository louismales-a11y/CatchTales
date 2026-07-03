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
        ],
      ),
    ),
  );
}

/// Call this from any AppBar actions list to add a help button.
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
        'Location sharing requires GPS permission.',
  ),
  'contact': _HelpEntry(
    icon: Icons.mail_outline,
    title: tr('helpContact'),
    body: tr('helpBodyContact'),
    tips: 'Bug reports auto-include your device model and app version so issues '
        'can be fixed faster. You control what additional info to write.',
  ),
  'community_stats': _HelpEntry(
    icon: Icons.people,
    title: tr('helpCommunityStats'),
    body: tr('helpBodyCommunityStats'),
    tips: 'Search results are powered by Google Places. Data is aggregated anonymously from '
        'fellow anglers — no personal information or exact locations are shared. '
        'Results improve as more anglers record their catches!',
  ),
};

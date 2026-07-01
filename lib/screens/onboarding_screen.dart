import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a short walkthrough for new users.
/// Appears only once — dismissed after swipe or tap "Got it!".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.record_voice_over,
      title: 'Voice Tally',
      desc: 'Say "fish buddy jason caught a pike"\n'
          'to tally fish per angler.\n'
          'Then say "yes" or "no" to log it.',
    ),
    _OnboardPage(
      icon: Icons.add_circle_outline,
      title: 'Record a Catch',
      desc: 'Tap + or say "record jason caught a pike"\n'
          'to open the catch form.\n'
          'GPS & weather auto-fill!',
    ),
    _OnboardPage(
      icon: Icons.camera_alt_outlined,
      title: 'Voice in Forms',
      desc: 'Tap the red 🎤 in the catch form, then say:\n'
          '  • "photo" — selfie camera, 3-2-1 snap\n'
          '  • "weighs 5 lb" — fill weight\n'
          '  • "length 20 inches" — fill length\n'
          '  • "save" — done!',
    ),
    _OnboardPage(
      icon: Icons.checklist,
      title: 'Prepare for Fishing',
      desc: 'Tap **Prepare for Fishing** in the ⋮ menu\n'
          'for a pre-trip checklist:\n'
          '  ✅ Add anglers, check weather & solunar\n'
          '  ✅ Set up tackle, review fish ID\n'
          '  ✅ Check map spots, start new trip\n'
          'Everything you need before heading out!',
    ),
    _OnboardPage(
      icon: Icons.cloud,
      title: 'Cloud Sync & Fish Together',
      desc: '**Cloud Sync** (⋮ menu > Cloud Sync):\n'
          '  ☁️ Back up catches to the cloud\n'
          '  ⬆️ Upload / ⬇️ Download / 🔗 Connect\n'
          '  🔐 Anonymous auth — no login needed\n\n'
          '**Fish Together** (from Cloud Sync screen):\n'
          '  🎣 Start a session, share code with a buddy\n'
          '  💬 Real-time chat while fishing\n'
          '  📍 Share GPS location for emergencies\n'
          '  🚨 Emergency alerts with directions',
    ),
    _OnboardPage(
      icon: Icons.more_vert,
      title: 'More Features (⋮ menu)',
      desc: 'Tap the ⋮ menu (top-right) for:\n'
          '  🎣 Prepare for Fishing checklist\n'
          '  🌤️ Weather & 5-day forecast\n'
          '  🌙 Solunar w/ wind, gusts & marine\n'
          '  🐟 Fish ID Field Guide\n'
          '  🎣 Tackle Box & Catalog\n'
          '  📅 Calendar & Statistics\n'
          '  🖼️ Photo Gallery / 🌓 Dark mode\n'
          '  ℹ️ About & Contact / 💬 Suggest / 🐛 Report\n'
          '  ☁️ Cloud Sync & Fish Together',
    ),
    _OnboardPage(
      icon: Icons.help_outline,
      title: 'Help is Everywhere',
      desc: 'Tap ❓ (top-right) on any screen\n'
          'for detailed help on that feature.\n\n'
          'Have a great fishing trip! 🎣',
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _done,
                child: Text('Skip', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _pages[i].build(theme),
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_pages.length, (i) {
                      return Container(
                        width: i == _page ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  // Next / Got it
                  FilledButton(
                    onPressed: () {
                      if (_page < _pages.length - 1) {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _done();
                      }
                    },
                    child: Text(_page < _pages.length - 1 ? 'Next' : 'Got it!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String desc;
  final bool isLast;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.desc,
    this.isLast = false,
  });

  Widget build(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 44, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

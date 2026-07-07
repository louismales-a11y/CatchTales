import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../widgets/water_background.dart';

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

  static List<_OnboardPage> get _pages => [
    _OnboardPage(
      icon: Icons.record_voice_over,
      title: tr('onboardVoiceTally'),
      desc: tr('onboardDescVoiceTally'),
    ),
    _OnboardPage(
      icon: Icons.add_circle_outline,
      title: tr('onboardRecordCatch'),
      desc: tr('onboardDescRecordCatch'),
    ),
    _OnboardPage(
      icon: Icons.camera_alt_outlined,
      title: tr('onboardVoiceForms'),
      desc: tr('onboardDescVoiceForms'),
    ),
    _OnboardPage(
      icon: Icons.map,
      title: tr('onboardMap'),
      desc: tr('onboardDescMap'),
    ),
    _OnboardPage(
      icon: Icons.checklist,
      title: tr('onboardPrepare'),
      desc: tr('onboardDescPrepare'),
    ),
    _OnboardPage(
      icon: Icons.directions_boat_filled,
      title: tr('onboardTrips'),
      desc: tr('onboardDescTrips'),
    ),
    _OnboardPage(
      icon: Icons.people,
      title: tr('onboardCommunityStats'),
      desc: tr('onboardDescCommunityStats'),
    ),
    _OnboardPage(
      icon: Icons.wb_sunny,
      title: tr('onboardWeather'),
      desc: tr('onboardDescWeather'),
    ),
    _OnboardPage(
      icon: Icons.nights_stay,
      title: tr('onboardSolunar'),
      desc: tr('onboardDescSolunar'),
    ),
    _OnboardPage(
      icon: Icons.menu_book,
      title: tr('onboardFishId'),
      desc: tr('onboardDescFishId'),
    ),
    _OnboardPage(
      icon: Icons.set_meal,
      title: tr('onboardTackleBox'),
      desc: tr('onboardDescTackleBox'),
    ),
    _OnboardPage(
      icon: Icons.calendar_month,
      title: tr('onboardCalendar'),
      desc: tr('onboardDescCalendar'),
    ),
    _OnboardPage(
      icon: Icons.star,
      title: tr('onboardStats'),
      desc: tr('onboardDescStats'),
    ),
    _OnboardPage(
      icon: Icons.photo_library,
      title: tr('onboardGallery'),
      desc: tr('onboardDescGallery'),
    ),
    _OnboardPage(
      icon: Icons.cloud,
      title: tr('onboardCloudSync'),
      desc: tr('onboardDescCloudSync'),
    ),
    _OnboardPage(
      icon: Icons.more_vert,
      title: tr('onboardMoreFeatures'),
      desc: tr('onboardDescMoreFeatures'),
    ),
    _OnboardPage(
      icon: Icons.check_circle,
      title: tr('onboardHelp'),
      desc: tr('onboardDescHelp'),
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
      body: WaterBackground(
        showFish: true,
        overlayOpacity: 0.35,
        child: SafeArea(
          child: Column(
            children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _done,
                child: Text(tr('skip'), style: const TextStyle(color: Colors.white54)),
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_pages.length, (i) {
                        return Container(
                          width: i == _page ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? const Color(0xFF76FF03)
                              : Colors.white30,
                        ),
                      );
                    }),
                  ),
                  ),
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
                    child: Text(_page < _pages.length - 1 ? tr('next') : tr('gotIt')),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white70,
              ),
            ),
            if (isLast) ...[const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help, size: 22, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Need help? Tap the red \"? Help\" button\nat the bottom of any screen.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.red.shade800,
                        ),
                      ),
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
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/add_catch_screen.dart';
import 'screens/catches_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/map_screen.dart';
import 'screens/prepare_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/solunar_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/fish_id_screen.dart';
import 'services/cloud_sync_service.dart';
import 'services/notification_service.dart';
import 'services/translation_service.dart';
import 'services/pro_service.dart';
import 'services/catches_provider.dart';
import 'services/analytics_service.dart';
import 'services/api_config.dart';
import 'screens/about_screen.dart';
import 'screens/cloud_sync_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/tackle_box_screen.dart';
import 'screens/trip_screen.dart';
import 'screens/community_stats_screen.dart';
import 'screens/language_picker_screen.dart';
import 'services/help_text.dart';
import 'services/theme_provider.dart';
import 'services/connectivity_service.dart';
import 'services/trip_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';

// ─── 5 Color Schemes ──────────────────────────────────────────────────────

class _ThemeDef {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  const _ThemeDef({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

const _themes = <String, _ThemeDef>{
  'Ocean Blue': _ThemeDef(
    primary: Color(0xFF00BCD4),
    secondary: Color(0xFFE040FB),
    tertiary: Color(0xFF76FF03),
  ),
  'Forest Green': _ThemeDef(
    primary: Color(0xFF4CAF50),
    secondary: Color(0xFF8BC34A),
    tertiary: Color(0xFF795548),
  ),
  'Sunset Orange': _ThemeDef(
    primary: Color(0xFFFF9800),
    secondary: Color(0xFFFF5722),
    tertiary: Color(0xFFFFC107),
  ),
  'Midnight': _ThemeDef(
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFFE040FB),
    tertiary: Color(0xFF00E5FF),
  ),
  'Lakeside': _ThemeDef(
    primary: Color(0xFF26C6DA),
    secondary: Color(0xFF42A5F5),
    tertiary: Color(0xFF66BB6A),
  ),
};

class BestFishBuddyAppTest extends StatelessWidget {
  const BestFishBuddyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    context.watch<TranslationService>();
    return MaterialApp(
      title: ApiConfig.appDisplayName,
      debugShowCheckedModeBanner: false,
      checkerboardOffscreenLayers: false,
      checkerboardRasterCacheImages: false,
      showPerformanceOverlay: false,
      theme: _buildTheme(tp.themeName, Brightness.light),
      darkTheme: _buildTheme(tp.themeName, Brightness.dark),
      themeMode: tp.themeMode,
      home: const SplashScreenTest(),
    );
  }

  ThemeData _buildTheme(String themeName, Brightness brightness) {
    final def = _themes[themeName] ?? _themes.values.first;
    final dark = brightness == Brightness.dark;

    final scaffoldBg =
        dark ? const Color(0xFF060A14) : const Color(0xFFF0F4FF);
    final cardBg = dark
        ? const Color(0xFF0E1422).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final appBarBg = const Color(0xFF0A0E1A);
    final navBg = dark ? const Color(0xFF0A0E1A) : Colors.white;
    final onSurface =
        dark ? const Color(0xFFE0E6F0) : const Color(0xFF0A0E1A);

    final prim = dark ? _lighten(def.primary) : def.primary;
    final onPrim = dark ? def.primary.darken() : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: prim,
        onPrimary: onPrim,
        secondary: def.secondary,
        onSecondary:
            dark ? const Color(0xFF4A0072) : Colors.white,
        tertiary: def.tertiary,
        onTertiary: Colors.black,
        error: dark ? const Color(0xFFFF5252) : const Color(0xFFFF1744),
        onError: dark ? const Color(0xFF3E0014) : Colors.white,
        surface: cardBg,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: dark ? 0 : 2,
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.2 : 0.08),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: dark ? 8 : 0,
        backgroundColor: navBg,
        indicatorColor:
            prim.withValues(alpha: dark ? 0.12 : 0.08),
      ),
    );
  }

  /// Lighten a color for dark-mode primary.
  Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }
}

// Small extension to darken a color for onPrimary in dark mode.
extension on Color {
  Color darken() {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - 0.4).clamp(0.0, 1.0))
        .toColor();
  }
}

// ─── Splash Screen (Test version with language picker) ────────────────────────
class SplashScreenTest extends StatefulWidget {
  const SplashScreenTest({super.key});

  @override
  State<SplashScreenTest> createState() => _SplashScreenTestState();
}

class _SplashScreenTestState extends State<SplashScreenTest> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    TripService.instance.load();
    // Show device-kicked message if applicable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = AuthService.instance.logoutMessage;
      if (msg != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Session Ended'),
              ],
            ),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _loadVersion() async {
    String version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      if (mounted) setState(() => _version = version);
    } catch (_) {
      version = '1.0.0';
      if (mounted) setState(() => _version = version);
    }
    await CloudSyncService.instance.init();
    await NotificationService.instance.init();
    // What's new check
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString('last_version_seen');
    if (lastSeen != version) {
      await prefs.setString('last_version_seen', version);
      if (mounted) _showWhatsNew(version);
    }
  }

  void _showWhatsNew(String version) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text('What\'s New', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _whatsNewItem('🎣 Fishing Trips — find it in the ⋮ menu top-right'),
              _whatsNewItem('Swipe to delete catches with undo'),
              _whatsNewItem('Search/filter your catch list'),
              _whatsNewItem('Larger photo thumbnails + full-screen viewer'),
              _whatsNewItem('CSV, JSON & KML export in Import/Export screen'),
              _whatsNewItem('Haptic feedback on key actions'),
              _whatsNewItem('Offline indicator banner'),
              _whatsNewItem('Rate app prompt after 5 catches'),
              _whatsNewItem('Improved error messages throughout'),
              _whatsNewItem('Database performance optimizations'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _whatsNewItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨ ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2137),
              Color(0xFF0A1A2E),
              Color(0xFF06101E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: tp.isDark
                            ? tp.themeInfo.accent.withValues(alpha: 0.4)
                            : tp.themeInfo.accent.withValues(alpha: 0.4),
                        blurRadius: 30),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child:
                      Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Best Fish Buddy Pro',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF76FF03),
                    letterSpacing: 1.5,
                  )),
              const SizedBox(height: 6),
              const Text('For Bragging Rights!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 2),
              Text(context.watch<ProService>().isPro ? 'PRO-VERSION' : 'FREE-VERSION',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF76FF03),
                    letterSpacing: 4,
                  )),
              const SizedBox(height: 4),
              const Text('🇨🇦  🇺🇸',
                  style: TextStyle(fontSize: 20)),
              const Spacer(),
              Text(_version.isNotEmpty ? 'v$_version' : '',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final auth = AuthService.instance;
                      final prefs = await SharedPreferences.getInstance();

                      // If not logged in, show auth screen first
                      if (!auth.isLoggedIn) {
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
                        // After returning from auth, check if they logged in
                        if (!AuthService.instance.isLoggedIn) return;
                      }

                      // Show language picker on first launch
                      if (await TranslationService.isFirstLaunch()) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          useSafeArea: false,
                          builder: (_) => LanguagePickerScreen(
                            onComplete: () => Navigator.of(context).pop(),
                          ),
                        );
                      }

                      // Show onboarding first (if first launch)
                      if (!(prefs.getBool('onboarding_done') ?? false)) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          useSafeArea: false,
                          builder: (_) => const OnboardingScreen(),
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => const HomeScreenTest(),
                          transitionsBuilder:
                              (_, animation, _, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('CONTINUE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tp.themeInfo.accent,
                      foregroundColor: const Color(0xFF003544),
                      elevation: 8,
                      shadowColor:
                          tp.themeInfo.accent.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Home / Navigation Shell (Test version with translations) ──────────────────
class HomeScreenTest extends StatefulWidget {
  const HomeScreenTest({super.key});

  @override
  State<HomeScreenTest> createState() => _HomeScreenTestState();
}

class _HomeScreenTestState extends State<HomeScreenTest> {
  int _selectedIndex = 0;
  final _catchesKey = GlobalKey<CatchesScreenState>();
  final _mapKey = GlobalKey<MapScreenState>();

  List<Widget> get _screens => [
    CatchesScreen(key: _catchesKey),
    CounterScreen(),
    MapScreen(key: _mapKey),
  ];

  void _showThemePicker(BuildContext context, ThemeProvider tp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(tr('chooseTheme'),
                    style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 12),
                // Theme tiles
                ...ThemeProvider.themes.map((t) {
                  final active = tp.themeName == t.name;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: t.accent,
                      radius: 18,
                      child: active
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : Icon(t.icon,
                              color: Colors.white, size: 20),
                    ),
                    title: Text(t.name,
                        style: TextStyle(
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? t.accent
                              : theme.colorScheme.onSurface,
                        )),
                    trailing: active
                        ? Icon(Icons.check_circle,
                            color: t.accent, size: 22)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      tp.setTheme(t.name);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const Divider(height: 4),
                // Follow system toggle
                SwitchListTile(
                  title: const Text('Follow system'),
                  subtitle: tp.followSystem
                      ? Text('Uses your device settings',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                      : null,
                  secondary: Icon(
                    Icons.settings_brightness,
                    color: theme.colorScheme.primary,
                  ),
                  value: tp.followSystem,
                  onChanged: (v) {
                    tp.setFollowSystem(v);
                    Navigator.pop(ctx);
                  },
                ),
                // Manual dark mode toggle (disabled when following system)
                SwitchListTile(
                  title: Text(tr('darkMode')),
                  secondary: Icon(
                    tp.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: tp.followSystem
                        ? Colors.grey
                        : theme.colorScheme.primary,
                  ),
                  value: tp.followSystem ? false : tp.isDark,
                  onChanged: tp.followSystem
                      ? null
                      : (_) {
                          tp.toggleDark();
                          Navigator.pop(ctx);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final ts = TranslationService.instance;
        final current = ts.currentLang;
        final names = <String, String>{
          'en': 'English',
          'fr': 'Français',
          'es': 'Español',
          'de': 'Deutsch',
          'uk': 'Українська',
        };
        final flags = <String, String>{
          'en': '🇬🇧',
          'fr': '🇫🇷',
          'es': '🇪🇸',
          'de': '🇩🇪',
          'uk': '🇺🇦',
        };
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(tr('language'),
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 12),
                ...['en', 'fr', 'es', 'de', 'uk'].map((code) {
                  final active = current == code;
                  return ListTile(
                    leading: Text(flags[code] ?? '',
                        style: const TextStyle(fontSize: 28)),
                    title: Text(names[code] ?? code,
                        style: TextStyle(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        )),
                    trailing: active
                        ? Icon(Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () async {
                      await ts.setLanguage(code);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDevOptions(BuildContext context) {
    final pro = context.read<ProService>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.build, size: 20),
              SizedBox(width: 8),
              Text('Developer Options'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(pro.isPro ? 'Pro Mode: ON' : 'Pro Mode: OFF',
                      style: TextStyle(
                        fontSize: 14,
                        color: pro.isPro ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: pro.isPro ? FontWeight.w600 : FontWeight.w400,
                      )),
                  const Spacer(),
                  Switch(
                    value: pro.isPro,
                    onChanged: (v) async {
                      if (v) {
                        await ProService.instance.unlockPro();
                      } else {
                        await ProService.instance.resetToFree();
                      }
                      setSt(() {});
                    },
                  ),
                ],
              ),
              Text(
                pro.isPro
                    ? 'All Pro features unlocked \u2713'
                    : 'Free mode active \u2014 10 catch limit, no delete',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalkthrough(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setBool('onboarding_done', false);
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (_) => const OnboardingScreen(),
      );
      await prefs.setBool('onboarding_done', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreen('home');
    final tp = context.watch<ThemeProvider>();
    context.watch<TranslationService>();
    final accent = tp.themeInfo.accent;
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ApiConfig.appDisplayName, style: TextStyle(fontSize: Theme.of(context).textTheme.titleLarge?.fontSize)),
                Text(context.watch<ProService>().isPro ? tr('proVersion') : tr('freeVersion'),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                if (TripService.instance.isActive)
                  Text('🎣 ${TripService.instance.activeTrip}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
        actions: [
          // 3-dot menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: accent),
            onSelected: (value) {
              switch (value) {
                // ── Planning ──
                case 'prepare':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PrepareScreen()));
                  break;
                // ── Trips ──
                case 'trips':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TripScreen()));
                  break;
                case 'community_stats':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CommunityStatsScreen()));
                  break;
                case 'weather':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ForecastScreen()));
                  break;
                case 'solunar':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SolunarScreen()));
                  break;
                case 'fish_id':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const FishIdScreen()));
                  break;
                case 'tackle_box':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TackleBoxScreen()));
                  break;
                // ── History ──
                case 'calendar':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CalendarScreen()));
                  break;
                case 'stats':
                  if (!ProService.instance.isPro) {
                    ProService.showUpgradeDialog(context);
                    return;
                  }
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const StatsScreen()));
                  break;
                case 'gallery':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const GalleryScreen()));
                  break;
                // ── Appearance ──
                case 'dark_mode':
                  tp.toggleDark();
                  break;
                case 'theme':
                  _showThemePicker(context, tp);
                  break;
                case 'language':
                  _showLanguagePicker(context);
                  break;
                // ── Cloud ──
                case 'cloud_sync':
                  if (!ProService.instance.isPro) {
                    ProService.showUpgradeDialog(context);
                    return;
                  }
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CloudSyncScreen()));
                  break;
                // ── About & Contact ──
                case 'about':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen()));
                  break;
                case 'contact':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ContactScreen()));
                  break;
                // ── Admin Only ──
                case 'walkthrough':
                  _showWalkthrough(context);
                  break;
                case 'dev_options':
                  _showDevOptions(context);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              // ── Planning ──
              PopupMenuItem(
                value: 'prepare',
                child: ListTile(
                  leading: Icon(Icons.checklist),
                  title: Text(tr('prepare')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── Trips ──
              PopupMenuItem(
                value: 'trips',
                child: ListTile(
                  leading: Icon(Icons.directions_boat_filled, size: 20),
                  title: const Text('Fishing Trips', style: TextStyle(fontSize: 13)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'community_stats',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: const Text('Community Stats'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'weather',
                child: ListTile(
                  leading: Icon(Icons.wb_sunny),
                  title: Text(tr('weather')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'solunar',
                child: ListTile(
                  leading: Icon(Icons.nights_stay),
                  title: Text(tr('solunar')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'fish_id',
                child: ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text(tr('fishId')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'tackle_box',
                child: ListTile(
                  leading: Icon(Icons.set_meal),
                  title: Text(tr('tackleBox')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── History ──
              PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text(tr('calendar')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text(tr('statistics')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'gallery',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text(tr('gallery')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── Cloud ──
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'cloud_sync',
                child: ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text(tr('cloudSync')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── About & Contact ──
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(tr('about')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'contact',
                child: ListTile(
                  leading: Icon(Icons.mail_outline),
                  title: Text(tr('contact')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── Admin Only ──
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Admin Only',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              PopupMenuItem(
                value: 'walkthrough',
                child: ListTile(
                  leading: Icon(Icons.school, size: 20),
                  title: const Text('Show Walkthrough', style: TextStyle(fontSize: 13)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (ApiConfig.isDev)
                PopupMenuItem(
                  value: 'dev_options',
                  child: ListTile(
                    leading: Icon(Icons.build, size: 20),
                    title: const Text('Developer Options', style: TextStyle(fontSize: 13)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // ── Appearance ──
              PopupMenuItem(
                value: 'dark_mode',
                child: ListTile(
                  leading: Icon(tp.followSystem
                      ? Icons.settings_brightness
                      : (tp.isDark
                          ? Icons.light_mode
                          : Icons.dark_mode)),
                  title: Text(tp.followSystem
                      ? 'System (${tr('darkMode')})'
                      : (tp.isDark ? tr('lightMode') : tr('darkMode'))),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined, color: accent),
                  title: Text(tr('theme')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  leading: Icon(Icons.language, color: accent),
                  title: Text(tr('language')),
                  subtitle: Text(TranslationService.instance.currentLang),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Row(
            children: [
              // NavigationRail for tablets
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) {
                    if (i == 2 && !ProService.instance.isPro) {
                      ProService.showUpgradeDialog(context);
                      return;
                    }
                    setState(() => _selectedIndex = i);
                    if (i == 2) {
                      _mapKey.currentState?.loadCatches();
                    }
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.set_meal_outlined,
                          color: _selectedIndex == 0 ? accent : null),
                      selectedIcon:
                          Icon(Icons.set_meal, color: accent),
                      label: Text(tr('catches')),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outlined,
                          color: _selectedIndex == 1 ? accent : null),
                      selectedIcon:
                          Icon(Icons.people, color: accent),
                      label: Text(tr('counter')),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined,
                          color: _selectedIndex == 2 ? accent : null),
                      selectedIcon:
                          Icon(Icons.map, color: accent),
                      label: Text(tr('map')),
                    ),
                  ],
                ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Offline banner
                    if (!context.watch<ConnectivityService>().isOnline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: Colors.orange.shade800,
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('You are offline — some features may be limited',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _screens[_selectedIndex],
                    ),
                    helpChip(context, _selectedIndex == 0
                        ? 'catches'
                        : _selectedIndex == 1
                            ? 'counter'
                            : 'map'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                if (!ProService.instance.isPro) {
                  final count = await context.read<CatchesProvider>().getCatchCount();
                  if (count >= ProService.freeCatchLimit) {
                    if (context.mounted) {
                      ProService.showUpgradeDialog(context);
                    }
                    return;
                  }
                }
                if (!context.mounted) return;
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddCatchScreen()),
                );
                if (added == true) {
                  if (context.mounted) context.read<CatchesProvider>().loadCatches();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          if (isWide) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              if (i == 2 && !ProService.instance.isPro) {
                ProService.showUpgradeDialog(context);
                return;
              }
              setState(() => _selectedIndex = i);
              if (i == 2) {
                _mapKey.currentState?.loadCatches();
              }
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.set_meal_outlined,
                    color: _selectedIndex == 0 ? accent : null),
                selectedIcon:
                    Icon(Icons.set_meal, color: accent),
                label: tr('catches'),
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outlined,
                    color: _selectedIndex == 1 ? accent : null),
                selectedIcon:
                    Icon(Icons.people, color: accent),
                label: tr('counter'),
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined,
                    color: _selectedIndex == 2 ? accent : null),
                selectedIcon:
                    Icon(Icons.map, color: accent),
                label: tr('map'),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

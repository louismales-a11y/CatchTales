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
import 'screens/verify_email_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/brag_board_screen.dart';
import 'screens/session_screen.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'widgets/water_background.dart';

import 'screens/brag_admin_screen.dart';
import 'services/skin_service.dart';
import 'main.dart' as main_lib;
import 'screens/session_screen.dart' as session_screen;

Widget _withWater(Widget child) => SkinService.instance.isClassic
    ? child
    : WaterBackground(showFish: true, overlayOpacity: 0.6, child: child);

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

class CatchTalesApp extends StatelessWidget {
  const CatchTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    context.watch<TranslationService>();
    return ValueListenableBuilder<String>(
      valueListenable: SkinService.instance,
      builder: (ctx, skin, _) => MaterialApp(
      title: ApiConfig.appDisplayName,
      debugShowCheckedModeBanner: false,
      checkerboardOffscreenLayers: false,
      checkerboardRasterCacheImages: false,
      showPerformanceOverlay: false,
      theme: _buildTheme(tp.themeName, SkinService.instance.isClassic ? Brightness.light : Brightness.dark),
      darkTheme: _buildTheme(tp.themeName, Brightness.dark),
      themeMode: SkinService.instance.isClassic ? tp.themeMode : ThemeMode.dark,
      home: const SplashScreen(),
    ),
    );
  }

  ThemeData _buildTheme(String themeName, Brightness brightness) {
    final def = _themes[themeName] ?? _themes.values.first;
    final dark = brightness == Brightness.dark;

    final isFancy = SkinService.instance.isFancy;
    final scaffoldBg = isFancy
        ? Colors.transparent
        : (dark ? const Color(0xFF060A14) : const Color(0xFFF0F4FF));
    final cardBg = isFancy
        ? (dark
            ? const Color(0xFF0E1422).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.45))
        : (dark
            ? const Color(0xFF0E1422).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85));
    final appBarBg = const Color(0xFF0A0E1A);
    final navBg = dark ? const Color(0xFF0A0E1A) : Colors.white;
    final onSurface = isFancy
        ? (dark ? const Color(0xFFE0E6F0) : const Color(0xFF0A0E1A))
        : (dark ? const Color(0xFFE0E6F0) : const Color(0xFF1A1F36));

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
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: onSurface),
        labelLarge: TextStyle(color: onSurface),
        labelMedium: TextStyle(color: onSurface),
        labelSmall: TextStyle(color: onSurface),
        titleLarge: TextStyle(color: onSurface),
        titleMedium: TextStyle(color: onSurface),
        titleSmall: TextStyle(color: onSurface),
      ),
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
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF0D2137)),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF0D2137),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        labelTextStyle: WidgetStateProperty.resolveWith((_) {
          return const TextStyle(color: Colors.white, fontSize: 14);
        }),
        iconColor: Colors.white70,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 4,
        backgroundColor: const Color(0xFF0D2137),  // Deep blue
        indicatorColor: const Color(0xFF00BCD4).withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);
          }
          return TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return IconThemeData(color: Colors.white.withValues(alpha: 0.6), size: 24);
        }),
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
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    SkinService.instance.addListener(() { if (mounted) setState(() {}); });
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
              _whatsNewItem('🤖 AI Fish ID — identify species from photos!'),
              _whatsNewItem('🤖 AI Lake Insights — ask questions about your catches'),
              _whatsNewItem('🤖 AI Tackle Picks — smart lure recommendations'),
              _whatsNewItem('🏆 Brag Board — share catch photos, like & comment!'),
              _whatsNewItem('🌊 Dream skin — animated fish & underwater background'),
              _whatsNewItem('🎨 Classic skin — light/dark mode with theme picker'),
              _whatsNewItem('🛡️ Brag Board admin panel (dev builds)'),
              _whatsNewItem('🎣 Fishing Trips — find it in the ⋮ menu'),
              _whatsNewItem('Swipe to delete catches with undo'),
              _whatsNewItem('Search/filter your catch list'),
              _whatsNewItem('Larger photo thumbnails + full-screen viewer'),
              _whatsNewItem('CSV, JSON & KML export in Import/Export screen'),
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
      body: WaterBackground(
        showFish: true,
        
        child: Container(
        width: double.infinity,
        height: double.infinity,
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
              Text(ApiConfig.appDisplayName,
                  style: const TextStyle(
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
              Text(context.watch<ProService>().isPro
                  ? 'PRO-VERSION'
                  : (ApiConfig.isDev ? 'DEV-VERSION' : 'FREE-VERSION'),
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

                      // If email is not yet verified, show verification screen
                      if (auth.status == AuthStatus.emailVerificationPending) {
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VerifyEmailScreen(),
                          ),
                        );
                        // If they didn't verify, block access
                        if (!AuthService.instance.isLoggedIn) return;
                      }

                      // Show language picker on first launch — full screen
                      if (await TranslationService.isFirstLaunch()) {
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => LanguagePickerScreen(
                              onComplete: () => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      }

                      // Show onboarding first (if first launch) — full screen
                      if (!(prefs.getBool('onboarding_done') ?? false)) {
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => const OnboardingScreen(),
                          ),
                        );
                      }
                      if (!context.mounted) return;

                      // If launched from ChatActivity (separate window), go directly to the session dashboard
                      final pendingCode = main_lib.pendingChatSessionCode;
                      if (pendingCode != null && pendingCode.isNotEmpty) {
                        main_lib.pendingChatSessionCode = null; // Clear it
                        final srv = SessionService.instance;
                        srv.setCurrentSession(pendingCode);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => session_screen.SessionDashboard(code: pendingCode),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => const HomeScreen(),
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
      ),
    );
  }
}

// ─── Home / Navigation Shell (Test version with translations) ──────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _catchesKey = GlobalKey<CatchesScreenState>();
  final _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    SkinService.instance.addListener(_onSkinChanged);
  }

  @override
  void dispose() {
    SkinService.instance.removeListener(_onSkinChanged);
    super.dispose();
  }

  void _onSkinChanged() {
    if (mounted) setState(() {});
  }

  List<Widget> get _screens => [
    CatchesScreen(key: _catchesKey),
    CounterScreen(),
    BragBoardScreen(),
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
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(tr('chooseTheme'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...ThemeProvider.themes.map((t) {
                  final active = tp.themeName == t.name;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: t.accent, radius: 18,
                      child: active
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Icon(t.icon, color: Colors.white, size: 20),
                    ),
                    title: Text(t.name,
                        style: TextStyle(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? t.accent : theme.colorScheme.onSurface,
                        )),
                    trailing: active
                        ? Icon(Icons.check_circle, color: t.accent, size: 22) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () { tp.setTheme(t.name); Navigator.pop(ctx); },
                  );
                }),
                const Divider(height: 4),
                SwitchListTile(
                  title: const Text('Follow system'),
                  subtitle: tp.followSystem
                      ? Text('Uses your device settings', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                      : null,
                  secondary: Icon(Icons.settings_brightness, color: theme.colorScheme.primary),
                  value: tp.followSystem,
                  onChanged: (v) { tp.setFollowSystem(v); Navigator.pop(ctx); },
                ),
                SwitchListTile(
                  title: Text(tr('darkMode')),
                  secondary: Icon(
                    tp.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: tp.followSystem ? Colors.grey : theme.colorScheme.primary,
                  ),
                  value: tp.followSystem ? false : tp.isDark,
                  onChanged: tp.followSystem ? null : (_) { tp.toggleDark(); Navigator.pop(ctx); },
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BragAdminScreen()));
                  },
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: const Text('🛡️ Brag Board Admin'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade400, side: BorderSide(color: Colors.red.shade400)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showWalkthrough(context);
                  },
                  icon: const Icon(Icons.school, size: 18),
                  label: const Text('Show Walkthrough'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade400, side: BorderSide(color: Colors.blue.shade400)),
                ),
              ),
              const SizedBox(height: 12),
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
          // User profile avatar (when logged in)
          Consumer<AuthService>(
            builder: (ctx, auth, _) {
              if (!auth.isLoggedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => _withWater(const SettingsScreen())));
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withValues(alpha: 0.2),
                    backgroundImage: AuthService.imageProviderFor(auth.profilePhotoUrl),
                    child: auth.profilePhotoUrl.isEmpty
                        ? Text(
                            auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: accent,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
          // Session indicator (when active)
          Consumer<SessionService>(
            builder: (ctx, srv, _) {
              if (!srv.hasActiveSession) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => _withWater(const SessionScreen())));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade800.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups, size: 16, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text('Room', style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // 3-dot menu
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                surface: const Color(0xFF0D2137),
                onSurface: Colors.white,
                onSurfaceVariant: Colors.white70,
              ),
              cardColor: const Color(0xFF0D2137),
              popupMenuTheme: PopupMenuThemeData(
                color: const Color(0xFF0D2137),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                iconColor: Colors.white70,
              ),
              menuTheme: MenuThemeData(
                style: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(const Color(0xFF0D2137)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: accent),
            onSelected: (value) {
              switch (value) {
                // ── Planning ──
                case 'prepare':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const PrepareScreen())));
                  break;
                // ── Trips ──
                case 'trips':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const TripScreen())));
                  break;
                case 'community_stats':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const CommunityStatsScreen())));
                  break;
                case 'weather':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const ForecastScreen())));
                  break;
                case 'solunar':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const SolunarScreen())));
                  break;
                case 'fish_id':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const FishIdScreen())));
                  break;
                case 'tackle_box':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const TackleBoxScreen())));
                  break;
                // ── History ──
                case 'calendar':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const CalendarScreen())));
                  break;
                case 'stats':
                  if (!ProService.instance.isPro) {
                    ProService.showUpgradeDialog(context);
                    return;
                  }
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const StatsScreen())));
                  break;
                case 'gallery':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const GalleryScreen())));
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
                          builder: (_) => _withWater(const CloudSyncScreen())));
                  break;
                // ── Settings ──
                case 'settings':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const SettingsScreen())));
                  break;
                // ── About & Contact ──
                case 'about':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const AboutScreen())));
                  break;
                case 'contact':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => _withWater(const ContactScreen())));
                  break;
                // ── Admin Only ──
                // ── Skin Toggle ──
                case 'skin_dream':
                  SkinService.instance.setSkin('fancy');
                  break;
                case 'skin_classic':
                  SkinService.instance.setSkin('classic');
                  break;
                // ── Appearance (Classic skin only) ──
                case 'dark_mode':
                  if (!SkinService.instance.isFancy) tp.toggleDark();
                  break;
                case 'theme':
                  if (!SkinService.instance.isFancy) _showThemePicker(context, tp);
                  break;
                case 'dev_options':
                  _showDevOptions(context);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              // ── Planning (always first) ──
              const PopupMenuDivider(),
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
              // ── Community Stats ──
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
              // ── Settings ──
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // ── Skin mode ──
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                height: 28,
                child: Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Text('Skin mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                ),
              ),
              PopupMenuItem(
                value: 'skin_dream',
                child: ListTile(
                  leading: Icon(Icons.water_drop, size: 20, color: Colors.blue.shade400),
                  title: const Text('Dream', style: TextStyle(fontSize: 13)),
                  trailing: SkinService.instance.isFancy
                      ? Icon(Icons.check, size: 18, color: Colors.blue.shade400)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'skin_classic',
                child: ListTile(
                  leading: Icon(Icons.dark_mode, size: 20, color: Colors.grey.shade500),
                  title: const Text('Classic', style: TextStyle(fontSize: 13)),
                  trailing: SkinService.instance.isClassic
                      ? Icon(Icons.check, size: 18, color: Colors.grey.shade400)
                      : null,
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
              // ── Appearance (Classic skin only) ──
              if (SkinService.instance.isClassic)
                PopupMenuItem(
                  value: 'dark_mode',
                  child: ListTile(
                    leading: Icon(tp.followSystem
                        ? Icons.settings_brightness
                        : (tp.isDark ? Icons.light_mode : Icons.dark_mode)),
                    title: Text(tp.followSystem
                        ? 'System (${tr('darkMode')})'
                        : (tp.isDark ? tr('lightMode') : tr('darkMode'))),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (SkinService.instance.isClassic)
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    leading: Icon(Icons.palette_outlined, color: accent),
                    title: Text(tr('theme')),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // ── Developer Options ──
              if (ApiConfig.isDev)
                PopupMenuItem(
                  value: 'dev_options',
                  child: ListTile(
                    leading: Icon(Icons.build, size: 20),
                    title: const Text('🛠️ Developer Options', style: TextStyle(fontSize: 13)),
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
                    if (i == 3 && !ProService.instance.isPro) {
                      ProService.showUpgradeDialog(context);
                      return;
                    }
                    setState(() => _selectedIndex = i);
                    if (i == 3) {
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
                      icon: Icon(Icons.emoji_events_outlined,
                          color: _selectedIndex == 2 ? accent : null),
                      selectedIcon:
                          Icon(Icons.emoji_events, color: accent),
                      label: const Text('Brag Board'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined,
                          color: _selectedIndex == 3 ? accent : null),
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
                      child: _selectedIndex == 3
                          ? _screens[3]  // Map — no background
                          : WaterBackground(
                              showFish: true,
                              overlayOpacity: 0.4,
                              child: _screens[_selectedIndex],
                            ),
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
              if (i == 3 && !ProService.instance.isPro) {
                ProService.showUpgradeDialog(context);
                return;
              }
              setState(() => _selectedIndex = i);
              if (i == 3) {
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
                icon: Icon(Icons.emoji_events_outlined,
                    color: _selectedIndex == 2 ? accent : null),
                selectedIcon:
                    Icon(Icons.emoji_events, color: accent),
                label: 'Brag Board',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined,
                    color: _selectedIndex == 3 ? accent : null),
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

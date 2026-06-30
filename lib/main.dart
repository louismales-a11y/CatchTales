import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'screens/add_catch_screen.dart';
import 'screens/catches_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/solunar_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/fish_id_screen.dart';
import 'screens/tackle_box_screen.dart';
import 'services/help_text.dart';
import 'services/theme_provider.dart';
import 'services/widget_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BestFishBuddyApp(),
    ),
  );
}

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

class BestFishBuddyApp extends StatelessWidget {
  const BestFishBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Best Fish Buddy',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(tp.themeName, Brightness.light),
      darkTheme: _buildTheme(tp.themeName, Brightness.dark),
      themeMode: tp.themeMode,
      home: const SplashScreen(),
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

// ─── Splash Screen ────────────────────────────────────────────────────────────
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
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = '1.0.0');
    }
    // Update home screen widget with latest data
    WidgetService.updateWidget();
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
              const Text('Best Fish Buddy',
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
                    onPressed: () {
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
    );
  }
}

// ─── Home / Navigation Shell ──────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _catchesKey = GlobalKey<CatchesScreenState>();
  final _mapKey = GlobalKey<MapScreenState>();

  late final _screens = [
    CatchesScreen(key: _catchesKey),
    const CounterScreen(),
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
                Text('Choose Theme',
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
                // Dark mode toggle
                SwitchListTile(
                  title: const Text('Dark mode'),
                  secondary: Icon(
                    tp.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  value: tp.isDark,
                  onChanged: (_) {
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final accent = tp.themeInfo.accent;
    return Scaffold(
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
            const Text('Best Fish Buddy'),
          ],
        ),
        actions: [
          // Help
          helpButton(context, _selectedIndex == 0
              ? 'catches'
              : _selectedIndex == 1
                  ? 'counter'
                  : 'map'),
          // 3-dot menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: accent),
            onSelected: (value) {
              switch (value) {
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
                case 'calendar':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CalendarScreen()));
                  break;
                case 'gallery':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const GalleryScreen()));
                  break;
                case 'stats':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const StatsScreen()));
                  break;
                case 'dark_mode':
                  tp.toggleDark();
                  break;
                case 'tackle_box':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TackleBoxScreen()));
                  break;
                case 'theme':
                  _showThemePicker(context, tp);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'weather',
                child: ListTile(
                  leading: Icon(Icons.wb_sunny),
                  title: Text('Weather'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'solunar',
                child: ListTile(
                  leading: Icon(Icons.nights_stay),
                  title: Text('Best Fishing Times'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'fish_id',
                child: ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('Fish ID'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('Calendar'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Photo Gallery'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tackle_box',
                child: ListTile(
                  leading: Icon(Icons.set_meal),
                  title: Text('Tackle Box'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Statistics'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'dark_mode',
                child: ListTile(
                  leading: Icon(tp.isDark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  title: Text(tp.isDark ? 'Light mode' : 'Dark mode'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined, color: accent),
                  title: Text('Theme'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddCatchScreen()),
                );
                if (added == true) {
                  _catchesKey.currentState?.loadCatches();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
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
            label: 'Catches',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined,
                color: _selectedIndex == 1 ? accent : null),
            selectedIcon:
                Icon(Icons.people, color: accent),
            label: 'Counter',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined,
                color: _selectedIndex == 2 ? accent : null),
            selectedIcon:
                Icon(Icons.map, color: accent),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'screens/add_catch_screen.dart';
import 'screens/catches_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'services/database_service.dart';
import 'services/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BestFishBuddyApp(),
    ),
  );
}

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFFE040FB);
  static const Color tertiary = Color(0xFF76FF03);
}

class BestFishBuddyApp extends StatelessWidget {
  const BestFishBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Best Fish Buddy',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scaffoldBg = dark ? const Color(0xFF060A14) : const Color(0xFFF0F4FF);
    final cardBg = dark
        ? const Color(0xFF0E1422).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final appBarBg = const Color(0xFF0A0E1A);
    final navBg = dark ? const Color(0xFF0A0E1A) : Colors.white;
    final onSurface =
        dark ? const Color(0xFFE0E6F0) : const Color(0xFF0A0E1A);
    final prim = dark ? AppColors.primary : AppColors.primaryDark;
    final onPrim = dark ? const Color(0xFF003544) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: prim,
        onPrimary: onPrim,
        secondary: dark ? AppColors.secondary : AppColors.secondary,
        onSecondary: dark ? const Color(0xFF4A0072) : Colors.white,
        tertiary: dark ? AppColors.tertiary : AppColors.tertiary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: dark ? 8 : 0,
        backgroundColor: navBg,
        indicatorColor:
            AppColors.primary.withValues(alpha: dark ? 0.12 : 0.08),
      ),
    );
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
              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: tp.isDark
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.primaryDark.withValues(alpha: 0.4),
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
              // Version
              Text(_version.isNotEmpty ? 'v$_version' : '',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 10),
              // Continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const HomeScreen(),
                          transitionsBuilder:
                              (_, animation, __, child) =>
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF003544),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: const Center(
                child:
                    Icon(Icons.set_meal, size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Best Fish Buddy'),
          ],
        ),
        actions: [
          // Stats
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
            tooltip: 'Statistics',
          ),
          // Dark/light toggle
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: tp.isDark
                  ? const Icon(Icons.light_mode, key: ValueKey('light'))
                  : const Icon(Icons.dark_mode, key: ValueKey('dark')),
            ),
            onPressed: tp.toggle,
            tooltip: tp.isDark ? 'Switch to light' : 'Switch to dark',
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.set_meal_outlined),
            selectedIcon: Icon(Icons.set_meal),
            label: 'Catches',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Counter',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

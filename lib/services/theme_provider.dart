import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_name';
  static const List<ThemeInfo> themes = [
    ThemeInfo('Ocean Blue', Icons.water_drop, Color(0xFF00BCD4)),
    ThemeInfo('Forest Green', Icons.forest, Color(0xFF4CAF50)),
    ThemeInfo('Sunset Orange', Icons.wb_sunny, Color(0xFFFF9800)),
    ThemeInfo('Midnight', Icons.nightlight_round, Color(0xFF7C4DFF)),
    ThemeInfo('Lakeside', Icons.beach_access, Color(0xFF26C6DA)),
  ];

  String _themeName = themes.first.name;
  bool _dark = false;

  String get themeName => _themeName;
  ThemeInfo get themeInfo => themes.firstWhere((t) => t.name == _themeName,
      orElse: () => themes.first);
  bool get isDark => _dark;

  /// Returns [ThemeMode] based on current dark/light toggle.
  ThemeMode get themeMode => _dark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString(_key) ?? themes.first.name;
    _dark = prefs.getBool('${_key}_dark') ?? false;
    notifyListeners();
  }

  Future<void> setTheme(String name) async {
    if (!themes.any((t) => t.name == name)) return;
    _themeName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }

  Future<void> toggleDark() async {
    _dark = !_dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_key}_dark', _dark);
  }
}

class ThemeInfo {
  final String name;
  final IconData icon;
  final Color accent;

  const ThemeInfo(this.name, this.icon, this.accent);
}

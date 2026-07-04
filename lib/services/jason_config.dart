import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Toggle to switch between original app behavior and "Jason" fixes at runtime.
/// Works only in Dev/Jason builds (has toggle in About screen).
class JasonConfig extends ChangeNotifier {
  static final JasonConfig instance = JasonConfig._();
  JasonConfig._();

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('jason_mode') ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('jason_mode', v);
    notifyListeners();
  }
}

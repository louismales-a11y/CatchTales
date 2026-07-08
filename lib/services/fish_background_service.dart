import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple notifier for the animated fish background setting.
class FishBackgroundService extends ValueNotifier<bool> {
  static final FishBackgroundService instance = FishBackgroundService._();

  FishBackgroundService._() : super(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool('fish_background_enabled') ?? true;
  }

  Future<void> setEnabled(bool v) async {
    value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fish_background_enabled', v);
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two app skins:
/// - 'fancy': underwater background + swimming fish, dark mode locked
/// - 'classic': plain background, no fish, light/dark toggle available
class SkinService extends ValueNotifier<String> {
  static final SkinService instance = SkinService._();
  SkinService._() : super('fancy');

  bool get isFancy => value == 'fancy';
  bool get isClassic => value == 'classic';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString('app_skin') ?? 'fancy';
  }

  Future<void> setSkin(String skin) async {
    value = skin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_skin', skin);
  }
}

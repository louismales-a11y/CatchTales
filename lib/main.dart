import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/translation_service.dart';
import 'services/pro_service.dart';
import 'services/api_config.dart';
import 'services/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/jason_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();
  // Mark this as the test version so language features are enabled
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_test', true);
  // Load saved language preference
  await TranslationService.instance.loadLanguage();
  // Load Pro status
  await ProService.instance.load();
  // Load Jason config
  await JasonConfig.instance.load();
  // Auto-unlock Pro for Jason builds (so only Jason toggle matters)
  if (ApiConfig.isDev && !ProService.instance.isPro) {
    await ProService.instance.unlockPro();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<TranslationService>.value(value: TranslationService.instance),
        ChangeNotifierProvider<ProService>.value(value: ProService.instance),
      ],
      child: const BestFishBuddyAppTest(),
    ),
  );
}

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/translation_service.dart';
import 'services/pro_service.dart';
import 'services/api_config.dart';
import 'services/theme_provider.dart';
import 'services/catches_provider.dart';
import 'services/connectivity_service.dart';
import 'services/tts_service.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();
  // Hide system nav bar for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Mark this as the test version so language features are enabled
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_test', true);
  // Load saved language preference
  await TranslationService.instance.loadLanguage();
  // Load Pro status
  await ProService.instance.load();
  // Auto-unlock Pro for Dev builds
  if (ApiConfig.isDev && !ProService.instance.isPro) {
    await ProService.instance.unlockPro();
  }
  // Start connectivity monitoring
  ConnectivityService.instance.start();
  // Initialize TTS
  TtsService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CatchesProvider()..loadCatches()),
        ChangeNotifierProvider<TranslationService>.value(value: TranslationService.instance),
        ChangeNotifierProvider<ProService>.value(value: ProService.instance),
        ChangeNotifierProvider<ConnectivityService>.value(value: ConnectivityService.instance),
      ],
      child: const BestFishBuddyAppTest(),
    ),
  );
}

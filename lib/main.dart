import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/translation_service.dart';
import 'services/pro_service.dart';
import 'services/api_config.dart';
import 'services/theme_provider.dart';
import 'services/catches_provider.dart';
import 'services/connectivity_service.dart';
import 'services/tts_service.dart';
import 'services/local_notification_service.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'services/skin_service.dart';
import 'services/ai_service.dart';

/// Session code passed from ChatActivity (separate window).
/// Set via MethodChannel before the app runs.
String? pendingChatSessionCode;

/// MethodChannel for receiving session code from ChatActivity.
const _chatChannel = MethodChannel('com.catchtales.catchtales/chat');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();
  // Hide system nav bar for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Mark dev builds so language features are enabled during development
  final prefs = await SharedPreferences.getInstance();
  if (ApiConfig.isDev) {
    await prefs.setBool('is_test', true);
  }
  // Load saved language preference
  await TranslationService.instance.loadLanguage();
  // Load Pro status
  await ProService.instance.load();
  // Auto-unlock Pro for Dev builds
  if (ApiConfig.isDev && !ProService.instance.isPro) {
    await ProService.instance.unlockPro();
  }
  // Initialize Auth (checks for existing session)
  await AuthService.instance.init();
  // Start connectivity monitoring
  ConnectivityService.instance.start();
  // Initialize TTS
  TtsService.instance.init();
  // Initialize local notifications
  LocalNotificationService.instance.init();
  // Load skin preference
  await SkinService.instance.load();

  // Initialize AI service (non-blocking)
  AIService.instance.init();

  // Check if launched from ChatActivity (separate window)
  try {
    pendingChatSessionCode = await _chatChannel
        .invokeMethod<String>('getSessionCode')
        .timeout(const Duration(seconds: 2));
  } catch (_) {
    // Not launched from chat activity — normal start
    pendingChatSessionCode = null;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CatchesProvider()..loadCatches()),
        ChangeNotifierProvider<TranslationService>.value(value: TranslationService.instance),
        ChangeNotifierProvider<ProService>.value(value: ProService.instance),
        ChangeNotifierProvider<ConnectivityService>.value(value: ConnectivityService.instance),
        ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
        ChangeNotifierProvider<SessionService>.value(value: SessionService.instance),
      ],
      child: const CatchTalesApp(),
    ),
  );
}

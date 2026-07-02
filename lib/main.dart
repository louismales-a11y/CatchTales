import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/translation_service.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mark this as the test version so language features are enabled
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_test', true);
  // Load saved language preference
  await TranslationService.instance.loadLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<TranslationService>.value(value: TranslationService.instance),
      ],
      child: const BestFishBuddyAppTest(),
    ),
  );
}

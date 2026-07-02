import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Full-screen language picker shown on first launch (after splash, before onboarding).
class LanguagePickerScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const LanguagePickerScreen({super.key, required this.onComplete});

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  String _selected = 'en';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.language, size: 44, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text('Welcome!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Choose your language', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              // Language options
              _langOption('English', '🇬🇧', 'en'),
              _langOption('Français', '🇫🇷', 'fr'),
              _langOption('Español', '🇪🇸', 'es'),
              _langOption('Deutsch', '🇩🇪', 'de'),
              _langOption('Українська', '🇺🇦', 'uk'),
              const Spacer(flex: 3),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    await TranslationService.instance.setLanguage(_selected);
                    widget.onComplete();
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(String name, String flag, String code) {
    final selected = _selected == code;
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 32)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.circle_outlined),
        onTap: () => setState(() => _selected = code),
      ),
    );
  }
}

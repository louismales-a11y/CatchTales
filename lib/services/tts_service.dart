import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lightweight text-to-speech service for audio feedback.
///
/// Speaks short confirmation phrases after key actions.
/// Silently does nothing if TTS is unavailable (no crash risk).
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  FlutterTts? _tts;
  bool _available = false;
  bool _enabled = true;

  bool get enabled => _enabled;

  /// Initialize. Call once at app startup.
  Future<void> init() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setVolume(0.8);
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  /// Toggle TTS on/off.
  void toggle() {
    _enabled = !_enabled;
  }

  /// Speak a short phrase (fire-and-forget).
  Future<void> speak(String text) async {
    if (!_available || !_enabled || _tts == null) return;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (_) {
      // Silently fail — TTS is not critical
    }
  }
}

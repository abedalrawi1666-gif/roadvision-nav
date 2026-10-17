import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = false; // Opt-in, to avoid unexpected speech.

  Future<void> speak(String instruction) async {
    if (!enabled || instruction.trim().isEmpty) return;
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.48);
      await _tts.speak(instruction);
    } catch (_) {
      // Unsupported TTS voices are not fatal to navigation UI.
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    print("🗣️ VoiceService: Initializing...");
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4); 
      await _flutterTts.setVolume(1.0);
      print("🗣️ VoiceService: Ready.");
    } catch (e) {
      print("🗣️ VoiceService Init Error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    print("🗣️ VoiceService: speak() called with: $text");
    try {
      await _flutterTts.speak(text);
      print("🗣️ VoiceService: speak() command sent.");
    } catch (e) {
      print("🗣️ VoiceService Error during speak: $e");
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

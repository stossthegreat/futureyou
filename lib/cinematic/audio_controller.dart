import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioController {
  final _musicPlayer = AudioPlayer();
  final _tts = FlutterTts();
  final double _baseVolume = 0.6;
  final double _duckVolume = 0.2;

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (e) {
      // TTS init failed, continue without voice
    }
  }

  Future<void> playMusic(String asset) async {
    try {
      await _musicPlayer.setAsset(asset);
      await _musicPlayer.setVolume(_baseVolume);
      await _musicPlayer.setLoopMode(LoopMode.one);
      _musicPlayer.play();
    } catch (e) {
      // Silent fail for missing assets
    }
  }

  Future<void> speak(String text) async {
    try {
      // Duck music
      await _musicPlayer.setVolume(_duckVolume);

      // Speak
      await _tts.speak(text);

      // Wait for completion (rough estimate)
      await Future.delayed(Duration(seconds: text.length ~/ 20));

      // Restore music
      await _musicPlayer.setVolume(_baseVolume);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> stopTTS() async {
    try {
      await _tts.stop();
      await _musicPlayer.setVolume(_baseVolume);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
    } catch (e) {
      // Silent fail
    }
  }
}


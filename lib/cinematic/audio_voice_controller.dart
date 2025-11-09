import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioVoiceController {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  
  bool _musicEnabled = true;
  bool _voiceEnabled = true;
  double _voiceSpeed = 1.0;
  
  static const double _musicVolBase = 0.6;
  static const double _musicVolDucked = 0.2;
  
  bool get musicEnabled => _musicEnabled;
  bool get voiceEnabled => _voiceEnabled;
  double get voiceSpeed => _voiceSpeed;
  
  Future<void> init() async {
    await _musicPlayer.setLoopMode(LoopMode.one);
    
    // Configure TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_voiceSpeed);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    if (!kIsWeb) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );
    }
  }
  
  Future<void> playMusic(String assetPath) async {
    if (!_musicEnabled) return;
    
    try {
      await _musicPlayer.setAsset(assetPath);
      await _musicPlayer.setVolume(_musicVolBase);
      await _musicPlayer.play();
    } catch (e) {
      debugPrint('Music playback error: $e');
    }
  }
  
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
  
  Future<void> crossfadeMusic(String newAssetPath) async {
    if (!_musicEnabled) return;
    
    // Fade out current
    for (double vol = _musicVolBase; vol >= 0; vol -= 0.1) {
      await _musicPlayer.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 60));
    }
    
    // Switch track
    await _musicPlayer.setAsset(newAssetPath);
    await _musicPlayer.play();
    
    // Fade in new
    for (double vol = 0; vol <= _musicVolBase; vol += 0.1) {
      await _musicPlayer.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }
  
  Future<void> duckMusic() async {
    await _musicPlayer.setVolume(_musicVolDucked);
  }
  
  Future<void> unduckMusic() async {
    await _musicPlayer.setVolume(_musicVolBase);
  }
  
  Future<void> speakText(String text, {VoidCallback? onComplete}) async {
    if (!_voiceEnabled) {
      onComplete?.call();
      return;
    }
    
    // Duck music during speech
    await duckMusic();
    
    // Set up completion handler
    _tts.setCompletionHandler(() {
      unduckMusic();
      onComplete?.call();
    });
    
    await _tts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _tts.stop();
    await unduckMusic();
  }
  
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }
  
  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled) {
      stopSpeaking();
    }
  }
  
  Future<void> setVoiceSpeed(double speed) async {
    _voiceSpeed = speed;
    await _tts.setSpeechRate(speed);
  }
  
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _tts.stop();
  }
}


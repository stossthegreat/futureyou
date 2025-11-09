import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cinematic_scene.dart';
import 'cinematic_book.dart';
import 'cinematic_api_mock.dart';
import 'audio_voice_controller.dart';
import 'phase_model.dart';

class CinematicScreen extends StatefulWidget {
  const CinematicScreen({Key? key}) : super(key: key);

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen> {
  late PageController _pageController;
  late AudioVoiceController _audioController;
  int _currentPhaseIndex = 0;
  
  bool _musicEnabled = true;
  bool _voiceEnabled = true;
  double _voiceSpeed = 1.0;
  bool _autoAdvance = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _audioController = AudioVoiceController();
    _audioController.init();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('cinematic_music') ?? true;
      _voiceEnabled = prefs.getBool('cinematic_voice') ?? true;
      _voiceSpeed = prefs.getDouble('cinematic_speed') ?? 1.0;
      _autoAdvance = prefs.getBool('cinematic_auto') ?? false;
    });
    
    _audioController.setMusicEnabled(_musicEnabled);
    _audioController.setVoiceEnabled(_voiceEnabled);
    _audioController.setVoiceSpeed(_voiceSpeed);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cinematic_music', _musicEnabled);
    await prefs.setBool('cinematic_voice', _voiceEnabled);
    await prefs.setDouble('cinematic_speed', _voiceSpeed);
    await prefs.setBool('cinematic_auto', _autoAdvance);
  }

  void _onNextPhase() {
    if (_currentPhaseIndex < FuturePhase.values.length - 1) {
      setState(() {
        _currentPhaseIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      
      // Crossfade music
      final nextPhase = FuturePhase.values[_currentPhaseIndex];
      _audioController.crossfadeMusic(nextPhase.musicFile);
    } else {
      // Show book compilation
      _showBookCompilation();
    }
  }

  void _showBookCompilation() {
    // Collect all chapters
    final chapters = <String, String>{};
    for (final phase in FuturePhase.values) {
      chapters[phase.title] = CinematicApiMock.getChapterContent(phase);
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CinematicBook(
          chapters: chapters,
          audioController: _audioController,
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Music toggle
              SwitchListTile(
                title: const Text(
                  'Background Music',
                  style: TextStyle(color: Colors.white),
                ),
                value: _musicEnabled,
                onChanged: (value) {
                  setState(() {
                    _musicEnabled = value;
                  });
                  _audioController.setMusicEnabled(value);
                  _saveSettings();
                },
                activeColor: Colors.green,
              ),
              
              // Voice toggle
              SwitchListTile(
                title: const Text(
                  'Voice Narration',
                  style: TextStyle(color: Colors.white),
                ),
                value: _voiceEnabled,
                onChanged: (value) {
                  setState(() {
                    _voiceEnabled = value;
                  });
                  _audioController.setVoiceEnabled(value);
                  _saveSettings();
                },
                activeColor: Colors.green,
              ),
              
              // Voice speed slider
              ListTile(
                title: const Text(
                  'Narration Speed',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Slider(
                  value: _voiceSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${_voiceSpeed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() {
                      _voiceSpeed = value;
                    });
                    _audioController.setVoiceSpeed(value);
                    _saveSettings();
                  },
                  activeColor: Colors.green,
                ),
              ),
              
              // Auto-advance toggle
              SwitchListTile(
                title: const Text(
                  'Auto-Advance',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Automatically move to next chapter',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: _autoAdvance,
                onChanged: (value) {
                  setState(() {
                    _autoAdvance = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Phase ${_currentPhaseIndex + 1} of ${FuturePhase.values.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: FuturePhase.values.length,
        onPageChanged: (index) {
          setState(() {
            _currentPhaseIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final phase = FuturePhase.values[index];
          return CinematicScene(
            title: phase.title,
            body: CinematicApiMock.getChapterContent(phase),
            phase: phase,
            controller: _audioController,
            onNext: _onNextPhase,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioController.dispose();
    super.dispose();
  }
}


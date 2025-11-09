import 'package:flutter/material.dart';
import 'cinematic_particles.dart';
import 'cinematic_typing.dart';
import 'audio_voice_controller.dart';
import 'phase_model.dart';

enum SceneState { particles, typing, complete }

class CinematicScene extends StatefulWidget {
  final String title;
  final String body;
  final FuturePhase phase;
  final AudioVoiceController controller;
  final VoidCallback? onNext;
  
  const CinematicScene({
    Key? key,
    required this.title,
    required this.body,
    required this.phase,
    required this.controller,
    this.onNext,
  }) : super(key: key);

  @override
  State<CinematicScene> createState() => _CinematicSceneState();
}

class _CinematicSceneState extends State<CinematicScene> {
  SceneState _state = SceneState.particles;
  final GlobalKey<CinematicTypingState> _typingKey = GlobalKey();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    // Start music for this phase
    widget.controller.playMusic(widget.phase.musicFile);
  }

  void _onParticlesFinished() {
    if (mounted) {
      setState(() {
        _state = SceneState.typing;
      });
    }
  }

  void _onTypingFinished() {
    if (mounted) {
      setState(() {
        _state = SceneState.complete;
      });
    }
  }

  void _onSkipTyping() {
    if (mounted) {
      setState(() {
        _state = SceneState.complete;
      });
    }
  }

  void _startNarration() {
    if (_isSpeaking) {
      // Stop narration
      widget.controller.stopSpeaking();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      // Start narration
      setState(() {
        _isSpeaking = true;
      });
      widget.controller.speakText(
        widget.body,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Content area
                Expanded(
                  child: _buildContent(),
                ),
                
                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip narration button (only when typing complete)
                      if (_state == SceneState.complete && widget.controller.voiceEnabled)
                        TextButton.icon(
                          onPressed: _startNarration,
                          icon: Icon(
                            _isSpeaking ? Icons.stop : Icons.volume_up,
                            color: Colors.white70,
                          ),
                          label: Text(
                            _isSpeaking ? 'Stop' : 'Read Aloud',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      
                      // Next button (only when complete)
                      if (_state == SceneState.complete && widget.onNext != null)
                        ElevatedButton.icon(
                          onPressed: widget.onNext,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case SceneState.particles:
        return Center(
          child: CinematicParticles(
            onFinished: _onParticlesFinished,
          ),
        );
      
      case SceneState.typing:
      case SceneState.complete:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: CinematicTyping(
            key: _typingKey,
            text: widget.body,
            wordsPerMinute: 14.0,
            onFinished: _onTypingFinished,
            onSkip: _onSkipTyping,
          ),
        );
    }
  }

  @override
  void dispose() {
    if (_isSpeaking) {
      widget.controller.stopSpeaking();
    }
    super.dispose();
  }
}


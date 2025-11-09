import 'package:flutter/material.dart';
import 'cinematic_intro.dart';
import 'cinematic_chat.dart';
import 'chapter_display.dart';
import 'cinematic_particles.dart';
import 'audio_controller.dart';
import 'phase_model.dart';
import '../services/api_client.dart';

enum PhaseState { intro, chat, chapter, complete }

class CinematicPhaseScene extends StatefulWidget {
  final FuturePhase phase;
  final AudioController audioController;
  final VoidCallback onComplete;

  const CinematicPhaseScene({
    super.key,
    required this.phase,
    required this.audioController,
    required this.onComplete,
  });

  @override
  State<CinematicPhaseScene> createState() => _CinematicPhaseSceneState();
}

class _CinematicPhaseSceneState extends State<CinematicPhaseScene> {
  PhaseState _state = PhaseState.intro;
  // Conversation stored for transcript generation
  List<Map<String, String>> _conversation = [];
  Map<String, dynamic>? _generatedChapter;

  @override
  void initState() {
    super.initState();
    widget.audioController.playMusic(widget.phase.musicAsset);
  }

  void _onIntroComplete() {
    setState(() {
      _state = PhaseState.chat;
    });
  }

  Future<void> _onChatComplete(List<Map<String, String>> conversation) async {
    setState(() {
      _conversation = conversation;
      _state = PhaseState.chapter;
    });

    // Generate chapter from conversation
    try {
      final response = await ApiClient.generateChapter(
        phase: widget.phase.apiName,
        title: widget.phase.title,
        body: _buildTranscript(conversation),
      );

      if (response.success && response.data != null) {
        setState(() {
          _generatedChapter = response.data!['chapter'];
        });
      }
    } catch (e) {
      debugPrint('❌ Chapter generation failed: $e');
      // Fallback to mock
      setState(() {
        _generatedChapter = {
          'title': widget.phase.title,
          'bodyMd': 'Your personal chapter will appear here...',
          'words': 0,
        };
      });
    }
  }

  String _buildTranscript(List<Map<String, String>> convo) {
    return convo.map((msg) => '${msg['role']}: ${msg['text']}').join('\n\n');
  }

  void _onChapterComplete() {
    setState(() {
      _state = PhaseState.complete;
    });
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
                colors: [
                  widget.phase.gradientStart.withOpacity(0.3),
                  widget.phase.gradientEnd.withOpacity(0.3),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Particles
          const CinematicParticles(),

          // Content based on state
          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case PhaseState.intro:
        return CinematicIntro(
          phase: widget.phase,
          audioController: widget.audioController,
          onComplete: _onIntroComplete,
        );

      case PhaseState.chat:
        return CinematicChat(
          phase: widget.phase,
          onComplete: _onChatComplete,
        );

      case PhaseState.chapter:
        if (_generatedChapter == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Generating your chapter...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ChapterDisplay(
          chapter: _generatedChapter!,
          audioController: widget.audioController,
          onComplete: _onChapterComplete,
        );

      case PhaseState.complete:
        return Center(
          child: ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.phase.gradientEnd,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Next Chapter →',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }
}


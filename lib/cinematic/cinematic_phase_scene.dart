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

    // Generate chapter from conversation with timeout
    try {
      final response = await ApiClient.generateChapter(
        phase: widget.phase.apiName,
        title: widget.phase.title,
        body: _buildTranscript(conversation),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Chapter generation timed out, using fallback');
          throw TimeoutException('Chapter generation timed out');
        },
      );

      if (response.success && response.data != null) {
        final chapter = response.data!['chapter'];
        if (chapter != null) {
          setState(() {
            _generatedChapter = {
              'title': chapter['title'] ?? widget.phase.title,
              'bodyMd': chapter['bodyMd'] ?? chapter['body'] ?? 'Your chapter is being written...',
              'words': chapter['words'] ?? 0,
            };
          });
        } else {
          throw Exception('No chapter data in response');
        }
      } else {
        throw Exception('Chapter generation failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('❌ Chapter generation failed: $e');
      // Fallback to mock with beautiful prose
      final fallbackProse = _generateFallbackChapter(conversation);
      setState(() {
        _generatedChapter = {
          'title': widget.phase.title,
          'bodyMd': fallbackProse,
          'words': fallbackProse.split(' ').length,
        };
      });
    }
  }

  String _generateFallbackChapter(List<Map<String, String>> convo) {
    // Create a beautiful fallback chapter from the conversation
    final userMessages = convo.where((m) => m['role'] == 'user').map((m) => m['text']).toList();
    
    return '''# ${widget.phase.title}

In the quiet moments of reflection, a journey begins. ${userMessages.isNotEmpty ? userMessages.first : 'The path ahead is unclear, but the first step has been taken.'}

${userMessages.length > 1 ? userMessages[1] : 'Every great transformation starts with a single question: What if?'}

The answers are not found in grand gestures, but in the small, deliberate choices we make each day. This is not the end of the story, but merely the beginning of a new chapter.

${userMessages.length > 2 ? userMessages.last : 'The future is being written, one moment at a time.'}''';
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  'Your coach is reflecting...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Writing your personal chapter',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
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


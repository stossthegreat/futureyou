import 'package:flutter/material.dart';
import '../models/chapter_model.dart';
import '../widgets/cinematic_intro.dart';
import '../widgets/deep_chat.dart';
import '../widgets/chapter_prose_display.dart';
import '../services/lifetask_api.dart';

/// CHAPTER SCREEN
/// 
/// The main container for a chapter experience:
/// 1. Cinematic Intro (90 seconds)
/// 2. Deep Chat (1-2 hours)
/// 3. Chapter Display (generated prose)

enum ChapterPhase {
  intro,
  chat,
  complete,
}

class ChapterScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterScreen({
    Key? key,
    required this.chapter,
  }) : super(key: key);

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  late Chapter currentChapter;
  ChapterPhase currentPhase = ChapterPhase.intro;
  DateTime? sessionStartTime;

  @override
  void initState() {
    super.initState();
    currentChapter = widget.chapter;
    
    // If chapter already in progress or completed, skip intro
    if (currentChapter.status == ChapterStatus.inProgress ||
        currentChapter.status == ChapterStatus.completed) {
      currentPhase = currentChapter.status == ChapterStatus.completed
          ? ChapterPhase.complete
          : ChapterPhase.chat;
    }
    
    sessionStartTime = DateTime.now();
  }

  void _onIntroComplete() {
    setState(() {
      currentPhase = ChapterPhase.chat;
      currentChapter = currentChapter.copyWith(
        status: ChapterStatus.inProgress,
      );
    });
  }

  void _onChatComplete(String generatedProse, Map<String, dynamic> patterns) {
    final timeSpent = DateTime.now().difference(sessionStartTime!).inMinutes;
    
    setState(() {
      currentPhase = ChapterPhase.complete;
      currentChapter = currentChapter.copyWith(
        status: ChapterStatus.completed,
        generatedProseText: generatedProse,
        extractedPatterns: patterns,
        completedAt: DateTime.now(),
        timeSpentMinutes: currentChapter.timeSpentMinutes + timeSpent,
      );
    });
  }

  void _finishChapter() {
    Navigator.pop(context, currentChapter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildCurrentPhase(),
    );
  }

  Widget _buildCurrentPhase() {
    switch (currentPhase) {
      case ChapterPhase.intro:
        return CinematicIntro(
          chapterNumber: currentChapter.number,
          onComplete: _onIntroComplete,
        );

      case ChapterPhase.chat:
        return _buildChatPlaceholder();

      case ChapterPhase.complete:
        return _buildCompletePlaceholder();
    }
  }

  Widget _buildChatPlaceholder() {
    // TODO: Get actual API instance from app-level provider/dependency injection
    final api = LifeTaskAPI(
      baseUrl: 'http://your-backend-url',  // TODO: Configure from environment
      getAuthToken: () => 'your-auth-token',  // TODO: Get from auth service
    );

    return DeepChat(
      chapterNumber: currentChapter.number,
      api: api,
      onComplete: _onChatComplete,
    );
  }

  Widget _buildCompletePlaceholder() {
    return ChapterProseDisplay(
      chapterNumber: currentChapter.number,
      proseText: currentChapter.generatedProseText ?? 'Your chapter text will appear here...',
      onComplete: _finishChapter,
      onReplay: () {
        // TODO: Implement TTS replay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS narration coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}


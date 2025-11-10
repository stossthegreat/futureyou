import 'package:flutter/material.dart';
import '../models/chapter_model.dart';
import '../widgets/cinematic_intro.dart';

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

  // TODO: Replace with actual deep chat widget
  Widget _buildChatPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Deep Chat Coming Soon',
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'This is where the hour-long conversation happens',
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              // Simulate chapter completion for now
              _onChatComplete(
                'This is a test prose chapter...',
                {'test': 'pattern'},
              );
            },
            child: const Text('Simulate Complete'),
          ),
        ],
      ),
    );
  }

  // TODO: Replace with actual chapter display widget
  Widget _buildCompletePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chapter Complete! 🎉',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 32,
                color: const Color(0xFFfbbf24),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Your personalized prose chapter has been generated.',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _finishChapter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfbbf24),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Continue Journey',
                style: TextStyle(
                  fontFamily: 'Crimson Pro',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


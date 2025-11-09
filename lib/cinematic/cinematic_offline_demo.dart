import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'phase_model.dart';
import 'audio_controller.dart';
import 'cinematic_particles.dart';

class CinematicOfflineDemo extends StatefulWidget {
  const CinematicOfflineDemo({super.key});

  @override
  State<CinematicOfflineDemo> createState() => _CinematicOfflineDemoState();
}

class _CinematicOfflineDemoState extends State<CinematicOfflineDemo> {
  late final AudioController _audioController;
  late final PageController _pageController;
  int _currentPhase = 0;
  DemoState _state = DemoState.intro;
  int _visibleChars = 0;
  bool _typingDone = false;
  final List<String> _mockChapters = [];

  @override
  void initState() {
    super.initState();
    _audioController = AudioController();
    _audioController.init();
    _pageController = PageController();
    _startIntro();
  }

  void _startIntro() async {
    // Start music
    _audioController.playMusic(FuturePhase.values[_currentPhase].musicAsset);
    
    // Start typing animation
    final text = FuturePhase.values[_currentPhase].introText;
    for (int i = 0; i <= text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (mounted) {
        setState(() {
          _visibleChars = i;
        });
      }
    }
    
    setState(() {
      _typingDone = true;
    });
    
    // Start TTS
    _audioController.speak(text);
  }

  void _nextStep() {
    if (_state == DemoState.intro) {
      setState(() {
        _state = DemoState.chat;
      });
      _showMockChat();
    } else if (_state == DemoState.chat) {
      setState(() {
        _state = DemoState.chapter;
      });
      _showMockChapter();
    } else if (_state == DemoState.chapter) {
      _nextPhase();
    }
  }

  void _showMockChat() async {
    // Simulate AI conversation
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _state = DemoState.chapter;
    });
    _showMockChapter();
  }

  void _showMockChapter() {
    final phase = FuturePhase.values[_currentPhase];
    final mockChapter = _generateMockChapter(phase);
    _mockChapters.add(mockChapter);
    
    // Reset typing for chapter
    setState(() {
      _visibleChars = 0;
      _typingDone = false;
    });
    
    _startChapterTyping(mockChapter);
  }

  void _startChapterTyping(String text) async {
    for (int i = 0; i <= text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (mounted) {
        setState(() {
          _visibleChars = i;
        });
      }
    }
    
    setState(() {
      _typingDone = true;
    });
    
    _audioController.speak(text);
  }

  void _nextPhase() {
    if (_currentPhase < FuturePhase.values.length - 1) {
      setState(() {
        _currentPhase++;
        _state = DemoState.intro;
        _visibleChars = 0;
        _typingDone = false;
      });
      _startIntro();
    } else {
      _showBook();
    }
  }

  void _showBook() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _BookView(chapters: _mockChapters),
      ),
    );
  }

  String _generateMockChapter(FuturePhase phase) {
    switch (phase) {
      case FuturePhase.call:
        return """# Chapter I — The Call

The memory comes back sharp and clear. You're eight years old, building something in your backyard—not just playing, but creating with the focused intensity that would later define your best work.

Your hands moved with certainty then, arranging pieces into patterns that made sense to you in ways you couldn't explain. There was no self-doubt, no inner critic questioning whether you were good enough.

That child knew something you've spent years trying to remember: the feeling of being exactly where you belong, doing exactly what you're meant to do.

The call isn't a voice from the sky. It's the echo of that eight-year-old's certainty, still waiting for you to listen.""";

      case FuturePhase.conflict:
        return """# Chapter II — The Conflict

You've been living two lives. The one everyone sees—successful, responsible, moving through the motions of what you're supposed to want. And the one that whispers in quiet moments, asking why this doesn't feel like enough.

The conflict isn't between you and the world. It's between the person you've become and the person you were meant to be.

Every time you've felt stuck, it wasn't because you lacked ability. It was because you were climbing ladders leaning against the wrong walls, chasing goals that belonged to someone else's vision of success.

The discomfort you feel isn't failure. It's your authentic self, refusing to be ignored any longer.""";

      case FuturePhase.mirror:
        return """# Chapter III — The Mirror

In the reflection, you see patterns you've been avoiding. The way you light up when talking about certain ideas. The projects you start with enthusiasm but abandon when they get difficult. The dreams you've called "unrealistic" to avoid the risk of trying.

You see your strengths—the ones you downplay because they come so naturally you assume everyone has them. The unique way you solve problems, connect ideas, see possibilities others miss.

And you see the fears. The voice that says you're not ready, not qualified, not special enough. The same voice that's been keeping you safe and small.

The mirror doesn't judge. It simply shows you what's true.""";

      case FuturePhase.mentor:
        return """# Chapter IV — The Mentor

Your future self speaks with quiet authority: "I know what you're capable of because I've seen you do it. Not the perfect version—the real version, with all your doubts and mistakes and beautiful imperfections.

The path wasn't what you expected. It was messier, more uncertain, but infinitely more alive than the safe route you were considering.

You stopped waiting for permission. You stopped needing to have it all figured out before you began. You learned that courage isn't the absence of fear—it's the decision that something else matters more than the fear.

The work that fulfills you isn't work at all. It's the natural expression of who you are when you stop pretending to be someone else.""";

      case FuturePhase.task:
        return """# Chapter V — The Task

Your life's task crystallizes like a key turning in a lock: You help people see possibilities they didn't know existed.

It's not about the specific job title or industry. It's about the thread that runs through everything you do when you're at your best—the way you illuminate potential, connect disparate ideas, and help others believe in what they're capable of.

This task has been present in every meaningful moment of your life. In the way you naturally mentor others, the problems you can't help but solve, the conversations that energize rather than drain you.

The task isn't something you need to become qualified for. It's something you've been preparing for your entire life.""";

      case FuturePhase.path:
        return """# Chapter VI — The Path

The path reveals itself in small, concrete steps. Not a grand transformation, but a series of Tuesday morning decisions that compound into something extraordinary.

You begin by dedicating one hour each day to your task. Not when you have time, but at a specific time that becomes sacred. You start the project you've been postponing. You have the conversation you've been avoiding.

You build systems that support your vision: morning routines that center you, evening reflections that guide you, weekly reviews that keep you aligned.

The path isn't about perfection. It's about consistency. About showing up for yourself with the same reliability you show up for others.""";

      case FuturePhase.promise:
        return """# Chapter VII — The Promise

The promise isn't made in a moment of inspiration. It's made in the quiet certainty that comes after you've seen who you really are and decided to honor that truth.

You promise to stop apologizing for your ambitions. To stop making yourself smaller to make others comfortable. To stop waiting for the "right time" that never comes.

You promise to trust the process, even when you can't see the outcome. To value progress over perfection. To remember that your unique contribution matters, even when—especially when—it feels risky to offer it.

This is your beginning. Not your end. The story of who you're becoming starts now.""";
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = FuturePhase.values[_currentPhase];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phase.gradientStart.withOpacity(0.4),
                  phase.gradientEnd.withOpacity(0.4),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Particles
          const CinematicParticles(),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPhase + 1} of ${FuturePhase.values.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _state == DemoState.chapter 
                        ? 'Your Personal Chapter'
                        : phase.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'serif',
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 32),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _state == DemoState.chapter && _mockChapters.isNotEmpty
                            ? _mockChapters.last.substring(0, _visibleChars.clamp(0, _mockChapters.last.length))
                            : phase.introText.substring(0, _visibleChars.clamp(0, phase.introText.length)),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _state == DemoState.chapter ? 18 : 20,
                          height: 1.8,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),

                  // Action button
                  if (_typingDone)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: phase.gradientEnd.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(
                          _state == DemoState.intro 
                              ? 'Begin Conversation →'
                              : _state == DemoState.chat
                                  ? 'Generate Chapter →'
                                  : _currentPhase < FuturePhase.values.length - 1
                                      ? 'Next Chapter →'
                                      : 'Create Your Book →',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                    ),
                ],
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 24,
            child: TextButton(
              onPressed: () => setState(() {
                _visibleChars = _state == DemoState.chapter && _mockChapters.isNotEmpty
                    ? _mockChapters.last.length
                    : phase.introText.length;
                _typingDone = true;
              }),
              child: const Text(
                'Skip →',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

enum DemoState { intro, chat, chapter }

class _BookView extends StatelessWidget {
  final List<String> chapters;

  const _BookView({required this.chapters});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Book of Purpose',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: chapters.map((chapter) => Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              chapter,
              style: const TextStyle(
                fontSize: 18,
                height: 1.8,
                color: Colors.black87,
                fontFamily: 'serif',
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

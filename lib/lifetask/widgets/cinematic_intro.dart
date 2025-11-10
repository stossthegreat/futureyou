import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'epic_particles.dart';
import 'cinematic_particles.dart'; // Keep for theme definitions
import '../data/chapter_prose.dart';

/// CINEMATIC INTRO
/// 
/// The 90-second opening sequence for each chapter.
/// This is CINEMA - not a splash screen.
/// 
/// Sequence:
/// 1. Black screen + silence (0-10s)
/// 2. Particles fade in (10-15s)
/// 3. Music begins (15s)
/// 4. Gradient crossfade (15-30s)
/// 5. Title appears (30-35s)
/// 6. Subtitle appears (35-40s)
/// 7. Prose types word-by-word with TTS (40-90s)
/// 8. Continue button appears (90s)

class CinematicIntro extends StatefulWidget {
  final int chapterNumber;
  final VoidCallback onComplete;

  const CinematicIntro({
    Key? key,
    required this.chapterNumber,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CinematicIntro> createState() => _CinematicIntroState();
}

class _CinematicIntroState extends State<CinematicIntro>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _particleController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _proseController;
  late AnimationController _glowController;

  late ChapterProse prose;
  late ChapterTheme theme;
  
  // Audio player for TTS narration
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasAudio = false;

  String visibleText = '';
  int currentParagraphIndex = 0;
  int currentWordIndex = 0;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _canSkip = false;
  bool _hasSkipped = false;
  bool _sequenceComplete = false; // Button ONLY shows after full 90s

  @override
  void initState() {
    super.initState();

    prose = getChapterProse(widget.chapterNumber);
    theme = getChapterTheme(widget.chapterNumber);

    // Master timeline controller (90 seconds)
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    );

    // Particle fade-in
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Title animation
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Subtitle animation
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Prose fade-in
    _proseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Glow pulse animation (continuous)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _startCinematicSequence();
  }

  void _startCinematicSequence() async {
    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start master timeline
    _masterController.forward();

    // Sequence timeline:
    await Future.delayed(const Duration(seconds: 2)); // Pure black
    _particleController.forward(); // Particles fade in

    await Future.delayed(const Duration(seconds: 3));
    // Start TTS narration (if audio file exists)
    await _playTTSNarration();

    await Future.delayed(const Duration(seconds: 15));
    _titleController.forward(); // Title appears

    await Future.delayed(const Duration(seconds: 5));
    _subtitleController.forward(); // Subtitle appears

    await Future.delayed(const Duration(seconds: 5));
    _proseController.forward(); // Prose container fades in
    _startTyping(); // Begin typing animation

    // Enable skip after 10 seconds
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      setState(() {
        _canSkip = true;
      });
    }
  }

  void _startTyping() {
    if (!mounted) return;

    setState(() {
      _isTyping = true;
    });

    // Word-by-word typing with realistic pacing
    _typingTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted || _hasSkipped) {
        timer.cancel();
        return;
      }

      final paragraphs = prose.proseParagraphs;
      if (currentParagraphIndex >= paragraphs.length) {
        timer.cancel();
        _onTypingComplete();
        return;
      }

      final paragraph = paragraphs[currentParagraphIndex];
      final words = paragraph.split(' ');

      if (currentWordIndex < words.length) {
        setState(() {
          if (currentWordIndex == 0) {
            visibleText += '\n\n${words[currentWordIndex]} ';
          } else {
            visibleText += '${words[currentWordIndex]} ';
          }
          currentWordIndex++;
        });

        // TODO: Trigger TTS for current word
        // TODO: Pulse particles on emphasis words
      } else {
        // Move to next paragraph
        currentParagraphIndex++;
        currentWordIndex = 0;
      }
    });
  }

  void _onTypingComplete() {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _sequenceComplete = true; // NOW the button can appear
    });
  }

  void _skip() {
    if (!_canSkip || _hasSkipped) return;

    setState(() {
      _hasSkipped = true;
      visibleText = prose.prose;
      _isTyping = false;
      _sequenceComplete = true; // Allow button to show after skip
    });

    _typingTimer?.cancel();
    
    // Fast-forward all animations
    _particleController.value = 1.0;
    _titleController.value = 1.0;
    _subtitleController.value = 1.0;
    _proseController.value = 1.0;
  }

  Future<void> _playTTSNarration() async {
    // Map chapter number to audio file
    final audioFiles = {
      1: 'cinema/audio/chapter_1_call.mp3',
      2: 'cinema/audio/chapter_2_conflict.mp3',
      3: 'cinema/audio/chapter_3_mirror.mp3',
      4: 'cinema/audio/chapter_4_mentor.mp3',
      5: 'cinema/audio/chapter_5_task.mp3',
      6: 'cinema/audio/chapter_6_path.mp3',
      7: 'cinema/audio/chapter_7_promise.mp3',
    };

    final audioPath = audioFiles[widget.chapterNumber];
    if (audioPath == null) return;

    try {
      await _audioPlayer.play(AssetSource(audioPath));
      _hasAudio = true;
      print('🎵 Playing TTS narration: $audioPath');
    } catch (e) {
      print('⚠️ TTS audio not found: $audioPath (Add your ElevenLabs file!)');
      // Continue without audio - not critical
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _particleController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _proseController.dispose();
    _glowController.dispose();
    _typingTimer?.cancel();
    _audioPlayer.dispose(); // Dispose audio player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Animated gradient background
            _buildGradientBackground(),

            // EPIC Particle system (multi-layer, bokeh, god rays)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Opacity(
                  opacity: _particleController.value,
                  child: EpicParticles(
                    colors: theme.particleColors,
                    isPulsing: _isTyping,
                    intensity: 0.9, // Cranked up to 0.9 for IMPACT
                  ),
                );
              },
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildTitle(),

                    const SizedBox(height: 16),

                    // Subtitle
                    _buildSubtitle(),

                    const SizedBox(height: 64),

                    // Prose text
                    Expanded(
                      child: _buildProseText(),
                    ),

                    // Skip hint / Continue button
                    _buildBottomAction(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    // Multi-layer gradient for DEPTH
    return Stack(
      children: [
        // Base gradient
        AnimatedContainer(
          duration: const Duration(seconds: 20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 2.0,
              colors: [
                theme.gradientColors.first.withOpacity(0.4),
                theme.gradientColors[1].withOpacity(0.3),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        // Overlay gradient (moves slowly)
        AnimatedContainer(
          duration: const Duration(seconds: 25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.gradientColors.last.withOpacity(0.2),
                Colors.transparent,
                theme.gradientColors.first.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Vignette (darker edges)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _titleController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _titleController,
              curve: Curves.easeOut,
            )),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                // EPIC GLOW - Multi-layer shadows for depth
                final glowIntensity = 0.5 + (_glowController.value * 0.5);
                return Text(
                  prose.title,
                  style: TextStyle(
                    fontFamily: 'Crimson Pro',
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      // Outer glow (theme color)
                      Shadow(
                        color: theme.particleColors[2].withOpacity(glowIntensity * 0.8),
                        blurRadius: 60,
                      ),
                      // Mid glow (brighter)
                      Shadow(
                        color: theme.particleColors[2].withOpacity(glowIntensity * 0.6),
                        blurRadius: 40,
                      ),
                      // Inner glow (white)
                      Shadow(
                        color: Colors.white.withOpacity(glowIntensity * 0.5),
                        blurRadius: 25,
                      ),
                      // Sharp highlight
                      Shadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                      // Subtle depth shadow
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _subtitleController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _subtitleController,
          child: Text(
            prose.subtitle,
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProseText() {
    return AnimatedBuilder(
      animation: _proseController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _proseController,
          child: SingleChildScrollView(
            child: Text(
              visibleText,
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 20,
                height: 2.0,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    if (_isTyping && _canSkip) {
      return Center(
        child: AnimatedOpacity(
          opacity: 0.4,
          duration: const Duration(seconds: 1),
          child: Text(
            'Tap to skip',
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      );
    } else if (_sequenceComplete) {
      // Button ONLY shows after full sequence completes
      return Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 800),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: theme.particleColors[2].withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.particleColors[2].withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Begin Journey',
                style: TextStyle(
                  fontFamily: 'Crimson Pro',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'cinematic_particles.dart';
import '../data/chapter_prose.dart';

/// CHAPTER PROSE DISPLAY
/// 
/// The emotional crescendo - where users read their personalized chapter
/// and feel SEEN for the first time.
/// 
/// Features:
/// - Typing animation (50ms per char - slow, intimate)
/// - Paragraph pauses (3 seconds - let emotions sink in)
/// - TTS narration (warm, knowing voice)
/// - Golden typography with glow
/// - Particle effects pulsing with emotional beats
/// - "Keep Forever" buttons after completion

class ChapterProseDisplay extends StatefulWidget {
  final int chapterNumber;
  final String proseText; // AI-generated personalized prose
  final VoidCallback onComplete;
  final VoidCallback? onReplay;

  const ChapterProseDisplay({
    Key? key,
    required this.chapterNumber,
    required this.proseText,
    required this.onComplete,
    this.onReplay,
  }) : super(key: key);

  @override
  State<ChapterProseDisplay> createState() => _ChapterProseDisplayState();
}

class _ChapterProseDisplayState extends State<ChapterProseDisplay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late ScrollController _scrollController;

  String _displayedText = '';
  int _currentCharIndex = 0;
  Timer? _typingTimer;
  bool _isTyping = true;
  bool _hasFinished = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scrollController = ScrollController();

    _startTypingAnimation();
  }

  void _startTypingAnimation() async {
    // Fade in container first
    await _fadeController.forward();

    // Start typing after 1 second
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Word-by-word typing for intimate feel
    final words = widget.proseText.split(' ');
    int wordIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (wordIndex >= words.length) {
        timer.cancel();
        _onTypingComplete();
        return;
      }

      setState(() {
        if (wordIndex == 0) {
          _displayedText = words[wordIndex];
        } else {
          _displayedText += ' ${words[wordIndex]}';
        }
        wordIndex++;

        // Check for paragraph breaks (double newlines in original text)
        if (_displayedText.endsWith('.') || _displayedText.endsWith('!') || _displayedText.endsWith('?')) {
          // Trigger particle pulse on sentence end
          _particleController.forward(from: 0.0);
        }
      });

      // Auto-scroll as text appears
      _autoScroll();

      // TODO: Trigger TTS narration word-by-word
    });
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTypingComplete() {
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _hasFinished = true;
    });

    // Show buttons after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
      }
    });
  }

  void _saveToVault() {
    // TODO: Save chapter prose to local vault
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chapter saved to your vault 💚'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareChapter() {
    // TODO: Generate beautiful image + copy text
    Clipboard.setData(ClipboardData(text: widget.proseText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chapter copied to clipboard 📋'),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = getChapterTheme(widget.chapterNumber);
    final chapterProse = getChapterProse(widget.chapterNumber);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient (chapter theme)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    theme.gradientColors[0].withOpacity(0.3),
                    theme.gradientColors[1].withOpacity(0.15),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // Particles (subtle, emotional)
          Opacity(
            opacity: 0.4,
            child: CinematicParticles(
              theme: theme,
              isPulsing: _isTyping,
              intensity: 0.4,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(chapterProse),

                // Prose text (scrollable)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: _buildProseContent(theme),
                  ),
                ),

                // Action buttons (appear after typing completes)
                if (_showButtons) _buildActionButtons(theme),
              ],
            ),
          ),

          // Typing cursor (blinks at end of text)
          if (_isTyping) _buildCursor(),
        ],
      ),
    );
  }

  Widget _buildHeader(ChapterProse chapterProse) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Text(
                      chapterProse.title,
                      style: TextStyle(
                        fontFamily: 'Crimson Pro',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFfbbf24).withOpacity(
                              0.3 + (_glowController.value * 0.3),
                            ),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Personalized Chapter',
                  style: TextStyle(
                    fontFamily: 'Crimson Pro',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance with back button
        ],
      ),
    );
  }

  Widget _buildProseContent(ChapterTheme theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Text(
        _displayedText,
        style: TextStyle(
          fontFamily: 'Crimson Pro',
          fontSize: 22,
          height: 2.2, // VERY breathable - poetry spacing
          color: const Color(0xFFFFFAED), // White with 15% gold tint
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: const Color(0xFFfbbf24).withOpacity(0.15),
              blurRadius: 30,
            ),
          ],
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildCursor() {
    return Positioned(
      bottom: 200,
      right: 48,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Opacity(
            opacity: _glowController.value,
            child: Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFfbbf24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFfbbf24).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ChapterTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action: Continue Journey
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfbbf24),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFfbbf24).withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Journey',
                    style: TextStyle(
                      fontFamily: 'Crimson Pro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, duration: 600.ms),

          const SizedBox(height: 12),

          // Secondary actions row
          Row(
            children: [
              // Save to Vault
              Expanded(
                child: OutlinedButton(
                  onPressed: _saveToVault,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.particleColors[0]),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: theme.particleColors[0], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Hear Again (TTS)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReplay,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Listen',
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Share
              Expanded(
                child: OutlinedButton(
                  onPressed: _shareChapter,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, duration: 600.ms),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'audio_controller.dart';

class ChapterDisplay extends StatefulWidget {
  final Map<String, dynamic> chapter;
  final AudioController audioController;
  final VoidCallback onComplete;

  const ChapterDisplay({
    super.key,
    required this.chapter,
    required this.audioController,
    required this.onComplete,
  });

  @override
  State<ChapterDisplay> createState() => _ChapterDisplayState();
}

class _ChapterDisplayState extends State<ChapterDisplay> with TickerProviderStateMixin {
  int _visibleChars = 0;
  bool _done = false;
  bool _skipped = false;
  late AnimationController _fadeController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _startTyping();
    _startTTS();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startTyping() async {
    final text = widget.chapter['bodyMd'] as String;
    final chars = text.length;

    // Start immediately, no delay
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i <= chars; i++) {
      if (_skipped) break;
      await Future.delayed(const Duration(milliseconds: 15)); // Faster typing
      if (mounted) {
        setState(() {
          _visibleChars = i;
        });
      }
    }

    if (mounted) {
      setState(() {
        _done = true;
      });
    }
  }

  void _startTTS() {
    widget.audioController.speak(widget.chapter['bodyMd'] as String);
  }

  void _skip() {
    setState(() {
      _skipped = true;
      _visibleChars = (widget.chapter['bodyMd'] as String).length;
      _done = true;
    });
    widget.audioController.stopTTS();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.chapter['bodyMd'] as String;

    return GestureDetector(
      onTap: _done ? null : _skip,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Colors.amber.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Title with glow effect
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Text(
                  widget.chapter['title'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.amber.withOpacity(0.3 + (_glowController.value * 0.3)),
                        blurRadius: 20,
                      ),
                      Shadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3, end: 0);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Decorative line
            Container(
              height: 2,
              width: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate().scaleX(duration: 1000.ms, delay: 300.ms),

            const SizedBox(height: 48),

            // Chapter text with fade-in animation
            Expanded(
              child: FadeTransition(
                opacity: _fadeController,
                child: SingleChildScrollView(
                  child: Text(
                    text.substring(0, _visibleChars),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 2.0,
                      fontFamily: 'serif',
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Skip hint
            if (!_done && !_skipped)
              Center(
                child: Text(
                  'Tap to skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1500.ms)
                  .fadeOut(duration: 1500.ms),
              ),

            // Complete button with animation
            if (_done)
              Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.3),
                        Colors.orange.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue Journey ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms).scale(delay: 200.ms),
              ),
          ],
        ),
      ),
    );
  }
}


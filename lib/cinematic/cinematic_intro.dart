import 'package:flutter/material.dart';
import 'phase_model.dart';
import 'audio_controller.dart';

class CinematicIntro extends StatefulWidget {
  final FuturePhase phase;
  final AudioController audioController;
  final VoidCallback onComplete;

  const CinematicIntro({
    super.key,
    required this.phase,
    required this.audioController,
    required this.onComplete,
  });

  @override
  State<CinematicIntro> createState() => _CinematicIntroState();
}

class _CinematicIntroState extends State<CinematicIntro> {
  int _visibleChars = 0;
  bool _done = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
    _startTTS();
  }

  void _startTyping() async {
    final text = widget.phase.introText;
    final chars = text.length;

    for (int i = 0; i <= chars; i++) {
      if (_skipped) break;
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _visibleChars = i;
        });
      }
    }

    setState(() {
      _done = true;
    });
  }

  void _startTTS() {
    widget.audioController.speak(widget.phase.introText);
  }

  void _skip() {
    setState(() {
      _skipped = true;
      _visibleChars = widget.phase.introText.length;
      _done = true;
    });
    widget.audioController.stopTTS();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _done ? null : _skip,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.phase.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 32),

            // Intro text
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.phase.introText.substring(0, _visibleChars),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.8,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),

            // Continue button
            if (_done)
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                  child: const Text(
                    'Continue →',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


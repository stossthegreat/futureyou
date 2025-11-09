import 'package:flutter/material.dart';
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

class _ChapterDisplayState extends State<ChapterDisplay> {
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
    final text = widget.chapter['bodyMd'] as String;
    final chars = text.length;

    for (int i = 0; i <= chars; i++) {
      if (_skipped) break;
      await Future.delayed(const Duration(milliseconds: 20));
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.chapter['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 32),

            // Chapter text
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text.substring(0, _visibleChars),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.8,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),

            // Complete button
            if (_done)
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                  child: const Text(
                    'Complete Chapter ✓',
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


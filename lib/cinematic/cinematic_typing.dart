import 'package:flutter/material.dart';

class CinematicTyping extends StatefulWidget {
  final String text;
  final double wordsPerMinute;
  final VoidCallback? onFinished;
  final VoidCallback? onSkip;
  
  const CinematicTyping({
    Key? key,
    required this.text,
    this.wordsPerMinute = 14.0,
    this.onFinished,
    this.onSkip,
  }) : super(key: key);

  @override
  State<CinematicTyping> createState() => CinematicTypingState();
}

class CinematicTypingState extends State<CinematicTyping> {
  String _displayedText = '';
  int _currentWordIndex = 0;
  bool _isComplete = false;
  List<String> _words = [];
  
  @override
  void initState() {
    super.initState();
    _words = widget.text.split(RegExp(r'\s+'));
    _startTyping();
  }
  
  void _startTyping() {
    final msPerWord = (60000 / widget.wordsPerMinute).round();
    
    Future.doWhile(() async {
      if (_currentWordIndex >= _words.length) {
        _isComplete = true;
        widget.onFinished?.call();
        return false;
      }
      
      await Future.delayed(Duration(milliseconds: msPerWord));
      
      if (mounted) {
        setState(() {
          _displayedText += (_displayedText.isEmpty ? '' : ' ') + _words[_currentWordIndex];
          _currentWordIndex++;
        });
      }
      
      return !_isComplete && mounted;
    });
  }
  
  void skip() {
    if (_isComplete) return;
    
    setState(() {
      _displayedText = widget.text;
      _currentWordIndex = _words.length;
      _isComplete = true;
    });
    
    widget.onSkip?.call();
    widget.onFinished?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: skip,
      child: SingleChildScrollView(
        child: SelectableText(
          _displayedText,
          style: const TextStyle(
            fontSize: 18,
            height: 1.8,
            color: Colors.white,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}


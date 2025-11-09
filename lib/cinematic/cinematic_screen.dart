import 'package:flutter/material.dart';
import 'cinematic_phase_scene.dart';
import 'cinematic_book.dart';
import 'audio_controller.dart';
import 'phase_model.dart';

class CinematicScreen extends StatefulWidget {
  const CinematicScreen({super.key});

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen> {
  late final AudioController _audioController;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioController = AudioController();
    _audioController.init();
    _pageController = PageController();
  }

  void _nextPhase() {
    if (_currentIndex < FuturePhase.values.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentIndex++;
      });
    } else {
      // All phases complete → show book
      _showBook();
    }
  }

  Future<void> _showBook() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CinematicBook(audioController: _audioController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: FuturePhase.values.length,
      itemBuilder: (context, index) {
        return CinematicPhaseScene(
          phase: FuturePhase.values[index],
          audioController: _audioController,
          onComplete: _nextPhase,
        );
      },
    );
  }

  @override
  void dispose() {
    _audioController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

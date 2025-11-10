import 'package:flutter/material.dart';
import '../widgets/cinematic_intro.dart';

/// CINEMATIC TEST SCREEN
/// 
/// Quick way to test the cinematic intros without going through the whole flow

class CinematicTestScreen extends StatelessWidget {
  const CinematicTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Cinematic Intros',
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 48),
            ...List.generate(7, (index) {
              final chapterNum = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CinematicIntro(
                          chapterNumber: chapterNum,
                          onComplete: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfbbf24),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Test Chapter $chapterNum Intro',
                    style: TextStyle(
                      fontFamily: 'Crimson Pro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


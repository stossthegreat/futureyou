import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CinematicParticles extends StatelessWidget {
  const CinematicParticles({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.3,
        child: IgnorePointer(
          child: Lottie.asset(
            'assets/cinema/anims/particles.json',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if Lottie file missing
              return Container();
            },
          ),
        ),
      ),
    );
  }
}

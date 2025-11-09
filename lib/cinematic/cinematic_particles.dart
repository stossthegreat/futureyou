import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CinematicParticles extends StatefulWidget {
  final VoidCallback? onFinished;
  final Duration duration;
  
  const CinematicParticles({
    Key? key,
    this.onFinished,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<CinematicParticles> createState() => _CinematicParticlesState();
}

class _CinematicParticlesState extends State<CinematicParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _controller.forward().then((_) {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.2),
          child: Opacity(
            opacity: 1.0 - (_controller.value * 0.3),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Try to load Lottie, fallback to simple animation
          _buildParticleEffect(),
        ],
      ),
    );
  }

  Widget _buildParticleEffect() {
    // Try to load Lottie file, if not available show fallback
    try {
      return Lottie.asset(
        'assets/cinema/anims/particles.json',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAnimation();
        },
      );
    } catch (e) {
      return _buildFallbackAnimation();
    }
  }

  Widget _buildFallbackAnimation() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}


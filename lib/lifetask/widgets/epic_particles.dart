import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// EPIC CINEMATIC PARTICLES
/// 
/// Multi-layer particle system with:
/// - 3 depth layers (foreground, mid, background) with parallax
/// - Bokeh particles (out-of-focus circles)
/// - Light rays/god rays
/// - Film grain texture
/// - Dynamic color shifting
/// 
/// This is what makes people say "DAMN, that's beautiful"

class EpicParticles extends StatefulWidget {
  final List<Color> colors;
  final double intensity; // 0.0 to 1.0
  final bool isPulsing;

  const EpicParticles({
    Key? key,
    required this.colors,
    this.intensity = 0.7,
    this.isPulsing = false,
  }) : super(key: key);

  @override
  State<EpicParticles> createState() => _EpicParticlesState();
}

class _EpicParticlesState extends State<EpicParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Generate 100 particles across 3 layers
    for (int i = 0; i < 100; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 8 + 2, // 2-10px
        speed: _random.nextDouble() * 0.5 + 0.1, // 0.1-0.6
        layer: _random.nextInt(3), // 0=background, 1=mid, 2=foreground
        color: widget.colors[_random.nextInt(widget.colors.length)],
        opacity: _random.nextDouble() * 0.6 + 0.2, // 0.2-0.8
        blur: _random.nextDouble() * 15 + 5, // 5-20px blur for bokeh
      ));
    }
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
        return CustomPaint(
          painter: EpicParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            intensity: widget.intensity,
            isPulsing: widget.isPulsing,
            colors: widget.colors,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final int layer; // 0=background (slow), 1=mid, 2=foreground (fast)
  final Color color;
  final double opacity;
  final double blur;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.layer,
    required this.color,
    required this.opacity,
    required this.blur,
  });
}

class EpicParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final double intensity;
  final bool isPulsing;
  final List<Color> colors;

  EpicParticlesPainter({
    required this.particles,
    required this.progress,
    required this.intensity,
    required this.isPulsing,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Film grain texture (subtle)
    _drawFilmGrain(canvas, size);

    // 2. Draw particles in 3 layers (background to foreground)
    for (int layer = 0; layer <= 2; layer++) {
      final layerParticles = particles.where((p) => p.layer == layer).toList();
      for (final particle in layerParticles) {
        _drawParticle(canvas, size, particle, layer);
      }
    }

    // 3. Light rays (god rays effect)
    _drawLightRays(canvas, size);
  }

  void _drawFilmGrain(Canvas canvas, Size size) {
    final Random random = Random((progress * 1000).toInt());
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02);

    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  void _drawParticle(Canvas canvas, Size size, Particle particle, int layer) {
    // Parallax effect: different layers move at different speeds
    final layerSpeed = particle.speed * (layer + 1) * 0.5;
    final yOffset = (progress * layerSpeed * size.height) % size.height;
    
    final x = particle.x * size.width;
    final y = (particle.y * size.height + yOffset) % size.height;

    // Pulsing effect
    final pulseMultiplier = isPulsing ? (1.0 + sin(progress * pi * 4) * 0.3) : 1.0;
    final currentSize = particle.size * pulseMultiplier * intensity;

    // Create bokeh effect (blurred circles)
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.opacity * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.blur * intensity);

    // Draw particle
    canvas.drawCircle(Offset(x, y), currentSize, paint);

    // Add a brighter center for depth
    if (layer == 2) { // Only for foreground particles
      final centerPaint = Paint()
        ..color = Colors.white.withOpacity(0.4 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), currentSize * 0.3, centerPaint);
    }
  }

  void _drawLightRays(Canvas canvas, Size size) {
    // Subtle light sweep from top
    final gradient = RadialGradient(
      center: Alignment.topCenter,
      radius: 1.5,
      colors: [
        colors.first.withOpacity(0.15 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);

    // Add animated light ray
    final rayAngle = progress * pi * 2;
    final rayPaint = Paint()
      ..color = colors.last.withOpacity(0.1 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final rayPath = Path();
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.3;
    final rayLength = size.height * 1.5;

    rayPath.moveTo(centerX, centerY);
    rayPath.lineTo(
      centerX + cos(rayAngle) * rayLength,
      centerY + sin(rayAngle) * rayLength,
    );

    canvas.drawPath(rayPath, rayPaint);
  }

  @override
  bool shouldRepaint(covariant EpicParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isPulsing != isPulsing;
  }
}


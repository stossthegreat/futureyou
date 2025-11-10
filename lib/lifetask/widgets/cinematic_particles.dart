import 'dart:math';
import 'package:flutter/material.dart';

/// CINEMATIC PARTICLE SYSTEM
/// 
/// Creates living, breathing particle fields that respond to:
/// - Chapter themes (colors, movement patterns)
/// - TTS audio (pulse on emphasis)
/// - User interaction (touch creates ripples)
/// - Emotional state (speed, intensity)
/// 
/// This is the SOUL of the visual experience.

class CinematicParticles extends StatefulWidget {
  final ChapterTheme theme;
  final bool isPulsing;
  final double intensity; // 0.0 - 1.0
  
  const CinematicParticles({
    Key? key,
    required this.theme,
    this.isPulsing = false,
    this.intensity = 0.5,
  }) : super(key: key);

  @override
  State<CinematicParticles> createState() => _CinematicParticlesState();
}

class _CinematicParticlesState extends State<CinematicParticles>
    with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  List<Particle> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    // Slow drift animation (particles float)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    // Pulse animation (syncs with TTS)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Rotation animation (background subtle rotation)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Initialize particles
    _createParticles();
  }

  void _createParticles() {
    particles = List.generate(200, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: widget.theme.particleSizeMin +
            random.nextDouble() *
                (widget.theme.particleSizeMax - widget.theme.particleSizeMin),
        speed: widget.theme.particleSpeedMin +
            random.nextDouble() *
                (widget.theme.particleSpeedMax - widget.theme.particleSpeedMin),
        opacity: widget.theme.particleOpacityMin +
            random.nextDouble() *
                (widget.theme.particleOpacityMax -
                    widget.theme.particleOpacityMin),
        color: widget.theme.particleColors[
            random.nextInt(widget.theme.particleColors.length)],
        angle: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void didUpdateWidget(CinematicParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.theme != widget.theme) {
      // Theme changed - recreate particles with new colors
      _createParticles();
    }
    
    if (widget.isPulsing && !oldWidget.isPulsing) {
      // Start pulse animation
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _driftController,
        _pulseController,
        _rotationController,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            progress: _driftController.value,
            pulseProgress: _pulseController.value,
            rotationProgress: _rotationController.value,
            intensity: widget.intensity,
            theme: widget.theme,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final double pulseProgress;
  final double rotationProgress;
  final double intensity;
  final ChapterTheme theme;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.pulseProgress,
    required this.rotationProgress,
    required this.intensity,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate position with drift
      final driftX = particle.x + (sin(progress * 2 * pi + particle.angle) * 0.05);
      final driftY = particle.y + (cos(progress * 2 * pi + particle.angle) * 0.05);
      
      // Apply bounds wrapping
      final x = (driftX % 1.0) * size.width;
      final y = (driftY % 1.0) * size.height;

      // Calculate size with pulse
      final pulseScale = 1.0 + (sin(pulseProgress * pi) * 0.3 * intensity);
      final finalSize = particle.size * pulseScale;

      // Calculate opacity with pulse
      final pulseOpacity = particle.opacity * (1.0 + (pulseProgress * 0.5));

      // Draw particle with glow
      final paint = Paint()
        ..color = particle.color.withOpacity(pulseOpacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          theme.particleBlur,
        );

      canvas.drawCircle(
        Offset(x, y),
        finalSize,
        paint,
      );

      // Draw outer glow for larger particles
      if (particle.size > 2.0) {
        final glowPaint = Paint()
          ..color = particle.color.withOpacity(pulseOpacity * 0.3)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            theme.particleBlur * 2,
          );

        canvas.drawCircle(
          Offset(x, y),
          finalSize * 1.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;
  final double angle;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.angle,
  });
}

/// CHAPTER THEMES
/// Each chapter has unique visual identity

class ChapterTheme {
  final String name;
  final List<Color> particleColors;
  final double particleSizeMin;
  final double particleSizeMax;
  final double particleSpeedMin;
  final double particleSpeedMax;
  final double particleOpacityMin;
  final double particleOpacityMax;
  final double particleBlur;
  final List<Color> gradientColors;

  const ChapterTheme({
    required this.name,
    required this.particleColors,
    this.particleSizeMin = 1.0,
    this.particleSizeMax = 3.0,
    this.particleSpeedMin = 0.1,
    this.particleSpeedMax = 0.3,
    this.particleOpacityMin = 0.1,
    this.particleOpacityMax = 0.4,
    this.particleBlur = 3.0,
    required this.gradientColors,
  });
}

/// CHAPTER 1: THE CALL
/// Soft blues, warm golds, gentle light
const chapterOneTheme = ChapterTheme(
  name: 'The Call',
  particleColors: [
    Color(0xFF0ea5e9), // Sky blue
    Color(0xFF22d3ee), // Cyan
    Color(0xFFfbbf24), // Gold
    Color(0xFFfde047), // Yellow
  ],
  particleSizeMin: 1.0,
  particleSizeMax: 3.0,
  particleSpeedMin: 0.2,
  particleSpeedMax: 0.4,
  particleOpacityMin: 0.15,
  particleOpacityMax: 0.35,
  particleBlur: 4.0,
  gradientColors: [
    Color(0xFF0a1929), // Deep blue
    Color(0xFF1e3a5f), // Medium blue
    Color(0xFF000000), // Black
  ],
);

/// CHAPTER 2: THE CONFLICT
/// Dark crimson, charcoal, sharp contrast
const chapterTwoTheme = ChapterTheme(
  name: 'The Conflict',
  particleColors: [
    Color(0xFF8b0000), // Dark red
    Color(0xFFdc2626), // Red
    Color(0xFFfbbf24), // Ember gold
    Color(0xFFffffff), // White spark
  ],
  particleSizeMin: 0.8,
  particleSizeMax: 2.5,
  particleSpeedMin: 0.3,
  particleSpeedMax: 0.6,
  particleOpacityMin: 0.1,
  particleOpacityMax: 0.5,
  particleBlur: 5.0,
  gradientColors: [
    Color(0xFF000000), // Pure black
    Color(0xFF1a0000), // Dark crimson
    Color(0xFF2d2d2d), // Charcoal
  ],
);

/// CHAPTER 3: THE MIRROR
/// Silver, ice blue, crystal clear
const chapterThreeTheme = ChapterTheme(
  name: 'The Mirror',
  particleColors: [
    Color(0xFFc0c0c0), // Silver
    Color(0xFFe0f2fe), // Ice blue
    Color(0xFFbae6fd), // Crystal blue
    Color(0xFFffffff), // Pure white
  ],
  particleSizeMin: 1.2,
  particleSizeMax: 2.8,
  particleSpeedMin: 0.15,
  particleSpeedMax: 0.35,
  particleOpacityMin: 0.2,
  particleOpacityMax: 0.4,
  particleBlur: 6.0,
  gradientColors: [
    Color(0xFF1e293b), // Dark slate
    Color(0xFF334155), // Slate
    Color(0xFF64748b), // Light slate
  ],
);

/// Get theme for chapter number
ChapterTheme getChapterTheme(int chapterNumber) {
  switch (chapterNumber) {
    case 1:
      return chapterOneTheme;
    case 2:
      return chapterTwoTheme;
    case 3:
      return chapterThreeTheme;
    // TODO: Add chapters 4-7 themes
    default:
      return chapterOneTheme;
  }
}


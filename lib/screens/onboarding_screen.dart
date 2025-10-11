import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  static const _slides = [
    (
      id: 1,
      icon: LucideIcons.sparkles,
      title: 'The Awakening',
      headline: 'You’ve drifted long enough.',
      sub: 'Time isn’t running out — you are.',
      body: [
        'Most people let the days decide for them.',
        'Future U OS reconnects you to the only version that matters — the one who didn’t give up on the mission.',
      ],
      glowFrom: AppColors.emerald,
      glowTo: AppColors.cyan,
      isFinal: false,
    ),
    (
      id: 2,
      icon: LucideIcons.penTool,
      title: 'The Choice',
      headline: 'Define or be defined.',
      sub: 'Choose your identity. Forge the path.',
      body: [
        'Who do you want to become — not today, but in the end?',
        'The system turns your identity into daily proof — one habit, one promise, one truth at a time.',
      ],
      glowFrom: AppColors.cyan,
      glowTo: Color(0xFF3B82F6),
      isFinal: false,
    ),
    (
      id: 3,
      icon: LucideIcons.bell,
      title: 'The Mentor',
      headline: 'Your Future Self Speaks.',
      sub: 'He doesn’t coach. He corrects.',
      body: [
        'Each morning, he writes to you.',
        'Each night, he measures the gap between who you are and who you swore you’d be.',
        'He rewards integrity — not effort.',
      ],
      glowFrom: AppColors.emerald,
      glowTo: Color(0xFFA3E635),
      isFinal: false,
    ),
    (
      id: 4,
      icon: LucideIcons.flame,
      title: 'The Shadow',
      headline: 'Fulfillment vs Drift.',
      sub: 'Two forces. One truth.',
      body: [
        'Every kept promise feeds the light.',
        'Every skipped one feeds the Drift.',
        'The mirror remembers everything.',
      ],
      glowFrom: Color(0xFFF43F5E),
      glowTo: Color(0xFFF59E0B),
      isFinal: false,
    ),
    (
      id: 5,
      icon: LucideIcons.eye,
      title: 'The Mirror',
      headline: 'See Who You’re Becoming.',
      sub: 'Integrity made visible.',
      body: [
        'Look into the Mirror — it glows with your kept promises.',
        'More consistency, more light.',
        'You can’t fake what the Mirror remembers.',
      ],
      glowFrom: AppColors.cyan,
      glowTo: Color(0xFF6366F1),
      isFinal: false,
    ),
    (
      id: 6,
      icon: LucideIcons.crown,
      title: 'The Pact',
      headline: 'Commit or Decay.',
      sub: '4.99 / month or 40 / year.',
      body: [
        'Free: Habit + Alarm OS for standard integrity.',
        'Pro: Unlock the full AI OS — letters, foresight, and Future You watching over every choice.',
        'Make the Pact. Begin the ascent.',
      ],
      glowFrom: Color(0xFFFBBF24),
      glowTo: AppColors.emerald,
      isFinal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            const _ParticleField(count: 32),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: _ParallaxCard(
                child: ValueListenableBuilder<int>(
                  valueListenable: _index,
                  builder: (context, i, _) {
                    final s = _slides[i];
                    return _SlideCard(
                      index: i,
                      title: s.title,
                      icon: s.icon,
                      headline: s.headline,
                      sub: s.sub,
                      body: s.body,
                      glowFrom: s.glowFrom,
                      glowTo: s.glowTo,
                      isFinal: s.isFinal,
                      onBack: i == 0 ? null : () => _index.value = i - 1,
                      onNext: i == _slides.length - 1
                          ? null
                          : () => _index.value = i + 1,
                      onComplete: widget.onComplete,
                    );
                  },
                ),
              ),
              ),
            ),

            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Future U OS · Integrity Engine · Make the Pact',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textQuaternary,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                      duration: 1200.ms,
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ParticleField extends StatefulWidget {
  final int count;
  const _ParticleField({required this.count});

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Dot> _dots;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    final rnd = math.Random();
    _dots = List.generate(widget.count, (i) {
      return _Dot(
        left: rnd.nextDouble() * 100,
        top: rnd.nextDouble() * 100,
        size: rnd.nextDouble() * 4 + 2,
        phase: rnd.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: _dots.map((d) {
                final opacity = 0.2 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + d.phase));
                final y = 0 + 10 * math.sin(t * 2 * math.pi + d.phase);
                return Positioned(
                  left: MediaQuery.of(context).size.width * d.left / 100,
                  top: MediaQuery.of(context).size.height * d.top / 100 + y,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x6622C55E), // emerald 400/40
                          Color(0x4D22D3EE), // cyan 400/30
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D10B981),
                          blurRadius: 20,
                          spreadRadius: 0,
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _Dot {
  final double left;
  final double top;
  final double size;
  final double phase;
  _Dot({required this.left, required this.top, required this.size, required this.phase});
}

class _ParallaxCard extends StatefulWidget {
  final Widget child;
  const _ParallaxCard({required this.child});

  @override
  State<_ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<_ParallaxCard> {
  double x = 0;
  double y = 0;

  void _onPointer(PointerHoverEvent e, Size size) {
    final dx = e.localPosition.dx - size.width / 2;
    final dy = e.localPosition.dy - size.height / 2;
    setState(() {
      x = dx.clamp(-240, 240) / 30;
      y = dy.clamp(-240, 240) / 30;
    });
  }

  void _reset() => setState(() {
        x = 0;
        y = 0;
      });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _onPointer(e, const Size(360, 520)),
      onExit: (_) => _reset(),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(y * math.pi / 180)
          ..rotateY(-x * math.pi / 180),
        child: SizedBox(width: 360, child: widget.child),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final String headline;
  final String sub;
  final List<String> body;
  final Color glowFrom;
  final Color glowTo;
  final bool isFinal;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;

  const _SlideCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.headline,
    required this.sub,
    required this.body,
    required this.glowFrom,
    required this.glowTo,
    required this.isFinal,
    this.onBack,
    this.onNext,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.glassBorder),
        gradient: LinearGradient(
          colors: [
            glowFrom.withOpacity(0.25),
            glowTo.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4010B981),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.emerald),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  )
                ],
              ),
              Row(
                children: List.generate(_OnboardingScreenState._slides.length, (i) {
                  return Container(
                    width: 24,
                    height: 4,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: i <= index ? AppColors.emerald : AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Column(
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppColors.emerald, AppColors.cyan],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                children: body
                    .map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            line,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          AnimatedSwitcher(
            duration: 400.ms,
            child: index == 4
                ? _MirrorOrb(strength: 0.75, key: const ValueKey('orb'))
                : _buildSlideImage(index),
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              _GlassChip(
                label: 'Back',
                onPressed: onBack,
                disabled: onBack == null,
              ),
              const Spacer(),
              Flexible(
                child: (!isFinal)
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: _PrimaryButton(
                          label: 'Next',
                          icon: LucideIcons.arrowRight,
                          onPressed: onNext,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GlassChip(
                              label: 'Start Free',
                              onPressed: onComplete,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PrimaryButton(
                              label: 'Unlock Pro — \$4.99/mo · \$40/yr',
                              onPressed: onComplete,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideImage(int slideIndex) {
    // Asset paths for each slide - you can replace these with your actual image paths
    final List<String> imagePaths = [
      'assets/images/onboarding/awakening.jpg',      // Slide 1: The Awakening
      'assets/images/onboarding/choice.jpg',         // Slide 2: The Choice  
      'assets/images/onboarding/mentor.jpg',         // Slide 3: The Mentor
      'assets/images/onboarding/shadow.jpg',         // Slide 4: The Shadow
      'assets/images/onboarding/mirror.jpg',         // Slide 5: The Mirror (handled separately)
      'assets/images/onboarding/pact.jpg',           // Slide 6: The Pact
    ];

    return Container(
      key: ValueKey('image_$slideIndex'),
      width: 280,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.glass,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Stack(
          children: [
            // Image placeholder with gradient background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    glowFrom.withOpacity(0.3),
                    glowTo.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Load actual onboarding image; contain to avoid cropping
            Image.asset(
              imagePaths[slideIndex],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder(slideIndex);
              },
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildImagePlaceholder(int slideIndex) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: glowFrom.withOpacity(0.8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Image ${slideIndex + 1}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            'Add to assets/images/onboarding/',
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textQuaternary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MirrorOrb extends StatelessWidget {
  final double strength;
  const _MirrorOrb({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [ScaleEffect(begin: const Offset(1, 1), end: Offset(1 + strength * 0.06, 1 + strength * 0.06), duration: 6.seconds)],
      onPlay: (c) => c.repeat(reverse: true),
      child: Container(
        width: 224,
        height: 224,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x2EFFFFFF),
              Color(0x0FFFFFFF),
              Colors.transparent,
            ],
          ),
          border: Border.all(color: AppColors.emerald.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.55),
              blurRadius: 12 + strength * 46,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool disabled;
  const _GlassChip({required this.label, this.onPressed, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border.all(color: AppColors.glassBorder),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.emerald, AppColors.cyan]),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodySemiBold.copyWith(color: Colors.black),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, size: 16, color: Colors.black),
            ]
          ],
        ),
      ),
    );
  }
}


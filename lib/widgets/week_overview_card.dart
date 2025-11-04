import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../services/weekly_stats_service.dart';
import 'dart:math' as math;

class WeekOverviewCard extends StatefulWidget {
  final WeeklyStats stats;

  const WeekOverviewCard({
    super.key,
    required this.stats,
  });

  @override
  State<WeekOverviewCard> createState() => _WeekOverviewCardState();
}

class _WeekOverviewCardState extends State<WeekOverviewCard>
    with TickerProviderStateMixin {
  late AnimationController _perfectController;
  late AnimationController _microController;
  late AnimationController _driftController;
  late AnimationController _glowController;

  late Animation<int> _perfectAnimation;
  late Animation<int> _microAnimation;
  late Animation<int> _driftAnimation;

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    // Counter animations with different durations
    _perfectController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _microController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _driftController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _perfectAnimation = IntTween(
      begin: 0,
      end: widget.stats.perfectDays,
    ).animate(CurvedAnimation(
      parent: _perfectController,
      curve: Curves.easeOut,
    ));

    _microAnimation = IntTween(
      begin: 0,
      end: widget.stats.microWins,
    ).animate(CurvedAnimation(
      parent: _microController,
      curve: Curves.easeOut,
    ));

    _driftAnimation = IntTween(
      begin: 0,
      end: widget.stats.driftDays,
    ).animate(CurvedAnimation(
      parent: _driftController,
      curve: Curves.easeOut,
    ));

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _perfectController.forward();
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _microController.forward();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _driftController.forward();
    });
  }

  @override
  void dispose() {
    _perfectController.dispose();
    _microController.dispose();
    _driftController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Stack(
        children: [
          // Confetti layer
          if (_showConfetti) _buildConfetti(),

          // Main card
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowValue = _glowController.value;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                  border: Border.all(
                    color: AppColors.emerald.withOpacity(0.5 + glowValue * 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withOpacity(0.2 * glowValue),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF18181B), // zinc-900
                      Color(0xFF09090B), // zinc-950
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStatsGrid(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.award,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.emeraldGradient
                      .createShader(bounds),
                  child: const Text(
                    'Week Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your momentum tracker',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.emerald.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.emerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.emerald.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.trendingUp,
                color: AppColors.emerald,
                size: 16,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveY(begin: 0, end: -3, duration: 600.ms)
                  .then()
                  .moveY(begin: -3, end: 0, duration: 600.ms),
              const SizedBox(width: 4),
              Text(
                '+${widget.stats.trendingPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make boxes slightly wider by reducing gap
        final gap = AppSpacing.md;
        final totalGapWidth = gap * 2;
        final boxWidth = (constraints.maxWidth - totalGapWidth) / 3;

        return Row(
          children: [
            // Perfect days
            SizedBox(
              width: boxWidth,
              child: _buildStatBox(
                animation: _perfectAnimation,
                label: 'Perfect days',
                gradient: const LinearGradient(
                  colors: [
                    Color(0x4010B981), // emerald-500/25
                    Color(0x26059669), // emerald-600/15
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppColors.emerald.withOpacity(0.5),
                icon: LucideIcons.sparkles,
                iconColor: AppColors.emerald,
                textColor: AppColors.emerald,
                onTap: () {
                  setState(() {
                    _showConfetti = true;
                  });
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _showConfetti = false;
                      });
                    }
                  });
                },
              ),
            ),
            SizedBox(width: gap),
            // Micro-wins
            SizedBox(
              width: boxWidth,
              child: _buildStatBox(
                animation: _microAnimation,
                label: 'Micro-wins',
                gradient: const LinearGradient(
                  colors: [
                    Color(0x40F59E0B), // amber-500/25
                    Color(0x26F97316), // orange-500/15
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppColors.warning.withOpacity(0.5),
                icon: LucideIcons.zap,
                iconColor: AppColors.warning,
                textColor: AppColors.warning,
                onTap: null,
              ),
            ),
            SizedBox(width: gap),
            // Drift
            SizedBox(
              width: boxWidth,
              child: _buildStatBox(
                animation: _driftAnimation,
                label: 'Slipped days',
                gradient: const LinearGradient(
                  colors: [
                    Color(0x40EF4444), // red-500/25
                    Color(0x26FB7185), // rose-500/15
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppColors.error.withOpacity(0.5),
                icon: null,
                iconColor: AppColors.error,
                textColor: AppColors.error,
                labelTop: 'DRIFT',
                onTap: null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatBox({
    required Animation<int> animation,
    required String label,
    required Gradient gradient,
    required Color borderColor,
    IconData? icon,
    required Color iconColor,
    required Color textColor,
    String? labelTop,
    VoidCallback? onTap,
  }) {
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top label or icon
          if (labelTop != null)
            Text(
              labelTop,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textColor.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            )
          else if (icon != null)
            Icon(
              icon,
              size: 14,
              color: iconColor,
            ).animate(onPlay: (controller) => controller.repeat())
                .rotate(begin: 0, end: 1, duration: 2000.ms),
          
          const SizedBox(height: 4),

          // Animated number
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Text(
                '${animation.value}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Bottom label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildConfetti() {
    final confettiParticles = List.generate(30, (i) {
      return _ConfettiParticle(
        key: ValueKey(i),
        left: math.Random().nextDouble(),
        delay: math.Random().nextDouble() * 0.5,
      );
    });

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: confettiParticles,
        ),
      ),
    );
  }
}

class _ConfettiParticle extends StatefulWidget {
  final double left;
  final double delay;

  const _ConfettiParticle({
    super.key,
    required this.left,
    required this.delay,
  });

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fallAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000 + math.Random().nextInt(1000)),
      vsync: this,
    );

    _fallAnimation = Tween<double>(begin: 0, end: 300).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: math.pi * 2).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
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
        return Positioned(
          left: MediaQuery.of(context).size.width * widget.left,
          top: _fallAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


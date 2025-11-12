import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design/tokens.dart';

/// BEAUTIFUL FEATURE CARD
/// 
/// Glass morphism cards for Life's Task Discovery features
/// Matches the stunning design of habit system cards

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? progressText;
  final int? progressValue; // 0-100
  final bool glowEffect;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.progressText,
    this.progressValue,
    this.glowEffect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
          border: Border.all(
            color: Colors.white.withOpacity(glowEffect ? 0.3 : 0.1),
            width: glowEffect ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(glowEffect ? 0.4 : 0.2),
              blurRadius: glowEffect ? 30 : 20,
              spreadRadius: glowEffect ? 2 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
          child: Stack(
            children: [
              // Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Glass overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),

              // Animated particles (more elegant for feature cards)
              Positioned.fill(
                child: _buildParticles(),
              ),

              // Content - smaller padding for compact cards
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg), // ✅ Reduced from xl to lg
                child: Row(
                  children: [
                    // Icon container - smaller
                    Container(
                      width: 48, // ✅ Reduced from 64 to 48
                      height: 48, // ✅ Reduced from 64 to 48
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 24, // ✅ Reduced from 32 to 24
                        color: Colors.white,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          duration: 3000.ms,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.08, 1.08),
                        ),

                    const SizedBox(width: AppSpacing.lg),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6, // ✅ FIX 1: Slightly more padding for better pill shape
                            ),
                            decoration: BoxDecoration(
                              color: gradientColors.first.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(100), // ✅ FIX 1: Force full pill shape
                              border: Border.all(
                                color: gradientColors.first.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  badge,
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xs), // ✅ Reduced spacing

                          // Title - smaller and more compact
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18, // ✅ Reduced from 22 to 18
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.2, // ✅ Tighter line height
                            ),
                            maxLines: 2, // ✅ Allow max 2 lines for "The Book Of\nPurpose"
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Subtitle - smaller
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12, // ✅ Reduced from 14 to 12
                              height: 1.3,
                            ),
                            maxLines: 3, // ✅ Increased from 2 to 3 to show full descriptions
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Progress (if provided)
                          if (progressText != null || progressValue != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildProgress(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.3),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 700.ms)
      .slideY(begin: 0.2, end: 0, duration: 700.ms, curve: Curves.easeOutCubic)
      .then(delay: 200.ms)
      .shimmer(
        duration: glowEffect ? 1500.ms : 2500.ms,
        color: gradientColors.first.withOpacity(glowEffect ? 0.5 : 0.3),
      )
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(
        begin: const Offset(1.0, 1.0),
        end: Offset(glowEffect ? 1.03 : 1.015, glowEffect ? 1.03 : 1.015),
        duration: glowEffect ? 1800.ms : 2500.ms,
        curve: Curves.easeInOut,
      );
  }

  Widget _buildParticles() {
    return Stack(
      children: List.generate(8, (index) {
        return Positioned(
          left: (index * 43) % 100 + 5.0,
          top: (index * 67) % 100 + 5.0,
          child: Container(
            width: index % 2 == 0 ? 4 : 3,
            height: index % 2 == 0 ? 4 : 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: (1000 + index * 150).ms)
              .then()
              .fadeOut(duration: (1000 + index * 150).ms),
        );
      }),
    );
  }

  Widget _buildProgress() {
    if (progressValue != null) {
      // Progress bar
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                progressText ?? 'Progress',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$progressValue%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: LinearProgressIndicator(
              value: progressValue! / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (progressText != null) {
      // Simple text
      return Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            progressText!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}


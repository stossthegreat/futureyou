import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AppColors.emerald.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Hero Header
              SliverToBoxAdapter(
                child: _buildHeroHeader(),
              ),

              // Personal OS Card - OUR CORE STRENGTH
              SliverToBoxAdapter(
                child: _buildPersonalOSCard(),
              ),

              // AI-Powered Tools Section
              SliverToBoxAdapter(
                child: _buildSectionTitle('🤖 AI-POWERED TRANSFORMATION'),
              ),

              // Feature Cards Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      title: 'Book of Purpose',
                      subtitle: 'Cinematic Journey',
                      emoji: '📖',
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFFBBF24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/cinematic'),
                      badge: 'NEW',
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'What-If Simulator',
                      subtitle: 'Predict Future',
                      emoji: '✨',
                      gradient: LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 3),
                      badge: 'HOT',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'AI Visualization',
                      subtitle: 'Funeral Exercise',
                      emoji: '🎬',
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ),
                      onTap: () {
                        // Navigate to visualization videos
                      },
                      badge: 'ELITE',
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'AI Coach',
                      subtitle: '24/7 Guidance',
                      emoji: '🧠',
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 2),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                  ]),
                ),
              ),

              // Habit Systems Section
              SliverToBoxAdapter(
                child: _buildSectionTitle('💎 VIRAL HABIT SYSTEMS'),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      title: '15 Viral Systems',
                      subtitle: 'Proven Frameworks',
                      emoji: '🔥',
                      gradient: LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                      ),
                      onTap: () {
                        // Navigate to viral systems
                      },
                      stats: '15 Systems',
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Habit Library',
                      subtitle: 'Science-Backed',
                      emoji: '📚',
                      gradient: LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
                      ),
                      onTap: () {
                        // Navigate to habit library
                      },
                      stats: '100+ Habits',
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'System Creator',
                      subtitle: 'Build Custom',
                      emoji: '🎨',
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 1),
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Habit Master',
                      subtitle: '3-Phase Plans',
                      emoji: '⚡',
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFFFBBF24)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 3),
                    ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.3),
                  ]),
                ),
              ),

              // Mirror & Streaks Section (from Mirror page)
              SliverToBoxAdapter(
                child: _buildSectionTitle('🪞 PROGRESS & REFLECTION'),
              ),

              SliverToBoxAdapter(
                child: _buildMirrorSection(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Animated logo/icon
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald.withOpacity(0.8),
                      AppColors.cyan.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald
                          .withOpacity(0.4 + (_glowController.value * 0.3)),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2)),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'COMMAND CENTER',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    AppColors.emerald,
                    AppColors.cyan,
                    AppColors.emerald,
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
              letterSpacing: 2,
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Your Personal Transformation OS',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildPersonalOSCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            gradient: LinearGradient(
              colors: [
                AppColors.emerald.withOpacity(0.2),
                AppColors.cyan.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Icon(
                      LucideIcons.cpu,
                      color: AppColors.emerald,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PERSONAL OS',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The only app that adapts to YOU',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Key Features
              _buildOSFeature('🧠', 'AI learns your patterns'),
              _buildOSFeature('🎯', 'Adapts to your goals'),
              _buildOSFeature('⚡', 'Evolves with you'),
              _buildOSFeature('💎', 'Unique to YOU'),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms);
  }

  Widget _buildOSFeature(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Gradient gradient,
    required VoidCallback onTap,
    String? badge,
    String? stats,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          child: Stack(
            children: [
              // Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),

              // Glass overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 48),
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (stats != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stats,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Badge
              if (badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMirrorSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withOpacity(0.1),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Current Streak',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '47 Days',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Completion Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💯 Completion Rate',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '89%',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Active Systems
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ Active Systems',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '12',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3);
  }
}


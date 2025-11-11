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
      backgroundColor: Colors.black, // ✅ CHANGE 3: Pure black background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Future-You OS Header with Settings
            SliverToBoxAdapter(
              child: _buildFutureYouHeader(),
            ),

            // ✅ CHANGE 1: Removed _buildManifesto() - the big box at top

            // THE CORE: AI-POWERED PURPOSE ENGINE
            SliverToBoxAdapter(
              child: _buildCoreEngine(),
            ),

            // AI-Powered Tools Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('YOUR WEAPONS'),
            ),

            // Feature Cards Grid - ✅ CHANGE 2: Increased height to show full text
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65, // Changed from 0.75 to 0.65 for taller cards
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      title: 'Book of Purpose',
                      subtitle: '7-phase deep interrogation to find your life\'s task. No bullshit. No fluff.',
                      emoji: '📖',
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFFBBF24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/cinematic'),
                      badge: 'CORE',
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'What-If Simulator',
                      subtitle: 'GPT-5 simulates your future in terrifying detail. See the consequences before you choose.',
                      emoji: '⚡',
                      gradient: LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 4),
                      badge: 'POWERFUL',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'Funeral Exercise',
                      subtitle: 'Face your death. Then live like you mean it. AI-guided visualization.',
                      emoji: '💀',
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ),
                      onTap: () {
                        // Navigate to visualization videos
                      },
                      badge: 'RUTHLESS',
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'AI Accountability',
                      subtitle: 'GPT-5 watches everything. Checks in daily. Refuses to let you quit.',
                      emoji: '👁️',
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 3),
                      badge: 'ALWAYS ON',
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                  ]),
                ),
              ),

              // Habit Systems Section
              SliverToBoxAdapter(
                child: _buildSectionTitle('HABIT WARFARE'),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      title: 'Viral Systems',
                      subtitle: '15 battle-tested systems used by millions. 5AM Club. 75 Hard. Monk Mode.',
                      emoji: '🔥',
                      gradient: LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                      ),
                      onTap: () {
                        // Navigate to viral systems
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Habit Library',
                      subtitle: '100+ science-backed habits. Pre-built. Ready to commit.',
                      emoji: '📚',
                      gradient: LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
                      ),
                      onTap: () {
                        // Navigate to habit library
                      },
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'System Creator',
                      subtitle: 'Build your own habit system. Custom colors. Custom schedule.',
                      emoji: '🎨',
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 2),
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Habit Master',
                      subtitle: 'GPT-5 creates personalized 3-phase transformation plans.',
                      emoji: '⚡',
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFFFBBF24)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/main', arguments: 4),
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

  Widget _buildFutureYouHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Future-You OS Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.emerald, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.brain,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FUTURE-YOU OS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [AppColors.emerald, AppColors.cyan],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 24)),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Powered by GPT-5',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Settings Icon
          IconButton(
            onPressed: () {
              // Navigate to settings
            },
            icon: const Icon(
              LucideIcons.settings,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ✅ _buildManifesto() removed - no longer needed

  Widget _buildCoreEngine() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        gradient: LinearGradient(
          colors: [
            Colors.black,
            AppColors.cyan.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.cyan, AppColors.emerald],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan
                              .withOpacity(0.4 + (_glowController.value * 0.3)),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.zap,
                      color: Colors.white,
                      size: 26,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI PURPOSE ENGINE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'GPT-5 · Always Watching',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._buildEngineBullets(),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2);
  }

  List<Widget> _buildEngineBullets() {
    final bullets = [
      ('🎯', 'FINDS your life\'s task through 7-phase deep interrogation'),
      ('🧠', 'LEARNS your patterns, strengths, and psychological drivers'),
      ('⚡', 'ADAPTS your habits and goals as you evolve'),
      ('💎', 'HOLDS you accountable with AI-powered check-ins'),
      ('🔥', 'REFUSES to let you settle for mediocrity'),
    ];

    return bullets.map((bullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bullet.$1,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bullet.$2,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // OLD Personal OS Card removed - replaced with Manifesto and Core Engine

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

                    // Subtitle (longer description) - ✅ CHANGE 2: Show full text
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 5, // Increased from 4 to 5
                      overflow: TextOverflow.visible, // Changed from ellipsis to visible
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


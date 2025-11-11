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
            // ✅ NEW: Welcome header - centered, no logo
            SliverToBoxAdapter(
              child: _buildWelcomeHeader(),
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
                      onTap: () => Navigator.pushNamed(context, '/what-if'),
                      badge: 'POWERFUL',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'Funeral Exercise',
                      subtitle: 'Face your death. Then live like you mean it. AI-guided visualization.',
                      emoji: '💀',
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/future-you'),
                      badge: 'RUTHLESS',
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),

                    _buildFeatureCard(
                      title: 'AI Accountability',
                      subtitle: 'GPT-5 watches everything. Checks in daily. Refuses to let you quit.',
                      emoji: '👁️',
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/reflections'),
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
                    childAspectRatio: 0.65,
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
                      onTap: () => Navigator.pushNamed(context, '/viral-systems'),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Celebrity Systems',
                      subtitle: '25 viral celebrity routines. The Rock. Huberman. Ronaldo. Commit any system instantly.',
                      emoji: '⭐',
                      gradient: LinearGradient(
                        colors: [Color(0xFFDA22FF), Color(0xFF9733EE), Color(0xFF4F46E5)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/celebrity-systems'),
                      badge: 'NEW',
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Mastery Lessons',
                      subtitle: '25 viral habit formation rules. 2-Minute Rule. Habit Stacking. Identity-Based Habits.',
                      emoji: '📖',
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF0080), Color(0xFFFF8C00), Color(0xFF40E0D0)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/mastery-lessons'),
                      badge: 'NEW',
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),

                    _buildFeatureCard(
                      title: 'Saved Plans',
                      subtitle: 'Your vault of What-If simulations and habit systems. All saved plans in one place.',
                      emoji: '💎',
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/habit-vault'),
                    ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.3),
                  ]),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Welcome header - centered, no logo
  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          // Big beautiful title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.emerald,
                AppColors.cyan,
                AppColors.emerald,
              ],
            ).createShader(bounds),
            child: const Text(
              'WELCOME TO\nFUTURE-YOU OS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Subtitle
          Text(
            'The first AI Operating System that helps you\nbecome who you\'re meant to be',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1, end: 0);
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


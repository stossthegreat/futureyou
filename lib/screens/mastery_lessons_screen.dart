import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/simple_header.dart';
import '../data/mastery_rules.dart';

class MasteryLessonsScreen extends StatelessWidget {
  const MasteryLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header
          const SliverAppBar(
            expandedHeight: 80,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: SimpleHeader(),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6347)],
                  ).createShader(bounds),
                  child: const Text(
                    'Habit Mastery Lessons',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'The Ultimate Viral Habit Formation Rules',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

                const SizedBox(height: AppSpacing.xl),

                // Stats bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emerald.withOpacity(0.2),
                        AppColors.cyan.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: LucideIcons.trendingUp,
                            label: '15B+',
                            subtitle: 'TikTok views',
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                          _StatItem(
                            icon: LucideIcons.bookOpen,
                            label: '50M+',
                            subtitle: 'Books sold',
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                          _StatItem(
                            icon: LucideIcons.calendar,
                            label: '66 Days',
                            subtitle: 'Average',
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

                const SizedBox(height: AppSpacing.xl),

                // Mastery cards grid
                ...List.generate(masteryRules.length, (index) {
                  final rule = masteryRules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _MasteryCard(
                      rule: rule,
                      onTap: () => _showRuleDetail(context, rule),
                    ).animate(delay: Duration(milliseconds: index * 30))
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),
                  );
                }),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showRuleDetail(BuildContext context, MasteryRule rule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RuleDetailScreen(rule: rule),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.emerald, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        Text(
          subtitle,
          style: AppTextStyles.captionSmall.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final MasteryRule rule;
  final VoidCallback onTap;

  const _MasteryCard({
    required this.rule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]).withOpacity(0.3),
              Color.fromARGB(255, rule.gradientColors[3], rule.gradientColors[4], rule.gradientColors[5]).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
                          Color.fromARGB(255, rule.gradientColors[3], rule.gradientColors[4], rule.gradientColors[5]),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${rule.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              rule.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rule.title,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.subtitle,
                          style: AppTextStyles.captionSmall.copyWith(
                            color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleDetailScreen extends StatelessWidget {
  final MasteryRule rule;

  const _RuleDetailScreen({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
                      Color.fromARGB(255, rule.gradientColors[3], rule.gradientColors[4], rule.gradientColors[5]),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rule.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'RULE #${rule.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        rule.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        rule.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // The Rule
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]).withOpacity(0.2),
                        Color.fromARGB(255, rule.gradientColors[3], rule.gradientColors[4], rule.gradientColors[5]).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE RULE',
                        style: AppTextStyles.caption.copyWith(
                          color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rule.rule,
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.xl),

                // Key Points
                Text(
                  'KEY POINTS',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(rule.keyPoints.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, rule.gradientColors[0], rule.gradientColors[1], rule.gradientColors[2]),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            rule.keyPoints[index],
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0);
                }),

                const SizedBox(height: AppSpacing.xl),

                // Examples
                Text(
                  'EXAMPLES',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(rule.examples.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        rule.examples[index],
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0);
                }),

                const SizedBox(height: AppSpacing.xl),

                // Why It Works
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.lightbulb, color: AppColors.emerald, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'WHY IT WORKS',
                            style: TextStyle(
                              color: AppColors.emerald,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rule.whyItWorks,
                        style: AppTextStyles.body.copyWith(color: AppColors.emerald),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


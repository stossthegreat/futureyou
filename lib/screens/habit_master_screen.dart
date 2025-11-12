import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/simple_header.dart';
import 'what_if_redesign.dart';
import 'habit_library_screen.dart';
import 'viral_systems_screen.dart';
import 'habit_vault_screen.dart';
import 'celebrity_systems_screen.dart';
import 'mastery_lessons_screen.dart';

/// 🎯 HABIT MASTER TAB
/// Central hub for all habit-related features:
/// - What-If AI
/// - Habit Library  
/// - Viral Systems
/// - Celebrity Systems
/// - Habit Lessons
class HabitMasterScreen extends StatelessWidget {
  const HabitMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background like other tabs
      body: CustomScrollView(
        slivers: [
          // Header with settings icon
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
                // Title Section
                // ✅ Removed "Future-You OS" prefix per user request
                
                const SizedBox(height: 8),
                
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6347)],
                  ).createShader(bounds),
                  child: const Text(
                    'Master Your Habits',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.xl),

                // 🎯 CARD 1: What-If AI (routes to old what-if content)
                _MasterCard(
                  title: 'What-If AI',
                  subtitle: 'Build science-backed habit plans',
                  icon: LucideIcons.brain,
                  gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB)],
                  accentColor: const Color(0xFF667EEA),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WhatIfRedesignScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: AppSpacing.lg),

                // 🎯 CARD 2: Habit Library
                _MasterCard(
                  title: 'Habit Library',
                  subtitle: '100+ evidence-based habits',
                  icon: LucideIcons.library,
                  gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                  accentColor: const Color(0xFF11998E),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HabitLibraryScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.lg),

                // 🎯 CARD 3: Viral Systems
                _MasterCard(
                  title: 'Viral Systems',
                  subtitle: '15 trending habit systems',
                  icon: LucideIcons.trendingUp,
                  gradientColors: const [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFFC837)],
                  accentColor: const Color(0xFFFF6B35),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViralSystemsScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: AppSpacing.lg),

                // 🎯 CARD 4: Celebrity Systems
                _MasterCard(
                  title: 'Celebrity Systems',
                  subtitle: '25 viral celebrity routines',
                  icon: LucideIcons.star,
                  gradientColors: const [Color(0xFFDA22FF), Color(0xFF9733EE), Color(0xFF4F46E5)],
                  accentColor: const Color(0xFFDA22FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CelebritySystemsScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideX(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.lg),

                // 🎯 CARD 5: Mastery Lessons
                _MasterCard(
                  title: 'Mastery Lessons',
                  subtitle: '25 viral habit formation rules',
                  icon: LucideIcons.bookOpen,
                  gradientColors: const [Color(0xFFFF0080), Color(0xFFFF8C00), Color(0xFF40E0D0)],
                  accentColor: const Color(0xFFFF0080),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MasteryLessonsScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideX(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.lg),

                // 🎯 CARD 6: Habit Vault (moved to bottom)
                _MasterCard(
                  title: 'Habit Vault',
                  subtitle: 'Your saved plans & simulations',
                  icon: LucideIcons.archive,
                  gradientColors: const [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6347)],
                  accentColor: const Color(0xFFFFD700),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HabitVaultScreen()),
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beautiful master card with gradient, animations, and optional badge
class _MasterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  const _MasterCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Dark overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),

              // Animated particles
              Positioned.fill(
                child: _AnimatedParticles(),
              ),

              // Badge (if present)
              if (badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(
                      LucideIcons.chevronRight,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated floating particles for visual flair
class _AnimatedParticles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(8, (index) {
        return Positioned(
          left: (index * 43) % 120 + 20,
          top: (index * 57) % 100 + 10,
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: (1000 + index * 200).ms)
              .then()
              .fadeOut(duration: (1000 + index * 200).ms),
        );
      }),
    );
  }
}


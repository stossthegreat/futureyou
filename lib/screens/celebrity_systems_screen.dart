import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/simple_header.dart';
import '../data/celebrity_systems.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class CelebritySystemsScreen extends ConsumerStatefulWidget {
  const CelebritySystemsScreen({super.key});

  @override
  ConsumerState<CelebritySystemsScreen> createState() => _CelebritySystemsScreenState();
}

class _CelebritySystemsScreenState extends ConsumerState<CelebritySystemsScreen> {
  String _selectedFilter = 'All';

  List<CelebritySystem> get _filteredSystems {
    if (_selectedFilter == 'All') return celebritySystems;
    return celebritySystems.where((s) => s.tier.contains(_selectedFilter)).toList();
  }

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
                  shaderCallback: (bounds) => AppColors.emeraldGradient.createShader(bounds),
                  child: const Text(
                    'Celebrity Habit Systems',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Most Followed, Most Viewed, Most Influential',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

                const SizedBox(height: AppSpacing.xl),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'MEGA-VIRAL',
                        isSelected: _selectedFilter == 'MEGA-VIRAL',
                        onTap: () => setState(() => _selectedFilter = 'MEGA-VIRAL'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'SUPER VIRAL',
                        isSelected: _selectedFilter == 'SUPER VIRAL',
                        onTap: () => setState(() => _selectedFilter = 'SUPER VIRAL'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'INFLUENTIAL',
                        isSelected: _selectedFilter == 'INFLUENTIAL',
                        onTap: () => setState(() => _selectedFilter = 'INFLUENTIAL'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Celebrity cards
                ...List.generate(_filteredSystems.length, (index) {
                  final system = _filteredSystems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _CelebrityCard(
                      system: system,
                      onTap: () => _showSystemDetail(system),
                    ).animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
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

  void _showSystemDetail(CelebritySystem system) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SystemDetailSheet(system: system),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.emerald : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CelebrityCard extends StatelessWidget {
  final CelebritySystem system;
  final VoidCallback onTap;

  const _CelebrityCard({
    required this.system,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]).withOpacity(0.3),
              Color.fromARGB(255, system.gradientColors[3], system.gradientColors[4], system.gradientColors[5]).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]).withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  system.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        system.name,
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                      Text(
                        system.subtitle,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]),
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
            const SizedBox(height: AppSpacing.md),
            Text(
              system.title,
              style: AppTextStyles.h3.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${system.habits.length} habits • Tap to commit',
              style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemDetailSheet extends ConsumerWidget {
  final CelebritySystem system;

  const _SystemDetailSheet({required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xl)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]).withOpacity(0.3),
                  Color.fromARGB(255, system.gradientColors[3], system.gradientColors[4], system.gradientColors[5]).withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                Text(
                  system.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        system.name,
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      Text(
                        system.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Why it's viral
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trendingUp, color: AppColors.emerald, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            system.whyViral,
                            style: AppTextStyles.body.copyWith(color: AppColors.emerald),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'THE SYSTEM',
                    style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Habits list
                  ...List.generate(system.habits.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              system.habits[index],
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xl),

                  // Commit button
                  GestureDetector(
                    onTap: () => _commitSystem(context, ref, system),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, system.gradientColors[0], system.gradientColors[1], system.gradientColors[2]),
                            Color.fromARGB(255, system.gradientColors[3], system.gradientColors[4], system.gradientColors[5]),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Commit to This System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _commitSystem(BuildContext context, WidgetRef ref, CelebritySystem system) async {
    // Create habits from the system
    final now = DateTime.now();
    for (var habitText in system.habits) {
      final habit = Habit(
        id: '${now.millisecondsSinceEpoch}_${system.habits.indexOf(habitText)}',
        title: habitText,
        type: 'habit',
        time: '09:00',
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        repeatDays: [1, 2, 3, 4, 5, 6, 0], // All days
        createdAt: now,
        systemId: system.name,
      );
      ref.read(habitEngineProvider.notifier).addHabit(habit);
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Added ${system.habits.length} habits from ${system.name}\'s system!'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}


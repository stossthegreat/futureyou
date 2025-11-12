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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => _CommitDialog(system: system),
                      );
                    },
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
}

// Commit Dialog Widget (copied from Viral Systems)
class _CommitDialog extends ConsumerStatefulWidget {
  final CelebritySystem system;

  const _CommitDialog({required this.system});

  @override
  ConsumerState<_CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<_CommitDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _alarmEnabled = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 9, minute: 0);
  late List<bool> _selectedHabits;
  String _scheduleType = 'everyday';
  
  @override
  void initState() {
    super.initState();
    _selectedHabits = List.filled(widget.system.habits.length, true);
  }
  
  Color _getTextColor() {
    final colors = widget.system.gradientColors;
    double totalBrightness = 0;
    for (int i = 0; i < colors.length; i += 3) {
      final r = colors[i] / 255.0;
      final g = colors[i + 1] / 255.0;
      final b = colors[i + 2] / 255.0;
      totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b);
    }
    return (totalBrightness / (colors.length / 3)) > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, widget.system.gradientColors[0], widget.system.gradientColors[1], widget.system.gradientColors[2]),
              Color.fromARGB(255, widget.system.gradientColors[3], widget.system.gradientColors[4], widget.system.gradientColors[5]),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Commit to ${widget.system.name}',
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Habits Selection
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Habits (${_selectedHabits.where((s) => s).length}/${widget.system.habits.length})',
                      style: TextStyle(
                        color: _getTextColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...List.generate(widget.system.habits.length, (index) {
                      return CheckboxListTile(
                        title: Text(
                          widget.system.habits[index],
                          style: TextStyle(color: _getTextColor(), fontSize: 14),
                        ),
                        value: _selectedHabits[index],
                        onChanged: (val) {
                          setState(() => _selectedHabits[index] = val ?? false);
                        },
                        activeColor: Colors.white,
                        checkColor: Color.fromARGB(255, widget.system.gradientColors[0], widget.system.gradientColors[1], widget.system.gradientColors[2]),
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _getTextColor(),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedCount = _selectedHabits.where((s) => s).length;
                        if (selectedCount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one habit')),
                          );
                          return;
                        }

                        try {
                          final now = DateTime.now();
                          final timeStr = _alarmEnabled ? '${_alarmTime.hour.toString().padLeft(2, '0')}:${_alarmTime.minute.toString().padLeft(2, '0')}' : '';
                          
                          for (int i = 0; i < widget.system.habits.length; i++) {
                            if (_selectedHabits[i]) {
                              debugPrint('🎯 Creating celebrity habit: "${widget.system.habits[i]}" with reminderOn=$_alarmEnabled, time="$timeStr"');
                              
                              final habit = Habit(
                                id: '${now.millisecondsSinceEpoch}_$i',
                                title: widget.system.habits[i],
                                type: 'habit',
                                time: timeStr,
                                startDate: _startDate,
                                endDate: _endDate,
                                repeatDays: _scheduleType == 'everyday' 
                                    ? [0, 1, 2, 3, 4, 5, 6]
                                    : _scheduleType == 'weekdays'
                                    ? [1, 2, 3, 4, 5]
                                    : [0, 6],
                                createdAt: now,
                                systemId: widget.system.name,
                                reminderOn: _alarmEnabled,
                              );
                              ref.read(habitEngineProvider.notifier).addHabit(habit);
                            }
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Committed $selectedCount habits from ${widget.system.name}!'),
                                backgroundColor: Color.fromARGB(255, widget.system.gradientColors[0], widget.system.gradientColors[1], widget.system.gradientColors[2]),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Failed to commit: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color.fromARGB(255, widget.system.gradientColors[0], widget.system.gradientColors[1], widget.system.gradientColors[2]),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'COMMIT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_strip.dart';
import '../widgets/habit_card.dart';
import '../logic/habit_engine.dart';
import '../models/habit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitEngineState = ref.watch(habitEngineProvider);
    final allHabits = habitEngineState.habits;
    
    // Filter habits for selected date
    final dayHabits = allHabits.where((habit) {
      return habit.isScheduledForDate(_selectedDate);
    }).toList();
    
    // ✅ Date-aware completion
    final completedCount = dayHabits.where((h) => h.isDoneOn(_selectedDate)).length;
    final totalCount = dayHabits.length;
    final fulfillmentPercentage = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;
    final driftPercentage = 100.0 - fulfillmentPercentage;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date strip
          DateStrip(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Fulfillment overview card
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fulfillment for Selected Day',
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textQuaternary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount/$totalCount kept',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Progress bars
                Column(
                  children: [
                    _buildProgressBar(
                      progress: fulfillmentPercentage,
                      label: 'Fulfillment Index',
                      color: AppColors.emerald,
                      description: 'Measures promises kept today across all scheduled items.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProgressBar(
                      progress: driftPercentage,
                      label: 'Drift Load (Unfulfilled)',
                      color: AppColors.warning,
                      description: 'How much you promised but didn\'t deliver (today).',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Habits list
          if (dayHabits.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 48,
                    color: AppColors.textQuaternary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nothing here yet',
                    style: AppTextStyles.bodySemiBold.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a habit or task in Planner.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: dayHabits.map((habit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: HabitCard(
                    key: ValueKey(habit.id),
                    habit: habit,
                    onToggle: () async {
                      await ref.read(habitEngineProvider.notifier).toggleHabitCompletion(habit.id);
                    },
                    onDelete: () async {
                      await ref.read(habitEngineProvider.notifier).deleteHabit(habit.id);
                    },
                  ),
                );
              }).toList(),
            ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Integrity footer
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.gauge,
                        size: 16,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Integrity = Promises Kept / Promises Made',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Trend engine hooks in backend',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding for navigation
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar({
    required double progress,
    required String label,
    required Color color,
    required String description,
  }) {
    final clampedProgress = progress.clamp(0.0, 100.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              '${clampedProgress.toInt()}%',
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            color: AppColors.glassBackground,
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
                FractionallySizedBox(
                  widthFactor: clampedProgress / 100,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textQuaternary,
          ),
        ),
      ],
    );
  }
}

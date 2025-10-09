import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_strip.dart';
import '../widgets/habit_card.dart';
import '../services/local_storage.dart';
import '../logic/habit_engine.dart';

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
  
  void _toggleHabit(String habitId) async {
    final habit = LocalStorageService.getHabit(habitId);
    if (habit != null) {
      await LocalStorageService.updateHabitCompletion(habitId, !habit.done);
      setState(() {}); // Refresh UI
      
      // Sync to backend
      ref.read(habitEngineProvider.notifier).syncHabitCompletion(habitId, !habit.done);
    }
  }
  
  void _deleteHabit(String habitId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(),
    );
    
    if (confirmed == true) {
      await LocalStorageService.deleteHabit(habitId);
      setState(() {}); // Refresh UI
      
      // Sync to backend
      ref.read(habitEngineProvider.notifier).deleteHabit(habitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayHabits = LocalStorageService.getHabitsForDate(_selectedDate);
    final fulfillmentPercentage = LocalStorageService.getFulfillmentPercentage(_selectedDate);
    final driftPercentage = LocalStorageService.getDriftPercentage(_selectedDate);
    final completedCount = dayHabits.where((h) => h.done).length;
    final totalCount = dayHabits.length;
    
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
                    HabitProgressBar(
                      progress: fulfillmentPercentage,
                      label: 'Fulfillment Index',
                      gradient: AppColors.fulfillmentGradient,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HabitProgressBar(
                      progress: driftPercentage,
                      label: 'Drift Load (Unfulfilled)',
                      gradient: AppColors.driftGradient,
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
                    'Add a habit or task in Planner to get started.',
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
                return HabitCard(
                  key: ValueKey(habit.id),
                  habit: habit,
                  onToggle: () => _toggleHabit(habit.id),
                  onDelete: () => _deleteHabit(habit.id),
                );
              }).toList(),
            ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Integrity meter footer
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
  
  Widget _buildDeleteConfirmationDialog() {
    return AlertDialog(
      backgroundColor: AppColors.baseDark2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: Text(
        'Delete Habit',
        style: AppTextStyles.h3,
      ),
      content: Text(
        'Are you sure you want to delete this habit? This action cannot be undone.',
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              onTap: () => Navigator.of(context).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  'Delete',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HabitProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  final Gradient gradient;
  
  const HabitProgressBar({
    super.key,
    required this.progress,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * (clampedProgress / 100),
                      height: double.infinity,
                      decoration: BoxDecoration(gradient: gradient),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _getProgressMessage(clampedProgress),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textQuaternary,
          ),
        ),
      ],
    );
  }
  
  String _getProgressMessage(double progress) {
    if (progress >= 100) {
      return "Perfect! All promises kept today.";
    } else if (progress >= 80) {
      return "Excellent progress! Keep pushing.";
    } else if (progress >= 60) {
      return "Good momentum. Stay consistent.";
    } else if (progress >= 40) {
      return "Building up. Every action counts.";
    } else if (progress >= 20) {
      return "Getting started. You've got this.";
    } else {
      return "Fresh start. Your future self is waiting.";
    }
  }
}

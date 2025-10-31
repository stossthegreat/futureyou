import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_strip.dart';
import '../widgets/scrollable_header.dart';
import '../widgets/nudge_banner.dart';
import '../widgets/morning_brief_modal.dart';
import '../providers/habit_provider.dart';
import '../services/messages_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _hasShownBrief = false;
  
  @override
  void initState() {
    super.initState();
    _checkForMorningBrief();
  }

  void _checkForMorningBrief() {
    // Check if it's morning (6am - 10am) and if we haven't shown brief yet today
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour < 10 && !_hasShownBrief) {
      final brief = messagesService.getTodaysBrief();
      if (brief != null && !brief.isRead) {
        // Show brief after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showMorningBrief(context, brief);
            _hasShownBrief = true;
          }
        });
      }
    }
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitEngine = ref.watch(habitEngineProvider);
    final allHabits = habitEngine.habits;
    
    // Filter habits for selected date
    final dayHabits = allHabits.where((habit) {
      return habit.isScheduledForDate(_selectedDate);
    }).toList();
    
    // ✅ Date-aware completion
    final completedCount = dayHabits.where((h) => h.isDoneOn(_selectedDate)).length;
    
    // Check for active nudge
    final activeNudge = messagesService.getActiveNudge();
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    
    // Format date like React: "Thursday, Oct 30, 2025"
    final dateFormatter = DateFormat('EEEE, MMM d, yyyy');
    final formattedDate = dateFormatter.format(_selectedDate);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable header
            const ScrollableHeader(),
            
            // Date strip
            DateStrip(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            
            // Nudge Banner (only for today)
            if (activeNudge != null && isToday)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: NudgeBanner(
                  nudge: activeNudge,
                  onDismiss: () => setState(() {}),
                  onDoIt: () {
                    // Scroll to first undone habit
                  },
                ),
              ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Simple date subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                formattedDate,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Habit cards (React style)
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: dayHabits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final habit = entry.value;
                  final isDone = habit.isDoneOn(_selectedDate);
                  
                  return _buildReactHabitCard(
                    habit: habit,
                    isDone: isDone,
                    index: index,
                    onToggle: () async {
                      await ref.read(habitEngineProvider).toggleHabitCompletion(habit.id);
                    },
                  );
                }).toList(),
              ),
            ),
          
          // Bottom padding for nav bar (extra space for breathing room)
          const SizedBox(height: 150),
        ],
      ),
    ),
    );
  }
  
  Widget _buildReactHabitCard({
    required dynamic habit,
    required bool isDone,
    required int index,
    required VoidCallback onToggle,
  }) {
    final timeFormatter = DateFormat('HH:mm');
    final time = timeFormatter.format(DateTime.parse('2025-01-01 ${habit.time}:00'));
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDone 
                ? AppColors.emerald.withOpacity(0.05)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: isDone
                  ? AppColors.emerald.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emoji or icon
                  if (habit.emoji != null)
                    Text(
                      habit.emoji!,
                      style: const TextStyle(fontSize: 32),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.flame,
                        size: 20,
                        color: AppColors.emerald,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time + Status chip
                        Row(
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('•', style: TextStyle(color: Colors.white38)),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppColors.emerald.withOpacity(0.15)
                                    : AppColors.cyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.emerald.withOpacity(0.3)
                                      : AppColors.cyan.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isDone ? 'done' : 'planned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isDone
                                      ? AppColors.emeraldLight
                                      : AppColors.cyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Title
                        Text(
                          habit.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkmark icon
                  Icon(
                    isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 28,
                    color: isDone
                        ? AppColors.emerald
                        : Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: isDone ? 1.0 : 0.56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isDone
                                ? AppColors.emeraldGradient
                                : LinearGradient(
                                    colors: [AppColors.cyan, AppColors.emerald],
                                  ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.full),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 30).ms)
      .fadeIn(duration: 260.ms)
      .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
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
                      gradient: label.contains('Fulfillment') 
                          ? AppColors.emeraldGradient 
                          : LinearGradient(
                              colors: [color, color.withOpacity(0.8)],
                            ),
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

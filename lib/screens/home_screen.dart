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
import '../services/weekly_stats_service.dart';
import '../services/local_storage.dart';
import '../models/habit_system.dart';
import '../widgets/week_overview_card.dart';

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
    
    // Load all systems and group habits
    final allSystems = LocalStorageService.getAllSystems();
    
    // Group habits by system
    final Map<String, List<dynamic>> systemHabitsMap = {};
    final List<dynamic> standaloneHabits = [];
    
    for (final habit in dayHabits) {
      bool belongsToSystem = false;
      for (final system in allSystems) {
        if (system.habitIds.contains(habit.id)) {
          if (!systemHabitsMap.containsKey(system.id)) {
            systemHabitsMap[system.id] = [];
          }
          systemHabitsMap[system.id]!.add(habit);
          belongsToSystem = true;
          break;
        }
      }
      if (!belongsToSystem) {
        standaloneHabits.add(habit);
      }
    }
    
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
            
            // Habit cards (System cards + Standalone habits)
          if (dayHabits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl * 2),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 32,
                      color: AppColors.textQuaternary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Nothing here yet',
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Add a habit or task in Planner.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // System Cards
                  ...allSystems.where((system) => systemHabitsMap.containsKey(system.id)).map((system) {
                    final systemHabits = systemHabitsMap[system.id]!;
                    return _buildSystemCard(
                      system: system,
                      habits: systemHabits,
                      selectedDate: _selectedDate,
                    );
                  }).toList(),
                  
                  // Standalone Habit Cards
                  ...standaloneHabits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    final isDone = habit.isDoneOn(_selectedDate);
                    
                    return _buildReactHabitCard(
                      habit: habit,
                      isDone: isDone,
                      index: index + allSystems.length,
                      onToggle: () async {
                        await ref.read(habitEngineProvider).toggleHabitCompletion(habit.id);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Week Overview Card
          WeekOverviewCard(
            stats: WeeklyStatsService.calculateCurrentWeekStats(),
          ),
          
          // Bottom padding for nav bar (extra space for breathing room)
          const SizedBox(height: 150),
        ],
      ),
    ),
    );
  }
  
  // System Card Widget - looks exactly like viral system cards
  Widget _buildSystemCard({
    required HabitSystem system,
    required List<dynamic> habits,
    required DateTime selectedDate,
  }) {
    // Calculate completion
    final completedCount = habits.where((h) => h.isDoneOn(selectedDate)).length;
    final completion = habits.isEmpty ? 0 : ((completedCount / habits.length) * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: system.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Text(
                        system.name.isNotEmpty ? system.name[0].toUpperCase() : '⭐',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            system.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            system.tagline,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body with progress + habits
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Progress ring + stats
                    Row(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: completion / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(system.accentColor),
                              ),
                              Center(
                                child: Text(
                                  '$completion%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$completedCount/${habits.length} habits today',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Habits list - clickable for ticking
                    ...habits.map((habit) {
                      final isDone = habit.isDoneOn(selectedDate);
                      return GestureDetector(
                        onTap: () async {
                          await ref.read(habitEngineProvider).toggleHabitCompletion(habit.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isDone ? system.accentColor : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isDone
                                    ? const Icon(LucideIcons.check, color: Colors.white, size: 10)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  habit.title,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildReactHabitCard({
    required dynamic habit,
    required bool isDone,
    required int index,
    required VoidCallback onToggle,
  }) {
    // Handle empty time (for system habits that don't have a specific time)
    String? time;
    if (habit.time != null && habit.time.isNotEmpty) {
      try {
        final timeFormatter = DateFormat('HH:mm');
        time = timeFormatter.format(DateTime.parse('2025-01-01 ${habit.time}:00'));
      } catch (e) {
        time = null; // Invalid time format, treat as no time
      }
    }
    
    // Use the habit's chosen color
    final habitColor = habit.color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDone 
                ? habitColor.withOpacity(0.05)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: isDone
                  ? habitColor.withOpacity(0.3)
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
                        color: habitColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.flame,
                        size: 20,
                        color: habitColor,
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
                            if (time != null) ...[
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: habitColor,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('•', style: TextStyle(color: Colors.white38)),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: habitColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: habitColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isDone ? 'done' : 'planned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: habitColor,
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
                        ? habitColor
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
                            gradient: LinearGradient(
                              colors: [
                                habitColor.withOpacity(0.8),
                                habitColor,
                              ],
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/simple_header.dart';
import '../providers/habit_provider.dart';

class ViralSystemsScreen extends ConsumerStatefulWidget {
  const ViralSystemsScreen({super.key});

  @override
  ConsumerState<ViralSystemsScreen> createState() => _ViralSystemsScreenState();
}

class _ViralSystemsScreenState extends ConsumerState<ViralSystemsScreen> {
  final List<ViralSystem> _systems = [
    ViralSystem(
      name: '5AM Club',
      tagline: 'Own your morning, own your day',
      icon: LucideIcons.sun,
      gradientColors: [const Color(0xFFFF6B35), const Color(0xFFF7931E), const Color(0xFFFFC837)],
      accentColor: const Color(0xFFFFC837),
      habits: ['⏰ Wake 5:00', '💧 Hydrate 500ml', '📖 Read 20m', '🏃 Move 20m', '🧘 Meditate 20m', '📝 Journal 20m'],
    ),
    ViralSystem(
      name: 'That Girl',
      tagline: 'Become who you\'re meant to be',
      icon: LucideIcons.sparkles,
      gradientColors: [const Color(0xFFFFB6C1), const Color(0xFFFFC0CB), const Color(0xFFFFFFFF)],
      accentColor: const Color(0xFFFF69B4),
      habits: ['🛏️ Make bed', '🧴 Skincare', '🥗 Healthy breakfast', '💪 Pilates/Yoga', '💅 Self-care', '📸 Gratitude photo'],
    ),
    ViralSystem(
      name: 'Dopamine Detox',
      tagline: 'Reset your brain, reclaim focus',
      icon: LucideIcons.zap,
      gradientColors: [const Color(0xFF00D4FF), const Color(0xFFA5F3FC), const Color(0xFFFFFFFF)],
      accentColor: const Color(0xFF00D4FF),
      habits: ['📵 No phone 1h', '🚫 No scrolling', '🥶 Cold shower', '📚 Read not scroll', '🚶 Walk no music', '🧘 Boredom practice'],
    ),
    ViralSystem(
      name: '75 Hard',
      tagline: '75 days. Zero compromise.',
      icon: LucideIcons.dumbbell,
      gradientColors: [const Color(0xFF1A1A1A), const Color(0xFFDC143C), const Color(0xFF8B0000)],
      accentColor: const Color(0xFFDC143C),
      habits: ['🏋️ 2×45m workouts', '🍎 Strict diet', '💧 1 gallon', '📖 Read 10 pages', '📸 Progress photo', '🚫 No alcohol'],
    ),
    ViralSystem(
      name: 'Deep Work',
      tagline: 'Focus is your superpower',
      icon: LucideIcons.brain,
      gradientColors: [const Color(0xFF003366), const Color(0xFF0066CC), const Color(0xFF00CCFF)],
      accentColor: const Color(0xFF00CCFF),
      habits: ['🎯 90m deep block', '☕ Break no phone', '🎯 90m block 2', '📵 Phone away', '🚫 No AM meetings', '📊 Track output'],
    ),
    ViralSystem(
      name: 'Night Routine',
      tagline: 'Wind down, wake up refreshed',
      icon: LucideIcons.moon,
      gradientColors: [const Color(0xFF4B0082), const Color(0xFF483D8B), const Color(0xFF191970)],
      accentColor: const Color(0xFF6A5ACD),
      habits: ['🧹 10-min tidy', '🛁 Shower/skincare', '📱 Phone away', '📖 Read 20m', '🧘 Breathing', '🛏️ Bed by 10'],
    ),
    ViralSystem(
      name: 'Monk Mode',
      tagline: '30-90 days of pure focus',
      icon: LucideIcons.flame,
      gradientColors: [const Color(0xFF000000), const Color(0xFFFFD700), const Color(0xFFFFA500)],
      accentColor: const Color(0xFFFFD700),
      habits: ['🚫 No dating', '📵 Social deleted', '🏋️ Train daily', '📚 Study 3h', '🧘 Meditation', '💼 Career focus'],
    ),
    ViralSystem(
      name: 'Wealth Building',
      tagline: 'Build wealth one day at a time',
      icon: LucideIcons.dollarSign,
      gradientColors: [const Color(0xFF50C878), const Color(0xFF00A86B), const Color(0xFFFFD700)],
      accentColor: const Color(0xFF00A86B),
      habits: ['📊 Check investments', '💵 Track expenses', '📚 Learn finance 20m', '💼 Side hustle 1h', '🚫 No impulse buys', '📈 Weekly review'],
    ),
    ViralSystem(
      name: 'Fitness Beast',
      tagline: 'Build the body you deserve',
      icon: LucideIcons.dumbbell,
      gradientColors: [const Color(0xFFDC143C), const Color(0xFFFF4500), const Color(0xFFFF6347)],
      accentColor: const Color(0xFFFF4500),
      habits: ['🏋️ Lift 5-6×', '🍗 Protein 1.6g/kg', '💧 Hydrate 3L+', '📸 Progress photos', '😴 Sleep 8h', '🚫 No alcohol'],
    ),
    ViralSystem(
      name: 'Morning Mindfulness',
      tagline: 'Start slow, stay centered',
      icon: LucideIcons.leaf,
      gradientColors: [const Color(0xFF90EE90), const Color(0xFF9DC183), const Color(0xFF8FBC8F)],
      accentColor: const Color(0xFF90EE90),
      habits: ['🧘 Meditate 10m', '📝 Gratitude', '☕ Slow coffee', '🚶 Mindful walk', '📵 No phone 30m', '🎵 Calm music'],
    ),
    ViralSystem(
      name: 'Creator Grind',
      tagline: 'Create, post, repeat',
      icon: LucideIcons.video,
      gradientColors: [const Color(0xFF0000FF), const Color(0xFF4B0082), const Color(0xFF8B008B)],
      accentColor: const Color(0xFF4B0082),
      habits: ['📹 Film 1 video', '✂️ Edit 30m', '📱 Post 2 platforms', '💬 Engage', '📊 Check analytics', '🧠 Study creators'],
    ),
    ViralSystem(
      name: 'Glow Up',
      tagline: 'Become your best self',
      icon: LucideIcons.star,
      gradientColors: [const Color(0xFFE0B0FF), const Color(0xFFFFC0CB), const Color(0xFFFFD700)],
      accentColor: const Color(0xFFE0B0FF),
      habits: ['💧 Water 2.5L', '🧴 AM+PM skincare', '💪 Move 30m', '🥗 Veggie meals', '😴 Sleep 7-8h', '💅 Weekly self-care'],
    ),
    ViralSystem(
      name: 'Minimalist Reset',
      tagline: 'Less stuff, more life',
      icon: LucideIcons.home,
      gradientColors: [const Color(0xFFFFFFFF), const Color(0xFFF5F5F5), const Color(0xFFD3D3D3)],
      accentColor: const Color(0xFF9CA3AF),
      habits: ['🗑️ Declutter 15m', '🧹 Clean 1 zone', '🚫 No impulse buys', '📦 Donate 1 item', '🛋️ Tidy before bed', '🧘 Mindful consume'],
    ),
    ViralSystem(
      name: '12-Week Year',
      tagline: '12 weeks = 1 year of results',
      icon: LucideIcons.target,
      gradientColors: [const Color(0xFFFF8C00), const Color(0xFFFFA500), const Color(0xFFFFD700)],
      accentColor: const Color(0xFFFFA500),
      habits: ['🎯 Weekly review', '📊 Track 3 metrics', '📅 Plan next week', '🚀 Daily execute', '🔄 Monthly reset', '📈 Quarterly review'],
    ),
    ViralSystem(
      name: 'Self-Love',
      tagline: 'You deserve your own love',
      icon: LucideIcons.heart,
      gradientColors: [const Color(0xFFFFB6C1), const Color(0xFFDDA0DD), const Color(0xFFE6E6FA)],
      accentColor: const Color(0xFFDDA0DD),
      habits: ['💭 Affirmations', '🚫 Set 1 boundary', '💅 Do for YOU', '📝 Self-compassion', '🧘 Meditation', '🛁 Evening care'],
    ),
  ];

  void _showCommitDialog(ViralSystem system) {
    showDialog(
      context: context,
      builder: (context) => _CommitDialog(system: system),
    );
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
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, color: Colors.purple[300], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Future-You OS · Viral Systems',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 8),
                
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE879F9), Color(0xFF34D399), Color(0xFF22D3EE)],
                  ).createShader(bounds),
                  child: const Text(
                    'The 15 Most Viral Habit Systems',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.xl),

                // Grid of systems - 1 column to show all habits
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _systems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _ViralSystemCard(
                        system: _systems[index],
                        onCommit: () => _showCommitDialog(_systems[index]),
                      ).animate(delay: Duration(milliseconds: index * 50))
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                    );
                  },
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViralSystemCard extends StatelessWidget {
  final ViralSystem system;
  final VoidCallback onCommit;

  const _ViralSystemCard({required this.system, required this.onCommit});

  @override
  Widget build(BuildContext context) {
    final completion = 75; // Mock completion
    final completedCount = (system.habits.length * completion / 100).ceil();
    final streak = 12; // Mock streak

    return Container(
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
            _buildHeader(),
            
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Progress ring + stats
                    _buildProgress(completion, completedCount, streak),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Habits grid
                    Expanded(child: _buildHabitsGrid(completedCount)),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Action buttons
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: system.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Animated particles
          ...List.generate(6, (i) => Positioned(
            left: (i * 15.0) % 100,
            top: (i * 20.0) % 50,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 800.ms, delay: Duration(milliseconds: i * 150))
                .fadeOut(duration: 800.ms),
          )),
          
          // Content
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(system.icon, color: Colors.white, size: 24),
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
        ],
      ),
    );
  }

  Widget _buildProgress(int completion, int completedCount, int streak) {
    return Row(
      children: [
        // Progress ring
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: AppSpacing.sm),
        
        // Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completedCount/${system.habits.length} habits',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.flame, color: Colors.orange[400], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$streak-day streak',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitsGrid(int completedCount) {
    return Column(
      children: system.habits.asMap().entries.map((entry) {
        final index = entry.key;
        final habit = entry.value;
        final completed = index < completedCount;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: completed ? system.accentColor : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: completed
                    ? const Icon(LucideIcons.check, color: Colors.white, size: 10)
                    : null,
              ),
              const SizedBox(width: 8),
              // Habit text with emoji
              Expanded(
                child: Text(
                  habit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onCommit,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: system.gradientColors,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: const Center(
                child: Text(
                  'COMMIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Center(
              child: Text(
                'Share',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommitDialog extends ConsumerStatefulWidget {
  final ViralSystem system;

  const _CommitDialog({required this.system});

  @override
  ConsumerState<_CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<_CommitDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _alarmEnabled = false;
  late List<bool> _selectedHabits;
  
  @override
  void initState() {
    super.initState();
    // All habits selected by default
    _selectedHabits = List.filled(widget.system.habits.length, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.system.gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Commit to ${widget.system.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Start Date
            _buildDateField(
              label: 'Start Date',
              date: _startDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // End Date
            _buildDateField(
              label: 'End Date',
              date: _endDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Habit Selection
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.system.habits.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedHabits[index] = !_selectedHabits[index]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_selectedHabits[index] ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(
                          color: Colors.white.withOpacity(_selectedHabits[index] ? 0.4 : 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _selectedHabits[index] ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _selectedHabits[index]
                                ? Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: widget.system.accentColor,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.system.habits[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Alarm Toggle
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    _alarmEnabled ? LucideIcons.bell : LucideIcons.bellOff,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Daily Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _alarmEnabled,
                    onChanged: (value) => setState(() => _alarmEnabled = value),
                    activeColor: Colors.white,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Count selected habits
                      final selectedCount = _selectedHabits.where((selected) => selected).length;
                      if (selectedCount == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Please select at least one habit')),
                        );
                        return;
                      }
                      
                      // Commit only selected habits
                      try {
                        final habitIds = <String>[];
                        
                        for (int i = 0; i < widget.system.habits.length; i++) {
                          if (_selectedHabits[i]) {
                            final habitId = DateTime.now().millisecondsSinceEpoch.toString() + '_$i';
                            habitIds.add(habitId);
                            
                            await ref.read(habitEngineProvider.notifier).createHabit(
                              title: widget.system.habits[i],
                              type: 'habit',
                              time: '', // No specific time for system habits
                              startDate: _startDate,
                              endDate: _endDate,
                              repeatDays: [0, 1, 2, 3, 4, 5, 6], // All days
                              color: widget.system.accentColor,
                              emoji: widget.system.habits[i].split(' ').first, // Extract emoji
                              reminderOn: _alarmEnabled,
                            );
                            
                            // Small delay to ensure unique IDs
                            await Future.delayed(const Duration(milliseconds: 10));
                          }
                        }
                        
                        // TODO: Store system metadata linking to habit IDs
                        // This will be used to show system cards on Home/Planner
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Committed $selectedCount habits from ${widget.system.name}!'),
                              backgroundColor: widget.system.accentColor,
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
                      foregroundColor: widget.system.accentColor,
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
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class ViralSystem {
  final String name;
  final String tagline;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final List<String> habits;

  ViralSystem({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.habits,
  });
}


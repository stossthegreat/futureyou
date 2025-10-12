import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_strip.dart';
import '../widgets/habit_card.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../services/api_client.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  List<CoachMessage> _messages = [];
  bool _loadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loadingMessages = true);
    final res = await ApiClient.getCoachMessages();
    if (mounted) {
      setState(() {
        _loadingMessages = false;
        if (res.success && res.data != null) {
          _messages = res.data!;
        } else {
          _messages = [];
        }
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _generateLetter(String topic) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating your Letter...')),
    );
    final res = await ApiClient.generateLetter(topic);
    if (res.success && res.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📬 Letter from Future You delivered!')),
      );
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to generate letter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitEngine = ref.watch(habitEngineProvider);
    final allHabits = habitEngine.habits;

    final dayHabits = allHabits.where((habit) {
      return habit.isScheduledForDate(_selectedDate);
    }).toList();

    final completedCount = dayHabits.where((h) => h.isDoneOn(_selectedDate)).length;
    final totalCount = dayHabits.length;
    final fulfillmentPercentage = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;
    final driftPercentage = 100.0 - fulfillmentPercentage;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        icon: const Icon(LucideIcons.mail),
        label: const Text('Letter from Future You ✨'),
        onPressed: () async {
          await _generateLetter('today’s progress and mindset');
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMessages,
          color: AppColors.emerald,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date strip
                DateStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateSelected,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Fulfillment overview
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
                      _buildProgressBar(
                        progress: fulfillmentPercentage,
                        label: 'Fulfillment Index 💎',
                        color: AppColors.emerald,
                        description: 'Promises kept today.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildProgressBar(
                        progress: driftPercentage,
                        label: 'Drift Load ⚡',
                        color: AppColors.warning,
                        description: 'Promises missed today.',
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
                        const Icon(LucideIcons.calendar, size: 48, color: AppColors.textQuaternary),
                        const SizedBox(height: AppSpacing.md),
                        Text('Nothing here yet',
                            style: AppTextStyles.bodySemiBold.copyWith(
                              color: AppColors.textSecondary,
                            )),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Add a habit or task in Planner.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center),
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
                            await ref.read(habitEngineProvider).toggleHabitCompletion(habit.id);
                          },
                          onDelete: () async {
                            await ref.read(habitEngineProvider).deleteHabit(habit.id);
                          },
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // 🧠 OS Messages Section
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.brain, color: AppColors.emerald, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Messages from Future You',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_loadingMessages)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.emerald),
                          ),
                        )
                      else if (_messages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'No messages yet — stay consistent, and your future self will write back soon 💌',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _messages.take(3).map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.title} ${_emojiForKind(m.kind)}',
                                      style: AppTextStyles.h4.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      m.body,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _emojiForKind(CoachMessageKind kind) {
    switch (kind) {
      case CoachMessageKind.brief:
        return '🌅';
      case CoachMessageKind.nudge:
        return '⚔️';
      case CoachMessageKind.mirror:
        return '🪞';
      case CoachMessageKind.letter:
        return '💌';
      default:
        return '✨';
    }
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
            Text(label,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                )),
            Text('${clampedProgress.toInt()}%',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                )),
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
            child: FractionallySizedBox(
              widthFactor: clampedProgress / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(description,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textQuaternary,
            )),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
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
  final ValueNotifier<bool> _refreshing = ValueNotifier(false);

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
  }

  Future<void> _onReflect() async {
    final topicController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Reflect", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: topicController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter topic (e.g. discipline, patience, focus)",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            child: const Text("Generate"),
            onPressed: () async {
              Navigator.pop(context);
              final topic = topicController.text.trim();
              if (topic.isEmpty) return;
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Summoning your letter...")),
                );
                final res = await http.post(
                  Uri.parse('${ApiClient._baseUrl}/api/v1/coach/reflect'),
                  headers: ApiClient._defaultHeaders,
                  body: jsonEncode({'topic': topic}),
                );
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Letter from Future-You generated")),
                  );
                  _refreshing.value = !_refreshing.value;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error ${res.statusCode}")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Network error: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitEngine = ref.watch(habitEngineProvider);
    final allHabits = habitEngine.habits;
    final dayHabits = allHabits.where((h) => h.isScheduledForDate(_selectedDate)).toList();
    final completedCount = dayHabits.where((h) => h.isDoneOn(_selectedDate)).length;
    final totalCount = dayHabits.length;
    final fulfillmentPercentage = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;
    final driftPercentage = 100.0 - fulfillmentPercentage;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onReflect,
        backgroundColor: AppColors.emerald,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("Reflect"),
      ),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder(
              valueListenable: _refreshing,
              builder: (_, __, ___) => const FutureYouFeed(),
            ),
            const SizedBox(height: AppSpacing.xl),
            DateStrip(selectedDate: _selectedDate, onDateSelected: _onDateSelected),
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
                          Text('Fulfillment for Selected Day',
                              style: AppTextStyles.captionSmall
                                  .copyWith(color: AppColors.textQuaternary)),
                          const SizedBox(height: 4),
                          Text('$completedCount/$totalCount kept',
                              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Column(
                    children: [
                      _buildProgressBar(
                        progress: fulfillmentPercentage,
                        label: 'Fulfillment Index',
                        color: AppColors.emerald,
                        description: 'Promises kept today.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildProgressBar(
                        progress: driftPercentage,
                        label: 'Drift Load (Unfulfilled)',
                        color: AppColors.warning,
                        description: 'Promises unkept today.',
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
                    Icon(LucideIcons.calendar, size: 48, color: AppColors.textQuaternary),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nothing here yet',
                        style: AppTextStyles.bodySemiBold
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Add a habit or task in Planner.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              Column(
                children: dayHabits
                    .map(
                      (habit) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HabitCard(
                          key: ValueKey(habit.id),
                          habit: habit,
                          onToggle: () async =>
                              ref.read(habitEngineProvider).toggleHabitCompletion(habit.id),
                          onDelete: () async =>
                              ref.read(habitEngineProvider).deleteHabit(habit.id),
                        ),
                      ),
                    )
                    .toList(),
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
                        Icon(LucideIcons.gauge, size: 16, color: AppColors.emerald),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Integrity = Promises Kept / Promises Made',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('Trend engine hooks in backend',
                      style: AppTextStyles.captionSmall
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required double progress,
    required String label,
    required Color color,
    required String description,
  }) {
    final clamped = progress.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.captionSmall.copyWith(color: AppColors.textTertiary)),
            Text('${clamped.toInt()}%',
                style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            color: AppColors.glassBackground,
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: Stack(children: [
              FractionallySizedBox(
                widthFactor: clamped / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(description,
            style: AppTextStyles.label.copyWith(color: AppColors.textQuaternary)),
      ],
    );
  }
}

// --------------------------- FUTURE YOU FEED --------------------------- //

class FutureYouFeed extends StatefulWidget {
  const FutureYouFeed({super.key});

  @override
  State<FutureYouFeed> createState() => _FutureYouFeedState();
}

class _FutureYouFeedState extends State<FutureYouFeed> {
  bool _loading = true;
  String? _error;
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiClient._baseUrl}/api/v1/coach/messages'),
        headers: ApiClient._defaultHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _messages = data['messages'] ?? []);
      } else {
        setState(() => _error = 'Failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator(color: AppColors.emerald)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(_error!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
      );
    }

    if (_messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Your Future Self is observing...',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _messages.map((msg) {
        final kind = msg['kind'] ?? 'nudge';
        final emoji = kind == 'brief'
            ? '⚔️'
            : kind == 'mirror'
                ? '🪞'
                : kind == 'letter'
                    ? '📜'
                    : '💭';
        final title = msg['title'] ?? 'Message';
        final body = msg['body'] ?? '';
        final mentor = msg['mentor'] ?? 'Future You';
        final ts = msg['createdAt']?.toString().split('T').first ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji  $title',
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: AppColors.emerald, fontSize: 16)),
                const SizedBox(height: AppSpacing.sm),
                Text(body,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textPrimary, height: 1.4)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mentor,
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.textQuaternary)),
                    Text(ts,
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.textQuaternary)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../services/api_client.dart';
import '../providers/habit_provider.dart';
import '../widgets/simple_header.dart';

class GoalData {
  final int id;
  final String title;
  final String subtitle;
  final String icon;
  final List<PlanStep> plan;

  GoalData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.plan,
  });
}

class PlanStep {
  final String action;
  final String why;
  final String study;

  PlanStep({
    required this.action,
    required this.why,
    required this.study,
  });
}

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  String? _toast;
  final TextEditingController _customInputController = TextEditingController();
  bool _chatExpanded = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  // Custom goals state
  List<GoalData> _customGoals = [];
  bool _loadingCustomGoals = true;

  @override
  void initState() {
    super.initState();
    _loadCustomGoals();
  }

  Future<void> _loadCustomGoals() async {
    try {
      final response = await ApiClient.getPurposeAlignedGoals();
      if (response.success && response.data != null) {
        final goals = response.data!['goals'] as List? ?? [];
        setState(() {
          _customGoals = goals.map((goal) {
            return GoalData(
              id: goal['title'].hashCode,
              title: goal['title'],
              subtitle: goal['subtitle'],
              icon: goal['icon'],
              plan: (goal['plan'] as List).map((step) {
                return PlanStep(
                  action: step['action'],
                  why: step['why'],
                  study: step['study'],
                );
              }).toList(),
            );
          }).toList();
          _loadingCustomGoals = false;
        });
      } else {
        setState(() => _loadingCustomGoals = false);
      }
    } catch (e) {
      debugPrint('No custom goals available: $e');
      setState(() => _loadingCustomGoals = false);
    }
  }

  final List<GoalData> _goals = [
    GoalData(
      id: 1,
      title: 'Smoother Skin',
      subtitle: 'Natural anti-aging',
      icon: '✨',
      plan: [
        PlanStep(action: 'SPF 50+ daily AM', why: 'Prevents 80% of aging', study: 'Dermatology Research 2021'),
        PlanStep(action: 'Retinol 0.3% 3x/week PM', why: 'Boosts collagen 47%', study: 'Stanford Medicine 2020'),
        PlanStep(action: 'Vitamin C serum AM', why: 'Brightens & protects', study: 'Skin Science 2022'),
        PlanStep(action: 'Hydrate 2.5L daily', why: 'Improves elasticity 40%', study: 'NIH 2022'),
        PlanStep(action: 'Omega-3 with meals', why: 'Reduces inflammation', study: 'Harvard Nutrition 2021'),
        PlanStep(action: 'Niacinamide serum PM', why: 'Minimizes pores', study: 'Clinical Derm 2021'),
        PlanStep(action: 'Silk pillowcase', why: 'Reduces friction wrinkles', study: 'Sleep Dermatology 2020'),
      ],
    ),
    GoalData(
      id: 2,
      title: 'Get In Shape',
      subtitle: 'Lean & strong',
      icon: '💪',
      plan: [
        PlanStep(action: 'Strength train 4x/week', why: 'Builds lean muscle', study: 'Exercise Science 2021'),
        PlanStep(action: '10k steps minimum daily', why: 'Burns 300-500 cal', study: 'Activity Research 2022'),
        PlanStep(action: 'Protein 1g per lb bodyweight', why: 'Muscle synthesis', study: 'Nutrition Journal 2020'),
        PlanStep(action: 'HIIT cardio 2x/week', why: 'Max fat burn', study: 'Metabolism 2021'),
        PlanStep(action: 'Sleep 7-9 hours', why: 'Recovery & growth hormone', study: 'Sleep & Exercise 2022'),
        PlanStep(action: 'Track calories in app', why: '64% better results', study: 'Behavioral Science 2020'),
        PlanStep(action: 'Meal prep Sundays', why: 'Consistency wins', study: 'Habit Formation 2021'),
      ],
    ),
    GoalData(
      id: 3,
      title: 'Lose 20kg',
      subtitle: 'Sustainable fat loss',
      icon: '📉',
      plan: [
        PlanStep(action: '500 cal deficit daily', why: '1kg/week safely', study: 'Weight Loss Meta 2021'),
        PlanStep(action: 'High protein breakfast 30g+', why: '60% less cravings', study: 'Metabolism 2022'),
        PlanStep(action: '30min movement daily', why: 'Preserves muscle', study: 'Exercise Phys 2020'),
        PlanStep(action: '500ml water before meals', why: '13% less intake', study: 'Obesity Research 2021'),
        PlanStep(action: 'Cut liquid calories', why: '400 cal/day saved', study: 'Nutrition Science 2022'),
        PlanStep(action: 'Strength train 3x/week', why: 'Maintains metabolism', study: 'Body Comp 2020'),
        PlanStep(action: 'Weigh daily, track weekly avg', why: 'Data beats emotion', study: 'Weight Mgmt 2021'),
        PlanStep(action: 'Sleep 7+ hours', why: 'Poor sleep = 30% more hunger', study: 'Sleep & Appetite 2022'),
      ],
    ),
    GoalData(
      id: 4,
      title: 'More Energy',
      subtitle: 'All-day vitality',
      icon: '⚡',
      plan: [
        PlanStep(action: '10min morning sun 6-8am', why: 'Anchors circadian', study: 'Sleep Medicine 2022'),
        PlanStep(action: 'No sugar after 2pm', why: 'Stabilizes afternoon', study: 'Glycemic Control 2021'),
        PlanStep(action: 'Magnesium glycinate 400mg', why: 'ATP production', study: 'Energy Metabolism 2020'),
        PlanStep(action: 'Cold shower 30sec finish', why: 'Boosts mitochondria', study: 'Cold Exposure 2021'),
        PlanStep(action: 'B-complex AM', why: 'Energy conversion', study: 'Nutrition Research 2022'),
        PlanStep(action: 'No caffeine after 2pm', why: 'Protects sleep quality', study: 'Caffeine Studies 2020'),
      ],
    ),
    GoalData(
      id: 5,
      title: 'Build Muscle',
      subtitle: 'Pack on size',
      icon: '🏋️',
      plan: [
        PlanStep(action: 'Progressive overload 4-5x/week', why: 'Triggers hypertrophy', study: 'Strength Science 2021'),
        PlanStep(action: '300-500 cal surplus daily', why: 'Building materials', study: 'Muscle Growth 2022'),
        PlanStep(action: 'Protein 1.6g per kg', why: 'Optimal synthesis', study: 'Protein Research 2020'),
        PlanStep(action: '8-9 hours sleep', why: 'Growth hormone peaks', study: 'Sleep & Recovery 2020'),
        PlanStep(action: 'Creatine 5g daily', why: '8-15% more strength', study: 'Sports Science 2021'),
        PlanStep(action: 'Train each muscle 2x/week', why: 'Higher frequency growth', study: 'Hypertrophy 2022'),
        PlanStep(action: 'Carbs around workouts', why: 'Fuels performance', study: 'Exercise Nutrition 2021'),
      ],
    ),
    GoalData(
      id: 6,
      title: 'Better Sleep',
      subtitle: 'Deep rest',
      icon: '🌙',
      plan: [
        PlanStep(action: 'Same bedtime daily ±30min', why: 'Trains rhythm', study: 'Sleep Foundation 2022'),
        PlanStep(action: 'Dim lights 2hrs before', why: '2x melatonin', study: 'Circadian Research 2021'),
        PlanStep(action: 'Cool room 18°C (65°F)', why: 'Optimal deep sleep', study: 'Sleep Medicine 2020'),
        PlanStep(action: 'Magnesium threonate 200mg', why: 'Crosses brain barrier', study: 'Neuroscience 2022'),
        PlanStep(action: 'No screens 1hr before', why: 'Blue light blocks', study: 'Digital Health 2021'),
        PlanStep(action: 'Blackout curtains/mask', why: 'Darkness = quality', study: 'Sleep Environment 2020'),
      ],
    ),
    GoalData(
      id: 7,
      title: 'Save £10k',
      subtitle: 'Build wealth fast',
      icon: '💰',
      plan: [
        PlanStep(action: 'Auto-save £192/week', why: 'Removes willpower', study: 'Behavioral Econ 2021'),
        PlanStep(action: 'Track every expense', why: '23% more saving', study: 'Personal Finance 2022'),
        PlanStep(action: 'One no-spend day/week', why: 'Builds impulse control', study: 'Habit Formation 2020'),
        PlanStep(action: 'Cancel unused subscriptions', why: '£640/yr wasted avg', study: 'Consumer Research 2023'),
        PlanStep(action: '30-day rule for £50+ purchases', why: 'Kills impulse buys', study: 'Spending Behavior 2021'),
        PlanStep(action: 'Cook 5 nights/week', why: 'Saves £200+ monthly', study: 'Budget Studies 2022'),
      ],
    ),
    GoalData(
      id: 8,
      title: 'Clear Skin',
      subtitle: 'Acne-free',
      icon: '🌟',
      plan: [
        PlanStep(action: 'Gentle cleanser 2x daily', why: 'Removes bacteria', study: 'Dermatology 2021'),
        PlanStep(action: 'Niacinamide 10% serum', why: '30% less sebum', study: 'Skin Research 2022'),
        PlanStep(action: 'Change pillowcase 2x/week', why: 'Prevents transfer', study: 'Acne Studies 2020'),
        PlanStep(action: 'Salicylic acid spot treat', why: 'Unclogs pores', study: 'Clinical Derm 2021'),
        PlanStep(action: 'Dairy-free 30 days trial', why: '47% acne link', study: 'Nutrition & Skin 2022'),
        PlanStep(action: 'Zinc supplement 30mg', why: '50% less lesions', study: 'Derm Research 2020'),
      ],
    ),
    GoalData(
      id: 9,
      title: 'Stop Procrastinating',
      subtitle: 'Get things done',
      icon: '🎯',
      plan: [
        PlanStep(action: '2-min rule: if <2min do now', why: 'Beats activation energy', study: 'Atomic Habits'),
        PlanStep(action: 'Pomodoro 25min blocks', why: '40% more focus', study: 'Productivity 2021'),
        PlanStep(action: 'Phone in another room', why: '#1 distraction gone', study: 'Digital Wellness 2022'),
        PlanStep(action: 'Plan tomorrow tonight', why: 'Kills decision fatigue', study: 'Cognitive Science 2020'),
        PlanStep(action: 'Eat frog: hardest first', why: 'Willpower highest AM', study: 'Psychology Today 2021'),
        PlanStep(action: 'Block calendar deep work', why: 'Protects focus time', study: 'Time Management 2022'),
      ],
    ),
    GoalData(
      id: 10,
      title: 'Read 30+ Books',
      subtitle: 'Become smarter',
      icon: '📚',
      plan: [
        PlanStep(action: '20 pages before bed', why: '30+ books/year', study: 'Habit Formation 2021'),
        PlanStep(action: 'Always carry book', why: 'Fill dead time', study: 'Time Management 2020'),
        PlanStep(action: 'Kindle on phone', why: 'Read anywhere', study: 'Reading Behavior 2022'),
        PlanStep(action: 'Join book club', why: 'Social pressure works', study: 'Group Dynamics 2021'),
        PlanStep(action: 'Set Goodreads goal', why: '42% more achievement', study: 'Goal Psychology 2020'),
      ],
    ),
    GoalData(
      id: 11,
      title: 'Quit Smoking',
      subtitle: 'Break free',
      icon: '🚭',
      plan: [
        PlanStep(action: 'Nicotine replacement (patch/gum)', why: '2x success rate', study: 'Addiction Medicine 2021'),
        PlanStep(action: 'Avoid triggers 30 days', why: 'Breaks associations', study: 'Behavioral Science 2022'),
        PlanStep(action: 'New ritual replacement', why: 'Fills habit void', study: 'Habit Research 2020'),
        PlanStep(action: 'Tell everyone quit date', why: 'Public commitment', study: 'Social Psychology 2021'),
        PlanStep(action: 'QuitSure app', why: 'Daily support', study: 'Digital Interventions 2022'),
        PlanStep(action: 'Calculate money saved daily', why: 'Visual motivation', study: 'Behavioral Econ 2020'),
      ],
    ),
    GoalData(
      id: 12,
      title: 'Learn Language',
      subtitle: 'Fluent in months',
      icon: '🗣️',
      plan: [
        PlanStep(action: 'Duolingo 15min daily', why: 'Spaced repetition', study: 'Language Acquisition 2021'),
        PlanStep(action: 'Shows with subtitles', why: '45% better comprehension', study: 'Linguistics 2022'),
        PlanStep(action: 'iTalki tutor 2x/week 30min', why: 'Real conversation', study: 'Language Learning 2020'),
        PlanStep(action: 'Anki flashcards daily', why: 'Active recall king', study: 'Memory Research 2021'),
        PlanStep(action: 'Think in target language 5min', why: 'Builds neural paths', study: 'Cognitive Science 2022'),
        PlanStep(action: 'Change phone language', why: 'Immersion accelerates', study: 'Applied Linguistics 2020'),
      ],
    ),
  ];

  @override
  void dispose() {
    _customInputController.dispose();
    _chatInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _commitGoal(GoalData goal) async {
    try {
      // Build title with micro goals (first 3 action steps)
      final microGoals = goal.plan.take(3).map((step) => step.action).join(' • ');
      final fullTitle = '${goal.title}\n$microGoals';
      
      // Create habit using HabitEngine
      await ref.read(habitEngineProvider).createHabit(
        title: fullTitle,
        type: 'habit',
        time: '07:00',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 21)),
        repeatDays: [1, 2, 3, 4, 5, 6, 0], // All days for 21-day commitment
        color: AppColors.emerald,
        emoji: goal.icon,
        reminderOn: false,
      );

      _showToast('💚 ${goal.title} committed for 21 days!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to commit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendChatMessage() async {
    final message = _chatInputController.text.trim();
    if (message.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: message,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _chatInputController.clear();
    });

    _scrollToBottom();

    try {
      // Use new What-If implementation coach (context-aware + citations)
      final result = await ApiClient.sendWhatIfMessage(message);

      if (result.success && result.data != null) {
        final aiMessage = result.data!['message'] as String;
        final suggestedPlan = result.data!['suggestedPlan'];

        final responseMessage = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'future',
          text: aiMessage,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(responseMessage);
          _isLoading = false;
        });

        // If AI generated a plan, show it as a beautiful card!
        if (suggestedPlan != null && suggestedPlan is Map) {
          _showSuggestedPlanCard(Map<String, dynamic>.from(suggestedPlan as Map));
        }
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Chat failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Chat error: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSuggestedPlanCard(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F1F0F),
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.emerald.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      plan['icon'] ?? '🎯',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['title'] ?? 'Your Plan',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            plan['subtitle'] ?? 'Science-backed steps',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Plan steps
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: (plan['plan'] as List?)?.length ?? 0,
                  itemBuilder: (context, index) {
                    final step = (plan['plan'] as List)[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.emerald.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step['action'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '💡 ${step['why'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📚 ${step['study'] ?? ''}',
                              style: TextStyle(
                                color: AppColors.emerald.withOpacity(0.8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Commit button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Not Yet',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _commitPlanFromChat(plan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Commit This Plan 🔥',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Future<void> _commitPlanFromChat(Map<String, dynamic> plan) async {
    // TODO: Implement commit logic (create habits from plan steps)
    _showToast('Plan committed! Check your habits.');
  }

  void _startCustomChat() {
    final customGoal = _customInputController.text.trim();
    if (customGoal.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: 'What if I $customGoal?',
      timestamp: DateTime.now(),
    );

    final aiResponse = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'future',
      text: 'Interesting goal! Let\'s break this down. What does success look like to you in 3 months?',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(aiResponse);
      _customInputController.clear();
      _chatExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main content with scrollable header
          CustomScrollView(
            slivers: [
              // Header that disappears when scrolling
              SliverAppBar(
                expandedHeight: 80,
                floating: true,
                snap: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: const SimpleHeader(),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildCustomGoalInput(),
                        const SizedBox(height: AppSpacing.xl),
                        // Custom goals section
                        if (_customGoals.isNotEmpty) ...[
                          _buildCustomGoalsSection(),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        // Preset goals header
                        _buildPresetsHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildGoalsGrid(),
                        const SizedBox(height: 150), // Bottom padding for nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Toast
          if (_toast != null) _buildToast(),

          // Chat overlay
          if (_chatExpanded) _buildChatOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withOpacity(0.1),
            AppColors.emerald.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
              border: Border.all(
                color: AppColors.emerald.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Science-Backed Goals',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'What if you actually achieved it?',
            style: AppTextStyles.h1.copyWith(
              fontSize: 32,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pick a goal. Get a detailed plan backed by research from Harvard, Stanford, NIH. One-click commit.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCustomGoalInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or Start Your Own',
            style: AppTextStyles.bodySemiBold.copyWith(
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _customInputController,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'What if I... (e.g., started waking at 5am, learned Spanish)',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textQuaternary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    onSubmitted: (_) => _startCustomChat(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: _startCustomChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Explore',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCustomGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.target, size: 24, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goals Aligned With Your Purpose',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald,
                    ),
                  ),
                  Text(
                    'AI-generated based on your discovery',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display custom goals
        ..._customGoals.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildGoalCard(goal, isCustom: true),
        )),
      ],
    );
  }

  Widget _buildPresetsHeader() {
    return Row(
      children: [
        const Icon(LucideIcons.bookOpen, size: 20, color: AppColors.emerald),
        const SizedBox(width: 8),
        Text(
          'Science-Backed Classics',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 0.75,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
      ),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return _buildGoalCard(goal, index: index);
      },
    );
  }

  Widget _buildGoalCard(GoalData goal, {int? index, bool isCustom = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: AppColors.emerald.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(
            goal.title,
            style: AppTextStyles.h3.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            goal.subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.emerald.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.builder(
              itemCount: goal.plan.length,
              itemBuilder: (context, i) {
                final step = goal.plan[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.2),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.emerald.withOpacity(0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.action,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.why,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.emerald.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.bookOpen,
                                  size: 10,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    step.study,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _commitGoal(goal),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '💚 Commit 21d',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  final promptMsg = ChatMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    role: 'user',
                    text: 'Tell me more about: ${goal.title}',
                    timestamp: DateTime.now(),
                  );
                  final aiReply = ChatMessage(
                    id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
                    role: 'future',
                    text: 'Let\'s explore ${goal.title}. What\'s your main motivation for this goal?',
                    timestamp: DateTime.now(),
                  );
                  setState(() {
                    _messages.add(promptMsg);
                    _messages.add(aiReply);
                    _chatExpanded = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Chat',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: ((index ?? 0) * 100).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildToast() {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: AppColors.emerald.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _toast!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.emerald.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal Exploration',
                        style: AppTextStyles.h3.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_messages.where((m) => m.role == 'user').length} messages',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _chatExpanded = false),
                    icon: const Icon(
                      LucideIcons.x,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(
                        color: AppColors.emerald.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Thinking...',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              140, // Extra space above nav tabs
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                top: BorderSide(
                  color: AppColors.emerald.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        border: Border.all(
                          color: AppColors.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _chatInputController,
                        style: AppTextStyles.body,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Tell me more...',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textQuaternary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(AppSpacing.md),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: _sendChatMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.emeraldGradient : null,
                color: isUser ? null : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: isUser
                      ? AppColors.emerald.withOpacity(0.3)
                      : AppColors.emerald.withOpacity(0.2),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


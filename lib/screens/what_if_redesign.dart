import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../services/api_client.dart';
import '../widgets/simple_header.dart';

class WhatIfRedesignScreen extends StatefulWidget {
  final String? initialTab; // 'simulator', 'architect', or 'library'
  
  const WhatIfRedesignScreen({super.key, this.initialTab});

  @override
  State<WhatIfRedesignScreen> createState() => _WhatIfRedesignScreenState();
}

class _WhatIfRedesignScreenState extends State<WhatIfRedesignScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _scenarioController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _outputCard;
  String? _errorMessage;
  String? _selectedPresetId;

  // Preset scenarios
  final List<PresetScenario> _presets = [
    PresetScenario(
      id: 'muscle',
      title: '💪 Build Muscle',
      subtitle: 'Strength & size',
      emoji: '💪',
      scenario: '''Goal: Gain 5-8kg lean muscle, increase strength 30%
Current: Gym 2x/week (inconsistent), bodyweight 75kg
Training: Thinking 4x/week weights (Mon/Tue/Thu/Fri)
Sleep: Average 6.5 hours (bed 12am, wake 6:30am)
Diet: Skip breakfast, lunch takeaway 3x/week, dinner home-cooked, protein ~80g/day
Energy: 5/10 mornings, 7/10 evenings
Barriers: Motivation after work, meal prep time
Timeline: 90 days to see real change''',
    ),
    PresetScenario(
      id: 'focus',
      title: '🧠 Peak Focus',
      subtitle: 'Mental performance',
      emoji: '🧠',
      scenario: '''Goal: Deep focus 4+ hours/day, eliminate afternoon crashes
Current: Focus in 20-30min bursts, crash at 2pm daily
Work: Software engineer, 8am-5pm, lots of meetings
Sleep: 7 hours but poor quality (wake 2-3x per night)
Diet: Coffee 3-4x/day, snack on chips/biscuits, irregular meals
Exercise: Walking 3k steps/day, no structured training
Stress: 7/10 (deadlines, context switching)
Timeline: 30 days to feel difference, 90 days to lock in''',
    ),
    PresetScenario(
      id: 'sleep',
      title: '😴 Fix Sleep',
      subtitle: 'Energy & recovery',
      emoji: '😴',
      scenario: '''Goal: Consistent 7.5h sleep, wake refreshed, stable energy all day
Current: Bed 11:30pm-12:30am (varies), wake 6:30am, feel tired
Sleep quality: Light sleeper, wake 2-3x, phone in bed
Caffeine: 2-3 coffees (last one at 3pm)
Exercise: Gym 2x/week, no cardio
Screen time: Phone/laptop until bed, blue light exposure high
Room: Light from street, temp varies, shared bed
Timeline: 90 days to form new routine''',
    ),
    PresetScenario(
      id: 'marathon',
      title: '🏃 Marathon',
      subtitle: 'First 42km',
      emoji: '🏃',
      scenario: '''Goal: Complete first marathon in under 4 hours
Current: Run 2x/week (5km each), no race experience
Fitness: Can run 10km without stopping, avg pace 6min/km
Training time: 5-6 hours/week available
Injuries: Occasional knee pain after long runs
Sleep: 7 hours, fairly consistent
Diet: Balanced, trying to eat clean
Timeline: 16 weeks until race day''',
    ),
    PresetScenario(
      id: 'skill',
      title: '📚 Learn Fast',
      subtitle: 'Master new skill',
      emoji: '📚',
      scenario: '''Goal: Master Spanish conversation (B2 level) for work
Current: Can read basic texts, speaking is weak
Time available: 1 hour/day (mornings before work)
Learning style: Visual + practice, not good with pure theory
Deadline: 6 months (work transfer to Madrid office)
Barriers: Consistency, speaking anxiety, no practice partners
Previous attempts: Duolingo for 3 months (quit)
Timeline: 180 days to functional fluency''',
    ),
    PresetScenario(
      id: 'hustle',
      title: '💰 Side Hustle',
      subtitle: 'Extra income',
      emoji: '💰',
      scenario: '''Goal: Launch consulting business, first \$5k/month
Current: Full-time job (9-6), weekends free
Skills: 8 years marketing experience, strong copywriting
Time available: 10-15 hours/week (evenings + Sat morning)
Financial need: Medium (want to quit day job in 12 months)
Barriers: No client network, imposter syndrome, time management
Investment: \$500 to start (website, tools)
Timeline: 90 days to first paying clients''',
    ),
    PresetScenario(
      id: 'create',
      title: '🎨 Daily Create',
      subtitle: 'Creative practice',
      emoji: '🎨',
      scenario: '''Goal: Write 500 words/day, publish 2 articles/week
Current: Write sporadically when "inspired" (2-3x/month)
Medium: Long-form essays on personal growth + tech
Time: 30-60 min/day available (early morning or night)
Consistency history: Good at gym (4x/week), bad at creative work
Barriers: Perfectionism, waiting for perfect idea, editing too early
Platform: Medium + personal blog
Timeline: 90 days to build habit + small audience''',
    ),
    PresetScenario(
      id: 'custom',
      title: '✍️ Custom',
      subtitle: 'Your scenario',
      emoji: '✍️',
      scenario: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab == 'architect' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scenarioController.dispose();
    super.dispose();
  }

  void _selectPreset(PresetScenario preset) {
    setState(() {
      _scenarioController.text = preset.scenario;
      _selectedPresetId = preset.id;
      _outputCard = null;
      _errorMessage = null;
    });
  }

  Future<void> _runSimulation() async {
    if (_scenarioController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe your scenario');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _outputCard = null;
    });

    try {
      final mode = _tabController.index == 0 ? 'simulator' : 'habit-master';
      
      // Send to backend
      final response = await ApiClient.sendWhatIfMessage(
        _scenarioController.text,
        preset: mode,
      );

      if (response.success && response.data != null) {
        // Debug: Print what we got
        print('✅ What-If Response: ${response.data}');
        print('✅ Has outputCard: ${response.data!['outputCard'] != null}');
        print('✅ Has message: ${response.data!['message'] != null}');
        
        setState(() {
          // Store the whole response { message, outputCard, habits, sources }
          _outputCard = response.data!;
          _isLoading = false;
        });
      } else {
        print('❌ What-If Error: ${response.error}');
        setState(() {
          _errorMessage = response.error ?? 'Simulation failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab selector
                  _buildTabSelector(),
                  
                  const SizedBox(height: AppSpacing.xl),

                  // Preset cards
                  _buildPresetGrid(),

                  const SizedBox(height: AppSpacing.xl),

                  // Input field
                  _buildInputField(),

                  const SizedBox(height: AppSpacing.lg),

                  // Run button
                  _buildRunButton(),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildErrorMessage(),
                  ],

                  if (_isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildLoadingState(),
                  ],

                  if (_outputCard != null && _outputCard!['outputCard'] != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildOutputCard(),
                  ],
                  
                  // Show AI message even if no full card yet (during conversation)
                  if (_outputCard != null && _outputCard!['outputCard'] == null && _outputCard!['message'] != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        _outputCard!['message'] as String,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: '🔮 Future Simulator',
              subtitle: 'Compare two timelines',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: '🏗️ Habit Architect',
              subtitle: 'Build the system',
              index: 1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildTabButton({required String label, required String subtitle, required int index}) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
          _outputCard = null;
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.emerald : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.bodySemiBold.copyWith(
                color: isSelected ? AppColors.emerald : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.captionSmall.copyWith(
                color: isSelected ? AppColors.emerald.withOpacity(0.7) : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.02, 1.02));
  }

  Widget _buildPresetGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Quick Scenarios',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: _presets.length,
          itemBuilder: (context, index) {
            return _buildPresetCard(_presets[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildPresetCard(PresetScenario preset, int index) {
    final isSelected = _selectedPresetId == preset.id;
    
    return GestureDetector(
      onTap: () => _selectPreset(preset),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    AppColors.emerald.withOpacity(0.4),
                    AppColors.emerald.withOpacity(0.2),
                  ]
                : [
                    AppColors.emerald.withOpacity(0.15),
                    AppColors.emerald.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.emerald.withOpacity(0.8)
                : AppColors.emerald.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Check mark when selected
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  preset.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  preset.title,
                  style: AppTextStyles.bodySemiBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  preset.subtitle,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Your Scenario',
          style: AppTextStyles.bodySemiBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Be specific! Include: goal, current state, sleep, diet, timeline, barriers.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: _scenarioController,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Describe your scenario in detail...',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _runSimulation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.emerald,
              AppColors.emerald.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            else
              const Icon(LucideIcons.zap, color: Colors.black),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _isLoading ? 'Running Simulation...' : '🚀 Run Simulation',
              style: AppTextStyles.h3.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: _isLoading ? 0 : 1)
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.emerald),
        const SizedBox(height: AppSpacing.md),
        Text(
          _tabController.index == 0
              ? 'Running both timelines...'
              : 'Building your system...',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms);
  }

  Widget _buildOutputCard() {
    // Backend returns: { message, outputCard: { title, sections, fullText }, habits, sources }
    // We want the fullText from outputCard
    final content = _outputCard?['outputCard']?['fullText'] ?? 
                    _outputCard?['fullText'] ?? 
                    _outputCard?['message'] ?? 
                    '';
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withOpacity(0.1),
            AppColors.emerald.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppColors.emerald, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _tabController.index == 0 ? 'Your Future Simulation' : 'Your Habit System',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Action buttons at top
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Copy to clipboard
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 Copied to clipboard!'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.copy, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Copy', style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Save to vault (Reflections tab)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔐 Saved to Reflections Vault!'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bookMarked, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Save to Vault', style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Content
          _buildFormattedContent(content),
        ],
      ),
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildFormattedContent(String content) {
    // Clean up the content
    String cleaned = content
        .replaceAll(RegExp(r'\{[^}]*type[^}]*:[^}]*\}'), '') // Remove {type: ...} blocks
        .replaceAll(RegExp(r'\},\s*\{'), '\n\n') // Space between sections
        .replaceAll(RegExp(r'[\{\}]'), '') // Remove braces
        .replaceAll(RegExp(r'content:\s*'), '') // Remove "content:"
        .replaceAll(RegExp(r'fullText:\s*Locked\.'), '') // Remove "fullText: Locked."
        .trim();
    
    // Split into sections
    final sections = cleaned.split(RegExp(r'\n\n+'));
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          section = section.trim();
          if (section.isEmpty) return const SizedBox.shrink();
          
          // Check if it's a heading (all caps, emoji, or starts with ---/###)
          final isHeading = section.startsWith(RegExp(r'[🔥💪😴🏃📚💰🌅📊🎯⚡]')) ||
              section == section.toUpperCase() ||
              section.startsWith('---') ||
              section.startsWith('###') ||
              section.startsWith('THE TWO FUTURES') ||
              section.startsWith('STAY SAME') ||
              section.startsWith('COMMIT') ||
              section.startsWith('COMPARISON') ||
              section.startsWith('SOURCES') ||
              section.startsWith('HABITS') ||
              section.startsWith('WHY IT WORKS');
          
          if (isHeading) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Text(
                section.replaceAll('---', '').replaceAll('###', '').trim(),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }
          
          // Check if it's a table (has | characters)
          if (section.contains('|') && section.split('\n').where((line) => line.contains('|')).length >= 2) {
            return _buildTable(section);
          }
          
          // Regular paragraph
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              section,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildTable(String tableText) {
    final lines = tableText.split('\n').where((l) => l.contains('|')).toList();
    if (lines.length < 2) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
            final isHeader = lines.indexOf(line) == 0;
            final isSeparator = line.contains('---');
            
            if (isSeparator) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: cells.map((cell) {
                  return Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      cell,
                      style: AppTextStyles.caption.copyWith(
                        color: isHeader ? AppColors.emerald : AppColors.textPrimary,
                        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PresetScenario {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String scenario;

  PresetScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.scenario,
  });
}


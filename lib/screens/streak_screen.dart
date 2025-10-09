import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../services/local_storage.dart';
import '../services/streak_service.dart';
import '../models/streak.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final ValueNotifier<StreakData> streakNotifier =
      ValueNotifier<StreakData>(StreakData(currentStreak: 0, longestStreak: 0, totalXP: 0));

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await streakService.load();
    streakNotifier.value = data;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ValueListenableBuilder<StreakData>(
        valueListenable: streakNotifier,
        builder: (context, data, _) {
          final current = data.currentStreak;
          final longest = data.longestStreak;

          return Column(
            children: [
              GlassCard(
                child: Row(
                  children: [
                    _Flame(size: 40, intensity: (current / 100).clamp(0.0, 1.0)),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Streak', style: AppTextStyles.captionSmall.copyWith(color: AppColors.textTertiary)),
                        Text('$current days', style: AppTextStyles.h2.copyWith(color: AppColors.warning, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Longest', style: AppTextStyles.captionSmall.copyWith(color: AppColors.textTertiary)),
                        Text('$longest days', style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: const [
                  Expanded(child: _Badge(title: '7-Day Discipline', need: 7, icon: LucideIcons.shield)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _Badge(title: '30-Day Legend', need: 30, icon: LucideIcons.crown)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _Badge(title: '100-Day Master', need: 100, icon: LucideIcons.trophy),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends ConsumerWidget {
  final String title;
  final int need;
  final IconData icon;
  const _Badge({required this.title, required this.need, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = LocalStorageService.calculateCurrentStreak();
    final unlocked = current >= need;
    final pct = (current / need).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? const LinearGradient(colors: [AppColors.emerald, AppColors.cyan])
                  : null,
              color: unlocked ? null : AppColors.glassBackground,
              border: Border.all(color: unlocked ? AppColors.emerald : AppColors.glassBorder),
              boxShadow: unlocked
                  ? const [BoxShadow(color: Color(0x4010B981), blurRadius: 20)]
                  : null,
            ),
            child: Icon(icon, color: unlocked ? Colors.black : AppColors.textQuaternary, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(unlocked ? '✅ Unlocked' : '${(pct * 100).toInt()}%', style: AppTextStyles.captionSmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _Flame extends StatelessWidget {
  final double size;
  final double intensity;
  const _Flame({required this.size, required this.intensity});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.warning, const Color(0xFFFF6B35), intensity);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color!.withOpacity(0.4), blurRadius: 12 + 12 * intensity),
        ],
      ),
      child: Icon(LucideIcons.flame, color: color, size: size),
    );
  }
}



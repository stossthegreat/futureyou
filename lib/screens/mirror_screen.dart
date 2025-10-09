import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_card.dart' as glass;
import '../services/local_storage.dart';

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fulfillmentPercentage = LocalStorageService.getTodayFulfillmentPercentage();
    final currentStreak = LocalStorageService.calculateCurrentStreak();
    final longestStreak = LocalStorageService.calculateLongestStreak();
    final todayHabits = LocalStorageService.getTodayHabits();
    final completedToday = todayHabits.where((h) => h.done).length;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Main mirror card
          GlassCard(
            child: Column(
              children: [
                Text(
                  'Future Mirror',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your trajectory if you keep this pace.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Animated mirror
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
                  builder: (context, child) {
                    final glowIntensity = (fulfillmentPercentage / 100) * _glowAnimation.value;
                    
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          gradient: RadialGradient(
                            center: const Alignment(0.3, -0.2),
                            radius: 1.2,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.06),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.emerald.withOpacity(0.4 + (glowIntensity * 0.4)),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withOpacity(0.2 + (glowIntensity * 0.3)),
                              blurRadius: 12 + (glowIntensity * 40),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: AppColors.emerald.withOpacity(0.1 + (glowIntensity * 0.2)),
                              blurRadius: 24 + (glowIntensity * 60),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background pattern
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.emerald.withOpacity(0.1 + (glowIntensity * 0.15)),
                                    AppColors.cyan.withOpacity(0.1 + (glowIntensity * 0.15)),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Central icon
                            Icon(
                              LucideIcons.user,
                              size: 64,
                              color: AppColors.emerald.withOpacity(0.6 + (glowIntensity * 0.4)),
                            ),
                            
                            // Fulfillment overlay
                            Positioned(
                              bottom: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                ),
                                child: Text(
                                  '${fulfillmentPercentage.toInt()}%',
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  'Glow grows with Fulfillment. Keep stacking days.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Streak',
                  '$currentStreak days',
                  LucideIcons.flame,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  'Longest Streak',
                  '$longestStreak days',
                  LucideIcons.trophy,
                  AppColors.emerald,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today',
                  '$completedToday/${todayHabits.length}',
                  LucideIcons.checkCircle,
                  AppColors.cyan,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  'Fulfillment',
                  '${fulfillmentPercentage.toInt()}%',
                  LucideIcons.gauge,
                  AppColors.emerald,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Future self message
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message from Future You',
                            style: AppTextStyles.bodySemiBold,
                          ),
                          Text(
                            _getFutureYouMessage(fulfillmentPercentage, currentStreak),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return glass.GlowingGlassCard(
      glowColor: color,
      glowIntensity: 0.3,
      animate: false,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getFutureYouMessage(double fulfillment, int streak) {
    if (fulfillment >= 100) {
      return "Perfect execution today! This is the discipline that builds empires. I'm proud of who you're becoming.";
    } else if (fulfillment >= 80) {
      return "Excellent momentum! You're in the top 5% of people who actually follow through. Keep this energy.";
    } else if (fulfillment >= 60) {
      return "Solid progress. Every completed habit is a vote for the person you want to become. Stay consistent.";
    } else if (fulfillment >= 40) {
      return "You're building something here. Small actions compound into extraordinary results. Don't stop now.";
    } else if (streak > 0) {
      return "Your streak shows you have what it takes. Get back on track - your future self is counting on you.";
    } else {
      return "Every master was once a beginner. Start small, stay consistent, and watch yourself transform.";
    }
  }
}

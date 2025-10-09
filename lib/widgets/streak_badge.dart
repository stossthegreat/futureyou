import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import 'glass_card.dart';

class StreakBadge extends StatefulWidget {
  final int streak;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final bool isUnlocked;
  
  const StreakBadge({
    super.key,
    required this.streak,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    this.isUnlocked = false,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    if (widget.isUnlocked) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          // Badge icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isUnlocked 
                    ? 1.0 + (_animationController.value * 0.1)
                    : 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isUnlocked
                        ? RadialGradient(
                            colors: [
                              widget.color,
                              widget.color.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: widget.isUnlocked ? null : AppColors.glassBackground,
                    border: Border.all(
                      color: widget.isUnlocked 
                          ? widget.color 
                          : AppColors.glassBorder,
                      width: 2,
                    ),
                    boxShadow: widget.isUnlocked
                        ? [
                            BoxShadow(
                              color: widget.color.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: widget.isUnlocked 
                        ? Colors.white 
                        : AppColors.textQuaternary,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Badge title
          Text(
            widget.title,
            style: AppTextStyles.bodySemiBold.copyWith(
              color: widget.isUnlocked 
                  ? AppColors.textPrimary 
                  : AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Badge description
          Text(
            widget.description,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textQuaternary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: widget.isUnlocked 
                  ? widget.color.withOpacity(0.2) 
                  : AppColors.glassBackground,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              border: Border.all(
                color: widget.isUnlocked 
                    ? widget.color.withOpacity(0.3) 
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              widget.isUnlocked 
                  ? '✅ Unlocked' 
                  : '${widget.streak}/${_getRequiredStreak(widget.title)}',
              style: AppTextStyles.label.copyWith(
                color: widget.isUnlocked 
                    ? widget.color 
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _getRequiredStreak(String title) {
    if (title.contains('7-Day')) return 7;
    if (title.contains('30-Day')) return 30;
    if (title.contains('100-Day')) return 100;
    return 1;
  }
}

class StreakFlame extends StatefulWidget {
  final int streak;
  final double size;
  
  const StreakFlame({
    super.key,
    required this.streak,
    this.size = 24,
  });

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _pulseController;
  late Animation<double> _flameAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _flameController = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.streak * 50).clamp(0, 1000)),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _flameAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _flameController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.streak > 0) {
      _flameController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _flameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streak == 0) {
      return Icon(
        LucideIcons.flame,
        size: widget.size,
        color: AppColors.textQuaternary,
      );
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_flameAnimation, _pulseAnimation]),
      builder: (context, child) {
        final intensity = (widget.streak / 100).clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: _pulseAnimation.value * _flameAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.3 + (intensity * 0.4)),
                  blurRadius: 8 + (intensity * 12),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.flame,
              size: widget.size,
              color: Color.lerp(
                AppColors.warning,
                const Color(0xFFFF6B35),
                intensity,
              ),
            ),
          ),
        );
      },
    );
  }
}

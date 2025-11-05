import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/coach_message.dart';
import '../services/messages_service.dart';
import '../design/tokens.dart';

class NudgeBanner extends StatefulWidget {
  final CoachMessage nudge;
  final VoidCallback onDismiss;
  final VoidCallback onDoIt;

  const NudgeBanner({
    super.key,
    required this.nudge,
    required this.onDismiss,
    required this.onDoIt,
  });

  @override
  State<NudgeBanner> createState() => _NudgeBannerState();
}

class _NudgeBannerState extends State<NudgeBanner>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await messagesService.markAsRead(widget.nudge.id);
    widget.onDismiss();
  }

  void _handleDoIt() {
    _handleDismiss();
    widget.onDoIt();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald.withOpacity(0.15),
                      AppColors.emerald.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                  border: Border.all(
                    color: AppColors.emerald.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.zap,
                            color: Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NUDGE FROM FUTURE-YOU',
                            style: AppTextStyles.captionSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Full-width message
                Text(
                  _isExpanded
                      ? widget.nudge.body
                      : _truncateText(widget.nudge.body),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),

                // Expand hint (if collapsed)
                if (!_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.chevronDown,
                          color: AppColors.emerald.withOpacity(0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to expand',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.emerald.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons (when expanded)
                if (_isExpanded) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(
                          color: AppColors.emerald.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        color: AppColors.emerald,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // Actions (shown when expanded)
                if (_isExpanded) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: 'Do it now',
                          icon: LucideIcons.zap,
                          onPressed: _handleDoIt,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ActionButton(
                          label: 'Later',
                          icon: LucideIcons.clock,
                          onPressed: _handleDismiss,
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _truncateText(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 60)}...';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.emeraldGradient : null,
          color: isPrimary ? null : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isPrimary
                ? AppColors.emerald.withOpacity(0.5)
                : AppColors.glassBorder,
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

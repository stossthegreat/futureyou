import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/coach_message.dart';
import '../services/messages_service.dart';
import '../design/tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Beautiful speech bubble for AI OS messages
/// Displays Brief, Nudge, Debrief, and Letter messages elegantly
class CoachMessageBubble extends StatefulWidget {
  final CoachMessage message;
  final VoidCallback onDismiss;
  final VoidCallback? onNavigateToReflections;

  const CoachMessageBubble({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onNavigateToReflections,
  });

  @override
  State<CoachMessageBubble> createState() => _CoachMessageBubbleState();
}

class _CoachMessageBubbleState extends State<CoachMessageBubble>
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
      begin: 0.7,
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
    await messagesService.markAsRead(widget.message.id);
    
    // Navigate to reflections if callback provided
    if (widget.onNavigateToReflections != null) {
      widget.onNavigateToReflections!();
    }
    
    widget.onDismiss();
  }

  /// Get theme colors based on message type
  _MessageTheme get _theme {
    switch (widget.message.kind) {
      case MessageKind.brief:
        return _MessageTheme(
          primaryColor: const Color(0xFFFFB800), // Gold
          secondaryColor: const Color(0xFFFF9500), // Orange
          icon: LucideIcons.sunrise,
          label: 'BRIEF',
        );
      case MessageKind.nudge:
        return _MessageTheme(
          primaryColor: AppColors.emerald, // Green
          secondaryColor: const Color(0xFF059669), // Darker green
          icon: LucideIcons.zap,
          label: 'NUDGE',
        );
      case MessageKind.debrief:
        return _MessageTheme(
          primaryColor: const Color(0xFF8B5CF6), // Purple
          secondaryColor: const Color(0xFF6366F1), // Indigo
          icon: LucideIcons.moon,
          label: 'DEBRIEF',
        );
      case MessageKind.letter:
        return _MessageTheme(
          primaryColor: const Color(0xFFEC4899), // Pink
          secondaryColor: const Color(0xFFEF4444), // Red
          icon: LucideIcons.heart,
          label: 'LETTER',
        );
      default:
        return _MessageTheme(
          primaryColor: AppColors.emerald,
          secondaryColor: AppColors.emerald,
          icon: LucideIcons.messageCircle,
          label: 'MESSAGE',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _theme.primaryColor.withOpacity(0.25 * _pulseAnimation.value),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _theme.primaryColor.withOpacity(0.12),
                      _theme.secondaryColor.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _theme.primaryColor.withOpacity(0.35),
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
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge and emoji
                Row(
                  children: [
                    // Speech bubble tail indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_theme.primaryColor, _theme.secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: _theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _theme.icon,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _theme.label,
                            style: AppTextStyles.captionSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Emoji indicator
                    Text(
                      widget.message.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),

                // Message text
                Text(
                  _isExpanded
                      ? widget.message.body
                      : _truncateText(widget.message.body),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                  maxLines: _isExpanded ? null : 2,
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
                          color: _theme.primaryColor.withOpacity(0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to read',
                          style: AppTextStyles.caption.copyWith(
                            color: _theme.primaryColor.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons (when expanded)
                if (_isExpanded) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'View Reflections',
                          icon: LucideIcons.bookOpen,
                          onPressed: _handleDismiss,
                          color: _theme.primaryColor,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                        label: 'Got it',
                        icon: LucideIcons.check,
                        onPressed: () async {
                          await messagesService.markAsRead(widget.message.id);
                          widget.onDismiss();
                        },
                        color: _theme.primaryColor,
                        isPrimary: false,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  String _truncateText(String text) {
    if (text.length <= 80) return text;
    return '${text.substring(0, 80)}...';
  }
}

class _MessageTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String label;

  _MessageTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.label,
  });
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isPrimary ? 16 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary ? LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ) : null,
          color: isPrimary ? null : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isPrimary
                ? color.withOpacity(0.5)
                : AppColors.glassBorder,
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isPrimary ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppColors.textSecondary,
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


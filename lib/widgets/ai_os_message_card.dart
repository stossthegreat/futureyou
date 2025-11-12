import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/coach_message.dart';
import '../services/messages_service.dart';
import '../design/tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 🔥 THE MOST BEAUTIFUL AI OS MESSAGE CARD EVER
/// Phase-aware, cinematic, Instagram-worthy
class AIOSMessageCard extends StatefulWidget {
  final CoachMessage message;
  final VoidCallback onDismiss;
  final VoidCallback? onNavigateToReflections;
  final String? phase; // 'observer', 'architect', 'oracle'
  final int? structuralIntegrity; // 0-100
  final String? focusPillar;

  const AIOSMessageCard({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onNavigateToReflections,
    this.phase,
    this.structuralIntegrity,
    this.focusPillar,
  });

  @override
  State<AIOSMessageCard> createState() => _AIOSMessageCardState();
}

class _AIOSMessageCardState extends State<AIOSMessageCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late Animation<double> _glowAnimation;
  late Animation<double> _entranceSlide;
  late Animation<double> _entranceFade;

  @override
  void initState() {
    super.initState();
    
    // Pulsing glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Cinematic entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _entranceSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await messagesService.markAsRead(widget.message.id);
    
    if (widget.onNavigateToReflections != null) {
      widget.onNavigateToReflections!();
    }
    
    widget.onDismiss();
  }

  /// Get phase-specific theme
  _PhaseTheme get _phaseTheme {
    final phase = widget.phase?.toLowerCase() ?? 'observer';
    
    switch (phase) {
      case 'architect':
        return _PhaseTheme(
          name: 'ARCHITECT',
          gradient: [
            const Color(0xFF667EEA), // Electric blue
            const Color(0xFF764BA2), // Deep purple
          ],
          accentColor: const Color(0xFF667EEA),
          emoji: '🔵',
          quote: '"Design the life that fits your nature"',
        );
      case 'oracle':
        return _PhaseTheme(
          name: 'ORACLE',
          gradient: [
            const Color(0xFF8B5CF6), // Deep purple
            const Color(0xFFEC4899), // Pink
          ],
          accentColor: const Color(0xFF8B5CF6),
          emoji: '🟣',
          quote: '"Translate discipline into destiny"',
        );
      default: // observer
        return _PhaseTheme(
          name: 'OBSERVER',
          gradient: [
            const Color(0xFFFFB800), // Gold
            const Color(0xFFFF6B35), // Orange
          ],
          accentColor: const Color(0xFFFFB800),
          emoji: '🟡',
          quote: '"Learning your nature"',
        );
    }
  }

  /// Get message-specific theme
  _MessageTheme get _messageTheme {
    switch (widget.message.kind) {
      case MessageKind.brief:
        return _MessageTheme(
          icon: LucideIcons.sunrise,
          label: 'MORNING BRIEF',
          emoji: '🌅',
          time: '7:00 AM',
        );
      case MessageKind.nudge:
        return _MessageTheme(
          icon: LucideIcons.zap,
          label: 'NUDGE',
          emoji: '⚡',
          time: 'Now',
        );
      case MessageKind.debrief:
        return _MessageTheme(
          icon: LucideIcons.moon,
          label: 'EVENING DEBRIEF',
          emoji: '🌙',
          time: '9:00 PM',
        );
      case MessageKind.letter:
        return _MessageTheme(
          icon: LucideIcons.heart,
          label: 'LETTER',
          emoji: '💌',
          time: 'Sunday',
        );
      default:
        return _MessageTheme(
          icon: LucideIcons.messageCircle,
          label: 'MESSAGE',
          emoji: '💬',
          time: 'Now',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _entranceSlide, _entranceFade]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _entranceSlide.value),
          child: Opacity(
            opacity: _entranceFade.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  // Outer glow
                  BoxShadow(
                    color: _phaseTheme.accentColor.withOpacity(0.4 * _glowAnimation.value),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  // Inner shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _phaseTheme.gradient[0].withOpacity(0.15),
                          _phaseTheme.gradient[1].withOpacity(0.08),
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: _phaseTheme.accentColor.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Phase + Message Type
                _buildHeader(),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Consciousness Indicators (if available)
                if (widget.structuralIntegrity != null || widget.focusPillar != null)
                  _buildConsciousnessIndicators(),
                
                // Message Body
                _buildMessageBody(),
                
                // Expand hint or actions
                if (!_isExpanded)
                  _buildExpandHint()
                else
                  _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Phase Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _phaseTheme.gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _phaseTheme.accentColor.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _phaseTheme.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                _phaseTheme.name,
                style: AppTextStyles.captionSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: AppSpacing.sm),
        
        // Message Type
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _messageTheme.icon,
                color: Colors.white.withOpacity(0.9),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                _messageTheme.label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Time + Emoji
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _messageTheme.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            Text(
              _messageTheme.time,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsciousnessIndicators() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _phaseTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Structural Integrity
          if (widget.structuralIntegrity != null) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  size: 16,
                  color: _phaseTheme.accentColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Structural Integrity',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.structuralIntegrity}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    color: _phaseTheme.accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (widget.structuralIntegrity ?? 0) / 100,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  _phaseTheme.accentColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
          
          // Focus Pillar
          if (widget.focusPillar != null) ...[
            if (widget.structuralIntegrity != null)
              const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  LucideIcons.target,
                  size: 16,
                  color: _phaseTheme.accentColor.withOpacity(0.8),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.focusPillar!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phase quote (subtle)
        Text(
          _phaseTheme.quote,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: _phaseTheme.accentColor.withOpacity(0.7),
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Message text
        Text(
          _isExpanded
              ? widget.message.body
              : _truncateText(widget.message.body, 120),
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.2,
          ),
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildExpandHint() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _phaseTheme.accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _phaseTheme.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.chevronDown,
                color: _phaseTheme.accentColor.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to expand',
                style: AppTextStyles.caption.copyWith(
                  color: _phaseTheme.accentColor.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'View Reflections',
              icon: LucideIcons.bookOpen,
              onPressed: _handleDismiss,
              gradient: _phaseTheme.gradient,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ActionButton(
            label: 'Dismiss',
            icon: LucideIcons.check,
            onPressed: () async {
              await messagesService.markAsRead(widget.message.id);
              widget.onDismiss();
            },
            gradient: _phaseTheme.gradient,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class _PhaseTheme {
  final String name;
  final List<Color> gradient;
  final Color accentColor;
  final String emoji;
  final String quote;

  _PhaseTheme({
    required this.name,
    required this.gradient,
    required this.accentColor,
    required this.emoji,
    required this.quote,
  });
}

class _MessageTheme {
  final IconData icon;
  final String label;
  final String emoji;
  final String time;

  _MessageTheme({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.time,
  });
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.gradient,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: isPrimary ? 24 : 16,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: gradient)
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
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


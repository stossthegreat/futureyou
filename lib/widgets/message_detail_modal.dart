import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../models/coach_message.dart';
import '../services/messages_service.dart';
import '../services/api_client.dart' as api;

class DesignTokens {
  static const accentColor = AppColors.emerald;
  static final darkGradient = AppColors.backgroundGradient;
}

class MessageDetailModal extends StatefulWidget {
  final CoachMessage message;
  final VoidCallback onClose;

  const MessageDetailModal({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<MessageDetailModal> createState() => _MessageDetailModalState();
}

class _MessageDetailModalState extends State<MessageDetailModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _reflectionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // Mark as read
    if (!widget.message.isRead) {
      messagesService.markAsRead(widget.message.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Color _getKindColor() {
    switch (widget.message.kind) {
      case MessageKind.brief:
        return const Color(0xFFFFB800);
      case MessageKind.nudge:
        return const Color(0xFFFF6B6B);
      case MessageKind.debrief:
        return const Color(0xFF8B5CF6);
      case MessageKind.letter:
        return const Color(0xFFF0F0F0);
      case MessageKind.mirror:
        return const Color(0xFF06B6D4);
      case MessageKind.awakening:
        return const Color(0xFF4A5568); // Dark gray/slate for awakening journey
      case MessageKind.chat:
        return DesignTokens.accentColor;
      case MessageKind.vault:
        return const Color(0xFFFFD700);
    }
  }

  void _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: DesignTokens.darkGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getKindColor().withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getKindColor().withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getKindColor().withOpacity(0.2),
                        _getKindColor().withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _getKindColor().withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.message.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.kindLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getKindColor(),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(widget.message.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _close,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.message.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Body
                        Text(
                          widget.message.body,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                          ),
                        ),
                        
                        // ✅ NEW: Reflection Section for briefs and debriefs
                        if (widget.message.kind == MessageKind.brief || 
                            widget.message.kind == MessageKind.debrief) ...[
                          const SizedBox(height: 32),
                          _buildReflectionSection(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _close,
                          child: const Text('Got it'),
                        ),
                      ),
                      if (widget.message.kind == MessageKind.nudge ||
                          widget.message.kind == MessageKind.brief) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Navigate to chat with context
                              _close();
                            },
                            child: const Text('Discuss in Chat'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeStr = _formatTime(dateTime);

    if (messageDate == today) {
      return 'Today at $timeStr';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} at $timeStr';
    }
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Widget _buildReflectionSection() {
    final String prompt = widget.message.kind == MessageKind.brief
        ? 'What\'s your main intention for today?'
        : 'What did you learn today?';
    
    final String emoji = widget.message.kind == MessageKind.brief
        ? '💭'
        : '🌙';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getKindColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getKindColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Reflection',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            prompt,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflectionController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getKindColor().withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getKindColor().withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getKindColor(),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReflection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getKindColor(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Reflection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReflection() async {
    final text = _reflectionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final apiClient = api.ApiClient();
      await apiClient.post('/api/os/reflections', {
        'message_id': widget.message.id,
        'message_kind': widget.message.kind.name,
        'reflection_text': text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Reflection saved'),
            backgroundColor: _getKindColor(),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _reflectionController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to save reflection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}


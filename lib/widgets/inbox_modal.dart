import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../models/coach_message.dart';
import '../services/messages_service.dart';
import 'glass_card.dart';
import 'message_detail_modal.dart';

class DesignTokens {
  static const accentColor = AppColors.emerald;
  static final darkGradient = AppColors.backgroundGradient;
}

class InboxModal extends StatefulWidget {
  final VoidCallback? onMessageRead;

  const InboxModal({
    super.key,
    this.onMessageRead,
  });

  @override
  State<InboxModal> createState() => _InboxModalState();
}

class _InboxModalState extends State<InboxModal> {
  List<CoachMessage> _messages = [];
  MessageKind? _filter;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      if (_filter == null) {
        _messages = messagesService.getAllMessages();
      } else {
        _messages = messagesService.getMessagesByKind(_filter!);
      }
    });
  }

  void _setFilter(MessageKind? kind) {
    setState(() {
      _filter = kind;
    });
    _loadMessages();
  }

  void _openMessage(CoachMessage message) {
    Navigator.of(context).pop(); // Close inbox
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => MessageDetailModal(
        message: message,
        onClose: () {
          Navigator.of(context).pop();
          widget.onMessageRead?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: DesignTokens.darkGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.inbox,
                  color: DesignTokens.accentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Future You Messages',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filter == null,
                    onTap: () => _setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Briefs',
                    emoji: '🌅',
                    isSelected: _filter == MessageKind.brief,
                    onTap: () => _setFilter(MessageKind.brief),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Nudges',
                    emoji: '🔴',
                    isSelected: _filter == MessageKind.nudge,
                    onTap: () => _setFilter(MessageKind.nudge),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Debriefs',
                    emoji: '🌙',
                    isSelected: _filter == MessageKind.debrief,
                    onTap: () => _setFilter(MessageKind.debrief),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Letters',
                    emoji: '💌',
                    isSelected: _filter == MessageKind.letter,
                    onTap: () => _setFilter(MessageKind.letter),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageListItem(
                        message: message,
                        onTap: () => _openMessage(message),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Future You will reach out soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? DesignTokens.accentColor
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageListItem extends StatelessWidget {
  final CoachMessage message;
  final VoidCallback onTap;

  const _MessageListItem({
    required this.message,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: message.isRead
            ? Colors.white.withOpacity(0.1)
            : DesignTokens.accentColor.withOpacity(0.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getKindColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      message.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.kindLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getKindColor(),
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (!message.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: DesignTokens.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getKindColor() {
    switch (message.kind) {
      case MessageKind.brief:
        return const Color(0xFFFFB800); // Gold
      case MessageKind.nudge:
        return const Color(0xFFFF6B6B); // Red/Orange
      case MessageKind.debrief:
        return const Color(0xFF8B5CF6); // Purple
      case MessageKind.letter:
        return const Color(0xFFF0F0F0); // White/Silver
      case MessageKind.mirror:
        return const Color(0xFF06B6D4); // Cyan
      default:
        return DesignTokens.accentColor;
    }
  }
}


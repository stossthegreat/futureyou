import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../services/messages_service.dart';
import 'inbox_modal.dart';
import 'settings_modal.dart';

class DesignTokens {
  static const accentColor = AppColors.emerald;
  static final darkGradient = AppColors.backgroundGradient;
}

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  
  const TopBar({
    super.key,
    required this.title,
  });

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = messagesService.getUnreadCount();
    });
  }

  void _showInbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InboxModal(
        onMessageRead: () {
          _updateUnreadCount();
        },
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        // Inbox icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.inbox_outlined,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _showInbox,
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.accentColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        // Settings icon
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: 26,
          ),
          onPressed: _showSettings,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}


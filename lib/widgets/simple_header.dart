import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../screens/settings_screen.dart';
import '../screens/reflections_screen.dart';
import '../services/messages_service.dart';

class SimpleHeader extends StatefulWidget {
  final String? tabName; // Optional tab name to display
  final Color? tabColor; // Optional color for the tab name
  
  const SimpleHeader({
    super.key,
    this.tabName,
    this.tabColor,
  });

  @override
  State<SimpleHeader> createState() => _SimpleHeaderState();
}

class _SimpleHeaderState extends State<SimpleHeader> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = messagesService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.tabName != null ? AppSpacing.sm : AppSpacing.lg, // Less padding on left if tab name present
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: widget.tabName != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          // Tab name (if provided)
          if (widget.tabName != null)
            Text(
              widget.tabName!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: widget.tabColor ?? AppColors.emerald,
                letterSpacing: 0.5,
              ),
            ),
          
          // Reflections + Settings icons
          Row(
            children: [
              // Reflections icon (left of Settings) with notification badge
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReflectionsScreen(),
                    ),
                  );
                  // Reload count when returning from Reflections screen
                  _loadUnreadCount();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: AppColors.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.bookOpen,
                        color: AppColors.emerald,
                        size: 22,
                      ),
                    ),
                    // Notification badge
                    if (_unreadCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              _unreadCount > 99 ? '99+' : '$_unreadCount',
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
              ),
              const SizedBox(width: AppSpacing.sm),
              // Settings icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.settings,
                    color: AppColors.emerald,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


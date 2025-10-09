import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

import '../design/tokens.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'chat_screen.dart';
import 'mirror_screen.dart';
import 'settings_screen.dart';
import 'streak_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _tabAnimationController;
  
  final List<TabItem> _tabs = [
    TabItem(
      icon: LucideIcons.activity,
      label: 'Home',
      screen: const HomeScreen(),
    ),
    TabItem(
      icon: LucideIcons.plus,
      label: 'Planner',
      screen: const PlannerScreen(),
    ),
    TabItem(
      icon: LucideIcons.messageSquare,
      label: 'Chat',
      screen: const ChatScreen(),
    ),
    TabItem(
      icon: LucideIcons.flame,
      label: 'Streak',
      screen: const StreakScreen(),
    ),
    TabItem(
      icon: LucideIcons.user,
      label: 'Mirror',
      screen: const MirrorScreen(),
    ),
    TabItem(
      icon: LucideIcons.settings,
      label: 'Settings',
      screen: const SettingsScreen(),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }
  
  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _tabAnimationController.forward().then((_) {
        _tabAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildHeader(),
              ),
              
              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _tabs[index].screen,
                    );
                  },
                ),
              ),
              
              // Bottom navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Future U OS',
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textQuaternary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Unicorn Habit System',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
              boxShadow: AppShadows.glass,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isActive = index == _currentIndex;
                
                return _buildTabButton(tab, index, isActive);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabButton(TabItem tab, int index, bool isActive) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        onTap: () => _onTabTapped(index),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.emerald.withOpacity(0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: isActive ? AppShadows.glow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                tab.icon,
                size: 20,
                color: isActive 
                    ? AppColors.emerald 
                    : AppColors.textTertiary,
              ),
            ).animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
              )
              .shimmer(
                duration: 1000.ms,
                color: AppColors.emerald.withOpacity(0.3),
              ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: AppTextStyles.label.copyWith(
                color: isActive 
                    ? AppColors.emerald 
                    : AppColors.textTertiary,
                fontWeight: isActive 
                    ? FontWeight.w600 
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class TabItem {
  final IconData icon;
  final String label;
  final Widget screen;
  
  const TabItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

import '../design/tokens.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'future_you_screen.dart';
import 'what_if_screen.dart';
import 'reflections_screen.dart';
import 'mirror_screen.dart';

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
      icon: LucideIcons.flame,
      label: 'Home',
      screen: const HomeScreen(),
    ),
    TabItem(
      icon: LucideIcons.clipboard,
      label: 'Planner',
      screen: const PlannerScreen(),
    ),
    TabItem(
      icon: LucideIcons.brain,
      label: 'Future-You',
      screen: const FutureYouScreen(),
    ),
    TabItem(
      icon: LucideIcons.sparkles,
      label: 'What-If',
      screen: const WhatIfScreen(),
    ),
    TabItem(
      icon: LucideIcons.bookOpen,
      label: 'Reflections',
      screen: const ReflectionsScreen(),
    ),
    TabItem(
      icon: LucideIcons.star,
      label: 'Mirror',
      screen: const MirrorScreen(),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Content
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  return _tabs[index].screen;
                },
              ),
              
              // Bottom navigation (always visible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glass overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo + Text
                Row(
                  children: [
                    // ƒ Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'ƒ',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Text
                    Text(
                      'FUTURE-YOU OS',
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.4,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Pulsing sparkles
                AnimatedBuilder(
                  animation: _tabAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.8 + (_tabAnimationController.value * 0.2),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 40,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(duration: 3600.ms, color: Colors.white.withOpacity(0.1));
  }
  
  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
              boxShadow: AppShadows.glass,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / _tabs.length;
                
                return Stack(
                  children: [
                    // Sliding pill indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: _currentIndex * tabWidth,
                      child: Container(
                        width: tabWidth,
                        height: 72,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.emeraldLight.withOpacity(0.2),
                                AppColors.emerald.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          ),
                        ),
                      ),
                    ),
                    
                    // Tab buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _tabs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tab = entry.value;
                        final isActive = index == _currentIndex;
                        
                        return _buildTabButton(tab, index, isActive);
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabButton(TabItem tab, int index, bool isActive) {
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: () => _onTabTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 24,
                  color: isActive 
                      ? AppColors.emeraldLight 
                      : AppColors.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(height: 6),
                Text(
                  tab.label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    color: isActive 
                        ? AppColors.emeraldLight 
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontWeight: isActive 
                        ? FontWeight.w700 
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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

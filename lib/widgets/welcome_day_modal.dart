import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';

class WelcomeDayModal extends StatelessWidget {
  final int day;
  final String moonPhase;
  final String title;
  final String content;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const WelcomeDayModal({
    super.key,
    required this.day,
    required this.moonPhase,
    required this.title,
    required this.content,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.emerald.withOpacity(0.03),
                    Colors.black,
                    Colors.black,
                  ],
                ),
              ),
            ),
            
            // Main content
            Column(
              children: [
                // Header with back button and progress
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Back button
                      if (onBack != null)
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  LucideIcons.arrowLeft,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Progress dots
                      Row(
                        children: List.generate(7, (index) {
                          final isActive = index + 1 <= day;
                          return Container(
                            width: isActive ? 8 : 6,
                            height: isActive ? 8 : 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? AppColors.emerald
                                  : Colors.white12,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 40),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Moon phase emoji
                        Text(
                          moonPhase,
                          style: const TextStyle(fontSize: 64),
                        ).animate().scale(
                          delay: 200.ms,
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppColors.emerald,
                              Colors.white,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.3,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                        
                        const SizedBox(height: 48),
                        
                        // Content with dramatic spacing
                        Text(
                          content,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: Colors.white87,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                
                // Bottom continue button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


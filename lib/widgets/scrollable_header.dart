import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';

class ScrollableHeader extends StatelessWidget {
  const ScrollableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main header - full width
        Container(
          height: 112,
          decoration: BoxDecoration(
            gradient: AppColors.emeraldGradient,
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
                  ),
                ),
              ),
              // Content - centered vertically
              Center(
                child: Padding(
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Settings icon (centered vertically, bigger and black)
        Positioned(
          top: 36,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.settings,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


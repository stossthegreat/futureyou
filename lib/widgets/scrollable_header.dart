import 'package:flutter/material.dart';
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
              // Content - centered vertically, full width from left to right
              Padding(
                padding: const EdgeInsets.only(
                  left: 16, // Moved to the left
                  right: 80, // More space for settings icon
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo - bigger
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
                              fontSize: 32,
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
                      const SizedBox(width: 14),
                      // Text
                      Text(
                        'Future-You OS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
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
                ),
              ),
            ],
          ),
        ),
        
        // Settings icon (centered vertically, smaller ring)
        Positioned(
          top: 38,
          right: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
            child: Container(
              padding: const EdgeInsets.all(8),
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
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


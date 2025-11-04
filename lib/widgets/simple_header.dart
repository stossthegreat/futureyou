import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../screens/settings_screen.dart';

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Future-You OS title in green
          ShaderMask(
            shaderCallback: (bounds) => AppColors.emeraldGradient
                .createShader(bounds),
            child: const Text(
              'Future-You OS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
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
    );
  }
}


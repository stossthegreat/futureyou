import 'package:flutter/material.dart';
import 'dart:ui';
import '../design/tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
        boxShadow: boxShadow ?? AppShadows.glass,
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glassBackground,
              borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
            ),
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    
    return widget;
  }
}

class AnimatedGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool enabled;
  
  const AnimatedGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.enabled = true,
  });

  @override
  State<AnimatedGlassButton> createState() => _AnimatedGlassButtonState();
}

class _AnimatedGlassButtonState extends State<AnimatedGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _animationController.forward();
    }
  }
  
  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _animationController.reverse();
    }
  }
  
  void _onTapCancel() {
    if (widget.enabled && widget.onPressed != null) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.enabled ? widget.onPressed : null,
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(AppBorderRadius.md),
                gradient: widget.gradient,
                color: widget.gradient == null 
                    ? (widget.backgroundColor ?? AppColors.glassBackground)
                    : null,
                border: Border.all(
                  color: widget.borderColor ?? AppColors.glassBorder,
                  width: 1,
                ),
                boxShadow: widget.enabled ? AppShadows.glass : null,
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(AppBorderRadius.md),
                child: widget.gradient == null
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
                          child: widget.child,
                        ),
                      )
                    : Container(
                        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlowingGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color glowColor;
  final double glowIntensity;
  final bool animate;
  
  const GlowingGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.glowColor = AppColors.emerald,
    this.glowIntensity = 1.0,
    this.animate = true,
  });

  @override
  State<GlowingGlassCard> createState() => _GlowingGlassCardState();
}

class _GlowingGlassCardState extends State<GlowingGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animate) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowValue = widget.animate ? _glowAnimation.value : 1.0;
        final adjustedIntensity = widget.glowIntensity * glowValue;
        
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.3 * adjustedIntensity),
                blurRadius: 20 * adjustedIntensity,
                spreadRadius: 2 * adjustedIntensity,
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.1 * adjustedIntensity),
                blurRadius: 40 * adjustedIntensity,
                spreadRadius: 4 * adjustedIntensity,
              ),
            ],
            border: Border.all(
              color: widget.glowColor.withOpacity(0.4 * adjustedIntensity),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(AppBorderRadius.xxl),
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.2),
                    radius: 1.2,
                    colors: [
                      widget.glowColor.withOpacity(0.15 * adjustedIntensity),
                      widget.glowColor.withOpacity(0.05 * adjustedIntensity),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Frosted-glass surface used for floating chips, badges, and overlays
/// (blur backdrop + translucent fill + hairline stroke).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color? fill;
  final Color? stroke;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.blur = 18,
    this.fill,
    this.stroke,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill ?? AppColors.glassFill,
            borderRadius: borderRadius,
            border: Border.all(
              color: stroke ?? AppColors.glassStroke,
              width: 1,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

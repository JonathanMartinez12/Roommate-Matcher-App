import 'package:flutter/material.dart';

/// Tweens an integer value from 0 (or [from]) to [value] when the widget
/// first builds or whenever [value] changes. Used for dashboard stats.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final int from;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.from = 0,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: from.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, v, _) {
        return Text(
          '$prefix${v.round()}$suffix',
          style: style,
        );
      },
    );
  }
}

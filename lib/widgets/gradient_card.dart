import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A soft, rounded card with a gradient background and two faint
/// decorative circles — the same visual language used on the AI
/// welcome card, reused anywhere a "hero" surface is needed (streak
/// banners, phase highlight, check-in prompts).
///
/// Wrap it in a [GestureDetector]/[InkWell] yourself if it needs to be
/// tappable — this widget stays presentation-only.
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showDecoration;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.showDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [AppColors.primary, AppColors.accent];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors.map((c) => c.withValues(alpha: 0.92)).toList(),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            if (showDecoration) ...[
              Positioned(top: -36, right: -36, child: _decorativeCircle(120)),
              Positioned(bottom: -28, left: -28, child: _decorativeCircle(100)),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
    ),
  );
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A fully-rounded "pill" button with a gentle scale-down animation on
/// press. Use [PillButtonStyle.filled] for primary actions (e.g. "Talk
/// to Saheli") and [PillButtonStyle.outline] for secondary ones.
enum PillButtonStyle { filled, outline, soft }

class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final PillButtonStyle style;
  final IconData? icon;
  final Color? color;

  /// Optional override for the label/icon color. Useful for
  /// [PillButtonStyle.filled] on a light background (e.g. a white pill
  /// button on a gradient card) where white text would be unreadable.
  final Color? foregroundColor;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillButtonStyle.filled,
    this.icon,
    this.color,
    this.foregroundColor,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppColors.primary;

    late final Color background;
    late final Color foreground;
    BoxBorder? border;

    switch (widget.style) {
      case PillButtonStyle.filled:
        background = base;
        foreground = widget.foregroundColor ?? Colors.white;
        break;
      case PillButtonStyle.outline:
        background = Colors.transparent;
        foreground = base;
        border = Border.all(color: base, width: 1.4);
        break;
      case PillButtonStyle.soft:
        background = base.withValues(alpha: 0.14);
        foreground = base;
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: border,
            boxShadow: widget.style == PillButtonStyle.filled
                ? [
                    BoxShadow(
                      color: base.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

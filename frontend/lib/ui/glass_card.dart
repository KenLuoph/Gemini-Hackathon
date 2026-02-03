import 'package:flutter/material.dart';

/// Glass-style card matching the React GlassCard (white/80, blur, rounded-2xl)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool withBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: withBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }
    return card;
  }
}

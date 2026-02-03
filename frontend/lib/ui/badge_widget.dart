import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Badge colors matching React Badge (blue, green, orange, red, gray, purple)
enum BadgeColor {
  blue,
  green,
  orange,
  red,
  gray,
  purple,
}

class BadgeWidget extends StatelessWidget {
  final Widget child;
  final BadgeColor color;

  const BadgeWidget({
    super.key,
    required this.child,
    this.color = BadgeColor.blue,
  });

  static Color _bgColor(BadgeColor c) {
    switch (c) {
      case BadgeColor.blue:
        return const Color(0xFFDBEAFE);
      case BadgeColor.green:
        return const Color(0xFFD1FAE5);
      case BadgeColor.orange:
        return const Color(0xFFFED7AA);
      case BadgeColor.red:
        return const Color(0xFFFECACA);
      case BadgeColor.gray:
        return AppTheme.slate100;
      case BadgeColor.purple:
        return const Color(0xFFF3E8FF);
    }
  }

  static Color _textColor(BadgeColor c) {
    switch (c) {
      case BadgeColor.blue:
        return const Color(0xFF1D4ED8);
      case BadgeColor.green:
        return const Color(0xFF047857);
      case BadgeColor.orange:
        return const Color(0xFFC2410C);
      case BadgeColor.red:
        return const Color(0xFFB91C1C);
      case BadgeColor.gray:
        return AppTheme.slate600;
      case BadgeColor.purple:
        return const Color(0xFF6B21A8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor(color),
        ),
        child: child,
      ),
    );
  }
}

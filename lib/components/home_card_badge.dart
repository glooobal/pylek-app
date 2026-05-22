import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';

class HomeCardBadge extends StatelessWidget {
  final AppIconKind iconKind;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;

  const HomeCardBadge({
    super.key,
    required this.iconKind,
    required this.background,
    required this.foreground,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
      ),
      child: Icon(
        AppIcons.of(context, iconKind),
        color: foreground,
        size: iconSize,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/theme/apple_colors.dart';

class SmallCard extends StatelessWidget {
  final String title;
  final String value;
  final String valueSize;
  final String text;
  final AppIconKind iconKind;
  final String? fetchedAt;
  final Color? badgeBackground;
  final Color? badgeForeground;
  final VoidCallback onTap;

  const SmallCard({
    super.key,
    required this.title,
    required this.value,
    this.valueSize = "large",
    required this.text,
    required this.iconKind,
    this.fetchedAt,
    this.badgeBackground,
    this.badgeForeground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final fg = badgeForeground ??
                      (iconKind == AppIconKind.air
                        ? AppColors.systemGreen
                        : AppColors.systemOrange);

                    final bg = badgeBackground ??
                      (iconKind == AppIconKind.air
                        ? fg.withOpacity(0.14)
                        : colorScheme.surfaceVariant);

                    return HomeCardBadge(
                      iconKind: iconKind,
                      background: bg,
                      foreground: fg,
                      size: 40,
                      iconSize: 19,
                    );
                  },
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      if (fetchedAt != null) ...[
                        Text(
                          fetchedAt!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Icon(
                        AppIcons.of(context, AppIconKind.chevronRight),
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            if (valueSize == "large") ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  height: 1,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ] else ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],

            const SizedBox(height: 8),

            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
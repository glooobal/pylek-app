import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';

class SmallCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final AppIconKind iconKind;
  final Color? badgeForeground;
  final Color? badgeBackground;
  final String? fetchedAt;
  final VoidCallback? onTap;
  final bool showChevron;

  const SmallCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.iconKind,
    this.badgeForeground,
    this.badgeBackground,
    this.fetchedAt,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSection = showChevron;

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isSection ? 28 : 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeCardBadge(
                iconKind: iconKind,
                background: badgeBackground ?? colorScheme.surfaceVariant,
                foreground: badgeForeground ?? colorScheme.onSurface,
                size: isSection ? 40 : 32,
                iconSize: isSection ? 19 : 16,
              ),
              const Spacer(),
              if (showChevron || fetchedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      if (showChevron)
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
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSection ? 13 : 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: isSection ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              height: 1.1,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSection ? 12 : 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(isSection ? 28 : 22),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

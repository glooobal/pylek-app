import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';

class InsightCard extends StatelessWidget {
  final String label;
  final String title;
  final String description;
  final String recommendation;
  final AppIconKind iconKind;
  final Color? badgeForeground;
  final Color? badgeBackground;
  final String? fetchedAt;

  const InsightCard({
    super.key,
    required this.label,
    required this.title,
    this.description = '',
    this.recommendation = '',
    required this.iconKind,
    this.badgeForeground,
    this.badgeBackground,
    this.fetchedAt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeCardBadge(
                iconKind: iconKind,
                background: badgeBackground ?? colorScheme.surfaceContainerHighest,
                foreground: badgeForeground ?? colorScheme.onSurface,
                size: 32,
                iconSize: 16,
              ),
              const Spacer(),
              if (fetchedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    fetchedAt!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              height: 1.1,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              recommendation,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

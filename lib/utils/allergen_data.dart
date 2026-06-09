import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

enum AllergenCategory { trees, grasses, weeds }

class AllergenOption {
  final String name;
  final String scientificName;
  final AllergenCategory category;

  const AllergenOption({
    required this.name,
    required this.scientificName,
    required this.category,
  });
}

class AllergenGroup {
  final String title;
  final AllergenCategory category;
  final List<AllergenOption> items;

  const AllergenGroup({
    required this.title,
    required this.category,
    required this.items,
  });
}

const List<AllergenGroup> allergenGroups = [
  AllergenGroup(
    title: 'Drzewa',
    category: AllergenCategory.trees,
    items: [
      AllergenOption(name: 'Brzoza', scientificName: 'Betula', category: AllergenCategory.trees),
      AllergenOption(name: 'Dąb', scientificName: 'Quercus', category: AllergenCategory.trees),
      AllergenOption(name: 'Jesion', scientificName: 'Fraxinus', category: AllergenCategory.trees),
      AllergenOption(name: 'Leszczyna', scientificName: 'Corylus', category: AllergenCategory.trees),
      AllergenOption(name: 'Olcha', scientificName: 'Alnus', category: AllergenCategory.trees),
      AllergenOption(name: 'Oliwka', scientificName: 'Olea', category: AllergenCategory.trees),
      AllergenOption(name: 'Sosna', scientificName: 'Pinus', category: AllergenCategory.trees),
      AllergenOption(name: 'Topola', scientificName: 'Populus', category: AllergenCategory.trees),
    ],
  ),
  AllergenGroup(
    title: 'Trawy',
    category: AllergenCategory.grasses,
    items: [
      AllergenOption(name: 'Trawy (ogólnie)', scientificName: 'Poaceae', category: AllergenCategory.grasses),
    ],
  ),
  AllergenGroup(
    title: 'Chwasty',
    category: AllergenCategory.weeds,
    items: [
      AllergenOption(name: 'Ambrozja', scientificName: 'Ambrosia', category: AllergenCategory.weeds),
      AllergenOption(name: 'Bylica', scientificName: 'Artemisia', category: AllergenCategory.weeds),
    ],
  ),
];

({
  AppIconKind icon,
  Color badgeForeground,
  Color badgeBackground,
}) allergenCategoryStyle(AllergenCategory category) {
  switch (category) {
    case AllergenCategory.trees:
      return (
        icon: AppIconKind.tree,
        badgeForeground: AppColors.systemGreen,
        badgeBackground: AppColors.systemGreen.withValues(alpha: 0.22),
      );
    case AllergenCategory.grasses:
      return (
        icon: AppIconKind.grass,
        badgeForeground: AppColors.systemGreenLight,
        badgeBackground: AppColors.systemGreenLight.withValues(alpha: 0.22),
      );
    case AllergenCategory.weeds:
      return (
        icon: AppIconKind.grass,
        badgeForeground: AppColors.systemGreenLight,
        badgeBackground: AppColors.systemGreenLight.withValues(alpha: 0.22),
      );
  }
}

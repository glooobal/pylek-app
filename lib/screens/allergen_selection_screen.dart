import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/allergen_data.dart';

class AllergenSelectionScreen extends StatefulWidget {
  final List<String> initialAllergens;

  const AllergenSelectionScreen({super.key, required this.initialAllergens});

  @override
  State<AllergenSelectionScreen> createState() => _AllergenSelectionScreenState();
}

class _AllergenSelectionScreenState extends State<AllergenSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = <String>{};
  String _searchQuery = '';
  bool _saving = false;

  bool get _hasChanges => !_selected.containsAll(widget.initialAllergens) ||
      !widget.initialAllergens.every((a) => _selected.contains(a));

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialAllergens);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AllergenGroup> get _filteredGroups {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return allergenGroups;

    return allergenGroups
        .map((group) {
          final items = group.items.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.scientificName.toLowerCase().contains(query);
          }).toList();
          if (items.isEmpty) return null;
          return AllergenGroup(
            title: group.title,
            category: group.category,
            items: items,
          );
        })
        .whereType<AllergenGroup>()
        .toList();
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_allergens', _selected.toList());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się zapisać alergenów.")),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Brightness get _brightness => Theme.of(context).brightness;

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Odrzucić zmiany?"),
        content: const Text("Masz niezapisane zmiany. Czy na pewno chcesz wyjść?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Zostań"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Odrzuć", style: TextStyle(color: AppColors.systemRed)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.background(_brightness);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      if (!_hasChanges) {
                        Navigator.of(context).pop();
                        return;
                      }
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.systemOrange,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                    ),
                    child: const Text(
                      'Wróć',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Wybierz swoje alergeny',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.primaryText(_brightness),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Wybierz alergeny, które chcesz obserwować.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.35,
                      color: AppColors.secondaryText(_brightness),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant(_brightness),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.of(context, AppIconKind.search),
                      size: 18,
                      color: AppColors.secondaryText(_brightness),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryText(_brightness),
                            ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Szukaj alergenu...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText(_brightness),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  if (_filteredGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          "Brak wyników",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText(_brightness),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final group in _filteredGroups) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        group.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ),
                    for (final allergen in group.items) _allergenRow(allergen),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryText(_brightness),
                    foregroundColor: AppColors.surfaceLight,
                    disabledBackgroundColor: AppColors.surfaceVariant(_brightness),
                    disabledForegroundColor: AppColors.secondaryText(_brightness),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Zapisywanie...' : 'Zapisz'),
                ),
              ),
            ),
          ],
        ),      // Column
      ),        // SafeArea
      ),        // Scaffold
    );          // PopScope
  }

  Widget _allergenRow(AllergenOption allergen) {
    final selected = _selected.contains(allergen.name);
    final style = allergenCategoryStyle(allergen.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface(_brightness),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggle(allergen.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                HomeCardBadge(
                  iconKind: style.icon,
                  background: style.badgeBackground,
                  foreground: style.badgeForeground,
                  size: 44,
                  iconSize: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allergen.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(_brightness),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        allergen.scientificName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ],
                  ),
                ),
                _selectionIndicator(selected: selected, accent: style.badgeForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionIndicator({required bool selected, required Color accent}) {
    if (selected) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          AppIcons.of(context, AppIconKind.checkMark),
          size: 14,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surfaceVariant(_brightness),
          width: 1.5,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/cities.dart';

class _CityOption {
  final String name;
  const _CityOption(this.name);
}

final List<_CityOption> _cities = availableCities.map((c) => _CityOption(c)).toList();

class CitySelectionScreen extends StatefulWidget {
  final String? currentCity;

  const CitySelectionScreen({super.key, this.currentCity});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.currentCity;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CityOption> get _filteredCities {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _cities;
    return _cities.where((city) => city.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _selectCity(_CityOption city) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final locations = await locationFromAddress('${city.name}, Polska');
      if (locations.isEmpty) throw Exception();

      final location = locations.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_mode', 'manual');
      await prefs.setDouble('manual_lat', location.latitude);
      await prefs.setDouble('manual_lng', location.longitude);
      await prefs.setString('manual_city_name', city.name);
      await prefs.setString('selected_city_name', city.name);

      if (!mounted) return;
      Navigator.of(context).pop(city.name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się pobrać współrzędnych miasta.')),
      );
    }
  }

  Brightness get _brightness => Theme.of(context).brightness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(_brightness),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                'Wybierz miasto',
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
                'Wybierz miasto dla prognozy pylenia.',
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
                          hintText: 'Szukaj miasta...',
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
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  if (_filteredCities.isEmpty)
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
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Miasta',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ),
                    for (final city in _filteredCities) _cityRow(city),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityRow(_CityOption city) {
    final selected = _selectedCity == city.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface(_brightness),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _selectCity(city),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                HomeCardBadge(
                  iconKind: AppIconKind.locationCity,
                  background: AppColors.systemBlue.withValues(alpha: 0.14),
                  foreground: AppColors.systemBlue,
                  size: 44,
                  iconSize: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(_brightness),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Polska',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ],
                  ),
                ),
                _selectionIndicator(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionIndicator({required bool selected}) {
    if (selected) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.systemBlue,
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

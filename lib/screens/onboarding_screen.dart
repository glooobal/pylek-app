import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/analytics_service.dart';
import 'package:pylek/utils/allergen_data.dart';
import 'package:pylek/utils/cities.dart';
import 'package:pylek/utils/location_utils.dart';

enum _OnboardingStep {
  requestingLocation,
  citySelection,
  allergenSelection,
}

const List<String> _cities = availableCities;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _allergenSearchController = TextEditingController();
  final Set<String> _selectedAllergens = <String>{};
  String _allergenSearchQuery = '';

  _OnboardingStep _step = _OnboardingStep.requestingLocation;
  String _searchQuery = '';
  String? _selectedCity;
  bool _isSavingLocation = false;
  bool _isSavingAllergens = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationFirst();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _allergenSearchController.dispose();
    super.dispose();
  }

  List<AllergenGroup> get _filteredAllergenGroups {
    final query = _allergenSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return allergenGroups;
    }

    return allergenGroups
        .map((group) {
          final items = group.items.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.scientificName.toLowerCase().contains(query);
          }).toList();

          if (items.isEmpty) {
            return null;
          }

          return AllergenGroup(
            title: group.title,
            category: group.category,
            items: items,
          );
        })
        .whereType<AllergenGroup>()
        .toList();
  }

  void _goBackFromAllergens() {
    setState(() {
      _step = _OnboardingStep.citySelection;
      _allergenSearchQuery = '';
      _allergenSearchController.clear();
    });
  }

  void _toggleAllergen(String name) {
    setState(() {
      if (_selectedAllergens.contains(name)) {
        _selectedAllergens.remove(name);
      } else {
        _selectedAllergens.add(name);
      }
    });
  }


  List<String> get _filteredCities {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _cities;
    }

    return _cities
        .where((city) => city.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _requestLocationFirst() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _step = _OnboardingStep.citySelection);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _step = _OnboardingStep.citySelection);
        return;
      }

      if (!mounted) return;
      setState(() => _isSavingLocation = true);

      final position = await tryGetLocation();
      if (position == null) {
        if (!mounted) return;
        setState(() => _step = _OnboardingStep.citySelection);
        return;
      }

      final cityName = await resolveCityName(position.latitude, position.longitude);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_mode', 'auto');
      await prefs.setDouble('auto_lat', position.latitude);
      await prefs.setDouble('auto_lng', position.longitude);
      await prefs.setString('auto_city_name', cityName);

      if (!mounted) return;
      setState(() {
        _isSavingLocation = false;
        _allergenSearchQuery = '';
        _allergenSearchController.clear();
        _step = _OnboardingStep.allergenSelection;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingLocation = false;
        _step = _OnboardingStep.citySelection;
      });
    }
  }

  void _skipLocation() {
    setState(() => _step = _OnboardingStep.citySelection);
  }

  void _selectCity(String city) {
    if (_isSavingLocation) return;
    setState(() => _selectedCity = city);
  }

  Future<void> _confirmCitySelection() async {
    if (_selectedCity == null || _isSavingLocation) return;

    final city = _cities.firstWhere((option) => option == _selectedCity);
    await _saveCityAndContinue(city);
  }

  Future<void> _saveCityAndContinue(String city) async {
    if (_isSavingLocation) return;

    try {
      setState(() => _isSavingLocation = true);

      final locations = await locationFromAddress('$city, Polska');
      if (locations.isEmpty) {
        throw Exception('Nie udało się znaleźć miasta.');
      }

      final location = locations.first;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('location_mode', 'manual');
      await prefs.setDouble('manual_lat', location.latitude);
      await prefs.setDouble('manual_lng', location.longitude);
      await prefs.setString('manual_city_name', city);
      await prefs.setString('selected_city_name', city);

      if (!mounted) return;
      setState(() {
        _selectedCity = city;
        _isSavingLocation = false;
        _allergenSearchQuery = '';
        _allergenSearchController.clear();
        _step = _OnboardingStep.allergenSelection;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingLocation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się pobrać współrzędnych miasta. Spróbuj ponownie.'),
        ),
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isSavingAllergens) return;

    setState(() => _isSavingAllergens = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'selected_allergens',
        _selectedAllergens.toList(),
      );
      await prefs.setBool('onboarding_complete', true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingAllergens = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się zapisać ustawień.")),
      );
      return;
    }

    if (!mounted) return;
    AnalyticsService.logOnboardingCompleted();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  Brightness get _brightness => Theme.of(context).brightness;

  Widget _onboardingProgressBar({required int completedSegments}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final completed = index < completedSegments;

        return Container(
          width: 22,
          height: 4,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
          decoration: BoxDecoration(
            color: completed
                ? AppColors.systemGreen
                : AppColors.surfaceVariant(_brightness),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _onboardingSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
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
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText(_brightness),
                  ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText(_brightness),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionIndicator({
    required bool selected,
    required Color accent,
  }) {
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

  Widget _onboardingPrimaryButton({
    required bool enabled,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final buttonBackground = AppColors.primaryTextLight;
    final buttonForeground = AppColors.surfaceLight;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
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
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }

  Widget _onboardingTopBar({
    VoidCallback? onBack,
    required int progressCompletedSegments,
  }) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: Icon(
              AppIcons.of(context, AppIconKind.chevronLeft),
              color: AppColors.primaryText(_brightness),
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 40, height: 40),
        const Spacer(),
        _onboardingProgressBar(completedSegments: progressCompletedSegments),
      ],
    );
  }

  Widget _cityRow(String city) {
    final selected = _selectedCity == city;
    const accent = AppColors.systemBlue;

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
                        city,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(_brightness),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Polska',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ],
                  ),
                ),
                _selectionIndicator(
                  selected: selected,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _citySelectionView(BuildContext context) {
    final canContinue = _selectedCity != null && !_isSavingLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _onboardingTopBar(progressCompletedSegments: 1),
        const SizedBox(height: 32),
        Text(
          'Wybierz swoje miasto',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.primaryText(_brightness),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Później możesz je zmienić w swoim profilu.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppColors.secondaryText(_brightness),
              ),
        ),
        const SizedBox(height: 32),
        _onboardingSearchField(
          controller: _searchController,
          hintText: 'Szukaj miasta...',
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
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
          ),
        ),
        const SizedBox(height: 16),
        _onboardingPrimaryButton(
          enabled: canContinue,
          label: _isSavingLocation ? 'Zapisywanie...' : 'Dalej',
          onPressed: _confirmCitySelection,
        ),
      ],
    );
  }

  Widget _allergenRow(AllergenOption allergen) {
    final selected = _selectedAllergens.contains(allergen.name);
    final style = allergenCategoryStyle(allergen.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface(_brightness),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggleAllergen(allergen.name),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              color: AppColors.secondaryText(_brightness),
                            ),
                      ),
                    ],
                  ),
                ),
                _selectionIndicator(
                  selected: selected,
                  accent: style.badgeForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _allergenSelectionView(BuildContext context) {
    final canContinue = _selectedAllergens.isNotEmpty && !_isSavingAllergens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _onboardingTopBar(
          onBack: _goBackFromAllergens,
          progressCompletedSegments: 2,
        ),
        const SizedBox(height: 32),
        Text(
          'Wybierz swoje alergeny',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.primaryText(_brightness),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Później możesz je zmienić w swoim profilu.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppColors.secondaryText(_brightness),
              ),
        ),
        const SizedBox(height: 32),
        _onboardingSearchField(
          controller: _allergenSearchController,
          hintText: 'Szukaj alergenu...',
          onChanged: (value) => setState(() => _allergenSearchQuery = value),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              for (final group in _filteredAllergenGroups) ...[
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
        _onboardingPrimaryButton(
          enabled: canContinue,
          label: _isSavingAllergens ? 'Zapisywanie...' : 'Dalej',
          onPressed: _finishOnboarding,
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.background(_brightness);

    if (_step == _OnboardingStep.requestingLocation) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                "Szukam Twojej lokalizacji...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(_brightness),
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _skipLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant(_brightness),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Pomiń',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(_brightness),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isSelectionStep = _step == _OnboardingStep.citySelection ||
        _step == _OnboardingStep.allergenSelection;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, isSelectionStep ? 8 : 0, 20, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              _OnboardingStep.citySelection => KeyedSubtree(
                  key: const ValueKey('city'),
                  child: _citySelectionView(context),
                ),
              _OnboardingStep.allergenSelection => KeyedSubtree(
                  key: const ValueKey('allergen'),
                  child: _allergenSelectionView(context),
                ),
              _OnboardingStep.requestingLocation => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}
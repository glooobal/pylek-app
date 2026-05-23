import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/theme/apple_colors.dart';

enum _AllergenCategory { trees, grasses, weeds }

class _AllergenOption {
  final String name;
  final String scientificName;
  final _AllergenCategory category;

  const _AllergenOption({
    required this.name,
    required this.scientificName,
    required this.category,
  });
}

class _AllergenGroup {
  final String title;
  final _AllergenCategory category;
  final List<_AllergenOption> items;

  const _AllergenGroup({
    required this.title,
    required this.category,
    required this.items,
  });
}

class _CityOption {
  final String name;

  const _CityOption(this.name);
}

enum _OnboardingStep {
  requestingLocation,
  citySelection,
  allergenSelection,
}

const List<_CityOption> _cities = [
  _CityOption('Warszawa'),
  _CityOption('Kraków'),
  _CityOption('Łódź'),
  _CityOption('Wrocław'),
  _CityOption('Poznań'),
  _CityOption('Gdańsk'),
  _CityOption('Szczecin'),
  _CityOption('Bydgoszcz'),
  _CityOption('Lublin'),
  _CityOption('Białystok'),
  _CityOption('Katowice'),
  _CityOption('Gdynia'),
  _CityOption('Częstochowa'),
  _CityOption('Radom'),
  _CityOption('Sosnowiec'),
  _CityOption('Toruń'),
  _CityOption('Kielce'),
  _CityOption('Gliwice'),
  _CityOption('Zabrze'),
  _CityOption('Bytom'),
  _CityOption('Olsztyn'),
  _CityOption('Bielsko-Biała'),
  _CityOption('Rzeszów'),
  _CityOption('Ruda Śląska'),
  _CityOption('Rybnik'),
  _CityOption('Tychy'),
  _CityOption('Opole'),
  _CityOption('Gorzów Wielkopolski'),
  _CityOption('Dąbrowa Górnicza'),
  _CityOption('Elbląg'),
  _CityOption('Płock'),
  _CityOption('Wałbrzych'),
  _CityOption('Włocławek'),
  _CityOption('Zielona Góra'),
  _CityOption('Tarnów'),
  _CityOption('Chorzów'),
  _CityOption('Koszalin'),
  _CityOption('Kalisz'),
  _CityOption('Legnica'),
  _CityOption('Grudziądz'),
  _CityOption('Słupsk'),
  _CityOption('Jaworzno'),
  _CityOption('Jastrzębie-Zdrój'),
  _CityOption('Jelenia Góra'),
  _CityOption('Nowy Sącz'),
  _CityOption('Siedlce'),
  _CityOption('Piotrków Trybunalski'),
  _CityOption('Inowrocław'),
  _CityOption('Suwałki'),
  _CityOption('Mysłowice'),
  _CityOption('Konin'),
  _CityOption('Lubin'),
  _CityOption('Ostrowiec Świętokrzyski'),
  _CityOption('Gniezno'),
  _CityOption('Leszno'),
  _CityOption('Zamość'),
  _CityOption('Łomża'),
  _CityOption('Ełk'),
  _CityOption('Przemyśl'),
  _CityOption('Chełm'),
  _CityOption('Mielec'),
  _CityOption('Bełchatów'),
  _CityOption('Tczew'),
  _CityOption('Biała Podlaska'),
  _CityOption('Kędzierzyn-Koźle'),
  _CityOption('Starachowice'),
  _CityOption('Świdnica'),
  _CityOption('Będzin'),
  _CityOption('Pabianice'),
  _CityOption('Otwock'),
  _CityOption('Zawiercie'),
  _CityOption('Racibórz'),
  _CityOption('Piła'),
  _CityOption('Skierniewice'),
  _CityOption('Ciechanów'),
  _CityOption('Kwidzyn'),
  _CityOption('Kołobrzeg'),
  _CityOption('Żory'),
  _CityOption('Wejherowo'),
  _CityOption('Stalowa Wola'),
  _CityOption('Nowa Sól'),
  _CityOption('Giżycko'),
  _CityOption('Łowicz'),
  _CityOption('Mińsk Mazowiecki'),
  _CityOption('Skarżysko-Kamienna'),
  _CityOption('Żyrardów'),
  _CityOption('Brodnica'),
  _CityOption('Bielawa'),
  _CityOption('Świnoujście'),
  _CityOption('Sopot'),
  _CityOption('Mikołów'),
  _CityOption('Tarnowskie Góry'),
  _CityOption('Chojnice'),
  _CityOption('Oświęcim'),
  _CityOption('Grodzisk Mazowiecki'),
  _CityOption('Czerwionka-Leszczyny'),
  _CityOption('Żary'),
  _CityOption('Sieradz'),
  _CityOption('Lidzbark Warmiński'),
  _CityOption('Mława'),
];

const List<_AllergenGroup> _allergenGroups = [
  _AllergenGroup(
    title: 'Drzewa',
    category: _AllergenCategory.trees,
    items: [
      _AllergenOption(
        name: 'Brzoza',
        scientificName: 'Betula',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Dąb',
        scientificName: 'Quercus',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Jesion',
        scientificName: 'Fraxinus',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Leszczyna',
        scientificName: 'Corylus',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Olcha',
        scientificName: 'Alnus',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Oliwka',
        scientificName: 'Olea',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Sosna',
        scientificName: 'Pinus',
        category: _AllergenCategory.trees,
      ),
      _AllergenOption(
        name: 'Topola',
        scientificName: 'Populus',
        category: _AllergenCategory.trees,
      ),
    ],
  ),
  _AllergenGroup(
    title: 'Trawy',
    category: _AllergenCategory.grasses,
    items: [
      _AllergenOption(
        name: 'Trawy (ogólnie)',
        scientificName: 'Poaceae',
        category: _AllergenCategory.grasses,
      ),
    ],
  ),
  _AllergenGroup(
    title: 'Chwasty',
    category: _AllergenCategory.weeds,
    items: [
      _AllergenOption(
        name: 'Ambrozja',
        scientificName: 'Ambrosia',
        category: _AllergenCategory.weeds,
      ),
      _AllergenOption(
        name: 'Bylica',
        scientificName: 'Artemisia',
        category: _AllergenCategory.weeds,
      ),
    ],
  ),
];

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

  List<_AllergenGroup> get _filteredAllergenGroups {
    final query = _allergenSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _allergenGroups;
    }

    return _allergenGroups
        .map((group) {
          final items = group.items.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.scientificName.toLowerCase().contains(query);
          }).toList();

          if (items.isEmpty) {
            return null;
          }

          return _AllergenGroup(
            title: group.title,
            category: group.category,
            items: items,
          );
        })
        .whereType<_AllergenGroup>()
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

  ({Color accent, Color badgeBackground, Color badgeForeground, AppIconKind icon})
      _categoryStyle(_AllergenCategory category) {
    switch (category) {
      case _AllergenCategory.trees:
        return (
          accent: AppColors.systemGreen,
          badgeBackground: AppColors.systemGreen.withOpacity(0.22),
          badgeForeground: AppColors.systemGreen,
          icon: AppIconKind.tree,
        );
      case _AllergenCategory.grasses:
        return (
          accent: AppColors.systemGreenLight,
          badgeBackground: AppColors.systemGreenLight.withOpacity(0.22),
          badgeForeground: AppColors.systemGreenLight,
          icon: AppIconKind.grass,
        );
      case _AllergenCategory.weeds:
        return (
          accent: AppColors.systemGreenLight,
          badgeBackground: AppColors.systemGreenLight.withOpacity(0.22),
          badgeForeground: AppColors.systemGreenLight,
          icon: AppIconKind.grass,
        );
    }
  }

  List<_CityOption> get _filteredCities {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _cities;
    }

    return _cities
        .where((city) => city.name.toLowerCase().contains(query))
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final cityName = await _resolveCityName(
        position.latitude,
        position.longitude,
      );

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

  Future<String> _resolveCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Twoja lokalizacja';
      }

      final placemark = placemarks.first;

      for (final candidate in [
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ]) {
        final value = candidate?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      return 'Twoja lokalizacja';
    } catch (_) {
      return 'Twoja lokalizacja';
    }
  }

  void _selectCity(_CityOption city) {
    if (_isSavingLocation) return;
    setState(() => _selectedCity = city.name);
  }

  Future<void> _confirmCitySelection() async {
    if (_selectedCity == null || _isSavingLocation) return;

    final city = _cities.firstWhere((option) => option.name == _selectedCity);
    await _saveCityAndContinue(city);
  }

  Future<void> _saveCityAndContinue(_CityOption city) async {
    if (_isSavingLocation) return;

    try {
      setState(() => _isSavingLocation = true);

      final locations = await locationFromAddress('${city.name}, Polska');
      if (locations.isEmpty) {
        throw Exception('Nie udało się znaleźć miasta.');
      }

      final location = locations.first;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('location_mode', 'manual');
      await prefs.setDouble('manual_lat', location.latitude);
      await prefs.setDouble('manual_lng', location.longitude);
      await prefs.setString('manual_city_name', city.name);
      await prefs.setString('selected_city_name', city.name);

      if (!mounted) return;
      setState(() {
        _selectedCity = city.name;
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_allergens',
      _selectedAllergens.toList(),
    );
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

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
    final buttonBackground = _brightness == Brightness.light
        ? AppColors.primaryTextLight
        : AppColors.primaryTextDark;
    final buttonForeground = _brightness == Brightness.light
        ? AppColors.surfaceLight
        : AppColors.backgroundDark;

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

  Widget _cityRow(_CityOption city) {
    final selected = _selectedCity == city.name;
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
                  background: AppColors.systemBlue.withOpacity(0.14),
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

  Widget _allergenRow(_AllergenOption allergen) {
    final selected = _selectedAllergens.contains(allergen.name);
    final style = _categoryStyle(allergen.category);

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
                  accent: style.accent,
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
              _OnboardingStep.requestingLocation => const SizedBox.shrink(),
              _OnboardingStep.citySelection => KeyedSubtree(
                  key: const ValueKey('city'),
                  child: _citySelectionView(context),
                ),
              _OnboardingStep.allergenSelection => KeyedSubtree(
                  key: const ValueKey('allergen'),
                  child: _allergenSelectionView(context),
                ),
            },
          ),
        ),
      ),
    );
  }
}
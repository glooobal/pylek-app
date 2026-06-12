import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/screens/allergen_selection_screen.dart';
import 'package:pylek/screens/city_selection_screen.dart';
import 'package:pylek/utils/location_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _selectedAllergens = [];
  String _locationMode = 'auto';
  String _cityName = 'Twoja lokalizacja';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAllergens = prefs.getStringList('selected_allergens') ?? [];
      _locationMode = prefs.getString('location_mode') ?? 'auto';
      _cityName = prefs.getString('manual_city_name') ??
          prefs.getString('auto_city_name') ??
          'Twoja lokalizacja';
    });
  }

  Future<void> _navigateToAllergens() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllergenSelectionScreen(
          initialAllergens: _selectedAllergens,
        ),
      ),
    );
    _loadSettings();
  }

  Future<void> _navigateToCityPicker() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CitySelectionScreen(currentCity: _cityName),
      ),
    );
    if (result != null) {
      setState(() {
        _cityName = result;
        _locationMode = 'manual';
      });
    }
  }

  Future<void> _setLocationMode(String mode) async {
    if (mode == _locationMode) return;

    if (mode == 'auto') {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Włącz usługi lokalizacji w ustawieniach telefonu, aby użyć bieżącej lokalizacji.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak zgody na lokalizację. Przejdź do Ustawienia → Pyłek → Lokalizacja, aby włączyć.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      final position = await tryGetLocation();
      if (position == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_mode', 'auto');
      await prefs.setDouble('auto_lat', position.latitude);
      await prefs.setDouble('auto_lng', position.longitude);

      setState(() => _locationMode = 'auto');
    } else {
      await _navigateToCityPicker();
    }
  }

  Future<void> _rateApp() async {
    final theme = Theme.of(context);
    final isIOS = theme.platform == TargetPlatform.iOS;
    final url = isIOS
        ? Uri.parse('https://apps.apple.com/app/pylek/id0000000000')
        : Uri.parse('https://play.google.com/store/apps/details?id=pl.vitalogic.pylek');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openContact() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'kontakt@vitalogic.pl',
      queryParameters: {'subject': 'Wiadomość z Pyłka!'},
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 12),
            _pageTitle(),
            const SizedBox(height: 16),
            _allergensSection(),
            const SizedBox(height: 32),
            _locationSection(),
            const SizedBox(height: 24),
            _aboutSection(),
            const SizedBox(height: 32),
            _disclaimerSection(),
            const SizedBox(height: 24),
            _versionFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.systemOrange,
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 40),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'Wróć',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _pageTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        'Ustawienia',
        style: TextStyle(
          fontSize: 40,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _allergensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Twoje alergeny'),
        _sectionCard([
          Text(
            'Wybrane alergeny:',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedAllergens.isEmpty)
            Text(
              'Nie wybrano żadnych alergenów',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selectedAllergens.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _navigateToAllergens,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.systemBlue,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Edytuj',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Lokalizacja'),
        _sectionCard([
          Text(
            'Zmień swoją lokalizację.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _locationOption(
            icon: AppIconKind.myLocation,
            title: 'Bieżąca lokalizacja',
            selected: _locationMode == 'auto',
            onTap: () => _setLocationMode('auto'),
          ),
          const SizedBox(height: 8),
          _locationOption(
            icon: AppIconKind.locationCity,
            title: 'Wybrane miasto',
            subtitle: _locationMode == 'manual' ? _cityName : null,
            selected: _locationMode == 'manual',
            onTap: () => _setLocationMode('manual'),
          ),
          if (_locationMode == 'manual') ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _navigateToCityPicker,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.systemBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Zmień miasto',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ]),
      ],
    );
  }

  Widget _locationOption({
    required AppIconKind icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bgColor = selected
        ? Theme.of(context).colorScheme.surfaceVariant
        : Colors.transparent;

    return Semantics(
      button: true,
      label: title,
      selected: selected,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
            children: [
              HomeCardBadge(
                iconKind: icon,
                background: AppColors.systemBlue.withValues(alpha: 0.14),
                foreground: AppColors.systemBlue,
                size: 36,
                iconSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.systemBlue : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.systemBlue
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _aboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('O Pyłku'),
        _sectionCard([
          Semantics(
            button: true,
            label: 'Oceń Pyłka',
            child: InkWell(
              onTap: _rateApp,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    HomeCardBadge(
                      iconKind: AppIconKind.star,
                      background: AppColors.systemYellow.withValues(alpha: 0.14),
                      foreground: AppColors.systemYellow,
                      size: 36,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Oceń Pyłka',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.of(context, AppIconKind.chevronRight),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _sectionCard([
          Semantics(
            button: true,
            label: 'Skontaktuj się z nami',
            child: InkWell(
              onTap: _openContact,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    HomeCardBadge(
                      iconKind: AppIconKind.mail,
                      background: AppColors.systemBlue.withValues(alpha: 0.14),
                      foreground: AppColors.systemBlue,
                      size: 36,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Skontaktuj się z nami',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.of(context, AppIconKind.chevronRight),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _sectionCard([
          Semantics(
            button: true,
            label: 'Polityka prywatności',
            child: InkWell(
              onTap: () => launchUrl(Uri.parse('https://vitalogic.pl/privacy')),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    HomeCardBadge(
                      iconKind: AppIconKind.document,
                      background: AppColors.systemGray.withValues(alpha: 0.14),
                      foreground: AppColors.systemGray,
                      size: 36,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Polityka prywatności',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.of(context, AppIconKind.chevronRight),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _disclaimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Aplikacja Pyłek! jest narzędziem do monitorowania pylenia roślin i jakości powietrza, skierowanym do osób zmagających się z alergiami. Aplikacja nie jest wyrobem medycznym i nie powinna być używana jako substytut profesjonalnej porady medycznej, diagnozy czy leczenia. Informacje dostarczane przez aplikację mają charakter informacyjny i nie powinny być traktowane jako zalecenia medyczne. W przypadku pytań dotyczących zdrowia lub alergii, zawsze należy skonsultować się z wykwalifikowanym pracownikiem służby zdrowia.',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _versionFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data != null
            ? 'Pyłek ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Pyłek 1.0.0';
        return Center(
          child: Text(
            version,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

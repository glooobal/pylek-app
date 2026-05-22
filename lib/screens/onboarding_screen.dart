import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/theme/apple_colors.dart';

class _CityOption {
  final String name;
  final double latitude;
  final double longitude;

  const _CityOption(this.name, this.latitude, this.longitude);
}

const List<_CityOption> _cities = [
  _CityOption('Warszawa', 52.2297, 21.0122),
  _CityOption('Kraków', 50.0647, 19.9450),
  _CityOption('Wrocław', 51.1079, 17.0385),
  _CityOption('Gdańsk', 54.3520, 18.6466),
  _CityOption('Poznań', 52.4064, 16.9252),
  _CityOption('Łódź', 51.7592, 19.4550),
  _CityOption('Katowice', 50.2649, 19.0238),
];

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context, {required bool manual, double? latitude, double? longitude, String? cityName}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboarding_complete', true);

    if (manual) {
      await prefs.setString('location_mode', 'manual');
      await prefs.setDouble('manual_lat', latitude!);
      await prefs.setDouble('manual_lng', longitude!);
      await prefs.setString('manual_city_name', cityName!);
    } else {
      await prefs.setString('location_mode', 'auto');
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required AppIconKind icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            HomeCardBadge(
              iconKind: icon,
              background: accent.withOpacity(0.14),
              foreground: accent,
              size: 44,
              iconSize: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.of(context, AppIconKind.chevronRight),
              color: colorScheme.onSurfaceVariant.withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityButton(
    BuildContext context,
    _CityOption city,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _finish(
        context,
        manual: true,
        latitude: city.latitude,
        longitude: city.longitude,
        cityName: city.name,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Text(
              city.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              AppIcons.of(context, AppIconKind.locationCity),
              size: 18,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 8),
            Text(
              'Wybierz sposób ustawienia lokalizacji',
              style: TextStyle(
                fontSize: 34,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Możesz użyć bieżącej lokalizacji albo wybrać miasto ręcznie.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _optionCard(
              context: context,
              title: 'Pobierz moją lokalizację',
              subtitle: 'Aplikacja poprosi o dostęp do GPS i użyje Twojej pozycji.',
              icon: AppIconKind.myLocation,
              accent: AppColors.systemTeal,
              onTap: () => _finish(context, manual: false),
            ),
            const SizedBox(height: 14),
            _optionCard(
              context: context,
              title: 'Ustaw miasto ręcznie',
              subtitle: 'Wybierz jedno z głównych miast w Polsce.',
              icon: AppIconKind.locationCity,
              accent: AppColors.systemYellow,
              onTap: () {},
            ),
            const SizedBox(height: 14),
            ..._cities.map((city) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _cityButton(context, city),
              );
            }),
          ],
        ),
      ),
    );
  }
}

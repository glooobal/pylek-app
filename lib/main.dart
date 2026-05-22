import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/screens/onboarding_screen.dart';
import 'package:pylek/theme/apple_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bbmnrxpctgyqxyoffkcd.supabase.co',
    anonKey: 'sb_publishable_QitdPrRUsqiHnaFqAM2xCg_bdkeFWPn',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pyłek',
      themeMode: ThemeMode.system,
      theme: ThemeData.from(colorScheme: AppColors.lightColorScheme).copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.primaryTextLight,
          surfaceTintColor: AppColors.backgroundLight,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundLight,
          selectedItemColor: AppColors.primaryTextLight,
          unselectedItemColor: AppColors.secondaryTextLight.withOpacity(0.75),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppColors.primaryTextLight,
              displayColor: AppColors.primaryTextLight,
            ),
      ),
      darkTheme: ThemeData.from(colorScheme: AppColors.darkColorScheme).copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.primaryTextDark,
          surfaceTintColor: AppColors.backgroundDark,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.primaryTextDark,
          unselectedItemColor: AppColors.secondaryTextDark.withOpacity(0.75),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.primaryTextDark,
              displayColor: AppColors.primaryTextDark,
            ),
      ),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  Future<bool>? _isOnboardingDone;

  @override
  void initState() {
    super.initState();
    _isOnboardingDone = _loadOnboardingState();
  }

  Future<bool> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingDone,
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
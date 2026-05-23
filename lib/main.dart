import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/screens/onboarding_screen.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/theme/app_typography.dart';

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

  ThemeData _theme({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.primaryTextDark : AppColors.primaryTextLight;
    final secondaryText =
        isDark ? AppColors.secondaryTextDark : AppColors.secondaryTextLight;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = AppTypography.applyPlatformFont(
      baseTextTheme.apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
      defaultTargetPlatform,
    );
    final fontFamily = AppTypography.fontFamilyFor(defaultTargetPlatform);
    final cupertinoTextStyle = TextStyle(
      fontFamily: fontFamily,
      color: primaryText,
    );

    return ThemeData.from(colorScheme: colorScheme).copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        surfaceTintColor: background,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryText,
        unselectedItemColor: secondaryText.withOpacity(0.75),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.systemBlue,
        scaffoldBackgroundColor: background,
        textTheme: CupertinoTextThemeData(
          textStyle: cupertinoTextStyle,
          actionTextStyle: cupertinoTextStyle.copyWith(
            color: AppColors.systemBlue,
          ),
          navTitleTextStyle: cupertinoTextStyle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: cupertinoTextStyle.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pyłek',
      themeMode: ThemeMode.system,
      theme: _theme(
        brightness: Brightness.light,
        colorScheme: AppColors.lightColorScheme,
      ),
      darkTheme: _theme(
        brightness: Brightness.dark,
        colorScheme: AppColors.darkColorScheme,
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
        if (!snapshot.hasData) {
          final brightness = Theme.of(context).brightness;

          return Scaffold(
            backgroundColor: AppColors.background(brightness),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.systemBlue,
              ),
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
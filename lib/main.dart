import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'package:pylek/screens/main_screen.dart';
import 'package:pylek/screens/onboarding_screen.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/theme/app_typography.dart';
import 'package:pylek/utils/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(ColorScheme colorScheme) {
    final primaryText = AppColors.primaryTextLight;
    final secondaryText = AppColors.secondaryTextLight;
    final background = AppColors.backgroundLight;
    final baseTextTheme = ThemeData.light().textTheme;
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

    return ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
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
        unselectedItemColor: secondaryText.withValues(alpha: 0.75),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.light,
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
      theme: _theme(AppColors.lightColorScheme),
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
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
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
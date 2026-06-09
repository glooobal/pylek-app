import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/screens/forecast_screen.dart';
import 'package:pylek/screens/home_screen.dart';
import 'package:pylek/screens/journal_screen.dart';
import 'package:pylek/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final PageController _pageController = PageController();

  late final List<Widget> pages = [
    HomeScreen(onNavigateToTab: _onTabChanged),
    const ForecastScreen(),
    const JournalScreen(),
  ];

  String _title(int i) {
    switch (i) {
      case 0:
        return "Dzisiaj";
      case 1:
        return "Prognoza";
      case 2:
        return "Dzienniczek";
      default:
        return "";
    }
  }

  void _onTabChanged(int i) {
    setState(() => index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _settingsButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: "Ustawienia",
      child: GestureDetector(
        onTap: () => _openSettings(),
        child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          AppIcons.of(context, AppIconKind.settings),
          size: 24,
          color: AppColors.systemGray,
        ),
      ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 92,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            _title(index),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _settingsButton(),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) {
          setState(() => index = i);
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: _onTabChanged,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.onSurface,
        unselectedItemColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        items: [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.of(context, AppIconKind.home)),
            label: "Dzisiaj",
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.of(context, AppIconKind.forecast)),
            label: "Prognoza",
          ),  
          BottomNavigationBarItem(
            icon: Icon(AppIcons.of(context, AppIconKind.journal)),
            label: "Dzienniczek",
          ),
        ],
      ),
    );
  }
}
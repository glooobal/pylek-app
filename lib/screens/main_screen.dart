import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/screens/alerts_screen.dart';
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

  final pages = const [
    HomeScreen(),
    ForecastScreen(),
    JournalScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  String _title(int i) {
    switch (i) {
      case 0:
        return "Dzisiaj";
      case 1:
        return "Prognoza";
      case 2:
        return "Dzienniczek";
      case 3:
        return "Alerty";
      case 4:
        return "Ustawienia";
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        surfaceTintColor: colorScheme.background,
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
        backgroundColor: colorScheme.background,
        selectedItemColor: colorScheme.onBackground,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
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
          BottomNavigationBarItem(
            icon: Icon(AppIcons.of(context, AppIconKind.alerts)),
            label: "Alerty",
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.of(context, AppIconKind.settings)),
            label: "Ustawienia",
          ),
        ],
      ),
    );
  }
}
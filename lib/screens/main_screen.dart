import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.black,
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
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        // selectedFontSize: 0,
        // unselectedFontSize: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Dzisiaj",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: "Prognoza",
          ),  
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: "Dzienniczek",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            label: "Alerty",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Ustawienia",
          ),
        ],
      ),
    );
  }
}
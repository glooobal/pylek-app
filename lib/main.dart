import 'package:flutter/material.dart';
import 'package:pylek/screens/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const MainScreen(),
    );
  }
}
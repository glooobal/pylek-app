import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? error;
  String? source;
  dynamic data;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await _getLocationAndFetch();
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        "Pyłek nie ma dostępu do lokalizacji. Włącz lokalizację w ustawieniach.",
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Pyłek nie ma dostępu do lokalizacji. Włącz uprawnienia w ustawieniach.",
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getLocationAndFetch() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final position = await _getLocation();

      final res = await _client.functions.invoke(
        'get_pollen',
        body: {
          "latitude": position.latitude,
          "longitude": position.longitude,
        },
      );

      if (res.data == null) {
        throw Exception("Nie udało się pobrać danych.");
      }

      setState(() {
        source = res.data['source'];
        data = res.data['data'];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ─────────────────────────────
  // DATA HELPERS
  // ─────────────────────────────

  List<dynamic> getDays() {
    return data?['dailyInfo'] ?? [];
  }

  Map<String, dynamic> analyzeDay(dynamic day) {
    final pollenTypes = day['pollenTypeInfo'] ?? [];
    final plants = day['plantInfo'] ?? [];

    int maxLevel = 0;
    String worstType = "Brak danych";

    for (final type in pollenTypes) {
      final value = type['indexInfo']?['value'];

      if (value != null && value > maxLevel) {
        maxLevel = value;
        worstType = type['displayName'] ?? "Nieznane";
      }
    }

    return {
      "level": maxLevel,
      "worstType": worstType,
      "plants": plants,
    };
  }

  String levelLabel(int level) {
    switch (level) {
      case 0:
        return "Bardzo niski";
      case 1:
        return "Niski";
      case 2:
        return "Umiarkowany";
      case 3:
        return "Wysoki";
      default:
        return "Nie pyli";
    }
  }

  Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case "bardzo niski":
        return Colors.green;

      case "niski":
        return Colors.lightGreen;

      case "umiarkowany":
        return Colors.orange;

      case "wysoki":
        return Colors.red;

      case "bardzo wysoki":
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  // ─────────────────────────────
  // UI CARD
  // ─────────────────────────────

  Widget _dayCard({
    required String date,
    required int level,
    required String worstType,
    required List<dynamic> plants,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE
          Text(
            date,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          // LEVEL
          Text(
            levelLabel(level),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Najgorszy alergen: $worstType",
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

          // PLANTS HEADER
          const Text(
            "Rośliny:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // PLANTS LIST
          ...plants.map((plant) {
            final name = plant['displayName'] ?? "Nieznane";
            final category = plant['indexInfo']?['category'] ?? "Nie pyli";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(name),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor(category).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor(category),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // BUILD
  // ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(error!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: getDays().length,
          itemBuilder: (context, index) {
            final day = getDays()[index];
            final analysis = analyzeDay(day);

            final date = day['date'];
            final label =
                "${date['day']}.${date['month']}.${date['year']}";

            return _dayCard(
              date: label,
              level: analysis['level'],
              worstType: analysis['worstType'],
              plants: analysis['plants'],
            );
          },
        ),
      ),
    );
  }
}
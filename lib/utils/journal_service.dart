import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JournalEntry {
  final String date;
  final int severity;
  final List<String> symptoms;
  final String notes;

  const JournalEntry({
    required this.date,
    required this.severity,
    required this.symptoms,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'severity': severity,
        'symptoms': symptoms,
        'notes': notes,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        date: json['date'] as String,
        severity: json['severity'] as int,
        symptoms: (json['symptoms'] as List).map((e) => e as String).toList(),
        notes: json['notes'] as String? ?? '',
      );
}

String _obfuscate(String input) {
  final bytes = utf8.encode(input);
  final key = 0x5A;
  final obscured = bytes.map((b) => b ^ key).toList();
  return base64Encode(obscured);
}

String _deobfuscate(String input) {
  try {
    final obscured = base64Decode(input);
    final key = 0x5A;
    final bytes = obscured.map((b) => b ^ key).toList();
    return utf8.decode(bytes);
  } catch (_) {
    return input;
  }
}

class JournalService {
  static const _key = 'journal_entries';

  Future<List<JournalEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = _deobfuscate(raw);
      final list = jsonDecode(decoded) as List;
      return list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntry(JournalEntry entry) async {
    final entries = await loadEntries();
    final existingIndex = entries.indexWhere((e) => e.date == entry.date);
    if (existingIndex >= 0) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    await _persist(entries);
  }

  Future<void> updateEntry(String date, JournalEntry updated) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.date == date);
    if (index < 0) return;
    entries[index] = updated;
    entries.sort((a, b) => b.date.compareTo(a.date));
    await _persist(entries);
  }

  Future<void> deleteEntry(String date) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.date == date);
    await _persist(entries);
  }

  Future<void> _persist(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    final obscured = _obfuscate(raw);
    await prefs.setString(_key, obscured);
  }
}

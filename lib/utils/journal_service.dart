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
        symptoms: (json['symptoms'] as List).cast<String>(),
        notes: json['notes'] as String? ?? '',
      );
}

class JournalService {
  static const _key = 'journal_entries';

  Future<List<JournalEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
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
    await prefs.setString(_key, raw);
  }
}

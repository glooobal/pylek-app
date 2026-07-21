import 'dart:convert';
import 'package:pylek/services/preferences_service.dart';

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
      final raw = await PreferencesService.instance.getString(_key);
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
    await PreferencesService.instance.synchronized(() async {
      final entries = await _loadUnsafe();
      final existingIndex = entries.indexWhere((e) => e.date == entry.date);
      if (existingIndex >= 0) {
        entries[existingIndex] = entry;
      } else {
        entries.add(entry);
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      await _persist(entries);
    });
  }

  Future<void> updateEntry(String date, JournalEntry updated) async {
    await PreferencesService.instance.synchronized(() async {
      final entries = await _loadUnsafe();
      final index = entries.indexWhere((e) => e.date == date);
      if (index < 0) return;
      entries[index] = updated;
      entries.sort((a, b) => b.date.compareTo(a.date));
      await _persist(entries);
    });
  }

  Future<void> deleteEntry(String date) async {
    await PreferencesService.instance.synchronized(() async {
      final entries = await _loadUnsafe();
      entries.removeWhere((e) => e.date == date);
      await _persist(entries);
    });
  }

  Future<List<JournalEntry>> _loadUnsafe() async {
    try {
      final raw = await PreferencesService.instance.getString(_key);
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

  Future<void> _persist(List<JournalEntry> entries) async {
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    final obscured = _obfuscate(raw);
    await PreferencesService.instance.setString(_key, obscured);
  }
}

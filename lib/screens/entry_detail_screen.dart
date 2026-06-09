import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/journal_service.dart';
import 'package:pylek/utils/journal_constants.dart';

class EntryDetailScreen extends StatefulWidget {
  final JournalEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final _service = JournalService();
  late int _severity;
  late Set<String> _selectedSymptoms;
  late TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _severity = widget.entry.severity;
    _selectedSymptoms = widget.entry.symptoms.toSet();
    _notesController = TextEditingController(text: widget.entry.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final updated = JournalEntry(
      date: widget.entry.date,
      severity: _severity,
      symptoms: _selectedSymptoms.toList()..sort(),
      notes: _notesController.text.trim(),
    );
    await _service.updateEntry(widget.entry.date, updated);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń wpis"),
        content: const Text("Czy na pewno chcesz usunąć ten wpis?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Usuń", style: TextStyle(color: AppColors.systemRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteEntry(widget.entry.date);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<bool> _onWillPop() async {
    if (!_isEditing) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Odrzucić zmiany?"),
        content: const Text("Masz niezapisane zmiany. Czy na pewno chcesz wyjść?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Zostań"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Odrzuć", style: TextStyle(color: AppColors.systemRed)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onBackPressed() async {
    if (!_isEditing) {
      Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    final shouldPop = await _onWillPop();
    if (shouldPop && context.mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => _onBackPressed(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              AppIcons.of(context, AppIconKind.chevronLeft),
              size: 24,
              color: AppColors.systemOrange,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          formatDate(widget.entry.date),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (!_isEditing)
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  "Edytuj",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.systemOrange,
                  ),
                ),
              ),
            ),
          if (_isEditing)
            GestureDetector(
              onTap: _delete,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete_rounded,
                  size: 22,
                  color: AppColors.systemRed,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nasilenie objawów",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        severityLabel(_severity),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: severityColor(_severity),
                        ),
                      ),
                    ),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < severityLevels.length; i++) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _severity = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _severity == i
                                        ? colorScheme.surfaceContainer
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _severity == i
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    severityLevels[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _severity == i
                                          ? severityColor(i)
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    "Objawy",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing && _selectedSymptoms.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _selectedSymptoms.join(' • '),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (_isEditing)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: symptomsList.map((symptom) {
                        final selected = _selectedSymptoms.contains(symptom);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedSymptoms.remove(symptom);
                              } else {
                                _selectedSymptoms.add(symptom);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.systemOrange.withValues(alpha: 0.08)
                                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              symptom,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? AppColors.systemOrange
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    "Notatka",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing && _notesController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _notesController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (!_isEditing && _notesController.text.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Brak notatki",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  if (_isEditing)
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Dodaj krótką notatkę...",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _saveEdit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Zapisz zmiany",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),      // ListView
      ),        // SafeArea
      ),        // Scaffold
    );          // PopScope
  }
}

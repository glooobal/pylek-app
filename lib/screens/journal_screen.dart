import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/analytics_service.dart';
import 'package:pylek/utils/journal_service.dart';
import 'package:pylek/utils/journal_constants.dart';

const List<String> _monthNamesNominative = [
  'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
  'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
];

const List<String> _weekdayLabels = [
  'Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Niedz',
];

String _formatSelectedDate(DateTime date) {
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}

String _toIso(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _service = JournalService();
  final _notesController = TextEditingController();

  List<JournalEntry> _entries = [];
  bool _loaded = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  int _severity = 0;
  Set<String> _selectedSymptoms = {};
  bool _isFormExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _service.loadEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loaded = true;
    });
  }

  JournalEntry? get _selectedEntry {
    final iso = _toIso(_selectedDate);
    try {
      return _entries.firstWhere((e) => e.date == iso);
    } catch (_) {
      return null;
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      final m = _focusedMonth.month - 1;
      _focusedMonth = DateTime(
        m == 0 ? _focusedMonth.year - 1 : _focusedMonth.year,
        m == 0 ? 12 : m,
        1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      final m = _focusedMonth.month + 1;
      _focusedMonth = DateTime(
        m == 13 ? _focusedMonth.year + 1 : _focusedMonth.year,
        m == 13 ? 1 : m,
        1,
      );
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (_selectedEntry == null) {
        _severity = 0;
        _selectedSymptoms = {};
        _notesController.clear();
        _isFormExpanded = false;
      }
    });
  }

  void _openForm() {
    setState(() {
      _severity = 0;
      _selectedSymptoms = {};
      _notesController.clear();
      _isFormExpanded = true;
    });
  }

  void _openEditForm() {
    final entry = _selectedEntry;
    if (entry == null) return;
    setState(() {
      _severity = entry.severity;
      _selectedSymptoms = entry.symptoms.toSet();
      _notesController.text = entry.notes;
      _isFormExpanded = true;
    });
  }

  void _closeForm() {
    setState(() {
      _isFormExpanded = false;
    });
  }

  Future<void> _save() async {
    final entry = JournalEntry(
      date: _toIso(_selectedDate),
      severity: _severity,
      symptoms: _selectedSymptoms.toList()..sort(),
      notes: _notesController.text.trim(),
    );
    try {
      await _service.saveEntry(entry);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się zapisać wpisu.")),
      );
      return;
    }
    AnalyticsService.logJournalEntryAdded();
    if (!mounted) return;
    setState(() {
      _isFormExpanded = false;
    });
    await _load();
  }

  Future<void> _delete() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
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
    try {
      await _service.deleteEntry(_toIso(_selectedDate));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się usunąć wpisu.")),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isFormExpanded = false;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _loaded
            ? ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: 16),

                  _CalendarSection(
                    focusedMonth: _focusedMonth,
                    selectedDate: _selectedDate,
                    entries: _entries,
                    onPreviousMonth: _goToPreviousMonth,
                    onNextMonth: _goToNextMonth,
                    onSelectDate: _selectDate,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      _formatSelectedDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  _buildContent(colorScheme),

                  const SizedBox(height: 64),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final entry = _selectedEntry;

    if (entry != null && !_isFormExpanded) {
      return _EntryDetailCard(
        entry: entry,
        colorScheme: colorScheme,
        onEdit: _openEditForm,
        onDelete: _delete,
      );
    }

    if (_isFormExpanded) {
      return _EntryForm(
        severity: _severity,
        selectedSymptoms: _selectedSymptoms,
        notesController: _notesController,
        colorScheme: colorScheme,
        isEditing: entry != null,
        onSeverityChanged: (v) => setState(() => _severity = v),
        onSymptomsChanged: (v) => setState(() => _selectedSymptoms = v),
        onSave: _save,
        onCancel: _closeForm,
      );
    }

    return _EmptyDayCard(
      colorScheme: colorScheme,
      onAdd: _openForm,
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

class _CalendarSection extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<JournalEntry> entries;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;
  final ColorScheme colorScheme;

  const _CalendarSection({
    required this.focusedMonth,
    required this.selectedDate,
    required this.entries,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    required this.colorScheme,
  });

  Color? _dotColorForDate(DateTime date) {
    final iso = _toIso(date);
    try {
      final entry = entries.firstWhere((e) => e.date == iso);
      return severityColor(entry.severity);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final nextM = month == 12 ? 1 : month + 1;
    final nextY = month == 12 ? year + 1 : year;
    final totalDays = DateTime(nextY, nextM, 0).day;
    final offset = DateTime(year, month, 1).weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            children: [
              Semantics(
                button: true,
                label: "Poprzedni miesiąc",
                child: GestureDetector(
                  onTap: onPreviousMonth,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      AppIcons.of(context, AppIconKind.chevronLeft),
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_monthNamesNominative[month - 1]} $year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: "Następny miesiąc",
                child: GestureDetector(
                  onTap: onNextMonth,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      AppIcons.of(context, AppIconKind.chevronRight),
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekday labels
          Row(
            children: _weekdayLabels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Day grid
          ..._buildDayGrid(today, year, month, totalDays, offset),
        ],
      ),
    );
  }

  List<Widget> _buildDayGrid(
    DateTime today, int year, int month, int totalDays, int offset,
  ) {
    final List<Widget> rows = [];
    int day = 1;
    final int totalCells = offset + totalDays;
    final int rowCount = (totalCells / 7).ceil();

    for (int r = 0; r < rowCount; r++) {
      final List<Widget> cells = [];
      for (int c = 0; c < 7; c++) {
        final int cellIndex = r * 7 + c;
        if (cellIndex < offset || day > totalDays) {
          cells.add(Expanded(child: const SizedBox(height: 48)));
        } else {
          final int dayNum = day++;
                  final cellDate = DateTime(year, month, dayNum);
                  final isToday = _isSameDay(cellDate, today);
                  final isSelected = _isSameDay(cellDate, selectedDate);
                  final dotColor = _dotColorForDate(cellDate);

                  cells.add(Expanded(
                    child: _DayCell(
                      day: dayNum,
                      isToday: isToday,
                      isSelected: isSelected,
                      dotColor: dotColor,
                      onTap: () => onSelectDate(cellDate),
                      colorScheme: colorScheme,
                    ),
                  ));
        }
      }
      rows.add(Row(children: cells));
      rows.add(const SizedBox(height: 4));
    }

    return rows;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final Color? dotColor;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.dotColor,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasDot = dotColor != null && !isToday;

    return Semantics(
      button: true,
      label: "Dzień ${day.toString()}",
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday && isSelected
                  ? AppColors.systemOrange
                  : isToday
                      ? AppColors.systemOrange.withValues(alpha: 0.15)
                      : isSelected
                          ? colorScheme.surfaceContainerHighest
                          : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.systemOrange.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isToday && isSelected
                      ? Colors.white
                      : isToday
                          ? AppColors.systemOrange
                          : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (hasDot)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            )
          else
            const SizedBox(height: 7),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry Detail Card (read-only)
// ---------------------------------------------------------------------------

class _EntryDetailCard extends StatelessWidget {
  final JournalEntry entry;
  final ColorScheme colorScheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryDetailCard({
    required this.entry,
    required this.colorScheme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = severityColor(entry.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HomeCardBadge(
                iconKind: severityIcon(entry.severity),
                background: sevColor.withValues(alpha: 0.14),
                foreground: sevColor,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      severityLabel(entry.severity),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.1,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (entry.symptoms.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Objawy",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.symptoms.join(' • '),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Notatka",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.notes,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: "Edytuj wpis",
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Edytuj",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemGray,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: "Usuń wpis",
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Usuń",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty Day Card
// ---------------------------------------------------------------------------

class _EmptyDayCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onAdd;

  const _EmptyDayCard({
    required this.colorScheme,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          HomeCardBadge(
            iconKind: AppIconKind.pencil,
            background: AppColors.systemGray.withValues(alpha: 0.14),
            foreground: AppColors.systemGray,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(height: 16),
          Text(
            "Brak wpisu dla tego dnia",
            style: TextStyle(
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Dodaj wpis, aby śledzić swoje objawy.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: "Dodaj wpis",
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Dodaj wpis",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry Form (add / edit)
// ---------------------------------------------------------------------------

class _EntryForm extends StatelessWidget {
  final int severity;
  final Set<String> selectedSymptoms;
  final TextEditingController notesController;
  final ColorScheme colorScheme;
  final bool isEditing;
  final ValueChanged<int> onSeverityChanged;
  final ValueChanged<Set<String>> onSymptomsChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EntryForm({
    required this.severity,
    required this.selectedSymptoms,
    required this.notesController,
    required this.colorScheme,
    required this.isEditing,
    required this.onSeverityChanged,
    required this.onSymptomsChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    child: Semantics(
                      button: true,
                      label: "Poziom ${severityLevels[i]}",
                      child: GestureDetector(
                        onTap: () => onSeverityChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: severity == i
                                ? colorScheme.surfaceContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: severity == i
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
                              color: severity == i
                                  ? severityColor(i)
                                  : colorScheme.onSurfaceVariant,
                            ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptomsList.map((symptom) {
              final sel = selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () {
                  final updated = Set<String>.from(selectedSymptoms);
                  if (sel) {
                    updated.remove(symptom);
                  } else {
                    updated.add(symptom);
                  }
                  onSymptomsChanged(updated);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.systemOrange.withValues(alpha: 0.08)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: sel
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
            "Notatka (opcjonalnie)",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            maxLines: 2,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: "Anuluj",
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Anuluj",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: "Zapisz wpis",
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Zapisz wpis",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

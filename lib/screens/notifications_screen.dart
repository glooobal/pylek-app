import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/home_card_badge.dart';
import 'package:pylek/services/fcm_service.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _notifications = [];
  bool _forecastReminderEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.loadNotifications(),
        FcmService.isEnabled(),
      ]);
      if (!mounted) return;
      setState(() {
        _notifications = results[0] as List<AppNotification>;
        _forecastReminderEnabled = results[1] as bool;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleForecastReminder(bool enabled) async {
    try {
      await FcmService.setEnabled(enabled);
      if (!mounted) return;
      setState(() => _forecastReminderEnabled = enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się zmienić ustawień powiadomień.")),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się oznaczyć jako przeczytane.")),
      );
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _service.markAsRead(notification.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się zaktualizować powiadomienia.")),
      );
    }
  }

  Future<void> _delete(AppNotification notification) async {
    try {
      await _service.deleteNotification(notification.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się usunąć powiadomienia.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 92,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Powiadomienia',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.0,
            ),
          ),
        ),
        actions: [
          if (unreadCount > 0)
            GestureDetector(
              onTap: _markAllAsRead,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'Przeczytane',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.systemOrange,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildList(colorScheme),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.of(context, AppIconKind.alerts),
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Brak powiadomień',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gdy pojawią się alerty o wysokim stężeniu pyłków\nlub zanieczyszczeń, zobaczysz je tutaj.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ColorScheme colorScheme) {
    final sections = _buildSections();

    return RefreshIndicator(
      onRefresh: _load,
      displacement: 60,
      color: AppColors.systemGray,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                HomeCardBadge(
                  iconKind: AppIconKind.forecast,
                  background: AppColors.systemTeal.withValues(alpha: 0.14),
                  foreground: AppColors.systemTeal,
                  size: 36,
                  iconSize: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prognoza o 9:00',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Codzienne przypomnienie o sprawdzeniu prognozy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _forecastReminderEnabled,
                  onChanged: _toggleForecastReminder,
                  activeTrackColor: AppColors.systemGreen.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.systemGreen,
                ),
              ],
            ),
          ),

          if (sections.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _sectionLabel(sections[i].label, colorScheme),
              const SizedBox(height: 10),
              ...sections[i].notifications.map((notification) {
                return _NotificationTile(
                  notification: notification,
                  colorScheme: colorScheme,
                  onTap: () => _markAsRead(notification),
                  onDismissed: () => _delete(notification),
                );
              }),
            ],
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<_NotificationSection> _buildSections() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final sorted = List<AppNotification>.from(_notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final sections = <_NotificationSection>[];

    void addToSection(String label, List<AppNotification> items) {
      if (items.isEmpty) return;
      sections.add(_NotificationSection(label: label, notifications: items));
    }

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final thisWeekItems = <AppNotification>[];
    final thisMonthItems = <AppNotification>[];
    final olderItems = <AppNotification>[];

    for (final n in sorted) {
      final day = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (day == today) {
        todayItems.add(n);
      } else if (day == yesterday) {
        yesterdayItems.add(n);
      } else if (day.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
        thisWeekItems.add(n);
      } else if (day.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        thisMonthItems.add(n);
      } else {
        olderItems.add(n);
      }
    }

    addToSection('Dzisiaj', todayItems);
    addToSection('Wczoraj', yesterdayItems);
    addToSection('W tym tygodniu', thisWeekItems);
    addToSection('W tym miesiącu', thisMonthItems);
    addToSection('Wcześniej', olderItems);

    return sections;
  }
}

class _NotificationSection {
  final String label;
  final List<AppNotification> notifications;

  const _NotificationSection({
    required this.label,
    required this.notifications,
  });
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.colorScheme,
    required this.onTap,
    required this.onDismissed,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final day = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);

    if (day == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final notificationColor = NotificationService.colorFor(notification.type);
    final iconKind = NotificationService.iconFor(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.systemRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: AppColors.systemRed,
          size: 22,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          button: true,
          label: notification.title,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeCardBadge(
                    iconKind: iconKind,
                    background:
                        notificationColor.withValues(alpha: notification.isRead ? 0.1 : 0.16),
                    foreground:
                        notificationColor.withValues(alpha: notification.isRead ? 0.5 : 1.0),
                    size: 40,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: notificationColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

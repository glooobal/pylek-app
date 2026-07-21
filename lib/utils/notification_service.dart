import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

enum NotificationType {
  highPollen,
  airQuality,
  forecast,
  reminder,
  feature,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

class NotificationService {
  static const _key = 'notifications';

  static AppIconKind iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.highPollen:
        return AppIconKind.grass;
      case NotificationType.airQuality:
        return AppIconKind.air;
      case NotificationType.forecast:
        return AppIconKind.forecast;
      case NotificationType.reminder:
        return AppIconKind.journal;
      case NotificationType.feature:
        return AppIconKind.star;
    }
  }

  static Color colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.highPollen:
        return AppColors.systemGreen;
      case NotificationType.airQuality:
        return AppColors.systemOrange;
      case NotificationType.forecast:
        return AppColors.systemTeal;
      case NotificationType.reminder:
        return AppColors.systemYellow;
      case NotificationType.feature:
        return AppColors.systemBlue;
    }
  }

  Future<List<AppNotification>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(notifications.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> markAsRead(String id) async {
    final notifications = await loadNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    notifications[index].isRead = true;
    await _persist(notifications);
  }

  Future<void> markAllAsRead() async {
    final notifications = await loadNotifications();
    for (final n in notifications) {
      n.isRead = true;
    }
    await _persist(notifications);
  }

  Future<void> deleteNotification(String id) async {
    final notifications = await loadNotifications();
    notifications.removeWhere((n) => n.id == id);
    await _persist(notifications);
  }

  void addNotification(AppNotification notification) async {
    final notifications = await loadNotifications();
    notifications.insert(0, notification);
    await _persist(notifications);
  }
}

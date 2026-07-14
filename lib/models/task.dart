import 'package:flutter/material.dart';
import '../app_colors.dart';

class Task {
  final String id;
  final int notificationId;
  String title;
  String? time;
  String category;
  bool isFixed;
  DateTime date;
  bool hasReminder;
  int reminderOffset;
  bool isDone;
  DateTime updatedAt;
  // null = tekrarlayan bir seriye ait değil. Rule bazlı seriler ('daily' / 'weekdays' /
  // 'weekly:1,3,5' — ISO haftanın günü, 1=Pzt..7=Paz) recurrenceGroupId ile birlikte kayan
  // pencereyle otomatik ileri tarihe genişletilir (bkz. TaskStore._topUpRecurringWindow).
  // Takvimden toplu gün seçimiyle eklenen görevler recurrenceGroupId taşır ama
  // recurrenceRule null kalır (sabit gün listesi, otomatik genişletilmez).
  String? recurrenceRule;
  String? recurrenceGroupId;

  Task({
    required this.id, required this.notificationId, required this.title, this.time,
    required this.category, required this.isFixed, required this.date,
    this.hasReminder = false, this.reminderOffset = 0, this.isDone = false,
    DateTime? updatedAt, this.recurrenceRule, this.recurrenceGroupId,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color get categoryColor {
    switch (category) { case 'Academic': return AppColors.academic; case 'Work': return AppColors.work; case 'Community': return AppColors.community; case 'Personal': return AppColors.personal; default: return AppColors.xp; }
  }

  Map<String, dynamic> toJson() => {'id': id, 'notificationId': notificationId, 'title': title, 'time': time, 'category': category, 'isFixed': isFixed, 'date': date.toIso8601String(), 'hasReminder': hasReminder, 'reminderOffset': reminderOffset, 'isDone': isDone, 'updatedAt': updatedAt.toIso8601String(), 'recurrenceRule': recurrenceRule, 'recurrenceGroupId': recurrenceGroupId};
  factory Task.fromJson(Map<String, dynamic> json) => Task(id: json['id'], notificationId: json['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000), title: json['title'], time: json['time'], category: json['category'], isFixed: json['isFixed'], date: DateTime.parse(json['date']), hasReminder: json['hasReminder'] ?? false, reminderOffset: json['reminderOffset'] ?? 0, isDone: json['isDone'], updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(), recurrenceRule: json['recurrenceRule'], recurrenceGroupId: json['recurrenceGroupId']);
}

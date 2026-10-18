class FocusSession {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final String? taskId;
  final String? taskTitle;
  final DateTime updatedAt;

  FocusSession({
    required this.id,
    required this.date,
    required this.durationMinutes,
    this.taskId,
    this.taskTitle,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'],
        date: DateTime.parse(json['date']),
        durationMinutes: json['durationMinutes'],
        taskId: json['taskId'],
        taskTitle: json['taskTitle'],
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
}
class MoodEntry {
  final DateTime date;
  final int score; // 1-5 (😞😕😐🙂😄)
  final String? note;
  final DateTime updatedAt;

  MoodEntry({required this.date, required this.score, this.note, DateTime? updatedAt}) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'score': score, 'note': note, 'updatedAt': updatedAt.toIso8601String()};
  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(date: DateTime.parse(json['date']), score: json['score'], note: json['note'], updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now());
}

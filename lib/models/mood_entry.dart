class MoodEntry {
  final DateTime date;
  final int score; // 1-5 (😞😕😐🙂😄)
  final String? note;

  MoodEntry({required this.date, required this.score, this.note});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'score': score, 'note': note};
  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(date: DateTime.parse(json['date']), score: json['score'], note: json['note']);
}

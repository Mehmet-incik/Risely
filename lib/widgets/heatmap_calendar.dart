import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/services.dart';

class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({super.key});

  static const int _totalWeeks = 17; // ~120 gün
  static const List<String> _weekdayShortTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const List<String> _monthsTr = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  Color _colorForLevel(int level) {
    switch (level) {
      case 1: return AppColors.xp.withOpacity(0.3);
      case 2: return AppColors.xp.withOpacity(0.5);
      case 3: return AppColors.xp.withOpacity(0.7);
      case 4: return AppColors.xp;
      default: return AppColors.surfaceAlt;
    }
  }

  void _showDayDetail(BuildContext context, DateTime day) {
    final tasks = TaskStore.getTasksForDate(day);
    final done = tasks.where((t) => t.isDone).length;
    final score = TaskStore.getScoreForDate(day);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${day.day} ${_monthsTr[day.month - 1]} ${day.year}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Text('Bu gün için görev yok.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic))
            else ...[
              Text('$done / ${tasks.length} görev tamamlandı', style: TextStyle(fontSize: 15, color: AppColors.text)),
              const SizedBox(height: 6),
              Text('Başarı: %$score', style: TextStyle(fontSize: 15, color: AppColors.xp, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final currentWeekStart = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    final firstWeekStart = currentWeekStart.subtract(const Duration(days: 7 * (_totalWeeks - 1)));
    final intensity = TaskStore.getIntensityMapForLastDays(_totalWeeks * 7);

    final weeks = List.generate(_totalWeeks, (w) {
      final weekStart = firstWeekStart.add(Duration(days: w * 7));
      return List.generate(7, (d) => weekStart.add(Duration(days: d)));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BAŞARI YOĞUNLUĞU · SON 17 HAFTA', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          SizedBox(
            height: 14 + 7 * 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayLabels(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: weeks.map((week) => _buildWeekColumn(context, week, todayOnly, intensity)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Az', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              ...List.generate(5, (level) => Container(
                width: 12, height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: _colorForLevel(level), borderRadius: BorderRadius.circular(3)),
              )),
              const SizedBox(width: 6),
              Text('Çok', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels() {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          for (int i = 0; i < 7; i++)
            Container(
              height: 14,
              margin: const EdgeInsets.only(bottom: 4),
              alignment: Alignment.centerLeft,
              child: (i == 0 || i == 2 || i == 4) ? Text(_weekdayShortTr[i], style: TextStyle(fontSize: 9, color: AppColors.textMuted)) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildWeekColumn(BuildContext context, List<DateTime> week, DateTime todayOnly, Map<DateTime, int> intensity) {
    final monthStartsThisWeek = week.where((d) => d.day == 1);
    final showMonthLabel = monthStartsThisWeek.isNotEmpty;
    final monthLabel = showMonthLabel ? _monthsTr[monthStartsThisWeek.first.month - 1] : '';

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14, child: showMonthLabel ? Text(monthLabel, style: TextStyle(fontSize: 9, color: AppColors.textMuted)) : null),
          ...week.map((day) => _buildCell(context, day, todayOnly, intensity)),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, DateTime day, DateTime todayOnly, Map<DateTime, int> intensity) {
    final isFuture = day.isAfter(todayOnly);
    final level = isFuture ? -1 : (intensity[day] ?? 0);
    final isToday = day.year == todayOnly.year && day.month == todayOnly.month && day.day == todayOnly.day;

    return GestureDetector(
      onTap: isFuture ? null : () => _showDayDetail(context, day),
      child: Container(
        width: 14, height: 14,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isFuture ? Colors.transparent : _colorForLevel(level),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: isToday ? AppColors.xp : AppColors.border, width: isToday ? 1.5 : 0.5),
        ),
      ),
    );
  }
}

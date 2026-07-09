import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../services/services.dart';
import '../widgets/heatmap_calendar.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Color _getCatColor(String cat) {
    switch (cat) {
      case 'Academic': return AppColors.academic;
      case 'Work': return AppColors.work;
      case 'Community': return AppColors.community;
      case 'Personal': return AppColors.personal;
      default: return AppColors.xp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final tasks = taskStore.allTasks;
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final pct = total == 0 ? 0 : ((done / total) * 100).round();

    final Map<String, Map<String, int>> catStats = {
      'Academic': {'total': 0, 'done': 0},
      'Work': {'total': 0, 'done': 0},
      'Community': {'total': 0, 'done': 0},
      'Personal': {'total': 0, 'done': 0}
    };

    for (var t in tasks) {
      if (catStats.containsKey(t.category)) {
        catStats[t.category]!['total'] = catStats[t.category]!['total']! + 1;
        if (t.isDone) catStats[t.category]!['done'] = catStats[t.category]!['done']! + 1;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GENEL BAKIŞ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('İstatistikler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: const HeatmapCalendar(),
            ),
            if (taskStore.getProductiveMoodEmoji() != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Text(taskStore.getProductiveMoodEmoji()!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('En üretken olduğun günlerdeki ortalama ruh halin bu', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.done_all_rounded, color: AppColors.xp, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('$done', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('Tamamlanan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.format_list_bulleted_rounded, color: Colors.blueAccent, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('$total', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('Toplam Görev', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.work.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.work, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('${taskStore.currentStreak}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('Güncel Seri', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('${taskStore.longestStreak}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('En Uzun Seri', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  SizedBox(
                    width: 90, height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(value: pct / 100, backgroundColor: AppColors.bg, valueColor: const AlwaysStoppedAnimation(AppColors.xp), strokeWidth: 6, strokeCap: StrokeCap.round),
                        Text('%$pct', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.xp)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Genel Başarı Oranı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                        const SizedBox(height: 4),
                        Text('Harika gidiyorsun! Devam et.', style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('KATEGORİ DETAYLARI', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            ...catStats.entries.map((e) {
              final color = _getCatColor(e.key);
              final t = e.value['total']!;
              final d = e.value['done']!;
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                          ],
                        ),
                        Text('$d/$t', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: t == 0 ? 0 : d / t, backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

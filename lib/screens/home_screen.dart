import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/task.dart';
import '../services/services.dart';
import 'task_form.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onHelpTapped;
  const HomeScreen({super.key, required this.onHelpTapped});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _moodEditing = false;

  TaskStore get taskStore => context.read<TaskStore>();

  List<Task> get tasks => taskStore.getTasksForDate(DateTime.now());
  List<Task> get fixedTasks => tasks.where((t) => t.isFixed).toList()..sort((a,b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
  List<Task> get flexTasks => tasks.where((t) => !t.isFixed).toList();
  int get doneTasks => tasks.where((t) => t.isDone).length;
  int get percentage => tasks.isEmpty ? 0 : ((doneTasks / tasks.length) * 100).round();

  void toggleTask(String id) => taskStore.toggleTask(id);

  void deleteTask(Task task) => taskStore.deleteTask(task);

  @override
  Widget build(BuildContext context) {
    context.watch<TaskStore>();
    final levelInfo = taskStore.getUserLevelInfo();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMotivationCard(),
            _buildScoreCard(levelInfo),
            _buildMoodCard(),
            if (fixedTasks.isNotEmpty) ...[
              _buildSectionLabel('SABİT ETKİNLİKLER'),
              ...fixedTasks.map((t) => _buildTaskCard(t)),
            ],
            if (flexTasks.isNotEmpty) ...[
              _buildSectionLabel('ESNEK GÖREVLER'),
              ...flexTasks.map((t) => _buildTaskCard(t)),
            ],
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Bugün için görev yok', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('+ ile ekleyebilirsin', style: TextStyle(color: AppColors.border, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TaskStore.getTodayLabel(), style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('Günaydın, ${taskStore.userName} 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onHelpTapped,
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                  child: Icon(Icons.help_outline_rounded, color: AppColors.textMuted, size: 20),
                ),
              ),
              Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.xp, AppColors.academic])),
                child: Center(child: Text(taskStore.userAvatar, style: const TextStyle(fontSize: 20))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    final msg = taskStore.getDailyMotivation();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.xp, size: 16),
              ),
              const SizedBox(width: 10),
              Text('GÜNÜN MOTİVASYONU', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(msg['body']!, style: TextStyle(fontSize: 14, color: AppColors.text, height: 1.5, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> levelInfo) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GÜNLÜK BAŞARI', style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 65, height: 65,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: percentage / 100, backgroundColor: AppColors.surfaceAlt, valueColor: const AlwaysStoppedAnimation(AppColors.xp), strokeWidth: 8, strokeCap: StrokeCap.round),
                    ),
                    Text('%$percentage', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.xp)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$doneTasks/${tasks.length} görev', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Text('+${doneTasks * 15} XP', style: const TextStyle(fontSize: 12, color: AppColors.xp, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: percentage / 100, backgroundColor: AppColors.surfaceAlt, valueColor: const AlwaysStoppedAnimation(AppColors.xp), minHeight: 8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStreakBadge(),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                          child: Text('Seviye ${levelInfo['level']}', style: const TextStyle(fontSize: 11, color: AppColors.xp, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    final streak = taskStore.currentStreak;
    final atRisk = taskStore.isStreakAtRisk;

    String label;
    Color color;
    if (streak == 0) {
      label = '🔥 Seriye Başla!';
      color = AppColors.work;
    } else if (atRisk) {
      label = '⚠️ $streak Günlük Seri - Riskte!';
      color = Colors.redAccent;
    } else {
      label = '🔥 $streak Günlük Seri!';
      color = AppColors.work;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMoodCard() {
    final today = DateTime.now();
    final todayMood = taskStore.getMoodForDate(today);
    final showPicker = todayMood == null || _moodEditing;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: showPicker
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugün nasılsın?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () async {
                      await taskStore.saveMood(today, i + 1);
                      if (mounted) setState(() => _moodEditing = false);
                    },
                    child: Text(TaskStore.moodEmojis[i], style: const TextStyle(fontSize: 30)),
                  )),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => setState(() => _moodEditing = true),
              child: Row(
                children: [
                  Text(TaskStore.moodEmojis[todayMood.score - 1], style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Bugün kendini ${TaskStore.moodLabels[todayMood.score - 1]} hissediyorsun', style: TextStyle(fontSize: 13, color: AppColors.text)),
                  ),
                  Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          showTaskForm(context, task: task);
          return false;
        }
        return true;
      },
      onDismissed: (_) => deleteTask(task),
      child: GestureDetector(
        onTap: () => toggleTask(task.id),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: task.isDone ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: task.isDone ? task.categoryColor.withOpacity(0.4) : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 4, height: 38,
                  decoration: BoxDecoration(color: task.categoryColor.withOpacity(task.isFixed ? 1.0 : 0.6), borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: task.isDone ? AppColors.textMuted : AppColors.text, decoration: task.isDone ? TextDecoration.lineThrough : null),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(task.time != null ? '${task.time} · ${task.category}' : 'Esnek · ${task.category}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          if (task.hasReminder) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.notifications_active_rounded, size: 12, color: AppColors.xp)
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: task.isDone ? task.categoryColor : Colors.transparent,
                    borderRadius: task.isFixed ? BorderRadius.circular(6) : BorderRadius.circular(11),
                    border: Border.all(color: task.isDone ? task.categoryColor : AppColors.border, width: 2),
                  ),
                  child: task.isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

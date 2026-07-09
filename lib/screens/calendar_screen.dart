import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/task.dart';
import '../services/services.dart';
import 'task_form.dart';

enum CalendarViewMode { weekly, monthly, yearly }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  DateTime getSelectedDate() => _CalendarScreenState.currentSelectedDate;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static DateTime currentSelectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.monthly;
  DateTime _displayedYearDate = DateTime.now();

  final List<String> daysTr = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  final List<String> monthsTr = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  TaskStore get taskStore => context.read<TaskStore>();

  void toggleTask(String id) => taskStore.toggleTask(id);

  void deleteTask(Task task) => taskStore.deleteTask(task);

  @override
  Widget build(BuildContext context) {
    context.watch<TaskStore>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: CupertinoSlidingSegmentedControl<CalendarViewMode>(
              backgroundColor: AppColors.surfaceAlt.withOpacity(0.5),
              thumbColor: AppColors.surface,
              groupValue: _viewMode,
              padding: const EdgeInsets.all(4),
              children: {
                CalendarViewMode.weekly: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Haftalık', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _viewMode == CalendarViewMode.weekly ? AppColors.xp : AppColors.textMuted))),
                CalendarViewMode.monthly: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Aylık', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _viewMode == CalendarViewMode.monthly ? AppColors.xp : AppColors.textMuted))),
                CalendarViewMode.yearly: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Yıllık', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _viewMode == CalendarViewMode.yearly ? AppColors.xp : AppColors.textMuted))),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _viewMode = val);
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case CalendarViewMode.weekly: return _buildWeeklyView();
      case CalendarViewMode.monthly: return _buildMonthlyView();
      case CalendarViewMode.yearly: return _buildYearlyView();
    }
  }

  Widget _buildWeeklyView() {
    DateTime startOfWeek = currentSelectedDate.subtract(Duration(days: currentSelectedDate.weekday - 1));
    return Column(
      key: const ValueKey('weekly'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.chevron_left_rounded, color: AppColors.text), onPressed: () => setState(() => currentSelectedDate = currentSelectedDate.subtract(const Duration(days: 7)))),
              Text('${startOfWeek.day} ${monthsTr[startOfWeek.month-1]} - ${startOfWeek.add(const Duration(days: 6)).day} ${monthsTr[startOfWeek.add(const Duration(days: 6)).month-1]}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              IconButton(icon: Icon(Icons.chevron_right_rounded, color: AppColors.text), onPressed: () => setState(() => currentSelectedDate = currentSelectedDate.add(const Duration(days: 7)))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 7,
            itemBuilder: (context, i) {
              DateTime day = startOfWeek.add(Duration(days: i));
              List<Task> dayTasks = taskStore.getTasksForDate(day)..sort((a,b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
              bool isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
              bool isSelected = day.year == currentSelectedDate.year && day.month == currentSelectedDate.month && day.day == currentSelectedDate.day;

              return GestureDetector(
                onTap: () => setState(() => currentSelectedDate = day),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.xp : (isToday ? AppColors.border : Colors.transparent), width: isSelected ? 2 : 1),
                      boxShadow: [if(isSelected) BoxShadow(color: AppColors.xp.withOpacity(0.2), blurRadius: 10, spreadRadius: -2)]
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: isSelected ? AppColors.xp.withOpacity(0.1) : Colors.transparent, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                        child: Column(
                          children: [
                            Text(daysTr[i].toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday || isSelected ? AppColors.xp : AppColors.textMuted, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('${day.day}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text)),
                          ],
                        ),
                      ),
                      Divider(color: AppColors.border, height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            ...dayTasks.map((t) => _buildMiniTaskCard(t)),
                            GestureDetector(
                              onTap: () => showTaskForm(context, selectedDate: day),
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, style: BorderStyle.none)),
                                child: const Center(child: Icon(Icons.add_rounded, color: AppColors.xp, size: 20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: task.isDone ? AppColors.bg : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: task.isDone ? AppColors.border : task.categoryColor.withOpacity(0.3))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  task.title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: task.isDone ? AppColors.textMuted : AppColors.text, decoration: task.isDone ? TextDecoration.lineThrough : null),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis
              ),
              if (task.time != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 10, color: task.categoryColor),
                    const SizedBox(width: 4),
                    Text(task.time!, style: TextStyle(fontSize: 10, color: task.categoryColor, fontWeight: FontWeight.bold)),
                    if (task.hasReminder) ...[const Spacer(), const Icon(Icons.notifications_active_rounded, size: 10, color: AppColors.xp)]
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final todayTasks = taskStore.getTasksForDate(currentSelectedDate)..sort((a, b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
    return Column(
      key: const ValueKey('monthly'),
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? const ColorScheme.dark(primary: AppColors.xp, onPrimary: Colors.white, surface: Color(0xFF12121A), onSurface: Colors.white)
                : const ColorScheme.light(primary: AppColors.xp, onPrimary: Colors.white, surface: Color(0xFFFFFFFF), onSurface: Colors.black),
          ),
          child: CalendarDatePicker(
            initialDate: currentSelectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) => setState(() => currentSelectedDate = date),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              Text('${currentSelectedDate.day} ${monthsTr[currentSelectedDate.month-1]} Görevleri', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Bugün planlanmış görev yok.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic))))
              else
                ...todayTasks.map((task) => _buildStandardTaskCard(task)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyView() {
    return Column(
      key: const ValueKey('yearly'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.text), onPressed: () => setState(() => _displayedYearDate = DateTime(_displayedYearDate.year - 1, 1, 1))),
              Text('${_displayedYearDate.year}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: 2)),
              IconButton(icon: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.text), onPressed: () => setState(() => _displayedYearDate = DateTime(_displayedYearDate.year + 1, 1, 1))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 1.0),
            itemCount: 12,
            itemBuilder: (context, i) {
              bool isSelectedMonth = currentSelectedDate.year == _displayedYearDate.year && currentSelectedDate.month == i + 1;
              bool isCurrentMonth = DateTime.now().year == _displayedYearDate.year && DateTime.now().month == i + 1;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentSelectedDate = DateTime(_displayedYearDate.year, i + 1, 1);
                    _viewMode = CalendarViewMode.monthly;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                      color: isSelectedMonth ? AppColors.xp : (isCurrentMonth ? AppColors.xp.withOpacity(0.15) : AppColors.surface),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelectedMonth ? AppColors.xp : AppColors.border, width: isCurrentMonth && !isSelectedMonth ? 2 : 1),
                      boxShadow: [if (isSelectedMonth) BoxShadow(color: AppColors.xp.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                  ),
                  alignment: Alignment.center,
                  child: Text(monthsTr[i], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelectedMonth ? Colors.white : (isCurrentMonth ? AppColors.xp : AppColors.text))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStandardTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id), direction: DismissDirection.horizontal,
      background: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.only(left: 20), decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerLeft, child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28)),
      secondaryBackground: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerRight, child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28)),
      confirmDismiss: (direction) async { if (direction == DismissDirection.startToEnd) { showTaskForm(context, task: task); return false; } return true; },
      onDismissed: (_) => deleteTask(task),
      child: GestureDetector(
        onTap: () => toggleTask(task.id),
        child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Row(children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: task.isDone ? task.categoryColor.withOpacity(0.4) : task.categoryColor, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: task.isDone ? AppColors.textMuted : AppColors.text, decoration: task.isDone ? TextDecoration.lineThrough : null)),
            Row(children: [Text(task.time != null ? '${task.time} · ${task.category}' : 'Esnek · ${task.category}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)), if (task.hasReminder) ...[const SizedBox(width: 6), const Icon(Icons.notifications_active_rounded, size: 12, color: AppColors.xp)]])
          ])),
          Icon(task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: task.isDone ? task.categoryColor : AppColors.border, size: 22)
        ])),
      ),
    );
  }
}

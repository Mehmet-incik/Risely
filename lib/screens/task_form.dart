import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../app_colors.dart';
import '../models/task.dart';
import '../services/services.dart';
import '../widgets/samsung_time_picker.dart';

void showTaskForm(BuildContext context, {Task? task, DateTime? selectedDate, required VoidCallback onSaved}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => TaskFormSheet(task: task, preSelectedDate: selectedDate, onSaved: onSaved),
  );
}

class TaskFormSheet extends StatefulWidget {
  final Task? task;
  final DateTime? preSelectedDate;
  final VoidCallback onSaved;

  const TaskFormSheet({super.key, this.task, this.preSelectedDate, required this.onSaved});

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late TextEditingController controller;
  late String selectedCategory;
  String? selectedTime;
  late DateTime selectedDate;
  bool hasReminder = false;
  int selectedReminderOffset = 0;

  final List<String> categories = ['Academic', 'Work', 'Community', 'Personal'];

  Color getCategoryColor(String cat) {
    switch (cat) {
      case 'Academic': return AppColors.academic;
      case 'Work': return AppColors.work;
      case 'Community': return AppColors.community;
      case 'Personal': return AppColors.personal;
      default: return AppColors.xp;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.task?.title ?? '');
    selectedCategory = widget.task?.category ?? 'Personal';
    selectedTime = widget.task?.time;
    selectedDate = widget.task?.date ?? widget.preSelectedDate ?? DateTime.now();
    hasReminder = widget.task?.hasReminder ?? false;
    selectedReminderOffset = widget.task?.reminderOffset ?? 0;
  }

  Future<void> _pickTime() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SamsungStyleTimePicker(initialTime: selectedTime),
      ),
    );
    if (result != null) setState(() => selectedTime = result);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: AppColors.isDark
              ? const ColorScheme.dark(primary: AppColors.xp, onPrimary: Colors.white, surface: Color(0xFF1A1A26), onSurface: Colors.white)
              : const ColorScheme.light(primary: AppColors.xp, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.task == null ? 'Yeni Görev Ekle' : 'Görevi Düzenle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Görev adı...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarih Seç', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedTime != null ? AppColors.xp : AppColors.border)),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: selectedTime != null ? AppColors.xp : AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Text(selectedTime ?? 'Seçilmedi', style: TextStyle(color: selectedTime != null ? AppColors.text : AppColors.textMuted, fontSize: 14, fontWeight: selectedTime != null ? FontWeight.w600 : FontWeight.normal)),
                            const Spacer(),
                            if (selectedTime != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  selectedTime = null;
                                  hasReminder = false;
                                }),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: AppColors.text, size: 16)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surfaceAlt.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.xp, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Görev Bildirimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                          Text(selectedTime == null ? 'Önce saat seçmelisin' : 'Özel hatırlatıcı ekle', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: hasReminder,
                      activeColor: AppColors.xp,
                      onChanged: selectedTime == null ? null : (val) => setState(() => hasReminder = val),
                    ),
                  ],
                ),
                if (hasReminder && selectedTime != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ne zaman hatırlatılsın?', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                          child: DropdownButton<int>(
                            value: selectedReminderOffset,
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox(),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
                            style: const TextStyle(fontSize: 12, color: AppColors.xp, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Tam saatinde')),
                              DropdownMenuItem(value: 5, child: Text('5 dk önce')),
                              DropdownMenuItem(value: 15, child: Text('15 dk önce')),
                              DropdownMenuItem(value: 30, child: Text('30 dk önce')),
                              DropdownMenuItem(value: 60, child: Text('1 saat önce')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => selectedReminderOffset = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Kategori', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat;
              final catColor = getCategoryColor(cat);
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? catColor.withOpacity(0.15) : AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? catColor : AppColors.border)),
                  child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? catColor : AppColors.textMuted)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.xp,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  Task finalTask;
                  if (widget.task == null) {
                    finalTask = Task(
                      id: DateTime.now().toString(),
                      notificationId: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                      title: controller.text,
                      time: selectedTime,
                      category: selectedCategory,
                      isFixed: selectedTime != null,
                      date: selectedDate,
                      hasReminder: hasReminder,
                      reminderOffset: selectedReminderOffset,
                    );
                    TaskStore.allTasks.add(finalTask);
                  } else {
                    finalTask = widget.task!;
                    finalTask.title = controller.text;
                    finalTask.time = selectedTime;
                    finalTask.category = selectedCategory;
                    finalTask.isFixed = selectedTime != null;
                    finalTask.date = selectedDate;
                    finalTask.hasReminder = hasReminder;
                    finalTask.reminderOffset = selectedReminderOffset;
                  }

                  if (hasReminder && selectedTime != null) {
                    final parts = selectedTime!.split(':');
                    final scheduleDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(parts[0]), int.parse(parts[1]));
                    await NotificationService.scheduleTaskReminder(finalTask.notificationId, finalTask.title, scheduleDateTime, finalTask.reminderOffset);
                  } else {
                    await NotificationService.cancelTaskReminder(finalTask.notificationId);
                  }

                  TaskStore.saveTasks();
                  widget.onSaved();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(widget.task == null ? 'Ekle' : 'Kaydet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

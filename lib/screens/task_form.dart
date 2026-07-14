import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/task.dart';
import '../services/services.dart';
import '../services/notification_service.dart';
import '../widgets/recurrence_scope_dialog.dart';
import '../widgets/samsung_time_picker.dart';

// bulkDates verilirse form "toplu ekleme" moduna geçer: tarih seçici gizlenir, tekrar kuralı
// seçici gösterilmez, kaydetme tek bir görev tanımını bulkDates'teki her güne kopyalar
// (bkz. TaskStore.addBulkTaskSeries).
void showTaskForm(BuildContext context, {Task? task, DateTime? selectedDate, List<DateTime>? bulkDates}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => TaskFormSheet(task: task, preSelectedDate: selectedDate, bulkDates: bulkDates),
  );
}

class TaskFormSheet extends StatefulWidget {
  final Task? task;
  final DateTime? preSelectedDate;
  final List<DateTime>? bulkDates;

  const TaskFormSheet({super.key, this.task, this.preSelectedDate, this.bulkDates});

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  TaskStore get taskStore => context.read<TaskStore>();

  late TextEditingController controller;
  late String selectedCategory;
  String? selectedTime;
  late DateTime selectedDate;
  bool hasReminder = false;
  int selectedReminderOffset = 0;

  // Yeni görev oluştururken tekrar kuralı seçimi. null = tekrarlanmasın, 'daily'/'weekdays' = hazır
  // kalıp, useCustomWeekdays = true ise selectedWeekdays'ten 'weekly:1,3,5' türetilir.
  String? recurrenceRule;
  bool useCustomWeekdays = false;
  Set<int> selectedWeekdays = {};

  // Mevcut bir seri görevini düzenlerken hangi occurrence'ların etkileneceği.
  RecurrenceScope editScope = RecurrenceScope.occurrence;

  bool get isBulkMode => widget.bulkDates != null && widget.bulkDates!.isNotEmpty;
  bool get isEditingSeriesTask => widget.task != null && widget.task!.recurrenceGroupId != null;

  String? get finalRecurrenceRule {
    if (useCustomWeekdays) {
      if (selectedWeekdays.isEmpty) return null;
      final sorted = selectedWeekdays.toList()..sort();
      return 'weekly:${sorted.join(',')}';
    }
    return recurrenceRule;
  }

  final List<String> categories = ['Academic', 'Work', 'Community', 'Personal'];
  final List<String> weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

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
          Text(
            widget.task != null ? 'Görevi Düzenle' : (isBulkMode ? '${widget.bulkDates!.length} Gün İçin Görev Ekle' : 'Yeni Görev Ekle'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          if (isEditingSeriesTask) ...[
            _buildEditScopeToggle(),
            const SizedBox(height: 16),
          ],
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
                    Text(isBulkMode ? 'Seçilen Günler' : 'Tarih Seç', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    if (isBulkMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.xp)),
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat_rounded, color: AppColors.xp, size: 20),
                            const SizedBox(width: 8),
                            Text('${widget.bulkDates!.length} gün seçildi', style: const TextStyle(color: AppColors.xp, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
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
          if (widget.task == null && !isBulkMode) ...[
            const SizedBox(height: 20),
            _buildRecurrencePicker(),
          ],
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
                if (controller.text.isEmpty) return;

                if (widget.task == null && isBulkMode) {
                  final created = taskStore.addBulkTaskSeries(
                    title: controller.text, time: selectedTime, category: selectedCategory,
                    isFixed: selectedTime != null, dates: widget.bulkDates!,
                    hasReminder: hasReminder, reminderOffset: selectedReminderOffset,
                  );
                  if (hasReminder && selectedTime != null) {
                    final parts = selectedTime!.split(':');
                    for (final t in created) {
                      final scheduleDateTime = DateTime(t.date.year, t.date.month, t.date.day, int.parse(parts[0]), int.parse(parts[1]));
                      await NotificationService.scheduleTaskReminder(t.notificationId, t.title, scheduleDateTime, t.reminderOffset);
                    }
                  }
                  taskStore.saveTasks();
                  if (context.mounted) Navigator.pop(context);
                  return;
                }

                if (widget.task == null && finalRecurrenceRule != null) {
                  final created = taskStore.addRecurringTaskSeries(
                    title: controller.text, time: selectedTime, category: selectedCategory,
                    isFixed: selectedTime != null, startDate: selectedDate, recurrenceRule: finalRecurrenceRule!,
                    hasReminder: hasReminder, reminderOffset: selectedReminderOffset,
                  );
                  if (hasReminder && selectedTime != null) {
                    final parts = selectedTime!.split(':');
                    for (final t in created) {
                      final scheduleDateTime = DateTime(t.date.year, t.date.month, t.date.day, int.parse(parts[0]), int.parse(parts[1]));
                      await NotificationService.scheduleTaskReminder(t.notificationId, t.title, scheduleDateTime, t.reminderOffset);
                    }
                  }
                  taskStore.saveTasks();
                  if (context.mounted) Navigator.pop(context);
                  return;
                }

                if (widget.task != null && isEditingSeriesTask && editScope != RecurrenceScope.occurrence) {
                  if (editScope == RecurrenceScope.series) {
                    await taskStore.editTaskSeries(
                      widget.task!.recurrenceGroupId!,
                      title: controller.text, time: selectedTime, category: selectedCategory,
                      isFixed: selectedTime != null, hasReminder: hasReminder, reminderOffset: selectedReminderOffset,
                    );
                  } else {
                    await taskStore.editTaskSeriesFrom(
                      widget.task!.recurrenceGroupId!, widget.task!.date,
                      title: controller.text, time: selectedTime, category: selectedCategory,
                      isFixed: selectedTime != null, hasReminder: hasReminder, reminderOffset: selectedReminderOffset,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  return;
                }

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
                  taskStore.addTask(finalTask);
                } else {
                  finalTask = widget.task!;
                  finalTask.title = controller.text;
                  finalTask.time = selectedTime;
                  finalTask.category = selectedCategory;
                  finalTask.isFixed = selectedTime != null;
                  finalTask.date = selectedDate;
                  finalTask.hasReminder = hasReminder;
                  finalTask.reminderOffset = selectedReminderOffset;
                  finalTask.updatedAt = DateTime.now();
                }

                if (hasReminder && selectedTime != null) {
                  final parts = selectedTime!.split(':');
                  final scheduleDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(parts[0]), int.parse(parts[1]));
                  await NotificationService.scheduleTaskReminder(finalTask.notificationId, finalTask.title, scheduleDateTime, finalTask.reminderOffset);
                } else {
                  await NotificationService.cancelTaskReminder(finalTask.notificationId);
                }

                taskStore.saveTasks();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                widget.task != null ? 'Kaydet' : (isBulkMode ? '${widget.bulkDates!.length} Gün İçin Ekle' : 'Ekle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditScopeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 16, color: AppColors.xp),
              const SizedBox(width: 8),
              Expanded(child: Text('Bu görev tekrarlayan bir serinin parçası', style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          _buildScopeOption('Sadece Bu Gün', RecurrenceScope.occurrence),
          const SizedBox(height: 6),
          _buildScopeOption('Bu Gün ve Sonrası', RecurrenceScope.remaining),
          const SizedBox(height: 6),
          _buildScopeOption('Tüm Seri', RecurrenceScope.series),
        ],
      ),
    );
  }

  Widget _buildScopeOption(String label, RecurrenceScope scope) {
    final selected = editScope == scope;
    return GestureDetector(
      onTap: () => setState(() => editScope = scope),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: selected ? AppColors.xp : AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? AppColors.xp : AppColors.border)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.textMuted)),
      ),
    );
  }

  Widget _buildRecurrencePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tekrar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _buildRecurrenceChip('Tekrarlanmasın', recurrenceRule == null && !useCustomWeekdays, () => setState(() { recurrenceRule = null; useCustomWeekdays = false; })),
            _buildRecurrenceChip('Her Gün', recurrenceRule == 'daily', () => setState(() { recurrenceRule = 'daily'; useCustomWeekdays = false; })),
            _buildRecurrenceChip('Hafta İçi', recurrenceRule == 'weekdays', () => setState(() { recurrenceRule = 'weekdays'; useCustomWeekdays = false; })),
            _buildRecurrenceChip('Seçili Günler', useCustomWeekdays, () => setState(() { useCustomWeekdays = true; recurrenceRule = null; })),
          ],
        ),
        if (useCustomWeekdays) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = selectedWeekdays.contains(day);
              return GestureDetector(
                onTap: () => setState(() => isSelected ? selectedWeekdays.remove(day) : selectedWeekdays.add(day)),
                child: Container(
                  width: 40, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: isSelected ? AppColors.xp.withOpacity(0.15) : AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? AppColors.xp : AppColors.border)),
                  child: Text(weekdayLabels[i], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.xp : AppColors.textMuted)),
                ),
              );
            }),
          ),
        ],
        if (finalRecurrenceRule != null) ...[
          const SizedBox(height: 8),
          Text(
            'Görev, seçilen tarihten itibaren ${TaskStore.recurrenceWindowDays} gün ileriye kadar otomatik oluşturulur.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrenceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? AppColors.xp.withOpacity(0.15) : AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.xp : AppColors.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? AppColors.xp : AppColors.textMuted)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../app_colors.dart';

// Takvimden "toplu görev ekleme" girişi: kullanıcı bir ay grid'inde istediği kadar günü
// dokunarak seçer, "Devam Et" ile seçilen tarih listesini (List<DateTime>) döner —
// null/boş dönerse vazgeçilmiş demektir. Sonraki adım: showTaskForm(bulkDates: ...).
Future<List<DateTime>?> showMultiDaySelectSheet(BuildContext context, {required DateTime initialMonth}) {
  return showModalBottomSheet<List<DateTime>>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => MultiDaySelectSheet(initialMonth: initialMonth),
  );
}

class MultiDaySelectSheet extends StatefulWidget {
  final DateTime initialMonth;
  const MultiDaySelectSheet({super.key, required this.initialMonth});

  @override
  State<MultiDaySelectSheet> createState() => _MultiDaySelectSheetState();
}

class _MultiDaySelectSheetState extends State<MultiDaySelectSheet> {
  late DateTime _displayedMonth;
  final Set<DateTime> _selected = {};

  final List<String> _monthsTr = const ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  final List<String> _dayHeadersTr = const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month, 1);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _toggleDay(DateTime day) {
    setState(() {
      if (_selected.contains(day)) {
        _selected.remove(day);
      } else {
        _selected.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Günleri Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, color: AppColors.text, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tek bir görev tanımını seçtiğin tüm günlere ekler.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: AppColors.text),
                onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1)),
              ),
              Text('${_monthsTr[_displayedMonth.month - 1]} ${_displayedMonth.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text)),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: AppColors.text),
                onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1)),
              ),
            ],
          ),
          Row(
            children: _dayHeadersTr
                .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)))))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, i) {
              if (i < leadingBlanks) return const SizedBox();
              final day = DateTime(_displayedMonth.year, _displayedMonth.month, i - leadingBlanks + 1);
              final isPast = day.isBefore(_today);
              final isSelected = _selected.contains(day);
              final isToday = day == _today;

              return Padding(
                padding: const EdgeInsets.all(3),
                child: GestureDetector(
                  onTap: isPast ? null : () => _toggleDay(day),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.xp : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.xp : (isToday ? AppColors.xp.withOpacity(0.5) : Colors.transparent)),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        color: isPast ? AppColors.textMuted.withOpacity(0.4) : (isSelected ? Colors.white : AppColors.text),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.xp,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.surfaceAlt,
              ),
              onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected.toList()..sort()),
              child: Text(
                _selected.isEmpty ? 'Gün Seç' : 'Devam Et (${_selected.length} gün seçili)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selected.isEmpty ? AppColors.textMuted : Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

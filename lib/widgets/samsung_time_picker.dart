import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';

class SamsungStyleTimePicker extends StatefulWidget {
  final String? initialTime;
  const SamsungStyleTimePicker({super.key, this.initialTime});
  @override
  State<SamsungStyleTimePicker> createState() => _SamsungStyleTimePickerState();
}

class _SamsungStyleTimePickerState extends State<SamsungStyleTimePicker> {
  bool isInputMode = false;
  late int hour;
  late int minute;
  late TextEditingController hourCtrl;
  late TextEditingController minCtrl;
  final FocusNode hourNode = FocusNode();
  final FocusNode minNode = FocusNode();
  bool _isDragging = false;
  late DateTime initialDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    hour = now.hour; minute = now.minute;
    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        hour = int.tryParse(parts[0]) ?? hour;
        minute = int.tryParse(parts[1]) ?? minute;
      }
    }
    hourCtrl = TextEditingController(text: hour.toString().padLeft(2, '0'));
    minCtrl = TextEditingController(text: minute.toString().padLeft(2, '0'));
    initialDate = DateTime(2024, 1, 1, hour, minute);
  }

  @override
  void dispose() {
    hourCtrl.dispose();
    minCtrl.dispose();
    hourNode.dispose();
    minNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: AppColors.text.withOpacity(0.7), fontSize: 16))),
                TextButton(onPressed: () => Navigator.pop(context, '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'), child: Text('Kaydet', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(child: Center(child: isInputMode ? _buildInputMode() : _buildRollerMode())),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRollerMode() {
    return Listener(
      onPointerDown: (_) => _isDragging = false,
      onPointerMove: (_) => _isDragging = true,
      onPointerUp: (e) {
        if (!_isDragging && e.localPosition.dy > 70 && e.localPosition.dy < 130) {
          setState(() {
            isInputMode = true;
            hourCtrl.text = hour.toString().padLeft(2, '0');
            minCtrl.text = minute.toString().padLeft(2, '0');
          });
          Future.delayed(const Duration(milliseconds: 50), () => hourNode.requestFocus());
        }
      },
      child: SizedBox(
        height: 200,
        child: CupertinoTheme(
          data: CupertinoThemeData(brightness: AppColors.isDark ? Brightness.dark : Brightness.light, textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.text))),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            initialDateTime: initialDate,
            onDateTimeChanged: (dt) {
              setState(() {
                hour = dt.hour;
                minute = dt.minute;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeTextField(
              controller: hourCtrl, focusNode: hourNode,
              onChanged: (val) {
                int? p = int.tryParse(val);
                if (p != null) { hour = p > 23 ? 23 : p; if (p > 23) hourCtrl.text = '23'; }
                if (val.length == 2) minNode.requestFocus();
              },
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(':', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: AppColors.text.withOpacity(0.5)))),
            _buildTimeTextField(
              controller: minCtrl, focusNode: minNode,
              onChanged: (val) {
                int? p = int.tryParse(val);
                if (p != null) { minute = p > 59 ? 59 : p; if (p > 59) minCtrl.text = '59'; }
                if (val.length == 2) minNode.unfocus();
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        TextButton.icon(
          onPressed: () => setState(() => isInputMode = false),
          icon: const Icon(Icons.swipe_vertical_rounded, color: AppColors.xp, size: 18),
          label: const Text('Kaydırmaya Dön', style: TextStyle(color: AppColors.xp, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildTimeTextField({required TextEditingController controller, required FocusNode focusNode, required Function(String) onChanged}) {
    return Container(
      width: 90, height: 100,
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(20), border: Border.all(color: focusNode.hasFocus ? AppColors.xp : Colors.transparent, width: 2)),
      alignment: Alignment.center,
      child: TextField(
        controller: controller, focusNode: focusNode, keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w500, color: AppColors.text),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 2,
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../app_colors.dart';

enum RecurrenceScope { occurrence, remaining, series }

// Silme/düzenleme akışlarında ortak kullanılır: görev bir tekrarlayan serinin parçasıysa,
// işlemin sadece o güne mi, o günden itibaren kalanlara mı, yoksa tüm seriye mi uygulanacağını
// sorar. null dönerse kullanıcı vazgeçmiştir.
Future<RecurrenceScope?> showRecurrenceScopeDialog(BuildContext context, {required String actionLabel}) {
  return showDialog<RecurrenceScope>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Tekrarlayan Görev', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bu görev tekrarlayan bir serinin parçası. $actionLabel işlemini nasıl uygulamak istersin?',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _optionButton(context, 'Sadece Bu Gün', RecurrenceScope.occurrence, AppColors.xp),
          const SizedBox(height: 8),
          _optionButton(context, 'Bu Gün ve Sonrası', RecurrenceScope.remaining, AppColors.xp),
          const SizedBox(height: 8),
          _optionButton(context, 'Tüm Seri', RecurrenceScope.series, Colors.redAccent),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    ),
  );
}

Widget _optionButton(BuildContext context, String label, RecurrenceScope scope, Color color) {
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: () => Navigator.pop(context, scope),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}

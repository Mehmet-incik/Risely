import 'package:flutter/material.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);

class AppColors {
  static bool get isDark => isDarkModeNotifier.value;
  static Color get bg => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF3F4F6);
  static Color get surface => isDark ? const Color(0xFF12121A) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => isDark ? const Color(0xFF1A1A26) : const Color(0xFFE5E7EB);
  static Color get border => isDark ? const Color(0xFF2A2A3A) : const Color(0xFFD1D5DB);
  static Color get text => isDark ? Colors.white : const Color(0xFF111827);
  static Color get textMuted => isDark ? const Color(0xFF7A7A9A) : const Color(0xFF6B7280);
  static const xp = Color(0xFFA78BFA);
  static const academic = Color(0xFF6C8EFF);
  static const work = Color(0xFFFF7A5C);
  static const community = Color(0xFF4ECDC4);
  static const personal = Color(0xFFF7B731);
}

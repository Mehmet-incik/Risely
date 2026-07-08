import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'task_form.dart';

// --- EĞİTİM EKRANI (TUTORIAL OVERLAY) ---
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const TutorialOverlay({super.key, required this.onFinish});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int step = 0;

  final List<Map<String, dynamic>> steps = [
    {'title': 'Risely\'e Hoş Geldin! 🚀', 'desc': 'Sana uygulamanın nasıl çalıştığını hızlıca göstereyim. (İlerlemek için ekrana dokun)', 'icon': Icons.waving_hand_rounded},
    {'title': '1. Ana Ekran', 'desc': 'Burası senin komuta merkezin. Günlük görevlerini ve XP puanlarını buradan takip edersin.', 'icon': Icons.home_rounded},
    {'title': '2. Görev Ekleme', 'desc': 'Sağ alttaki "+" butonuna basarak görev ekleyebilir, istersen göreve özel bildirim (hatırlatıcı) kurabilirsin.', 'icon': Icons.add_circle_outline_rounded},
    {'title': '3. Takvim Görünümü', 'desc': 'Takvim sekmesine geçerek haftalık, aylık ve yıllık planlarını yapabilirsin.', 'icon': Icons.calendar_month_rounded},
    {'title': '4. Bildirim ve Ayarlar', 'desc': 'Profil sekmesinden kendine bir sabah motivasyon saati kurmayı unutma!', 'icon': Icons.notifications_active_rounded},
    {'title': 'Hazırsın! 🔥', 'desc': 'Artık planlarını yapıp hedeflerine uçma vakti. Kendi efsaneni yazmaya başla!', 'icon': Icons.rocket_launch_rounded},
  ];

  void _nextStep() {
    if (step < steps.length - 1) {
      setState(() => step++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = steps[step];
    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey<int>(step),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(current['icon'], size: 70, color: AppColors.xp),
                    const SizedBox(height: 24),
                    Text(current['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(current['desc'], style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    const Text('Devam etmek için ekrana dokun', style: TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ANA EKRAN KONTROLCÜSÜ (MAIN SCREEN) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_tutorial') ?? false;
    if (!hasSeen) setState(() => _showTutorial = true);
  }

  void _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    setState(() => _showTutorial = false);
  }

  void _onTaskToggled() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        final screens = [
          HomeScreen(onHelpTapped: () => setState(() => _showTutorial = true)),
          CalendarScreen(onTaskToggled: _onTaskToggled),
          const StatsScreen(),
          ProfileScreen(onTaskToggled: _onTaskToggled),
        ];

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              screens[_currentIndex],
              if (_showTutorial) Positioned.fill(child: TutorialOverlay(onFinish: _finishTutorial))
            ],
          ),
          floatingActionButton: (_currentIndex == 0 || _currentIndex == 1) && !_showTutorial
              ? FloatingActionButton(
            onPressed: () => showTaskForm(
              context,
              selectedDate: (_currentIndex == 1) ? (screens[1] as CalendarScreen).getSelectedDate() : null,
              onSaved: _onTaskToggled,
            ),
            backgroundColor: AppColors.xp,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          )
              : null,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Ana', 0),
                _navItem(Icons.calendar_month_rounded, 'Takvim', 1),
                _navItem(Icons.bar_chart_rounded, 'İstat.', 2),
                _navItem(Icons.person_rounded, 'Profil', 3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.xp : AppColors.textMuted, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: active ? AppColors.xp : AppColors.textMuted)),
        ],
      ),
    );
  }
}

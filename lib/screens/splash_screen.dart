import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../app_colors.dart';
import '../services/services.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    _loadAppDependencies();
  }

  Future<void> _loadAppDependencies() async {
    tz_data.initializeTimeZones();
    try {
      final dynamic timezoneInfo = await FlutterTimezone.getLocalTimezone();
      String tzName = timezoneInfo is String ? timezoneInfo : timezoneInfo.name;
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      // Cihazdan gelen bölge adı tz veritabanında tanınmadıysa (ör. bazı Android
      // sürümlerinde/emülatörlerde döndürülen kısa "GMT" adı), sabit bir şehre
      // (ör. Europe/Istanbul) düşmek farklı ofsetli cihazlarda tüm zamanlanmış
      // bildirimleri saatlerce kaydırır. Bunun yerine cihazın gerçek UTC ofsetine
      // karşılık gelen sabit bölgeyi kullan.
      final offsetHours = -DateTime.now().timeZoneOffset.inHours;
      final sign = offsetHours >= 0 ? '+' : '';
      try {
        tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$offsetHours'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    await NotificationService.init();
    await context.read<TaskStore>().loadData();
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.xp, AppColors.academic]), boxShadow: [BoxShadow(color: AppColors.xp.withOpacity(0.4), blurRadius: 20, spreadRadius: -5)]),
                child: const Center(child: Text('🚀', style: TextStyle(fontSize: 60))),
              ),
              const SizedBox(height: 24),
              Text('Risely', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Kendi Efsaneni Yaz', style: TextStyle(fontSize: 14, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}

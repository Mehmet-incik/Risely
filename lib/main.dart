import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const List<Map<String, String>> messages = [
    {'icon': '🦅', 'greeting': 'Selam', 'body': 'Seni tanımlayan, kaç kez düştüğün değil, her seferinde nasıl kalktığındır.'},
    {'icon': '🌅', 'greeting': 'Günaydın', 'body': 'Sabırlı ol. İyi şeyler gelecek.'},
    {'icon': '🚀', 'greeting': 'Selam', 'body': 'Küçük adımlar, büyük zaferler getirir. Başla!'},
  ];

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleTaskReminder(int notificationId, String title, DateTime taskTime, int offsetMinutes) async {
    final local = tz.local;
    final tzTaskTime = tz.TZDateTime.from(taskTime, local);
    final tzScheduledTime = tzTaskTime.subtract(Duration(minutes: offsetMinutes));

    if (tzScheduledTime.isBefore(tz.TZDateTime.now(local))) return;

    String timeStr = '${taskTime.hour.toString().padLeft(2, '0')}:${taskTime.minute.toString().padLeft(2, '0')}';
    String bodyText = offsetMinutes == 0
        ? 'Görev zamanı geldi!'
        : 'Saat $timeStr\'daki görevine ${offsetMinutes == 60 ? '1 saat' : '$offsetMinutes dakika'} kaldı!';

    await _notifications.zonedSchedule(
      notificationId,
      '🔔 $title',
      bodyText,
      tzScheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders', 'Görev Hatırlatıcıları',
          channelDescription: 'Bireysel görevler için zamanlanmış bildirimler',
          importance: Importance.max, priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelTaskReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  static Future<void> scheduleMorningMotivation(int hour, int minute) async {
    for(int i=0; i<60; i++) { await _notifications.cancel(i); }

    final local = tz.local;
    final now = tz.TZDateTime.now(local);
    int dayOffset = tz.TZDateTime(local, now.year, now.month, now.day, hour, minute).isBefore(now) ? 1 : 0;

    for (int i = 0; i < 60; i++) {
      final scheduledDate = tz.TZDateTime(local, now.year, now.month, now.day, hour, minute).add(Duration(days: i + dayOffset));
      final msg = messages[i % messages.length];
      await _notifications.zonedSchedule(
        i,
        "${msg['icon']} ${msg['greeting']}, ${TaskStore.userName}",
        msg['body']!,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_motivation', 'Sabah Motivasyonu',
            importance: Importance.max, priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> testInstantNotification() async {
    final msg = messages[0];
    await _notifications.show(
      999,
      "${msg['icon']} Bu bir Test Bildirimidir!",
      "Eğer bunu görüyorsan, bildirim altyapın kusursuz çalışıyor demektir! 🚀",
      const NotificationDetails(android: AndroidNotificationDetails('morning_motivation', 'Sabah Motivasyonu', importance: Importance.max, priority: Priority.high)),
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('is_dark_mode') ?? true;
  runApp(const RiselyApp());
}

class RiselyApp extends StatelessWidget {
  const RiselyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Risely',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: AppColors.xp, surface: AppColors.surface,
            ),
          ),
          // YENİ AKIŞ: Uygulama artık LoginScreen ile başlıyor
          home: const LoginScreen(),
        );
      },
    );
  }
}

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

class Task {
  final String id;
  final int notificationId;
  String title;
  String? time;
  String category;
  bool isFixed;
  DateTime date;
  bool hasReminder;
  int reminderOffset;
  bool isDone;

  Task({
    required this.id, required this.notificationId, required this.title, this.time,
    required this.category, required this.isFixed, required this.date,
    this.hasReminder = false, this.reminderOffset = 0, this.isDone = false
  });

  Color get categoryColor {
    switch (category) { case 'Academic': return AppColors.academic; case 'Work': return AppColors.work; case 'Community': return AppColors.community; case 'Personal': return AppColors.personal; default: return AppColors.xp; }
  }

  Map<String, dynamic> toJson() => {'id': id, 'notificationId': notificationId, 'title': title, 'time': time, 'category': category, 'isFixed': isFixed, 'date': date.toIso8601String(), 'hasReminder': hasReminder, 'reminderOffset': reminderOffset, 'isDone': isDone};
  factory Task.fromJson(Map<String, dynamic> json) => Task(id: json['id'], notificationId: json['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000), title: json['title'], time: json['time'], category: json['category'], isFixed: json['isFixed'], date: DateTime.parse(json['date']), hasReminder: json['hasReminder'] ?? false, reminderOffset: json['reminderOffset'] ?? 0, isDone: json['isDone']);
}

class TaskStore {
  static List<Task> allTasks = [];
  static String userName = 'Kullanıcı';
  static String userAvatar = '🚀';
  static String? notificationTime;
  static DateTime? notificationStartDate;

  static String getTodayLabel() {
    final now = DateTime.now();
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  static int get totalXp => allTasks.where((t) => t.isDone).length * 15;

  static Map<String, dynamic> getUserLevelInfo() {
    int xp = totalXp;
    if (xp < 75) return {'level': 1, 'title': 'Acemi Planlayıcı'};
    if (xp < 150) return {'level': 2, 'title': 'Çaylak'};
    if (xp < 300) return {'level': 3, 'title': 'Çırak'};
    if (xp < 450) return {'level': 4, 'title': 'Kalfa'};
    return {'level': 5, 'title': 'Uzman'};
  }

  static List<Task> getTasksForDate(DateTime date) {
    return allTasks.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).toList();
  }

  static int getScoreForDate(DateTime date) {
    final tasks = getTasksForDate(date);
    if (tasks.isEmpty) return 0;
    return ((tasks.where((t) => t.isDone).length / tasks.length) * 100).round();
  }

  static Map<String, String> getDailyMotivation() {
    if (notificationStartDate == null) return NotificationService.messages[DateTime.now().day % NotificationService.messages.length];
    final now = DateTime.now();
    final startMidnight = DateTime(notificationStartDate!.year, notificationStartDate!.month, notificationStartDate!.day);
    final todayMidnight = DateTime(now.year, now.month, now.day);
    int diffDays = todayMidnight.difference(startMidnight).inDays;
    if (diffDays < 0) diffDays = 0;
    return NotificationService.messages[diffDays % NotificationService.messages.length];
  }

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_name') ?? 'Kullanıcı';
    userAvatar = prefs.getString('user_avatar') ?? '🚀';
    notificationTime = prefs.getString('notification_time');

    final startDateStr = prefs.getString('notification_start_date');
    if (startDateStr != null) notificationStartDate = DateTime.parse(startDateStr);

    final String? tasksJson = prefs.getString('saved_tasks');
    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        allTasks = decoded.map((item) => Task.fromJson(item)).toList();
      } catch (e) {
        allTasks = [];
      }
    } else {
      allTasks = [];
    }
  }

  static Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_tasks', jsonEncode(allTasks.map((t) => t.toJson()).toList()));
  }

  static Future<void> saveUserName(String name) async {
    userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  static Future<void> saveAvatar(String avatar) async {
    userAvatar = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar', avatar);
  }

  static Future<void> saveNotificationTime(String? time) async {
    notificationTime = time;
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setString('notification_time', time);
      notificationStartDate = DateTime.now();
      await prefs.setString('notification_start_date', notificationStartDate!.toIso8601String());
    } else {
      await prefs.remove('notification_time');
      await prefs.remove('notification_start_date');
      notificationStartDate = null;
    }
  }
}

// --- YENİ: GİRİŞ EKRANI ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;

  void _submitForm() {
    // Burada ileride Firebase işlemleri olacak
    // Şimdilik başarılı sayıp roketli ekrana atıyoruz
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  void _continueAsGuest() {
    // Misafir girişi simülasyonu
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo ve Başlık
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.xp, AppColors.academic]), boxShadow: [BoxShadow(color: AppColors.xp.withOpacity(0.4), blurRadius: 15, spreadRadius: -5)]),
                child: const Center(child: Text('🚀', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 24),
              Text('Risely', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(_isLoginMode ? 'Kendi efsaneni yazmaya devam et.' : 'Yeni bir başlangıç için efsaneni yazmaya başla.', style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 40),

              // Segment (Giriş Yap / Kayıt Ol)
              Center(
                child: CupertinoSlidingSegmentedControl<bool>(
                  backgroundColor: AppColors.surfaceAlt.withOpacity(0.5),
                  thumbColor: AppColors.surface,
                  groupValue: _isLoginMode,
                  padding: const EdgeInsets.all(4),
                  children: {
                    true: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Text('Giriş Yap', style: TextStyle(fontSize: 14, fontWeight: _isLoginMode ? FontWeight.bold : FontWeight.normal, color: _isLoginMode ? Colors.white : AppColors.textMuted))),
                    false: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Text('Kayıt Ol', style: TextStyle(fontSize: 14, fontWeight: !_isLoginMode ? FontWeight.bold : FontWeight.normal, color: !_isLoginMode ? Colors.white : AppColors.textMuted))),
                  },
                  onValueChanged: (val) { if (val != null) setState(() => _isLoginMode = val); },
                ),
              ),
              const SizedBox(height: 30),

              // Form Alanları
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_isLoginMode),
                  children: [
                    if (!_isLoginMode) ...[
                      TextField(controller: _nameController, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'Tam Adın', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                      const SizedBox(height: 16),
                    ],
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'E-posta Adresi', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                    const SizedBox(height: 16),
                    TextField(controller: _passwordController, obscureText: _obscurePassword, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'Şifre', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20), suffixIcon: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword), child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                  ],
                ),
              ),

              if (_isLoginMode) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Şifremi Unuttum?', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)))),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.xp, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 5, shadowColor: AppColors.xp.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _submitForm,
                  child: Text(_isLoginMode ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),

              // Misafir Girişi
              Row(children: [Expanded(child: Divider(color: AppColors.border, thickness: 1)), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('VEYA', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5))), Expanded(child: Divider(color: AppColors.border, thickness: 1))]),
              const SizedBox(height: 30),
              TextButton(
                onPressed: _continueAsGuest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Bir hesap açmadan ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    Text('Misafir Olarak Devam Et', style: TextStyle(fontSize: 13, color: AppColors.xp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- AÇILIŞ EKRANI (ROKET) ---
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
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    await NotificationService.init();
    await TaskStore.loadData();
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

// --- BİRİNCİ YARININ SONU ---
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
          HomeScreen(onTaskToggled: _onTaskToggled, onHelpTapped: () => setState(() => _showTutorial = true)),
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

// --- ANA SEKME EKRANLARI (HOME, CALENDAR, STATS, PROFILE) ---
class HomeScreen extends StatefulWidget {
  final VoidCallback onTaskToggled;
  final VoidCallback onHelpTapped;
  const HomeScreen({super.key, required this.onTaskToggled, required this.onHelpTapped});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> get tasks => TaskStore.getTasksForDate(DateTime.now());
  List<Task> get fixedTasks => tasks.where((t) => t.isFixed).toList()..sort((a,b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
  List<Task> get flexTasks => tasks.where((t) => !t.isFixed).toList();
  int get doneTasks => tasks.where((t) => t.isDone).length;
  int get percentage => tasks.isEmpty ? 0 : ((doneTasks / tasks.length) * 100).round();

  void toggleTask(String id) {
    setState(() {
      final task = TaskStore.allTasks.firstWhere((t) => t.id == id);
      task.isDone = !task.isDone;
    });
    TaskStore.saveTasks();
    widget.onTaskToggled();
  }

  void deleteTask(Task task) {
    setState(() => TaskStore.allTasks.removeWhere((t) => t.id == task.id));
    if (task.hasReminder) NotificationService.cancelTaskReminder(task.notificationId);
    TaskStore.saveTasks();
    widget.onTaskToggled();
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = TaskStore.getUserLevelInfo();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMotivationCard(),
            _buildScoreCard(levelInfo),
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
              Text('Günaydın, ${TaskStore.userName} 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
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
                child: Center(child: Text(TaskStore.userAvatar, style: const TextStyle(fontSize: 20))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    final msg = TaskStore.getDailyMotivation();
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.work.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                          child: const Text('🔥 Seriye Başla!', style: TextStyle(fontSize: 11, color: AppColors.work, fontWeight: FontWeight.w600)),
                        ),
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
          showTaskForm(context, task: task, onSaved: widget.onTaskToggled);
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

enum CalendarViewMode { weekly, monthly, yearly }

class CalendarScreen extends StatefulWidget {
  final VoidCallback onTaskToggled;
  const CalendarScreen({super.key, required this.onTaskToggled});

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

  void toggleTask(String id) {
    setState(() {
      final task = TaskStore.allTasks.firstWhere((t) => t.id == id);
      task.isDone = !task.isDone;
    });
    TaskStore.saveTasks();
    widget.onTaskToggled();
  }

  void deleteTask(Task task) {
    setState(() => TaskStore.allTasks.removeWhere((t) => t.id == task.id));
    if (task.hasReminder) NotificationService.cancelTaskReminder(task.notificationId);
    TaskStore.saveTasks();
    widget.onTaskToggled();
  }

  @override
  Widget build(BuildContext context) {
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
              List<Task> dayTasks = TaskStore.getTasksForDate(day)..sort((a,b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
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
                              onTap: () => showTaskForm(context, selectedDate: day, onSaved: widget.onTaskToggled),
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
          showTaskForm(context, task: task, onSaved: widget.onTaskToggled);
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
    final todayTasks = TaskStore.getTasksForDate(currentSelectedDate)..sort((a, b) => (a.time ?? '25:00').compareTo(b.time ?? '25:00'));
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
      confirmDismiss: (direction) async { if (direction == DismissDirection.startToEnd) { showTaskForm(context, task: task, onSaved: widget.onTaskToggled); return false; } return true; },
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

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Color _getCatColor(String cat) {
    switch (cat) {
      case 'Academic': return AppColors.academic;
      case 'Work': return AppColors.work;
      case 'Community': return AppColors.community;
      case 'Personal': return AppColors.personal;
      default: return AppColors.xp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = TaskStore.allTasks;
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final pct = total == 0 ? 0 : ((done / total) * 100).round();

    final Map<String, Map<String, int>> catStats = {
      'Academic': {'total': 0, 'done': 0},
      'Work': {'total': 0, 'done': 0},
      'Community': {'total': 0, 'done': 0},
      'Personal': {'total': 0, 'done': 0}
    };

    for (var t in tasks) {
      if (catStats.containsKey(t.category)) {
        catStats[t.category]!['total'] = catStats[t.category]!['total']! + 1;
        if (t.isDone) catStats[t.category]!['done'] = catStats[t.category]!['done']! + 1;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GENEL BAKIŞ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('İstatistikler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.xp.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.done_all_rounded, color: AppColors.xp, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('$done', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('Tamamlanan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.format_list_bulleted_rounded, color: Colors.blueAccent, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text('$total', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text('Toplam Görev', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  SizedBox(
                    width: 90, height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(value: pct / 100, backgroundColor: AppColors.bg, valueColor: const AlwaysStoppedAnimation(AppColors.xp), strokeWidth: 6, strokeCap: StrokeCap.round),
                        Text('%$pct', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.xp)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Genel Başarı Oranı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                        const SizedBox(height: 4),
                        Text('Harika gidiyorsun! Devam et.', style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('KATEGORİ DETAYLARI', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            ...catStats.entries.map((e) {
              final color = _getCatColor(e.key);
              final t = e.value['total']!;
              final d = e.value['done']!;
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                          ],
                        ),
                        Text('$d/$t', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: t == 0 ? 0 : d / t, backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback onTaskToggled;
  const ProfileScreen({super.key, required this.onTaskToggled});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickNotificationTime() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SamsungStyleTimePicker(initialTime: TaskStore.notificationTime ?? '07:00'),
      ),
    );
    if (result != null && context.mounted) {
      final parts = result.split(':');
      await TaskStore.saveNotificationTime(result);
      await NotificationService.scheduleMorningMotivation(int.parse(parts[0]), int.parse(parts[1]));
      setState(() {});
      widget.onTaskToggled();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔔 Her sabah $result\'da motivasyon gelecek!'), backgroundColor: AppColors.xp));
    }
  }

  Future<void> _cancelNotifications() async {
    await TaskStore.saveNotificationTime(null);
    await NotificationService.cancelAllNotifications();
    setState(() {});
    widget.onTaskToggled();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm bildirimler kapatıldı.'), backgroundColor: Colors.red));
    }
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: TaskStore.userName);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 16),
            Text('Adın', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppColors.text),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
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
                  if (nameCtrl.text.isNotEmpty) {
                    await TaskStore.saveUserName(nameCtrl.text);
                    setState(() {});
                    widget.onTaskToggled();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text('Tüm görevler ve istatistikler silinecek. Emin misiniz?'),
        actions: [
          CupertinoDialogAction(child: const Text('İptal', style: TextStyle(color: Colors.blue)), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Evet, Sil'),
            onPressed: () async {
              TaskStore.allTasks.clear();
              await TaskStore.saveTasks();
              widget.onTaskToggled();
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veriler sıfırlandı.'), backgroundColor: AppColors.xp));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = TaskStore.getUserLevelInfo();
    final doneTasks = TaskStore.allTasks.where((t) => t.isDone).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AvatarPickerSheet(
                  currentAvatar: TaskStore.userAvatar,
                  onSelected: (a) {
                    setState(() {});
                    widget.onTaskToggled();
                  },
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.xp, AppColors.academic])),
                    child: Center(child: Text(TaskStore.userAvatar, style: const TextStyle(fontSize: 48))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.xp, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(TaskStore.userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('Seviye ${levelInfo['level']} • ${levelInfo['title']}', style: const TextStyle(fontSize: 14, color: AppColors.xp, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard('Puan', '${TaskStore.totalXp} XP', AppColors.xp),
                  const SizedBox(width: 12),
                  _buildStatCard('Görev', '$doneTasks Adet', AppColors.work),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BİLDİRİMLER', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: TaskStore.notificationTime != null ? AppColors.xp : AppColors.textMuted,
                    title: TaskStore.notificationTime != null ? 'Sabah Bildirimi (${TaskStore.notificationTime})' : 'Sabah Motivasyonu Kur',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (TaskStore.notificationTime != null)
                          GestureDetector(
                            onTap: _cancelNotifications,
                            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.cancel, color: Colors.redAccent, size: 20)),
                          ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: _pickNotificationTime,
                  ),
                  // Test butonu KALDIRILDI!
                  const SizedBox(height: 24),
                  Text('AYARLAR', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Adımı Değiştir',
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showEditProfileSheet,
                  ),
                  _buildMenuTile(
                    icon: isDarkModeNotifier.value ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: isDarkModeNotifier.value ? 'Karanlık Mod' : 'Aydınlık Mod',
                    trailing: CupertinoSwitch(
                      value: isDarkModeNotifier.value,
                      activeColor: AppColors.xp,
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_dark_mode', val);
                        isDarkModeNotifier.value = val;
                      },
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  Text('VERİ YÖNETİMİ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Tüm Verileri Sıfırla',
                    titleColor: Colors.red,
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showResetDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required Widget trailing, required VoidCallback onTap, Color? iconColor, Color? titleColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textMuted, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor ?? AppColors.text))),
            trailing,
          ],
        ),
      ),
    );
  }
}

class AvatarPickerSheet extends StatefulWidget {
  final String currentAvatar;
  final Function(String) onSelected;
  const AvatarPickerSheet({super.key, required this.currentAvatar, required this.onSelected});

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late String selected;
  final List<Map<String, String>> avatars = [
    {'emoji': '🦅', 'name': 'Kartal'}, {'emoji': '🦁', 'name': 'Aslan'}, {'emoji': '🤖', 'name': 'Robot'},
    {'emoji': '🚀', 'name': 'Roket'}, {'emoji': '🌟', 'name': 'Yıldız'}, {'emoji': '⚡', 'name': 'Şimşek'},
    {'emoji': '🔥', 'name': 'Ateş'}, {'emoji': '🎯', 'name': 'Hedef'}, {'emoji': '🧠', 'name': 'Beyin'},
    {'emoji': '🦸', 'name': 'Kahraman'}
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.currentAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avatar Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Seni en iyi hangisi temsil ediyor?', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final isSelected = selected == avatar['emoji'];
              return GestureDetector(
                onTap: () => setState(() => selected = avatar['emoji']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.xp.withOpacity(0.15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.xp : AppColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(avatar['emoji']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(avatar['name']!, style: TextStyle(fontSize: 9, color: isSelected ? AppColors.xp : AppColors.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
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
              ),
              onPressed: () async {
                await TaskStore.saveAvatar(selected);
                widget.onSelected(selected);
                Navigator.pop(context);
              },
              child: const Text('Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

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
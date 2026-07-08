import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../models/mood_entry.dart';

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

  // Üreticilerin (özellikle Samsung) agresif pil optimizasyonu, uygulama arka plandayken/ekran
  // kilitliyken zamanlanmış bildirimleri sessizce engelleyebiliyor. Bu, uygulamayı muaf tutar.
  static Future<bool> isBatteryOptimizationDisabled() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  static Future<bool> requestDisableBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }
}

class TaskStore {
  static List<Task> allTasks = [];
  static List<MoodEntry> allMoods = [];
  static String userName = 'Kullanıcı';
  static String userAvatar = '🚀';
  static String? notificationTime;
  static DateTime? notificationStartDate;

  static const List<String> moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
  static const List<String> moodLabels = ['kötü', 'fena değil', 'idare eder', 'iyi', 'harika'];

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

  // 0: o gün görev yok, 1-4: skor arttıkça artan yoğunluk kademesi (heatmap için).
  static int getIntensityLevel(DateTime date) {
    final tasks = getTasksForDate(date);
    if (tasks.isEmpty) return 0;
    final score = getScoreForDate(date);
    if (score <= 25) return 1;
    if (score <= 50) return 2;
    if (score <= 75) return 3;
    return 4;
  }

  // Son [days] gün (bugün dahil) için yoğunluk kademesini tek geçişte hesaplar;
  // heatmap grid'inde gün başına ayrı ayrı getTasksForDate çağrısı yapmaktan kaçınır.
  static Map<DateTime, int> getIntensityMapForLastDays(int days) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startDate = todayOnly.subtract(Duration(days: days - 1));

    final Map<DateTime, List<Task>> grouped = {};
    for (final t in allTasks) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isBefore(startDate) || d.isAfter(todayOnly)) continue;
      grouped.putIfAbsent(d, () => []).add(t);
    }

    final Map<DateTime, int> result = {};
    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      final dayTasks = grouped[day];
      if (dayTasks == null || dayTasks.isEmpty) {
        result[day] = 0;
        continue;
      }
      final score = ((dayTasks.where((t) => t.isDone).length / dayTasks.length) * 100).round();
      if (score <= 25) {
        result[day] = 1;
      } else if (score <= 50) {
        result[day] = 2;
      } else if (score <= 75) {
        result[day] = 3;
      } else {
        result[day] = 4;
      }
    }
    return result;
  }

  static MoodEntry? getMoodForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final m in allMoods) {
      final d = DateTime(m.date.year, m.date.month, m.date.day);
      if (d == target) return m;
    }
    return null;
  }

  // Aynı güne ait kayıt varsa üzerine yazar (günde 1 mood kaydı kuralı).
  static Future<void> saveMood(DateTime date, int score, {String? note}) async {
    final target = DateTime(date.year, date.month, date.day);
    allMoods.removeWhere((m) => DateTime(m.date.year, m.date.month, m.date.day) == target);
    allMoods.add(MoodEntry(date: target, score: score, note: note));
    await saveMoods();
  }

  static Future<void> saveMoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_moods', jsonEncode(allMoods.map((m) => m.toJson()).toList()));
  }

  // Heatmap için: 0 = kayıt yok, 1-5 = mood skoru (kademe = skorun kendisi).
  static Map<DateTime, int> getMoodIntensityMapForLastDays(int days) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startDate = todayOnly.subtract(Duration(days: days - 1));

    final Map<DateTime, int> result = {};
    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      result[day] = getMoodForDate(day)?.score ?? 0;
    }
    return result;
  }

  // "En üretken günlerindeki (başarı skoru %75+) ortalama ruh halin" içgörüsü için emoji döndürür.
  static String? getProductiveMoodEmoji() {
    final productiveScores = <int>[];
    for (final mood in allMoods) {
      if (getScoreForDate(mood.date) >= 75) productiveScores.add(mood.score);
    }
    if (productiveScores.isEmpty) return null;
    final avg = productiveScores.reduce((a, b) => a + b) / productiveScores.length;
    return moodEmojis[avg.round().clamp(1, 5) - 1];
  }

  static Set<DateTime> get _completedDates {
    return allTasks.where((t) => t.isDone).map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet();
  }

  // Bugün henüz görev bitirilmemişse dünden geriye sayar (seri "risk altında" gösterilir ama kırılmış sayılmaz).
  static int get currentStreak {
    final completed = _completedDates;
    final now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);
    if (!completed.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));

    int streak = 0;
    while (completed.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int get longestStreak {
    final completed = _completedDates.toList()..sort();
    if (completed.isEmpty) return 0;

    int longest = 1;
    int running = 1;
    for (int i = 1; i < completed.length; i++) {
      final diff = completed[i].difference(completed[i - 1]).inDays;
      if (diff == 1) {
        running++;
      } else if (diff > 1) {
        running = 1;
      }
      if (running > longest) longest = running;
    }
    return longest;
  }

  static bool get isStreakAtRisk {
    if (currentStreak == 0) return false;
    final now = DateTime.now();
    return !_completedDates.contains(DateTime(now.year, now.month, now.day));
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

    final String? moodsJson = prefs.getString('saved_moods');
    if (moodsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(moodsJson);
        allMoods = decoded.map((item) => MoodEntry.fromJson(item)).toList();
      } catch (e) {
        allMoods = [];
      }
    } else {
      allMoods = [];
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

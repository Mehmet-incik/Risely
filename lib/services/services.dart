import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/mood_entry.dart';
import 'firestore_sync_service.dart';
import 'motivation_messages.dart';
import 'notification_service.dart';

class TaskStore extends ChangeNotifier {
  List<Task> allTasks = [];
  List<MoodEntry> allMoods = [];
  String userName = 'Kullanıcı';
  String userAvatar = '🚀';
  String? notificationTime;
  DateTime? notificationStartDate;
  DateTime settingsUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Kayıt formunda girilen isim: FirebaseAuth.createUserWithEmailAndPassword()
  // tamamlanır tamamlanmaz authStateChanges tetiklenip AuthGate SplashScreen'e
  // geçebilir — bu, LoginScreen'in ayrıca çağıracağı saveUserName() ile YARIŞIR
  // (loadData() bazen daha önce çalışıp ismi varsayılana geri döndürebilir).
  // Bunun yerine isim createUserWithEmailAndPassword'DAN ÖNCE senkron olarak
  // buraya yazılır, loadData() de bunu (varsa) yerel prefs'ten okumak yerine
  // kullanır — iki async işlemin sıralamasına bağımlı olmadan çalışır.
  String? pendingUserName;

  static const List<String> moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
  static const List<String> moodLabels = ['kötü', 'fena değil', 'idare eder', 'iyi', 'harika'];

  // Rule bazlı tekrarlayan seriler bu kadar gün ileriye kadar somut Task kaydı olarak
  // üretilir (kayan pencere) — "her gün" gibi sınırsız bir kural, sonsuz kayıt üretmesin diye.
  static const int recurrenceWindowDays = 60;

  static String getTodayLabel() {
    final now = DateTime.now();
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  int get totalXp => allTasks.where((t) => t.isDone).length * 15;

  Map<String, dynamic> getUserLevelInfo() {
    int xp = totalXp;
    if (xp < 75) return {'level': 1, 'title': 'Acemi Planlayıcı'};
    if (xp < 150) return {'level': 2, 'title': 'Çaylak'};
    if (xp < 300) return {'level': 3, 'title': 'Çırak'};
    if (xp < 450) return {'level': 4, 'title': 'Kalfa'};
    return {'level': 5, 'title': 'Uzman'};
  }

  List<Task> getTasksForDate(DateTime date) {
    return allTasks.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).toList();
  }

  int getScoreForDate(DateTime date) {
    final tasks = getTasksForDate(date);
    if (tasks.isEmpty) return 0;
    return ((tasks.where((t) => t.isDone).length / tasks.length) * 100).round();
  }

  // 0: o gün görev yok, 1-4: skor arttıkça artan yoğunluk kademesi (heatmap için).
  int getIntensityLevel(DateTime date) {
    final tasks = getTasksForDate(date);
    if (tasks.isEmpty) return 0;
    final score = getScoreForDate(date);
    if (score <= 25) return 1;
    if (score <= 50) return 2;
    if (score <= 75) return 3;
    return 4;
  }

  // Görev toggle/silme/ekleme, ekranlar arasında dağınık haldeydi (Faz 4 görev 2 öncesi);
  // Provider'a geçişte tek yerden yönetilmesi ve notifyListeners() ile bağlanması için buraya taşındı.
  Future<void> toggleTask(String id) async {
    final task = allTasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    task.updatedAt = DateTime.now();
    await saveTasks();
  }

  Future<void> deleteTask(Task task) async {
    allTasks.removeWhere((t) => t.id == task.id);
    if (task.hasReminder) NotificationService.cancelTaskReminder(task.notificationId);
    await saveTasks();
  }

  void addTask(Task task) {
    allTasks.add(task);
  }

  bool _ruleMatchesDate(String rule, DateTime date) {
    final weekday = date.weekday; // 1=Pzt .. 7=Paz
    if (rule == 'daily') return true;
    if (rule == 'weekdays') return weekday >= 1 && weekday <= 5;
    if (rule.startsWith('weekly:')) {
      final days = rule.substring(7).split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
      return days.contains(weekday);
    }
    return false;
  }

  List<DateTime> _datesForRule(DateTime start, String rule, int windowDays) {
    final startDay = DateTime(start.year, start.month, start.day);
    final dates = <DateTime>[];
    for (int i = 0; i < windowDays; i++) {
      final d = startDay.add(Duration(days: i));
      if (_ruleMatchesDate(rule, d)) dates.add(d);
    }
    return dates;
  }

  List<Task> _createSeries({
    required String title, String? time, required String category, required bool isFixed,
    required List<DateTime> dates, String? recurrenceRule, bool hasReminder = false, int reminderOffset = 0,
  }) {
    if (dates.isEmpty) return [];
    final groupId = '${recurrenceRule != null ? 'rec' : 'bulk'}_${DateTime.now().microsecondsSinceEpoch}';
    int notifSeed = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    final created = <Task>[];
    for (final d in dates) {
      final nid = notifSeed++;
      final task = Task(
        id: '${DateTime.now().microsecondsSinceEpoch}_$nid',
        notificationId: nid,
        title: title, time: time, category: category, isFixed: isFixed,
        date: DateTime(d.year, d.month, d.day),
        hasReminder: hasReminder, reminderOffset: reminderOffset,
        recurrenceRule: recurrenceRule, recurrenceGroupId: groupId,
      );
      allTasks.add(task);
      created.add(task);
    }
    return created;
  }

  // Görev formunda "Her gün / Hafta içi / Seçili günler" seçilince çağrılır — seçilen kuralı
  // başlangıç tarihinden itibaren recurrenceWindowDays kadar somut Task kaydına çevirir.
  // Bildirim planlaması ve saveTasks() çağrısı (tek görev ekleme akışıyla tutarlı olsun diye)
  // çağıran tarafta (task_form.dart) yapılır.
  List<Task> addRecurringTaskSeries({
    required String title, String? time, required String category, required bool isFixed,
    required DateTime startDate, required String recurrenceRule, bool hasReminder = false, int reminderOffset = 0,
  }) {
    final dates = _datesForRule(startDate, recurrenceRule, recurrenceWindowDays);
    return _createSeries(title: title, time: time, category: category, isFixed: isFixed, dates: dates, recurrenceRule: recurrenceRule, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  // Takvimden çoklu gün seçilip toplu eklendiğinde çağrılır. recurrenceRule YOK — seçilen
  // günler sabit bir liste, kayan pencereyle otomatik genişletilmez.
  List<Task> addBulkTaskSeries({
    required String title, String? time, required String category, required bool isFixed,
    required List<DateTime> dates, bool hasReminder = false, int reminderOffset = 0,
  }) {
    return _createSeries(title: title, time: time, category: category, isFixed: isFixed, dates: dates, recurrenceRule: null, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  // "Tüm seriyi sil": aynı recurrenceGroupId'ye sahip TÜM görevler (geçmiş dahil) silinir.
  // "Sadece bu günü sil" için mevcut deleteTask(task) kullanılır, bu metoda gerek yoktur.
  Future<void> deleteTaskSeries(String groupId) async {
    final toDelete = allTasks.where((t) => t.recurrenceGroupId == groupId).toList();
    for (final t in toDelete) {
      if (t.hasReminder) NotificationService.cancelTaskReminder(t.notificationId);
    }
    allTasks.removeWhere((t) => t.recurrenceGroupId == groupId);
    await saveTasks();
  }

  // "Bu gün ve sonrasını sil": fromDate dahil sonraki tüm occurrence'lar silinir, öncekiler
  // (geçmiş) dokunulmadan kalır. KRİTİK: kalan (geçmiş) occurrence'ların recurrenceRule'ü
  // temizlenir — aksi halde _topUpRecurringWindow bu seriyi hâlâ "aktif" sanıp bir sonraki
  // açılışta sildiğimiz günleri sessizce yeniden üretir (bkz. roadmap.md Faz 6A).
  Future<void> deleteTaskSeriesFrom(String groupId, DateTime fromDate) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final groupTasks = allTasks.where((t) => t.recurrenceGroupId == groupId).toList();

    final toDelete = groupTasks.where((t) => !DateTime(t.date.year, t.date.month, t.date.day).isBefore(from)).toList();
    for (final t in toDelete) {
      if (t.hasReminder) NotificationService.cancelTaskReminder(t.notificationId);
    }
    allTasks.removeWhere((t) => toDelete.contains(t));

    for (final t in groupTasks) {
      if (DateTime(t.date.year, t.date.month, t.date.day).isBefore(from)) {
        t.recurrenceRule = null;
      }
    }
    await saveTasks();
  }

  // "Tüm seriyi düzenle": başlık/saat/kategori/hatırlatıcı tüm occurrence'lara uygulanır;
  // her occurrence'ın kendi tarihi ve tamamlanma durumu (isDone) DOKUNULMADAN kalır.
  // v1'de tekrar kuralının kendisi (recurrenceRule) buradan değiştirilemez — kalıbı değiştirmek
  // isteyen kullanıcı seriyi silip yeniden oluşturur (bkz. roadmap.md Faz 6A riskleri).
  Future<void> editTaskSeries(String groupId, {
    required String title, String? time, required String category, required bool isFixed,
    required bool hasReminder, required int reminderOffset,
  }) async {
    final tasks = allTasks.where((t) => t.recurrenceGroupId == groupId).toList();
    await _applyEditToTasks(tasks, title: title, time: time, category: category, isFixed: isFixed, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  // "Bu gün ve sonrasını düzenle": fromDate dahil sonraki occurrence'lara uygulanır, geçmiş
  // occurrence'lar dokunulmadan kalır. recurrenceRule değişmez, seri top-up ile genişlemeye
  // devam eder (bu, silmeden farklı olarak seriyi "bitirmez").
  Future<void> editTaskSeriesFrom(String groupId, DateTime fromDate, {
    required String title, String? time, required String category, required bool isFixed,
    required bool hasReminder, required int reminderOffset,
  }) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final tasks = allTasks.where((t) => t.recurrenceGroupId == groupId && !DateTime(t.date.year, t.date.month, t.date.day).isBefore(from)).toList();
    await _applyEditToTasks(tasks, title: title, time: time, category: category, isFixed: isFixed, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  Future<void> _applyEditToTasks(List<Task> tasks, {
    required String title, String? time, required String category, required bool isFixed,
    required bool hasReminder, required int reminderOffset,
  }) async {
    for (final t in tasks) {
      t.title = title;
      t.time = time;
      t.category = category;
      t.isFixed = isFixed;
      t.hasReminder = hasReminder;
      t.reminderOffset = reminderOffset;
      t.updatedAt = DateTime.now();

      if (hasReminder && time != null) {
        final parts = time.split(':');
        final scheduleDateTime = DateTime(t.date.year, t.date.month, t.date.day, int.parse(parts[0]), int.parse(parts[1]));
        await NotificationService.scheduleTaskReminder(t.notificationId, title, scheduleDateTime, reminderOffset);
      } else {
        await NotificationService.cancelTaskReminder(t.notificationId);
      }
    }
    await saveTasks();
  }

  // Uygulama her açıldığında (loadData) çağrılır: rule bazlı her aktif seri için, en son
  // üretilmiş günden bugün+recurrenceWindowDays-1'e kadar eksik kalan günleri tamamlar.
  // Uygulama günlerce açılmasa bile pencere bir sonraki açılışta kendini toparlar.
  Future<void> _topUpRecurringWindow() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final windowEnd = todayOnly.add(Duration(days: recurrenceWindowDays - 1));

    final Map<String, List<Task>> groups = {};
    for (final t in allTasks) {
      if (t.recurrenceGroupId != null && t.recurrenceRule != null) {
        groups.putIfAbsent(t.recurrenceGroupId!, () => []).add(t);
      }
    }

    bool addedAny = false;
    int notifSeed = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

    for (final entry in groups.entries) {
      final groupTasks = entry.value;
      final template = groupTasks.last;
      final rule = template.recurrenceRule!;
      DateTime lastDate = groupTasks.map((t) => DateTime(t.date.year, t.date.month, t.date.day)).reduce((a, b) => a.isAfter(b) ? a : b);
      if (!lastDate.isBefore(windowEnd)) continue;

      DateTime cursor = lastDate.add(const Duration(days: 1));
      while (!cursor.isAfter(windowEnd)) {
        if (_ruleMatchesDate(rule, cursor)) {
          final nid = notifSeed++;
          final newTask = Task(
            id: '${DateTime.now().microsecondsSinceEpoch}_$nid',
            notificationId: nid,
            title: template.title, time: template.time, category: template.category, isFixed: template.isFixed,
            date: cursor,
            hasReminder: template.hasReminder, reminderOffset: template.reminderOffset,
            recurrenceRule: rule, recurrenceGroupId: entry.key,
          );
          allTasks.add(newTask);
          addedAny = true;
          if (newTask.hasReminder && newTask.time != null) {
            final parts = newTask.time!.split(':');
            final scheduleDateTime = DateTime(cursor.year, cursor.month, cursor.day, int.parse(parts[0]), int.parse(parts[1]));
            await NotificationService.scheduleTaskReminder(newTask.notificationId, newTask.title, scheduleDateTime, newTask.reminderOffset);
          }
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    if (addedAny) await saveTasks();
  }

  Future<void> clearAllData() async {
    allTasks.clear();
    await saveTasks();
    allMoods.clear();
    await saveMoods();
  }

  // Çıkış yapmadan ÖNCE çağrılır: bu TaskStore instance'ı uygulama boyunca tek
  // (main.dart'ta bir kez oluşturuluyor), aynı cihazda ikinci bir hesapla giriş
  // yapılırsa önceki hesabın yerel önbelleği (SharedPreferences) temizlenmezse
  // yeni hesabın verisiyle karışır. clearAllData()'dan farkı: burada Firestore'a
  // hiçbir şey push EDİLMİYOR — çıkan hesabın buluttaki verisi olduğu gibi kalır.
  Future<void> resetLocalStateOnSignOut() async {
    allTasks = [];
    allMoods = [];
    userName = 'Kullanıcı';
    userAvatar = '🚀';
    notificationTime = null;
    notificationStartDate = null;
    settingsUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

    await NotificationService.cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_tasks');
    await prefs.remove('saved_moods');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar');
    await prefs.remove('notification_time');
    await prefs.remove('notification_start_date');
    await prefs.remove('settings_updated_at');
    notifyListeners();
  }

  // Son [days] gün (bugün dahil) için yoğunluk kademesini tek geçişte hesaplar;
  // heatmap grid'inde gün başına ayrı ayrı getTasksForDate çağrısı yapmaktan kaçınır.
  Map<DateTime, int> getIntensityMapForLastDays(int days) {
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

  MoodEntry? getMoodForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final m in allMoods) {
      final d = DateTime(m.date.year, m.date.month, m.date.day);
      if (d == target) return m;
    }
    return null;
  }

  // Aynı güne ait kayıt varsa üzerine yazar (günde 1 mood kaydı kuralı).
  Future<void> saveMood(DateTime date, int score, {String? note}) async {
    final target = DateTime(date.year, date.month, date.day);
    allMoods.removeWhere((m) => DateTime(m.date.year, m.date.month, m.date.day) == target);
    allMoods.add(MoodEntry(date: target, score: score, note: note));
    await saveMoods();
  }

  Future<void> saveMoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_moods', jsonEncode(allMoods.map((m) => m.toJson()).toList()));
    notifyListeners();
    unawaited(FirestoreSyncService.pushMoods(List.of(allMoods)));
  }

  // Heatmap için: 0 = kayıt yok, 1-5 = mood skoru (kademe = skorun kendisi).
  Map<DateTime, int> getMoodIntensityMapForLastDays(int days) {
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
  String? getProductiveMoodEmoji() {
    final productiveScores = <int>[];
    for (final mood in allMoods) {
      if (getScoreForDate(mood.date) >= 75) productiveScores.add(mood.score);
    }
    if (productiveScores.isEmpty) return null;
    final avg = productiveScores.reduce((a, b) => a + b) / productiveScores.length;
    return moodEmojis[avg.round().clamp(1, 5) - 1];
  }

  Set<DateTime> get _completedDates {
    return allTasks.where((t) => t.isDone).map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet();
  }

  // Bugün henüz görev bitirilmemişse dünden geriye sayar (seri "risk altında" gösterilir ama kırılmış sayılmaz).
  int get currentStreak {
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

  int get longestStreak {
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

  bool get isStreakAtRisk {
    if (currentStreak == 0) return false;
    final now = DateTime.now();
    return !_completedDates.contains(DateTime(now.year, now.month, now.day));
  }

  Map<String, String> getDailyMotivation() {
    if (notificationStartDate == null) return motivationMessages[DateTime.now().day % motivationMessages.length];
    final now = DateTime.now();
    final startMidnight = DateTime(notificationStartDate!.year, notificationStartDate!.month, notificationStartDate!.day);
    final todayMidnight = DateTime(now.year, now.month, now.day);
    int diffDays = todayMidnight.difference(startMidnight).inDays;
    if (diffDays < 0) diffDays = 0;
    return motivationMessages[diffDays % motivationMessages.length];
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (pendingUserName != null) {
      userName = pendingUserName!;
      await prefs.setString('user_name', userName);
      pendingUserName = null;
    } else {
      userName = prefs.getString('user_name') ?? 'Kullanıcı';
    }
    userAvatar = prefs.getString('user_avatar') ?? '🚀';
    notificationTime = prefs.getString('notification_time');

    final settingsUpdatedAtStr = prefs.getString('settings_updated_at');
    settingsUpdatedAt = settingsUpdatedAtStr != null ? DateTime.parse(settingsUpdatedAtStr) : DateTime.fromMillisecondsSinceEpoch(0);

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
    notifyListeners();

    await _syncFromCloud();
    await _topUpRecurringWindow();
  }

  // Girişte tek seferlik buluttan çekme + last-write-wins birleştirme (roadmap Faz 5).
  // Sürekli dinleme (stream) YOK — sadece her uygulama açılışında bir kez çalışır.
  Future<void> _syncFromCloud() async {
    final results = await Future.wait([
      FirestoreSyncService.pullTasks(),
      FirestoreSyncService.pullMoods(),
      FirestoreSyncService.pullSettings(),
    ]);
    final cloudTasks = results[0] as List<Task>?;
    final cloudMoods = results[1] as List<MoodEntry>?;
    final cloudSettings = results[2] as Map<String, dynamic>?;

    bool changed = false;

    if (cloudTasks != null) {
      final byId = {for (final t in allTasks) t.id: t};
      for (final cloudTask in cloudTasks) {
        final localTask = byId[cloudTask.id];
        if (localTask == null || cloudTask.updatedAt.isAfter(localTask.updatedAt)) {
          byId[cloudTask.id] = cloudTask;
          changed = true;
        }
      }
      allTasks = byId.values.toList();
    }

    if (cloudMoods != null) {
      final byDate = {for (final m in allMoods) DateTime(m.date.year, m.date.month, m.date.day): m};
      for (final cloudMood in cloudMoods) {
        final key = DateTime(cloudMood.date.year, cloudMood.date.month, cloudMood.date.day);
        final localMood = byDate[key];
        if (localMood == null || cloudMood.updatedAt.isAfter(localMood.updatedAt)) {
          byDate[key] = cloudMood;
          changed = true;
        }
      }
      allMoods = byDate.values.toList();
    }

    if (cloudSettings != null) {
      final cloudUpdatedAtStr = cloudSettings['updatedAt'] as String?;
      final cloudUpdatedAt = cloudUpdatedAtStr != null ? DateTime.parse(cloudUpdatedAtStr) : null;
      if (cloudUpdatedAt != null && cloudUpdatedAt.isAfter(settingsUpdatedAt)) {
        userName = cloudSettings['userName'] as String? ?? userName;
        userAvatar = cloudSettings['userAvatar'] as String? ?? userAvatar;
        notificationTime = cloudSettings['notificationTime'] as String?;
        final cloudStartDateStr = cloudSettings['notificationStartDate'] as String?;
        notificationStartDate = cloudStartDateStr != null ? DateTime.parse(cloudStartDateStr) : null;
        settingsUpdatedAt = cloudUpdatedAt;
        changed = true;
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_tasks', jsonEncode(allTasks.map((t) => t.toJson()).toList()));
      await prefs.setString('saved_moods', jsonEncode(allMoods.map((m) => m.toJson()).toList()));
      await prefs.setString('user_name', userName);
      await prefs.setString('user_avatar', userAvatar);
      if (notificationTime != null) {
        await prefs.setString('notification_time', notificationTime!);
      } else {
        await prefs.remove('notification_time');
      }
      if (notificationStartDate != null) {
        await prefs.setString('notification_start_date', notificationStartDate!.toIso8601String());
      } else {
        await prefs.remove('notification_start_date');
      }
      await prefs.setString('settings_updated_at', settingsUpdatedAt.toIso8601String());
      notifyListeners();
    }

    // Birleşmiş sonucu buluta geri yansıt ki iki taraf da yakınsasın.
    unawaited(FirestoreSyncService.pushTasks(List.of(allTasks)));
    unawaited(FirestoreSyncService.pushMoods(List.of(allMoods)));
  }

  Map<String, dynamic> _settingsJson() => {
        'userName': userName,
        'userAvatar': userAvatar,
        'notificationTime': notificationTime,
        'notificationStartDate': notificationStartDate?.toIso8601String(),
        'updatedAt': settingsUpdatedAt.toIso8601String(),
      };

  Future<void> _persistSettingsUpdatedAt() async {
    settingsUpdatedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_updated_at', settingsUpdatedAt.toIso8601String());
    unawaited(FirestoreSyncService.pushSettings(_settingsJson()));
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_tasks', jsonEncode(allTasks.map((t) => t.toJson()).toList()));
    notifyListeners();
    unawaited(FirestoreSyncService.pushTasks(List.of(allTasks)));
  }

  Future<void> saveUserName(String name) async {
    userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
    await _persistSettingsUpdatedAt();
  }

  Future<void> saveAvatar(String avatar) async {
    userAvatar = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar', avatar);
    notifyListeners();
    await _persistSettingsUpdatedAt();
  }

  Future<void> saveNotificationTime(String? time) async {
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
    notifyListeners();
    await _persistSettingsUpdatedAt();
  }
}

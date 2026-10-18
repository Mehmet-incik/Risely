import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/mood_entry.dart';
import '../models/focus_session.dart';
import 'firestore_sync_service.dart';
import 'motivation_messages.dart';
import 'notification_service.dart';

class TaskStore extends ChangeNotifier {
  List<Task> allTasks = [];
  List<MoodEntry> allMoods = [];
  List<FocusSession> allFocusSessions = [];
  String userName = 'Kullanıcı';
  String userAvatar = '🚀';
  String? notificationTime;
  DateTime? notificationStartDate;
  DateTime settingsUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  String? pendingUserName;

  static const List<String> moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
  static const List<String> moodLabels = ['kötü', 'fena değil', 'idare eder', 'iyi', 'harika'];

  static const int recurrenceWindowDays = 60;

  static String getTodayLabel() {
    final now = DateTime.now();
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  int get totalXp => (allTasks.where((t) => t.isDone).length * 15) + (allFocusSessions.length * 25);

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

  int getIntensityLevel(DateTime date) {
    final tasks = getTasksForDate(date);
    if (tasks.isEmpty) return 0;
    final score = getScoreForDate(date);
    if (score <= 25) return 1;
    if (score <= 50) return 2;
    if (score <= 75) return 3;
    return 4;
  }

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

  // --- FOCUS SESSION (FAZ 6) ---
  Future<void> addFocusSession({required int durationMinutes, String? taskId, String? taskTitle}) async {
    final session = FocusSession(
      id: 'focus_${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      taskId: taskId,
      taskTitle: taskTitle,
    );
    allFocusSessions.add(session);
    await saveFocusSessions();
  }

  Future<void> saveFocusSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_focus_sessions', jsonEncode(allFocusSessions.map((s) => s.toJson()).toList()));
    notifyListeners();
    unawaited(FirestoreSyncService.pushFocusSessions(List.of(allFocusSessions)));
  }

  int get weeklyFocusMinutes {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final startOfWeek = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    int total = 0;
    for (final s in allFocusSessions) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      if (!d.isBefore(startOfWeek) && !d.isAfter(todayOnly)) {
        total += s.durationMinutes;
      }
    }
    return total;
  }

  int get weeklyFocusSessionCount {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final startOfWeek = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    return allFocusSessions.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(startOfWeek) && !d.isAfter(todayOnly);
    }).length;
  }

  bool _ruleMatchesDate(String rule, DateTime date) {
    final weekday = date.weekday;
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

  List<Task> addRecurringTaskSeries({
    required String title, String? time, required String category, required bool isFixed,
    required DateTime startDate, required String recurrenceRule, bool hasReminder = false, int reminderOffset = 0,
  }) {
    final dates = _datesForRule(startDate, recurrenceRule, recurrenceWindowDays);
    return _createSeries(title: title, time: time, category: category, isFixed: isFixed, dates: dates, recurrenceRule: recurrenceRule, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  List<Task> addBulkTaskSeries({
    required String title, String? time, required String category, required bool isFixed,
    required List<DateTime> dates, bool hasReminder = false, int reminderOffset = 0,
  }) {
    return _createSeries(title: title, time: time, category: category, isFixed: isFixed, dates: dates, recurrenceRule: null, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

  Future<void> deleteTaskSeries(String groupId) async {
    final toDelete = allTasks.where((t) => t.recurrenceGroupId == groupId).toList();
    for (final t in toDelete) {
      if (t.hasReminder) NotificationService.cancelTaskReminder(t.notificationId);
    }
    allTasks.removeWhere((t) => t.recurrenceGroupId == groupId);
    await saveTasks();
  }

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

  Future<void> editTaskSeries(String groupId, {
    required String title, String? time, required String category, required bool isFixed,
    required bool hasReminder, required int reminderOffset,
  }) async {
    final tasks = allTasks.where((t) => t.recurrenceGroupId == groupId).toList();
    await _applyEditToTasks(tasks, title: title, time: time, category: category, isFixed: isFixed, hasReminder: hasReminder, reminderOffset: reminderOffset);
  }

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
    allFocusSessions.clear();
    await saveFocusSessions();
  }

  Future<void> resetLocalStateOnSignOut() async {
    allTasks = [];
    allMoods = [];
    allFocusSessions = [];
    userName = 'Kullanıcı';
    userAvatar = '🚀';
    notificationTime = null;
    notificationStartDate = null;
    settingsUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

    await NotificationService.cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_tasks');
    await prefs.remove('saved_moods');
    await prefs.remove('saved_focus_sessions');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar');
    await prefs.remove('notification_time');
    await prefs.remove('notification_start_date');
    await prefs.remove('settings_updated_at');
    notifyListeners();
  }

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

    final String? focusJson = prefs.getString('saved_focus_sessions');
    if (focusJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(focusJson);
        allFocusSessions = decoded.map((item) => FocusSession.fromJson(item)).toList();
      } catch (e) {
        allFocusSessions = [];
      }
    } else {
      allFocusSessions = [];
    }

    notifyListeners();

    await _syncFromCloud();
    await _topUpRecurringWindow();
  }

  Future<void> _syncFromCloud() async {
    final results = await Future.wait([
      FirestoreSyncService.pullTasks(),
      FirestoreSyncService.pullMoods(),
      FirestoreSyncService.pullSettings(),
      FirestoreSyncService.pullFocusSessions(),
    ]);
    final cloudTasks = results[0] as List<Task>?;
    final cloudMoods = results[1] as List<MoodEntry>?;
    final cloudSettings = results[2] as Map<String, dynamic>?;
    final cloudFocus = results[3] as List<FocusSession>?;

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

    if (cloudFocus != null) {
      final byId = {for (final s in allFocusSessions) s.id: s};
      for (final cloudSession in cloudFocus) {
        final localSession = byId[cloudSession.id];
        if (localSession == null || cloudSession.updatedAt.isAfter(localSession.updatedAt)) {
          byId[cloudSession.id] = cloudSession;
          changed = true;
        }
      }
      allFocusSessions = byId.values.toList();
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
      await prefs.setString('saved_focus_sessions', jsonEncode(allFocusSessions.map((s) => s.toJson()).toList()));
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

    unawaited(FirestoreSyncService.pushTasks(List.of(allTasks)));
    unawaited(FirestoreSyncService.pushMoods(List.of(allMoods)));
    unawaited(FirestoreSyncService.pushFocusSessions(List.of(allFocusSessions)));
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
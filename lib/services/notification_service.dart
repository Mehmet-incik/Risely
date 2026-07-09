import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'motivation_messages.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

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

  static Future<void> scheduleMorningMotivation(int hour, int minute, String userName) async {
    for(int i=0; i<60; i++) { await _notifications.cancel(i); }

    final local = tz.local;
    final now = tz.TZDateTime.now(local);
    int dayOffset = tz.TZDateTime(local, now.year, now.month, now.day, hour, minute).isBefore(now) ? 1 : 0;

    for (int i = 0; i < 60; i++) {
      final scheduledDate = tz.TZDateTime(local, now.year, now.month, now.day, hour, minute).add(Duration(days: i + dayOffset));
      final msg = motivationMessages[i % motivationMessages.length];
      await _notifications.zonedSchedule(
        i,
        "${msg['icon']} ${msg['greeting']}, $userName",
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
    final msg = motivationMessages[0];
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

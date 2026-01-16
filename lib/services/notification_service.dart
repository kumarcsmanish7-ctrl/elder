import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print("🚀 Background Notification Action: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}");
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'daily_reminder_channel_v4';
  static const String channelName = 'Daily Reminders (High Priority)';
  static const String channelDescription = 'Crucial reminders for meals and medicines';

  // Stream to notify the app about notification actions
  static final StreamController<NotificationResponse> onNotifications = StreamController<NotificationResponse>.broadcast();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      print("🌍 DETECTED TIMEZONE: $timeZoneName");
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("⚠️ Error getting local timezone, using Utc: $e");
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("📱 FOREGROUND Notification Action Clicked: ${response.actionId} with payload: ${response.payload}");
        _handleAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Check if app was launched from a notification intent
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        if (launchDetails?.notificationResponse != null) {
          final res = launchDetails!.notificationResponse!;
          print("🚀 ALARM LAUNCH DETECTED: ${res.actionId} | Payload: ${res.payload}");
          
          // Process with enough delay to allow Provider and TTS to initialize
          Future.delayed(const Duration(milliseconds: 2500), () {
            _handleAction(res);
          });
        }
      }
    } catch (e) {
      print("⚠️ Error checking launch details: $e");
    }

    await _createNotificationChannel();
    await _requestPermissions();
  }

  void _handleAction(NotificationResponse response) async {
    print("🔔 _handleAction called with actionId: ${response.actionId}, payload: ${response.payload}");
    
    // CRITICAL: Trigger voice IMMEDIATELY for any notification response
    // This fires when notification arrives, not just when tapped
    onNotifications.add(response);

    if (response.actionId == 'snooze') {
      if (response.payload != null) {
        final int id = int.tryParse(response.payload!) ?? 0;
        await _snoozeReminder(id);
      }
    }
  }


  String getNiceMessage(String type, {String? reminderId}) {
    if (type == 'Medicines') {
      final List<String> medMessages = [
        "Time for your strength ritual! Please take your medicines. 💪💊",
        "Staying consistent with your health is key. Meds time! ✨💊",
        "Focus on yourself today. It's time for your medication. 🌸💊",
        "A small step for health: don't forget your medicine! ❤️💊",
      ];
      return medMessages[Random().nextInt(medMessages.length)];
    }

    if (reminderId == 'wake') return "Rise and shine, morning sunshine! Time to conquer the day! ☀️🌈";
    if (reminderId == 'breakfast') return "Mornin'! Time for a healthy, delicious breakfast. Enjoy! 🍳🍎";
    if (reminderId == 'lunch') return "Good afternoon! Fuel your body with a tasty lunch. 🥗🍱";
    if (reminderId == 'walk') return "A refreshing walk is good for the soul. Let's step out! 🚶🌲";
    if (reminderId == 'dinner') return "Good evening! Time for a lovely dinner and some rest. ❤️🍛";
    if (reminderId == 'sleep') return "You've done so well today. Sweet dreams! 🌙⏰";

    return "Stay healthy and have a beautiful day! ✨😊";
  }
  
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    
    // Request Exact Alarm permission (Android 12+)
    try {
      final bool? granted = await androidPlugin?.requestExactAlarmsPermission();
      print("🔔 Exact Alarm Permission: $granted");
    } catch (e) {
      print("⚠️ Could not request exact alarm permission: $e");
    }
  }

  Future<void> _snoozeReminder(int originalId) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      originalId + 5000, 
      'Snoozed Reminder ⏰',
      'This is your 15-minute gentle reminder.',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15)),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      final tz.TZDateTime nextTime = _nextInstanceOfTime(hour, minute);
      
      print("🔔 Scheduling ID:$id for $nextTime (EXACT)");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        nextTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: id.toString(),
      );
    } catch (e) {
      print("❌ ERROR Scheduling Notification ID:$id : $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _createNotificationChannel();
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(''),
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('done', 'DONE ✅', showsUserInterface: true),
          AndroidNotificationAction('snooze', 'SNOOZE ⏰', showsUserInterface: true),
        ],
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
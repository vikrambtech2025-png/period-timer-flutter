import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../constants.dart';
import '../models/schedule.dart';

class AlarmService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    const channel = AndroidNotificationChannel(
      'period-alarms-v4',
      'Period Alarms',
      description: 'Buzzer alarms for period starts',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('buzzer'),
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> requestExactAlarm() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  Future<bool> isExactAlarmGranted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<int> scheduleAll(Schedule schedule) async {
    await init();
    await _plugin.cancelAll();
    int count = 0;
    const dayToWeekday = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
    };
    for (final day in days) {
      final weekday = dayToWeekday[day]!;
      final entries = schedule.timetable[day] ?? [];
      for (var i = 0; i < schedule.periods.length; i++) {
        final pt = schedule.periods[i];
        final parts = pt.time.split('-');
        if (parts.length < 2) continue;
        final start = parts[0].trim();
        final hm = start.split(':');
        if (hm.length != 2) continue;
        final h = int.tryParse(hm[0]);
        final m = int.tryParse(hm[1]);
        if (h == null || m == null) continue;
        final entry = (i < entries.length) ? entries[i] : null;
        final subject = (entry?.subject ?? '').trim();
        final name = pt.name.isEmpty ? 'Period ${pt.period}' : pt.name;
        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        // advance to the right weekday
        while (scheduled.weekday != weekday) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        await _plugin.zonedSchedule(
          (day.hashCode * 31 + pt.period) & 0x7fffffff,
          'Period ${pt.period}: $name',
          '$day - ${subject.isEmpty ? "No subject" : subject} - ${pt.time}',
          scheduled,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'period-alarms-v4',
              'Period Alarms',
              channelDescription: 'Buzzer alarms for period starts',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('buzzer'),
              playSound: true,
              enableVibration: true,
              fullScreenIntent: false,
            ),
            iOS: const DarwinNotificationDetails(sound: 'buzzer.wav'),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        count++;
      }
    }
    return count;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Schedule a one-shot test alarm 1 minute from now.
  Future<void> scheduleTestAlarm() async {
    await init();
    final now = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    await _plugin.zonedSchedule(
      999999,
      'Test Alarm',
      'This is a test alarm. If you see this, alarms work!',
      now,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'period-alarms-v4',
          'Period Alarms',
          channelDescription: 'Buzzer alarms for period starts',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('buzzer'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(sound: 'buzzer.wav'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
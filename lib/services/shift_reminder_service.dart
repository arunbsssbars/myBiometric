import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models/shift_schedule.dart';

/// Service responsible for scheduling proactive automated local notifications
/// reminding employees of upcoming shift start times and post-shift clock-out requirements.
class ShiftReminderService {
  static final ShiftReminderService _instance = ShiftReminderService._internal();
  factory ShiftReminderService() => _instance;
  ShiftReminderService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const int shiftInNotificationId = 1001;
  static const int shiftOutNotificationId = 1002;

  static const String channelId = 'shift_reminders_channel';
  static const String channelName = 'Shift Clock-In & Clock-Out Reminders';
  static const String channelDescription =
      'Alerts employees before scheduled shifts and reminds them to clock out.';

  bool _isTzInitialized = false;

  /// Initializes timezone database for local schedule precision.
  Future<void> _ensureTimeZonesInitialized() async {
    if (!_isTzInitialized) {
      try {
        tz.initializeTimeZones();
        _isTzInitialized = true;
      } catch (e) {
        debugPrint("ShiftReminderService TZ init error: $e");
      }
    }
  }

  NotificationDetails _getNotificationDetails({required String subText}) {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    return const NotificationDetails(android: androidDetails);
  }

  /// Calculates the next occurrence of a target hour and minute in the local timezone.
  tz.TZDateTime calculateNextScheduleTime({
    required int hour,
    required int minute,
    int offsetMinutes = 0,
    tz.Location? location,
  }) {
    final loc = location ?? tz.local;
    final now = tz.TZDateTime.now(loc);

    var scheduledDate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(minutes: offsetMinutes));

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules daily recurring shift reminders based on the employee's assigned [ShiftSchedule].
  ///
  /// - Shift In: 15 minutes before shift start.
  /// - Shift Out: 10 minutes after scheduled shift end.
  Future<void> scheduleShiftReminders({
    required ShiftSchedule schedule,
    String companyName = 'Office',
  }) async {
    try {
      await _ensureTimeZonesInitialized();

      // 1. Calculate Shift Start Reminder (15 mins prior)
      final shiftInTime = calculateNextScheduleTime(
        hour: schedule.startHour,
        minute: schedule.startMinute,
        offsetMinutes: -15,
      );

      final inDetails = _getNotificationDetails(subText: 'Shift Starting');
      await _localNotifications.zonedSchedule(
        shiftInNotificationId,
        '⏰ Shift Starts in 15 Minutes',
        'Your shift at $companyName begins at ${schedule.startTimeFormatted}. Remember to clock in on arrival.',
        shiftInTime,
        inDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. Calculate Shift End Reminder (10 mins after scheduled end)
      final shiftOutTime = calculateNextScheduleTime(
        hour: schedule.endHour,
        minute: schedule.endMinute,
        offsetMinutes: 10,
      );

      final outDetails = _getNotificationDetails(subText: 'Shift Ending');
      await _localNotifications.zonedSchedule(
        shiftOutNotificationId,
        '🏁 Shift Ended - Clock Out Reminder',
        'Your scheduled shift ended at ${schedule.endTimeFormatted}. Don\'t forget to clock out to close your shift.',
        shiftOutTime,
        outDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        'Shift reminders scheduled: IN @ ${shiftInTime.toIso8601String()}, OUT @ ${shiftOutTime.toIso8601String()}',
      );
    } catch (e) {
      debugPrint('Error scheduling shift reminders: $e');
    }
  }

  /// Cancels upcoming shift-in notification once the employee has clocked in today.
  Future<void> cancelShiftInReminder() async {
    try {
      await _localNotifications.cancel(shiftInNotificationId);
      debugPrint('Cancelled Shift-In reminder (employee clocked in).');
    } catch (e) {
      debugPrint('Error cancelling shift-in reminder: $e');
    }
  }

  /// Cancels shift-out reminder once the employee has clocked out today.
  Future<void> cancelShiftOutReminder() async {
    try {
      await _localNotifications.cancel(shiftOutNotificationId);
      debugPrint('Cancelled Shift-Out reminder (employee clocked out).');
    } catch (e) {
      debugPrint('Error cancelling shift-out reminder: $e');
    }
  }

  /// Cancels all shift-related reminders (e.g. on logout or leave approval).
  Future<void> cancelAllShiftReminders() async {
    try {
      await _localNotifications.cancel(shiftInNotificationId);
      await _localNotifications.cancel(shiftOutNotificationId);
      debugPrint('Cancelled all active shift reminders.');
    } catch (e) {
      debugPrint('Error cancelling all shift reminders: $e');
    }
  }
}

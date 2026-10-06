import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized utility consolidating date, timestamp, duration, and color formatting.
/// Adheres strictly to the ACHS (Autonomous Code Hygiene & Security) DRY standard.
class AppFormatUtils {
  /// Safely parses various timestamp representations (Timestamp, DateTime, String, int) into DateTime.
  static DateTime parseTimestamp(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return fallback ?? DateTime.now();
  }

  /// Formats DateTime into standard 12-hour AM/PM string (e.g., "09:30 AM")
  static String formatTimeAmPm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  /// Formats explicit hour and minute integers into 12-hour AM/PM string
  static String formatHourMinuteAmPm(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  /// Safely parses a hex color string into a Flutter Color with null-safe fallback
  static Color parseHexColor(
    String? hex, {
    Color fallback = const Color(0xFF2563EB),
  }) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final intVal = int.tryParse('0xFF$clean');
      if (intVal != null) return Color(intVal);
    } else if (clean.length == 8) {
      final intVal = int.tryParse('0x$clean');
      if (intVal != null) return Color(intVal);
    }
    return fallback;
  }

  /// Formats total minutes into human-readable hours string (e.g., "8.5 hrs" or "8 hrs 30 mins")
  static String formatMinutesToHours(int totalMinutes, {bool compact = false}) {
    if (compact) {
      final h = (totalMinutes / 60.0).toStringAsFixed(1);
      return '$h hrs';
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m > 0) return '$h hrs $m mins';
    return '$h hrs';
  }

  /// Formats DateTime into readable date string (e.g. "Oct 04, 2026" or "2026-10-04")
  static String formatDate(DateTime dt, {bool compact = false}) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (compact) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  /// Formats TimeOfDay into standard 12-hour AM/PM string (e.g. "09:30 AM")
  static String formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour % 12 == 0 ? 12 : tod.hour % 12;
    final m = tod.minute.toString().padLeft(2, '0');
    final ampm = tod.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

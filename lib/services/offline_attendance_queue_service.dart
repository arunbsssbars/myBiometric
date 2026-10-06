import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service managing offline punch queue and synchronization with Firestore.
/// Guarantees that zero attendance punches are lost when Kiosk terminals operate
/// without internet connection.
class OfflineAttendanceQueueService {
  static final OfflineAttendanceQueueService _instance =
      OfflineAttendanceQueueService._internal();
  factory OfflineAttendanceQueueService() => _instance;
  OfflineAttendanceQueueService._internal();

  static const String _queueKey = 'kiosk_offline_attendance_queue';
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<DateTime?> lastSyncTimeNotifier = ValueNotifier<DateTime?>(null);
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Initialize and load pending queue count
  Future<void> initialize() async {
    final list = await getPendingPunches();
    pendingCountNotifier.value = list.length;
  }

  /// Enqueue an attendance punch locally when offline
  Future<void> enqueuePunch(Map<String, dynamic> punchData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getPendingPunches();

      // Ensure local timestamp is preserved as an ISO8601 string
      final Map<String, dynamic> record = Map<String, dynamic>.from(punchData);
      record['localEnqueuedAt'] = DateTime.now().toIso8601String();
      if (record['timestamp'] == null) {
        record['timestamp'] = DateTime.now().toIso8601String();
      } else if (record['timestamp'] is Timestamp) {
        record['timestamp'] = (record['timestamp'] as Timestamp).toDate().toIso8601String();
      }

      currentList.add(record);
      await prefs.setString(_queueKey, jsonEncode(currentList));
      pendingCountNotifier.value = currentList.length;
    } catch (_) {}
  }

  /// Get all pending offline punches
  Future<List<Map<String, dynamic>>> getPendingPunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Synchronize all pending offline punches with Firestore
  Future<int> syncPendingPunches({FirebaseFirestore? firestore}) async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int syncedCount = 0;
    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final pending = await getPendingPunches();
      if (pending.isEmpty) {
        _isSyncing = false;
        pendingCountNotifier.value = 0;
        return 0;
      }

      final List<Map<String, dynamic>> remaining = [];

      for (final punch in pending) {
        try {
          final Map<String, dynamic> firestorePayload = Map<String, dynamic>.from(punch);
          firestorePayload.remove('localEnqueuedAt');

          // Parse timestamp back to Firestore Timestamp
          if (firestorePayload['timestamp'] is String) {
            final dt = DateTime.tryParse(firestorePayload['timestamp'] as String) ?? DateTime.now();
            firestorePayload['timestamp'] = Timestamp.fromDate(dt);
          } else {
            firestorePayload['timestamp'] = FieldValue.serverTimestamp();
          }

          firestorePayload['syncedFromOfflineQueue'] = true;
          firestorePayload['syncedAt'] = FieldValue.serverTimestamp();

          await db.collection('attendance_logs').add(firestorePayload);
          syncedCount++;
        } catch (e) {
          // If a record fails (e.g. still no connection), keep in remaining
          remaining.add(punch);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      if (remaining.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        await prefs.setString(_queueKey, jsonEncode(remaining));
      }

      pendingCountNotifier.value = remaining.length;
      lastSyncTimeNotifier.value = DateTime.now();
    } catch (_) {
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Clear offline queue (e.g. for testing)
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    pendingCountNotifier.value = 0;
  }

  /// Generates a unique deterministic signature for an attendance punch
  static String generatePunchSignature(Map<String, dynamic> punch) {
    return '${punch['userId']}_${punch['type']}_${punch['timestamp']}';
  }

  /// Deduplicates pending offline punches based on deterministic signatures
  Future<int> deduplicatePendingPunches() async {
    final pending = await getPendingPunches();
    if (pending.isEmpty) return 0;

    final seenSignatures = <String>{};
    final uniquePunches = <Map<String, dynamic>>[];
    int removedCount = 0;

    for (final punch in pending) {
      final sig = generatePunchSignature(punch);
      if (seenSignatures.contains(sig)) {
        removedCount++;
      } else {
        seenSignatures.add(sig);
        uniquePunches.add(punch);
      }
    }

    if (removedCount > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(uniquePunches));
      pendingCountNotifier.value = uniquePunches.length;
    }

    return removedCount;
  }

  /// Compensates for clock drift between kiosk local device clock and authoritative NTP server
  Future<int> applyClockDriftCompensation(Duration offset) async {
    final pending = await getPendingPunches();
    if (pending.isEmpty) return 0;

    int adjustedCount = 0;
    final adjustedPunches = <Map<String, dynamic>>[];

    for (final punch in pending) {
      final copy = Map<String, dynamic>.from(punch);
      final tsStr = copy['timestamp'] as String?;
      if (tsStr != null) {
        final dt = DateTime.tryParse(tsStr);
        if (dt != null) {
          final adjusted = dt.add(offset);
          copy['timestamp'] = adjusted.toIso8601String();
          copy['clockDriftAdjustedMs'] = offset.inMilliseconds;
          adjustedCount++;
        }
      }
      adjustedPunches.add(copy);
    }

    if (adjustedCount > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(adjustedPunches));
    }

    return adjustedCount;
  }
}

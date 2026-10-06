import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';

/// Result summary of terminal event normalization and sync processing.
class TerminalSyncResult {
  final int totalReceived;
  final int normalizedCount;
  final int duplicateCount;
  final int unmappedEmployeeCount;
  final List<String> errors;

  const TerminalSyncResult({
    required this.totalReceived,
    required this.normalizedCount,
    required this.duplicateCount,
    required this.unmappedEmployeeCount,
    this.errors = const [],
  });
}

/// Service responsible for normalizing raw external biometric punches into
/// standard enterprise attendance logs, deduplicating double swipes, and saving to Firestore.
class TerminalAttendanceSyncService {
  final FirebaseFirestore _firestore;

  TerminalAttendanceSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Normalizes a batch of terminal attendance events against enterprise employees.
  Future<TerminalSyncResult> processAndPersistEvents({
    required String enterpriseId,
    required BiometricTerminalDevice device,
    required List<TerminalAttendanceEvent> events,
    int doubleSwipeThresholdSeconds = 120,
  }) async {
    if (events.isEmpty) {
      return const TerminalSyncResult(
        totalReceived: 0,
        normalizedCount: 0,
        duplicateCount: 0,
        unmappedEmployeeCount: 0,
      );
    }

    int normalized = 0;
    int duplicates = 0;
    int unmapped = 0;
    final errors = <String>[];

    try {
      // 1. Load enterprise employee mappings: employeeId -> (userId, fullName)
      final empSnapshot = await _firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('employees')
          .get();

      final idToEmpMap = <String, Map<String, dynamic>>{};
      for (final doc in empSnapshot.docs) {
        final data = doc.data();
        final empId = (data['employeeId'] ?? doc.id).toString().trim().toUpperCase();
        idToEmpMap[empId] = {
          'docId': doc.id,
          'fullName': data['fullName'] ?? data['name'] ?? 'Employee',
          'userId': data['userId'] ?? data['uid'] ?? doc.id,
        };
      }

      // 2. Fetch latest logs to check duplicate rapid swipes
      final recentLogsSnapshot = await _firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('attendance_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final recentPunches = <String, DateTime>{};
      for (final doc in recentLogsSnapshot.docs) {
        final data = doc.data();
        final eId = data['employeeId']?.toString().toUpperCase();
        final ts = data['timestamp'];
        DateTime? dt;
        if (ts is Timestamp) {
          dt = ts.toDate();
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        if (eId != null && dt != null) {
          recentPunches.putIfAbsent(eId, () => dt!);
        }
      }

      final batch = _firestore.batch();
      final logsCollection = _firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('attendance_logs');

      for (final event in events) {
        final normalizedEmpId = event.employeeId.trim().toUpperCase();
        final empInfo = idToEmpMap[normalizedEmpId];

        if (empInfo == null) {
          unmapped++;
          continue;
        }

        // Deduplication check
        final lastPunch = recentPunches[normalizedEmpId];
        if (lastPunch != null) {
          final diff = event.timestamp.difference(lastPunch).inSeconds.abs();
          if (diff < doubleSwipeThresholdSeconds) {
            duplicates++;
            continue;
          }
        }

        final logDoc = logsCollection.doc();
        final rootLogDoc = _firestore.collection('attendance_logs').doc(logDoc.id);

        final logData = {
          'id': logDoc.id,
          'userId': empInfo['userId'],
          'employeeId': normalizedEmpId,
          'employeeName': empInfo['fullName'],
          'enterpriseId': enterpriseId,
          'type': event.punchType,
          'timestamp': Timestamp.fromDate(event.timestamp),
          'verifiedVia': 'DEVICE_TERMINAL',
          'punchStatus': 'ON_TIME',
          'authMode': event.authMode.name,
          'terminalDeviceId': device.id,
          'terminalName': device.name,
          'terminalModel': device.modelName,
          'externalEventId': event.eventId,
          'similarityScore': event.similarityScore,
          'createdAt': FieldValue.serverTimestamp(),
        };

        batch.set(logDoc, logData);
        batch.set(rootLogDoc, logData);

        recentPunches[normalizedEmpId] = event.timestamp;
        normalized++;
      }

      if (normalized > 0) {
        // Update device stats
        final deviceDoc = _firestore
            .collection('enterprises')
            .doc(enterpriseId)
            .collection('terminals')
            .doc(device.id);

        batch.update(deviceDoc, {
          'lastSyncAt': FieldValue.serverTimestamp(),
          'totalEventsSynced': FieldValue.increment(normalized),
          'status': DeviceConnectionStatus.online.name,
        });

        await batch.commit();
      }

      return TerminalSyncResult(
        totalReceived: events.length,
        normalizedCount: normalized,
        duplicateCount: duplicates,
        unmappedEmployeeCount: unmapped,
        errors: errors,
      );
    } catch (e) {
      errors.add(e.toString());
      return TerminalSyncResult(
        totalReceived: events.length,
        normalizedCount: normalized,
        duplicateCount: duplicates,
        unmappedEmployeeCount: unmapped,
        errors: errors,
      );
    }
  }

  /// Pure deterministic function for testing deduplication and mapping logic.
  static List<TerminalAttendanceEvent> filterDuplicateEvents(
    List<TerminalAttendanceEvent> events, {
    int doubleSwipeThresholdSeconds = 120,
  }) {
    final clean = <TerminalAttendanceEvent>[];
    final lastSeen = <String, DateTime>{};

    for (final e in events) {
      final key = '${e.employeeId.toUpperCase()}_${e.punchType}';
      final prev = lastSeen[key];
      if (prev != null) {
        final diff = e.timestamp.difference(prev).inSeconds.abs();
        if (diff < doubleSwipeThresholdSeconds) {
          continue; // skip duplicate rapid punch
        }
      }
      clean.add(e);
      lastSeen[key] = e.timestamp;
    }
    return clean;
  }
}

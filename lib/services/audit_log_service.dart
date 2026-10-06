import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Service responsible for recording and querying immutable enterprise audit logs
/// for compliance, security event auditing, and administrative transparency.
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Standardized Categories
  static const String categorySecurity = 'SECURITY';
  static const String categoryPolicy = 'POLICY';
  static const String categoryAttendance = 'ATTENDANCE';
  static const String categoryApprovals = 'APPROVALS';
  static const String categoryStaff = 'STAFF';

  // Standardized Action Names
  static const String actionPinChanged = 'PIN_CHANGED';
  static const String actionKioskUnlocked = 'KIOSK_UNLOCKED';
  static const String actionShiftPolicyUpdated = 'SHIFT_POLICY_UPDATED';
  static const String actionGeofenceUpdated = 'GEOFENCE_UPDATED';
  static const String actionWifiPolicyUpdated = 'WIFI_POLICY_UPDATED';
  static const String actionPolicyUpdated = 'POLICY_UPDATED';
  static const String actionRegularizationApproved = 'REGULARIZATION_APPROVED';
  static const String actionRegularizationRejected = 'REGULARIZATION_REJECTED';
  static const String actionLeaveApproved = 'LEAVE_APPROVED';
  static const String actionLeaveRejected = 'LEAVE_REJECTED';
  static const String actionBiometricReset = 'BIOMETRIC_RESET';
  static const String actionStaffAdded = 'STAFF_ADDED';
  static const String actionStaffRemoved = 'STAFF_REMOVED';
  static const String actionManualAttendanceOverride = 'MANUAL_ATTENDANCE_OVERRIDE';
  static const String actionDailyReconciliationRun = 'DAILY_RECONCILIATION_RUN';

  /// Records an immutable audit log entry under `enterprises/{enterpriseId}/audit_logs`.
  Future<void> logAction({
    required String enterpriseId,
    required String action,
    required String details,
    String category = categorySecurity,
    String? targetEmployeeId,
    String? targetEmployeeName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = AuthService().currentUser;
      final adminUid = user?.uid ?? 'system';
      final adminEmail = user?.email ?? 'System / Kiosk Terminal';

      final Map<String, dynamic> data = {
        'action': action,
        'category': category,
        'details': details,
        'adminUid': adminUid,
        'adminEmail': adminEmail,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (targetEmployeeId != null && targetEmployeeId.isNotEmpty) {
        data['targetEmployeeId'] = targetEmployeeId;
      }
      if (targetEmployeeName != null && targetEmployeeName.isNotEmpty) {
        data['targetEmployeeName'] = targetEmployeeName;
      }
      if (metadata != null) {
        data['metadata'] = metadata;
      }

      await _firestore
          .collection('enterprises')
          .doc(enterpriseId.trim())
          .collection('audit_logs')
          .add(data);

      debugPrint('Audit log recorded: $action ($category) for enterprise: $enterpriseId');
    } catch (e) {
      debugPrint('Failed to record audit log: $e');
      // Do not rethrow in production to prevent administrative flow blocks
    }
  }

  /// Streams real-time audit logs for an enterprise ordered newest first.
  Stream<List<QueryDocumentSnapshot>> streamAuditLogs(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId.trim())
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Generates a structured CSV representation of audit logs (pure function for easy unit testing).
  static String generateAuditCsv(List<Map<String, dynamic>> logs) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Action,Category,Admin Email,Target Employee,Details');

    for (final log in logs) {
      final ts = log['timestamp']?.toString() ?? '';
      final action = log['action']?.toString() ?? '';
      final category = log['category']?.toString() ?? '';
      final adminEmail = log['adminEmail']?.toString() ?? '';

      final target = log['targetEmployeeName'] != null
          ? '${log['targetEmployeeName']} (${log['targetEmployeeId'] ?? ''})'
          : (log['targetEmployeeId']?.toString() ?? 'N/A');

      final details = (log['details']?.toString() ?? '').replaceAll('"', '""');

      buffer.writeln('"$ts","$action","$category","$adminEmail","$target","$details"');
    }

    return buffer.toString();
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/shift_schedule.dart';
import 'admin_pin_service.dart';
import 'push_notification_service.dart';
import 'shift_evaluation_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all employees for an enterprise
  Stream<QuerySnapshot> getEnterpriseEmployees({required String enterpriseId}) {
    return _db
        .collection('users')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .snapshots();
  }

  // Check if an Employee ID is already registered to another user within the enterprise
  Future<bool> isEmployeeIdTaken({
    required String enterpriseId,
    required String employeeId,
    required String excludeUserId,
  }) async {
    final query = await _db
        .collection('users')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .where('employeeId', isEqualTo: employeeId)
        .get();

    for (var doc in query.docs) {
      if (doc.id != excludeUserId) {
        return true;
      }
    }
    return false;
  }

  // Punch In / Out Logic
  Future<void> logAttendance({
    required String userId,
    required String enterpriseId,
    required String type,
    String verifiedVia = 'MANUAL',
    double? confidenceScore,
    int? shiftDurationMinutes,
    String? notes,
    String? employeeName,
    String? employeeId,
    String? punchStatus,
    int? lateMinutes,
    int? earlyMinutes,
    int? overtimeMinutes,
    String? workStatus,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'userId': userId,
        'enterpriseId': enterpriseId.trim(),
        'type': type, // 'PUNCH_IN' or 'PUNCH_OUT'
        'timestamp': FieldValue.serverTimestamp(),
        'verifiedVia': verifiedVia,
      };
      if (confidenceScore != null) data['confidenceScore'] = confidenceScore;
      if (shiftDurationMinutes != null) data['shiftDurationMinutes'] = shiftDurationMinutes;
      if (notes != null) data['notes'] = notes;
      if (employeeName != null) data['employeeName'] = employeeName;
      if (employeeId != null) data['employeeId'] = employeeId;
      if (punchStatus != null) data['punchStatus'] = punchStatus;
      if (lateMinutes != null) data['lateMinutes'] = lateMinutes;
      if (earlyMinutes != null) data['earlyMinutes'] = earlyMinutes;
      if (overtimeMinutes != null) data['overtimeMinutes'] = overtimeMinutes;
      if (workStatus != null) data['workStatus'] = workStatus;

      await _db.collection('attendance_logs').add(data);
    } catch (e) {
      throw Exception("Failed to log attendance: $e");
    }
  }

  // Log Employee Break Start or End
  Future<void> logBreak({
    required String userId,
    required String enterpriseId,
    bool isStart = true,
    String? type,
    String breakType = 'Lunch Break',
    String verifiedVia = 'MOBILE_GPS',
    String? employeeName,
    String? employeeId,
    String? notes,
    DateTime? timestamp,
  }) async {
    try {
      final actualType = type ?? (isStart ? 'START_BREAK' : 'END_BREAK');
      final Map<String, dynamic> data = {
        'userId': userId,
        'enterpriseId': enterpriseId.trim(),
        'type': actualType,
        'breakType': breakType,
        'timestamp': timestamp != null ? Timestamp.fromDate(timestamp) : FieldValue.serverTimestamp(),
        'verifiedVia': verifiedVia,
      };
      if (employeeName != null) data['employeeName'] = employeeName;
      if (employeeId != null) data['employeeId'] = employeeId;
      if (notes != null) data['notes'] = notes;

      await _db.collection('attendance_logs').add(data);
    } catch (e) {
      throw Exception("Failed to log break: $e");
    }
  }

  // Get the latest punch type for a user today (used for smart PUNCH_IN / PUNCH_OUT toggle)
  Future<String?> getLatestPunchTypeToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final snapshot = await _db
          .collection('attendance_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final todayLogs = snapshot.docs.where((doc) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return ts != null && ts.isAfter(startOfToday);
      }).toList();

      if (todayLogs.isEmpty) return null;

      todayLogs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });

      return todayLogs.first.data()['type'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Stream today's activity for a specific user (Single-field indexed for maximum reliability)
  Stream<List<QueryDocumentSnapshot>> getUserActivityToday(String userId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        return ts == null || ts.isAfter(startOfToday);
      }).toList();

      filtered.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return tB.compareTo(tA);
      });

      return filtered;
    });
  }

  // Stream today's enterprise activity across all employees (for Company Activity feed)
  Stream<List<QueryDocumentSnapshot>> getEnterpriseAttendanceToday(String enterpriseId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final targetId = enterpriseId.trim();

    return _db
        .collection('attendance_logs')
        .where('enterpriseId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) {
      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        return ts == null || ts.isAfter(startOfToday);
      }).toList();

      filtered.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return tB.compareTo(tA);
      });

      return filtered;
    });
  }

  // Stream all enterprise attendance logs for Admin MIS reporting and month-wise activity
  Stream<List<QueryDocumentSnapshot>> getEnterpriseAttendanceLogs(String enterpriseId) {
    return _db
        .collection('attendance_logs')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });
      return docs;
    });
  }

  // Stream all attendance logs for a specific user (for Month-wise activity)
  Stream<List<QueryDocumentSnapshot>> getUserAttendanceLogs(String userId) {
    return _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });
      return docs;
    });
  }

  // Detect unclosed / missing clock-out shifts in the past 7 days
  Future<List<Map<String, dynamic>>> getUnclosedShifts(String userId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

      final snapshot = await _db
          .collection('attendance_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final pastLogs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final ts = (data?['timestamp'] as Timestamp?)?.toDate();
        return ts != null && ts.isAfter(sevenDaysAgo) && ts.isBefore(startOfToday);
      }).toList();

      if (pastLogs.isEmpty) return [];

      final Map<String, List<QueryDocumentSnapshot>> dayGroups = {};
      for (var doc in pastLogs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp).toDate();
        final dateKey = '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
        dayGroups.putIfAbsent(dateKey, () => []).add(doc);
      }

      final List<Map<String, dynamic>> unclosed = [];
      for (var entry in dayGroups.entries) {
        final dayLogs = entry.value;
        dayLogs.sort((a, b) {
          final dA = a.data() as Map<String, dynamic>;
          final dB = b.data() as Map<String, dynamic>;
          final tA = (dA['timestamp'] as Timestamp).toDate();
          final tB = (dB['timestamp'] as Timestamp).toDate();
          return tA.compareTo(tB);
        });

        final hasIn = dayLogs.any((d) => (d.data() as Map<String, dynamic>)['type'] == 'PUNCH_IN');
        final hasOut = dayLogs.any((d) => (d.data() as Map<String, dynamic>)['type'] == 'PUNCH_OUT');

        if (hasIn && !hasOut) {
          final inDoc = dayLogs.firstWhere((d) => (d.data() as Map<String, dynamic>)['type'] == 'PUNCH_IN');
          final inData = inDoc.data() as Map<String, dynamic>;
          final inTime = (inData['timestamp'] as Timestamp).toDate();
          unclosed.add({
            'dateKey': entry.key,
            'date': inTime,
            'punchInId': inDoc.id,
            'punchInTime': inTime,
          });
        }
      }
      return unclosed;
    } catch (_) {
      return [];
    }
  }

  // Submit an attendance regularization request
  Future<void> submitRegularizationRequest({
    required String userId,
    required String enterpriseId,
    required String employeeName,
    required String employeeId,
    String? originalPunchInId,
    required DateTime shiftDate,
    required DateTime punchInTime,
    required DateTime requestedPunchOutTime,
    required String reason,
  }) async {
    await _db.collection('approval_requests').add({
      'userId': userId,
      'enterpriseId': enterpriseId,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'type': 'MISSING_CLOCK_OUT',
      if (originalPunchInId != null) 'originalPunchInId': originalPunchInId,
      'shiftDate': Timestamp.fromDate(shiftDate),
      'punchInTime': Timestamp.fromDate(punchInTime),
      'requestedPunchOutTime': Timestamp.fromDate(requestedPunchOutTime),
      'reason': reason,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Dispatch push notification to enterprise admins
    PushNotificationService().sendRegularizationRequestNotification(
      enterpriseId: enterpriseId,
      employeeName: employeeName,
      employeeId: employeeId,
      shiftDate: shiftDate,
      reason: reason,
    );
  }

  // Submit a missing punch-out regularization request (backwards-compatible alias)
  Future<void> submitMissingPunchOutRequest({
    required String userId,
    required String enterpriseId,
    required String employeeName,
    required String employeeId,
    required String originalPunchInId,
    required DateTime shiftDate,
    required DateTime punchInTime,
    required DateTime requestedPunchOutTime,
    required String reason,
  }) => submitRegularizationRequest(
    userId: userId,
    enterpriseId: enterpriseId,
    employeeName: employeeName,
    employeeId: employeeId,
    originalPunchInId: originalPunchInId,
    shiftDate: shiftDate,
    punchInTime: punchInTime,
    requestedPunchOutTime: requestedPunchOutTime,
    reason: reason,
  );

  // Stream approval requests for an enterprise (Pending requests first)
  Stream<List<QueryDocumentSnapshot>> getEnterpriseApprovalRequests(String enterpriseId) {
    return _db
        .collection('approval_requests')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final dA = a.data();
        final dB = b.data();
        final tA = (dA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = (dB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });
      return docs;
    });
  }

  // Stream approval requests for a specific user
  Stream<List<QueryDocumentSnapshot>> getUserApprovalRequests(String userId) {
    return _db
        .collection('approval_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Approve regularization request & create regularized PUNCH_OUT record
  Future<void> approveRegularizationRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
    required String adminUid,
  }) async {
    final punchIn = (requestData['punchInTime'] as Timestamp).toDate();
    final punchOut = (requestData['requestedPunchOutTime'] as Timestamp).toDate();
    final durationMinutes = punchOut.difference(punchIn).inMinutes;
    final effectiveDuration = durationMinutes > 0 ? durationMinutes : 0;
    final workStatus = effectiveDuration >= 480
        ? 'FULL_DAY'
        : (effectiveDuration >= 240 ? 'HALF_DAY' : 'SHORT_HOURS');

    // 1. Add the regularized PUNCH_OUT record
    await _db.collection('attendance_logs').add({
      'userId': requestData['userId'],
      'enterpriseId': requestData['enterpriseId'],
      'type': 'PUNCH_OUT',
      'timestamp': Timestamp.fromDate(punchOut),
      'verifiedVia': 'REGULARIZED_BY_ADMIN',
      'shiftDurationMinutes': effectiveDuration,
      'workStatus': workStatus,
      'punchStatus': 'REGULARIZED',
      if (requestData['employeeName'] != null) 'employeeName': requestData['employeeName'],
      if (requestData['employeeId'] != null) 'employeeId': requestData['employeeId'],
      'notes': 'Regularized by Admin: ${requestData['reason']}',
    });

    // 2. Mark the approval request as APPROVED
    await _db.collection('approval_requests').doc(requestId).update({
      'status': 'APPROVED',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    // 3. Dispatch push notification to the employee
    final shiftDate = requestData['shiftDate'] != null
        ? (requestData['shiftDate'] as Timestamp).toDate()
        : DateTime.now();
    PushNotificationService().sendRegularizationStatusNotification(
      userId: requestData['userId'] as String? ?? '',
      isApproved: true,
      shiftDate: shiftDate,
    );
  }

  // Reject regularization request
  Future<void> rejectRegularizationRequest({
    required String requestId,
    required String adminUid,
    Map<String, dynamic>? requestData,
    String? reason,
  }) async {
    await _db.collection('approval_requests').doc(requestId).update({
      'status': 'REJECTED',
      'reviewedBy': adminUid,
      if (reason != null) 'adminRejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    // Dispatch push notification to the employee
    if (requestData != null) {
      final shiftDate = requestData['shiftDate'] != null
          ? (requestData['shiftDate'] as Timestamp).toDate()
          : DateTime.now();
      PushNotificationService().sendRegularizationStatusNotification(
        userId: requestData['userId'] as String? ?? '',
        isApproved: false,
        shiftDate: shiftDate,
        reason: reason,
      );
    }
  }

  // Stream enterprise settings (geofence, office coordinates, etc.)
  Stream<DocumentSnapshot> getEnterpriseStream(String enterpriseId) {
    return _db.collection('enterprises').doc(enterpriseId).snapshots();
  }

  Future<DocumentSnapshot> getEnterprise(String enterpriseId) {
    return _db.collection('enterprises').doc(enterpriseId).get();
  }

  // Update enterprise geofence settings
  Future<void> updateEnterpriseGeofence({
    required String enterpriseId,
    required bool geofencingEnabled,
    required double officeLatitude,
    required double officeLongitude,
    required double geofenceRadiusMeters,
    String? locationName,
  }) async {
    await _db.collection('enterprises').doc(enterpriseId).set({
      'geofencingEnabled': geofencingEnabled,
      'officeLatitude': officeLatitude,
      'officeLongitude': officeLongitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      if (locationName != null) 'locationName': locationName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Update enterprise shift schedule configuration
  Future<void> updateEnterpriseShift({
    required String enterpriseId,
    required ShiftSchedule schedule,
  }) async {
    await _db.collection('enterprises').doc(enterpriseId).set({
      'shiftSchedule': schedule.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Fetch enterprise shift schedule configuration (falls back to default ShiftSchedule)
  Future<ShiftSchedule> getEnterpriseShiftSchedule(String enterpriseId) async {
    try {
      final doc = await _db.collection('enterprises').doc(enterpriseId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('shiftSchedule') && data['shiftSchedule'] != null) {
          final sMap = data['shiftSchedule'] as Map<String, dynamic>;
          return ShiftSchedule.fromJson(sMap);
        }
      }
    } catch (_) {}
    return const ShiftSchedule();
  }

  // Provision or link a new employee profile to the enterprise
  Future<String> addEnterpriseEmployee({
    required String enterpriseId,
    required String fullName,
    required String email,
    required String employeeId,
    String department = 'General',
    String role = 'employee',
    List<String>? allowedChannels,
    String defaultPin = '1234',
  }) async {
    final channels = allowedChannels ?? [
      'KIOSK_FACE',
      'KIOSK_PIN',
      'MOBILE_GPS',
      'OFFICE_WIFI',
      'PHONE_BIOMETRICS',
    ];

    final cleanRole = (role.toLowerCase() == 'enterprise_admin' || role.toLowerCase() == 'admin')
        ? 'enterprise_admin'
        : 'employee';

    QuerySnapshot? existing;
    try {
      existing = await _db
          .collection('users')
          .where('enterpriseId', isEqualTo: enterpriseId.trim())
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();
    } catch (e) {
      debugPrint('Existing user query note: $e');
    }

    if (existing != null && existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      await _db.collection('users').doc(docId).set({
        'enterpriseId': enterpriseId.trim(),
        'fullName': fullName.trim(),
        'name': fullName.trim(),
        'employeeId': employeeId.trim(),
        'department': department.trim(),
        'role': cleanRole,
        'allowedVerificationMethods': channels,
        'employeePin': defaultPin.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also mirror to enterprise employees subcollection
      try {
        await _db
            .collection('enterprises')
            .doc(enterpriseId.trim())
            .collection('employees')
            .doc(docId)
            .set({
          'fullName': fullName.trim(),
          'name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'employeeId': employeeId.trim(),
          'department': department.trim(),
          'role': cleanRole,
          'allowedVerificationMethods': channels,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return docId;
    }

    final newDoc = _db.collection('users').doc();
    await newDoc.set({
      'email': email.trim().toLowerCase(),
      'fullName': fullName.trim(),
      'name': fullName.trim(),
      'employeeId': employeeId.trim(),
      'department': department.trim(),
      'role': cleanRole,
      'enterpriseId': enterpriseId.trim(),
      'biometricsEnrolled': false,
      'allowedVerificationMethods': channels,
      'employeePin': defaultPin.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await _db
          .collection('enterprises')
          .doc(enterpriseId.trim())
          .collection('employees')
          .doc(newDoc.id)
          .set({
        'fullName': fullName.trim(),
        'name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'employeeId': employeeId.trim(),
        'department': department.trim(),
        'role': cleanRole,
        'allowedVerificationMethods': channels,
        'biometricsEnrolled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return newDoc.id;
  }

  // Reset employee biometric face template to allow fresh enrollment
  Future<void> resetEmployeeBiometrics(String userId, {String? enterpriseId}) async {
    await _db.collection('users').doc(userId).update({
      'biometricsEnrolled': false,
      'facialSignature': FieldValue.delete(),
      'biometricEnrolledAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (enterpriseId != null && enterpriseId.isNotEmpty) {
      try {
        await _db
            .collection('enterprises')
            .doc(enterpriseId.trim())
            .collection('employees')
            .doc(userId)
            .set({
          'biometricsEnrolled': false,
          'facialSignature': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // Update employee profile details
  Future<void> updateEmployeeProfile({
    required String userId,
    required String fullName,
    required String employeeId,
    String? department,
    String? role,
    String? assignedShift,
  }) async {
    final Map<String, dynamic> updates = {
      'fullName': fullName.trim(),
      'name': fullName.trim(),
      'employeeId': employeeId.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (department != null) updates['department'] = department.trim();
    if (role != null) updates['role'] = role;
    if (assignedShift != null) updates['assignedShift'] = assignedShift;
    await _db.collection('users').doc(userId).update(updates);
  }

  // Update employee allowed verification methods (e.g. KIOSK_FACE, KIOSK_PIN, MOBILE_GPS, OFFICE_WIFI)
  Future<void> updateEmployeeAllowedVerificationMethods({
    required String userId,
    required List<String> methods,
  }) async {
    await _db.collection('users').doc(userId).update({
      'allowedVerificationMethods': methods,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove / unlink employee from enterprise
  Future<void> removeEnterpriseEmployee({
    required String userId,
  }) async {
    await _db.collection('users').doc(userId).update({
      'enterpriseId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Record a verified manual attendance entry by Administrator
  Future<void> logManualAttendance({
    required String userId,
    required String enterpriseId,
    required String type,
    required DateTime timestamp,
    required String employeeName,
    required String employeeId,
    String? notes,
    ShiftSchedule schedule = const ShiftSchedule(),
    int? shiftDurationMinutes,
  }) async {
    final eval = ShiftEvaluationService.evaluatePunch(
      punchTime: timestamp,
      punchType: type,
      schedule: schedule,
      shiftDurationMinutes: shiftDurationMinutes,
    );

    await _db.collection('attendance_logs').add({
      'userId': userId,
      'enterpriseId': enterpriseId.trim(),
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'verifiedVia': 'ADMIN_MANUAL',
      'employeeName': employeeName,
      'employeeId': employeeId,
      'punchStatus': eval.punchStatus,
      'lateMinutes': eval.lateMinutes,
      'earlyMinutes': eval.earlyMinutes,
      'overtimeMinutes': eval.overtimeMinutes,
      if (eval.workStatus != null) 'workStatus': eval.workStatus,
      if (shiftDurationMinutes != null) 'shiftDurationMinutes': shiftDurationMinutes,
      'notes': notes ?? 'Manual entry by Administrator',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Enterprise Admin Terminal PIN
  Future<void> updateEnterprisePin({
    required String enterpriseId,
    required String newPin,
  }) async {
    final cleanPin = newPin.trim();
    await _db.collection('enterprises').doc(enterpriseId.trim()).update({
      'kioskPin': cleanPin,
      'adminPin': cleanPin,
      'pinUpdatedAt': FieldValue.serverTimestamp(),
    });
    // Immediately persist and synchronize local PIN cache
    await AdminPinService.instance.setPin(enterpriseId.trim(), cleanPin);
  }

  // Get Enterprise Admin Terminal PIN
  Future<String> getEnterprisePin(String enterpriseId) async {
    final doc = await _db.collection('enterprises').doc(enterpriseId.trim()).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data()!['kioskPin'] as String?) ??
          (doc.data()!['adminPin'] as String?) ??
          '1234';
    }
    return '1234';
  }

  // Unlink an employee/user from their enterprise (Industry standard)
  Future<void> unlinkUserFromEnterprise(String userId) async {
    await _db.collection('users').doc(userId.trim()).update({
      'enterpriseId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update employee allowed verification channels
  Future<void> updateEmployeeVerificationChannels({
    required String enterpriseId,
    required String userId,
    required List<String> channels,
  }) async {
    await _db.collection('users').doc(userId.trim()).update({
      'allowedVerificationMethods': channels,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await _db
          .collection('enterprises')
          .doc(enterpriseId.trim())
          .collection('employees')
          .doc(userId.trim())
          .set({
        'allowedVerificationMethods': channels,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // Update enterprise global default verification channels
  Future<void> updateEnterpriseDefaultChannels({
    required String enterpriseId,
    required List<String> channels,
  }) async {
    await _db.collection('enterprises').doc(enterpriseId.trim()).update({
      'defaultAllowedVerificationMethods': channels,
      'channelsUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update employee personal secret PIN
  Future<void> updateEmployeePersonalPin({
    required String userId,
    required String newPin,
  }) async {
    await _db.collection('users').doc(userId.trim()).update({
      'employeePin': newPin.trim(),
      'pinUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Enterprise Wi-Fi Geofence settings
  Future<void> updateEnterpriseWifi({
    required String enterpriseId,
    required bool enabled,
    required List<String> allowedSsids,
  }) async {
    await _db.collection('enterprises').doc(enterpriseId.trim()).update({
      'wifiGeofencingEnabled': enabled,
      'allowedWifiSsids': allowedSsids,
      'wifiUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream all registered employees of an enterprise
  Stream<List<QueryDocumentSnapshot>> getEnterpriseEmployeesStream(String enterpriseId) {
    return _db
        .collection('users')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final nameA = (a.data()['fullName'] as String?) ?? (a.data()['name'] as String?) ?? '';
        final nameB = (b.data()['fullName'] as String?) ?? (b.data()['name'] as String?) ?? '';
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
      return docs;
    });
  }

  // Stream active/approved leaves for an enterprise today
  Stream<List<QueryDocumentSnapshot>> getEnterpriseLeavesToday(String enterpriseId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .collection('leave_requests')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['status'] != 'APPROVED') return false;
        final startTs = (data['startDate'] as Timestamp?)?.toDate();
        final endTs = (data['endDate'] as Timestamp?)?.toDate() ?? startTs;
        if (startTs == null) return false;
        return !endOfToday.isBefore(startTs) && !startOfToday.isAfter(endTs!);
      }).toList();
    });
  }

}

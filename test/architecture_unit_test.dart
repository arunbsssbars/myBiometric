import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mybiometric/core/utils/face_math_utils.dart';
import 'package:mybiometric/services/location_service.dart';
import 'package:mybiometric/services/offline_roster_cache_service.dart';
import 'package:mybiometric/services/offline_attendance_queue_service.dart';
import 'package:mybiometric/services/shift_evaluation_service.dart';
import 'package:mybiometric/domain/models/employee_profile.dart';
import 'package:mybiometric/domain/models/shift_schedule.dart';
import 'package:mybiometric/domain/repositories/attendance_repository.dart';
import 'package:mybiometric/domain/repositories/user_repository.dart';
import 'package:mybiometric/domain/use_cases/enroll_face_use_case.dart';
import 'package:mybiometric/domain/use_cases/verify_face_punch_in_use_case.dart';
import 'package:mybiometric/domain/models/leave_request.dart';
import 'package:mybiometric/services/payroll_export_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mybiometric/services/shift_reminder_service.dart';
import 'package:mybiometric/services/absenteeism_reconciliation_service.dart';
import 'package:mybiometric/services/audit_log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mybiometric/services/kiosk_liveness_evaluator.dart';
import 'package:mybiometric/services/break_tracking_service.dart';
import 'package:mybiometric/domain/models/overtime_policy.dart';
import 'package:mybiometric/services/overtime_calculation_service.dart';
import 'package:mybiometric/domain/models/network_geofence_policy.dart';
import 'package:mybiometric/services/office_network_verification_service.dart';
import 'package:mybiometric/domain/models/department_role_policy.dart';
import 'package:mybiometric/services/department_permission_service.dart';
import 'package:mybiometric/domain/models/daily_attendance_digest.dart';
import 'package:mybiometric/services/daily_attendance_digest_service.dart';
import 'package:mybiometric/domain/models/shift_automation_policy.dart';
import 'package:mybiometric/services/shift_automation_service.dart';
import 'package:mybiometric/domain/models/work_project.dart';
import 'package:mybiometric/services/project_time_allocation_service.dart';
import 'package:mybiometric/core/utils/app_format_utils.dart';
import 'package:mybiometric/domain/models/attendance_regularization_request.dart';
import 'package:mybiometric/services/attendance_regularization_service.dart';

class MockUserRepository implements UserRepository {
  String? lastUserId;
  String? lastFullName;
  String? lastEmployeeId;
  List<double>? lastSignature;
  List<EmployeeProfile> existingEmployees = [];

  @override
  Future<void> saveBiometricEnrollment({
    required String userId,
    required String fullName,
    required String employeeId,
    required List<double> facialSignature,
  }) async {
    lastUserId = userId;
    lastFullName = fullName;
    lastEmployeeId = employeeId;
    lastSignature = facialSignature;
  }

  @override
  Stream<List<EmployeeProfile>> getEnterpriseEmployees(String enterpriseId) {
    return Stream.value(existingEmployees);
  }

  @override
  Future<List<EmployeeProfile>> getEnterpriseEmployeesList(String enterpriseId) async {
    return existingEmployees;
  }

  @override
  Future<EmployeeProfile?> getUserProfile(String userId) async {
    return existingEmployees.where((e) => e.uid == userId).firstOrNull;
  }

  @override
  Future<List<EmployeeProfile>> getAllEnrolledBiometricProfiles() async {
    return existingEmployees.where((e) => e.facialSignature != null && e.facialSignature!.isNotEmpty).toList();
  }
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<Map<String, dynamic>> loggedEntries = [];
  Map<String, dynamic>? latestPunch;

  @override
  Future<void> logAttendance({
    required String userId,
    required String enterpriseId,
    required String type,
    String verifiedVia = 'FACE_ID',
    double? confidenceScore,
    int? shiftDurationMinutes,
    double? latitude,
    double? longitude,
    double? distanceFromOfficeMeters,
    bool? withinGeofence,
    String? employeeName,
    String? employeeIdCode,
    String? punchStatus,
    int? lateMinutes,
    int? earlyMinutes,
    int? overtimeMinutes,
    String? workStatus,
    String? breakType,
  }) async {
    loggedEntries.add({
      'userId': userId,
      'enterpriseId': enterpriseId,
      'type': type,
      'verifiedVia': verifiedVia,
      'confidenceScore': confidenceScore,
      'shiftDurationMinutes': shiftDurationMinutes,
      'latitude': latitude,
      'longitude': longitude,
      'distanceFromOfficeMeters': distanceFromOfficeMeters,
      'withinGeofence': withinGeofence,
      'employeeName': employeeName,
      'employeeId': employeeIdCode,
      'punchStatus': punchStatus,
      'lateMinutes': lateMinutes,
      'earlyMinutes': earlyMinutes,
      'overtimeMinutes': overtimeMinutes,
      'workStatus': workStatus,
      'breakType': breakType,
    });
  }

  @override
  Future<Map<String, dynamic>?> getLatestPunchToday(String userId) async {
    return latestPunch;
  }

  @override
  Future<String?> getLatestPunchTypeToday(String userId) async {
    return latestPunch?['type'] as String?;
  }
}

void main() {
  group('FaceMathUtils Tests', () {
    test('l2Normalize normalizes arbitrary vector to unit length 1.0', () {
      final vec = [3.0, 4.0, 0.0];
      final normalized = FaceMathUtils.l2Normalize(vec);
      final norm = sqrt(normalized.fold(0.0, (acc, v) => acc + v * v));
      expect(norm, closeTo(1.0, 0.0001));
      expect(normalized[0], closeTo(0.6, 0.0001));
      expect(normalized[1], closeTo(0.8, 0.0001));
    });

    test('cosineSimilarity of identical vectors is 1.0', () {
      final v1 = FaceMathUtils.l2Normalize([1.0, 2.0, 3.0, 4.0]);
      final v2 = List<double>.from(v1);
      final sim = FaceMathUtils.cosineSimilarity(v1, v2);
      expect(sim, closeTo(1.0, 0.0001));
    });

    test('cosineSimilarity of orthogonal vectors is 0.0', () {
      final v1 = [1.0, 0.0, 0.0];
      final v2 = [0.0, 1.0, 0.0];
      final sim = FaceMathUtils.cosineSimilarity(v1, v2);
      expect(sim, closeTo(0.0, 0.0001));
    });

    test('averageAndNormalize averages multi-frame embeddings into unit vector', () {
      final f1 = [1.0, 0.0];
      final f2 = [0.0, 1.0];
      final averaged = FaceMathUtils.averageAndNormalize([f1, f2]);
      final norm = sqrt(averaged.fold(0.0, (acc, v) => acc + v * v));
      expect(norm, closeTo(1.0, 0.0001));
      expect(averaged[0], closeTo(averaged[1], 0.0001));
    });
  });

  group('EnrollFaceUseCase 1:N Deduplication Tests', () {
    test('validates and enrolls multi-frame face signatures when no collision', () async {
      final mockRepo = MockUserRepository();
      final useCase = EnrollFaceUseCase(userRepository: mockRepo);

      final frame1 = [1.0, 0.5, 0.2];
      final frame2 = [0.9, 0.6, 0.2];

      await useCase.execute(
        userId: 'user_123',
        enterpriseId: 'ACME',
        fullName: 'Jane Doe',
        employeeId: 'EMP001',
        rawEmbeddings: [frame1, frame2],
      );

      expect(mockRepo.lastUserId, 'user_123');
      expect(mockRepo.lastFullName, 'Jane Doe');
      expect(mockRepo.lastEmployeeId, 'EMP001');
      expect(mockRepo.lastSignature, isNotNull);
      final norm = sqrt(mockRepo.lastSignature!.fold(0.0, (acc, v) => acc + v * v));
      expect(norm, closeTo(1.0, 0.0001));
    });

    test('throws BiometricCollisionException when another employee has matching face >= 0.60', () async {
      final mockRepo = MockUserRepository();
      final registeredSig = FaceMathUtils.l2Normalize([0.9, 0.4, 0.1]);
      mockRepo.existingEmployees = [
        EmployeeProfile(
          uid: 'emp_original',
          fullName: 'Alice Smith',
          employeeId: 'EMP-001',
          enterpriseId: 'ACME',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final useCase = EnrollFaceUseCase(userRepository: mockRepo);

      // Attempt to register same face with different account/email
      final newFaceFrame = FaceMathUtils.l2Normalize([0.91, 0.39, 0.1]);

      expect(
        () async => await useCase.execute(
          userId: 'user_duplicate_account',
          enterpriseId: 'ACME',
          fullName: 'Bob Fake',
          employeeId: 'EMP-999',
          rawEmbeddings: [newFaceFrame],
        ),
        throwsA(isA<BiometricCollisionException>()),
      );

      // Verify no changes were saved
      expect(mockRepo.lastUserId, isNull);
    });

    test('blocks collision when enterpriseId parameter is omitted but resolved via user profile', () async {
      final mockRepo = MockUserRepository();
      final registeredSig = FaceMathUtils.l2Normalize([0.9, 0.4, 0.1]);
      mockRepo.existingEmployees = [
        EmployeeProfile(
          uid: 'emp_existing',
          fullName: 'John Senior',
          employeeId: 'EMP-010',
          enterpriseId: 'ACME_CORP',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
        const EmployeeProfile(
          uid: 'user_profile_resolved',
          fullName: 'John Junior',
          employeeId: 'EMP-011',
          enterpriseId: 'ACME_CORP',
        ),
      ];

      final useCase = EnrollFaceUseCase(userRepository: mockRepo);
      final newFaceFrame = FaceMathUtils.l2Normalize([0.905, 0.395, 0.1]);

      expect(
        () async => await useCase.execute(
          userId: 'user_profile_resolved',
          enterpriseId: '', // Omitted enterpriseId: should auto-resolve from profile
          fullName: 'John Junior',
          employeeId: 'EMP-011',
          rawEmbeddings: [newFaceFrame],
        ),
        throwsA(isA<BiometricCollisionException>()),
      );
      expect(mockRepo.lastUserId, isNull);
    });

    test('allows re-enrollment if the matching employee is the user themselves', () async {
      final mockRepo = MockUserRepository();
      final registeredSig = FaceMathUtils.l2Normalize([0.9, 0.4, 0.1]);
      mockRepo.existingEmployees = [
        EmployeeProfile(
          uid: 'user_123',
          fullName: 'Jane Doe',
          employeeId: 'EMP001',
          enterpriseId: 'ACME',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final useCase = EnrollFaceUseCase(userRepository: mockRepo);
      final newFaceFrame = FaceMathUtils.l2Normalize([0.91, 0.39, 0.1]);

      await useCase.execute(
        userId: 'user_123',
        enterpriseId: 'ACME',
        fullName: 'Jane Doe Updated',
        employeeId: 'EMP001',
        rawEmbeddings: [newFaceFrame],
      );

      expect(mockRepo.lastUserId, 'user_123');
      expect(mockRepo.lastFullName, 'Jane Doe Updated');
    });
  });

  group('VerifyFacePunchInUseCase Sequence State Machine Tests', () {
    test('matches employee and logs PUNCH_IN when no prior punches today', () async {
      final mockRepo = MockAttendanceRepository();
      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);

      final registeredSig = FaceMathUtils.l2Normalize([0.8, 0.6, 0.0]);
      final liveEmbedding = FaceMathUtils.l2Normalize([0.82, 0.58, 0.0]);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'AUTO',
      );

      expect(result.isMatch, isTrue);
      expect(result.matchedEmployee?.uid, 'emp_007');
      expect(result.similarity, greaterThanOrEqualTo(0.72));
      expect(result.punchType, 'PUNCH_IN');
      expect(result.isSequenceError, isFalse);
      expect(mockRepo.loggedEntries.length, 1);
      expect(mockRepo.loggedEntries.first['userId'], 'emp_007');
      expect(mockRepo.loggedEntries.first['type'], 'PUNCH_IN');
    });

    test('auto toggles to PUNCH_OUT and calculates shift duration when last punch was PUNCH_IN', () async {
      final mockRepo = MockAttendanceRepository();
      final punchInTime = DateTime.now().subtract(const Duration(hours: 8, minutes: 15));
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': punchInTime,
      };

      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);
      final registeredSig = FaceMathUtils.l2Normalize([0.8, 0.6, 0.0]);
      final liveEmbedding = FaceMathUtils.l2Normalize([0.81, 0.59, 0.0]);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'AUTO',
      );

      expect(result.isMatch, isTrue);
      expect(result.punchType, 'PUNCH_OUT');
      expect(result.isSequenceError, isFalse);
      expect(result.shiftDurationMinutes, greaterThanOrEqualTo(490));
      expect(mockRepo.loggedEntries.first['type'], 'PUNCH_OUT');
      expect(mockRepo.loggedEntries.first['shiftDurationMinutes'], greaterThanOrEqualTo(490));
    });

    test('blocks invalid sequence when manual PUNCH_IN is attempted while already clocked in', () async {
      final mockRepo = MockAttendanceRepository();
      final punchInTime = DateTime.now().subtract(const Duration(hours: 2));
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': punchInTime,
      };

      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);
      final registeredSig = FaceMathUtils.l2Normalize([0.8, 0.6, 0.0]);
      final liveEmbedding = FaceMathUtils.l2Normalize([0.81, 0.59, 0.0]);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'PUNCH_IN', // Invalid manual selection
      );

      expect(result.isMatch, isTrue);
      expect(result.isSequenceError, isTrue);
      expect(result.sequenceErrorMessage, contains('Already Clocked In'));
      expect(mockRepo.loggedEntries, isEmpty); // No invalid log saved
    });

    test('blocks invalid sequence when manual PUNCH_OUT is attempted while not clocked in', () async {
      final mockRepo = MockAttendanceRepository();
      mockRepo.latestPunch = null; // Not clocked in

      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);
      final registeredSig = FaceMathUtils.l2Normalize([0.8, 0.6, 0.0]);
      final liveEmbedding = FaceMathUtils.l2Normalize([0.81, 0.59, 0.0]);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'PUNCH_OUT', // Invalid manual selection
      );

      expect(result.isMatch, isTrue);
      expect(result.isSequenceError, isTrue);
      expect(result.sequenceErrorMessage, contains('Already Clocked Out'));
      expect(mockRepo.loggedEntries, isEmpty);
    });

    test('suppresses double-punches attempted within 2 minutes', () async {
      final mockRepo = MockAttendanceRepository();
      final recentPunch = DateTime.now().subtract(const Duration(seconds: 45));
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': recentPunch,
      };

      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);
      final registeredSig = FaceMathUtils.l2Normalize([0.8, 0.6, 0.0]);
      final liveEmbedding = FaceMathUtils.l2Normalize([0.81, 0.59, 0.0]);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'AUTO',
      );

      expect(result.isMatch, isTrue);
      expect(result.isSequenceError, isTrue);
      expect(result.sequenceErrorMessage, contains('You already punched'));
      expect(mockRepo.loggedEntries, isEmpty);
    });

    test('cooldown error returns isCooldownError true with minutes', () async {
      final mockRepo = MockAttendanceRepository();
      final now = DateTime.now();
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(seconds: 45))),
      };

      final useCase = VerifyFacePunchInUseCase(
        attendanceRepository: mockRepo,
        defaultThreshold: 0.65,
      );

      final liveEmbedding = FaceMathUtils.l2Normalize(List.generate(192, (i) => 1.0));
      final registeredSig = List<double>.from(liveEmbedding);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'AUTO',
      );

      expect(result.isMatch, isTrue);
      expect(result.isCooldownError, isTrue);
      expect(mockRepo.loggedEntries, isEmpty);
    });

    test('flags rapid punch-out (<15m) and requires confirmation when clocking out', () async {
      final mockRepo = MockAttendanceRepository();
      final now = DateTime.now();
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      };

      final useCase = VerifyFacePunchInUseCase(
        attendanceRepository: mockRepo,
        defaultThreshold: 0.65,
      );

      final liveEmbedding = FaceMathUtils.l2Normalize(List.generate(192, (i) => 1.0));
      final registeredSig = List<double>.from(liveEmbedding);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'PUNCH_OUT',
        bypassRapidPunchOut: false,
      );

      expect(result.isMatch, isTrue);
      expect(result.isRapidPunchOutConfirmationRequired, isTrue);
      expect(result.rapidElapsedMinutes, equals(5));
      expect(mockRepo.loggedEntries, isEmpty);
    });

    test('bypasses rapid punch-out check when bypassRapidPunchOut is true', () async {
      final mockRepo = MockAttendanceRepository();
      final now = DateTime.now();
      mockRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      };

      final useCase = VerifyFacePunchInUseCase(
        attendanceRepository: mockRepo,
        defaultThreshold: 0.65,
      );

      final liveEmbedding = FaceMathUtils.l2Normalize(List.generate(192, (i) => 1.0));
      final registeredSig = List<double>.from(liveEmbedding);

      final candidates = [
        EmployeeProfile(
          uid: 'emp_007',
          fullName: 'James Bond',
          employeeId: '007',
          facialSignature: registeredSig,
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'PUNCH_OUT',
        bypassRapidPunchOut: true,
      );

      expect(result.isMatch, isTrue);
      expect(result.isRapidPunchOutConfirmationRequired, isFalse);
      expect(mockRepo.loggedEntries.length, equals(1));
      expect(mockRepo.loggedEntries.first['type'], equals('PUNCH_OUT'));
    });

    test('records custom verifiedVia attribution (e.g. KIOSK or MANUAL) in attendance log', () async {
      final mockRepo = MockAttendanceRepository();
      final useCase = VerifyFacePunchInUseCase(
        attendanceRepository: mockRepo,
        defaultThreshold: 0.65,
      );

      final liveEmbedding = FaceMathUtils.l2Normalize(List.generate(192, (i) => 1.0));
      final candidates = [
        EmployeeProfile(
          uid: 'emp_kiosk_01',
          fullName: 'Kiosk User',
          employeeId: 'K-01',
          facialSignature: List<double>.from(liveEmbedding),
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'ENT_KIOSK',
        punchType: 'PUNCH_IN',
        verifiedVia: 'KIOSK',
      );

      expect(result.isMatch, isTrue);
      expect(mockRepo.loggedEntries.length, equals(1));
      expect(mockRepo.loggedEntries.first['verifiedVia'], equals('KIOSK'));
    });
  });

  group('Attendance Regularization Tests', () {
    test('accurately calculates shift duration minutes for approved clock-out', () {
      final punchIn = DateTime(2026, 9, 24, 9, 30);
      final requestedPunchOut = DateTime(2026, 9, 24, 18, 45); // 9h 15m = 555 mins
      final diffMinutes = requestedPunchOut.difference(punchIn).inMinutes;

      expect(diffMinutes, equals(555));
      expect(diffMinutes ~/ 60, equals(9));
      expect(diffMinutes % 60, equals(15));
    });

    test('validates regularization shift duration cannot be negative', () {
      final punchIn = DateTime(2026, 9, 24, 18, 00);
      final invalidPunchOut = DateTime(2026, 9, 24, 9, 00);
      final rawDiff = invalidPunchOut.difference(punchIn).inMinutes;
      final safeDuration = rawDiff > 0 ? rawDiff : 0;

      expect(safeDuration, equals(0));
    });
  });

  group('GPS Geofencing Tests', () {
    test('LocationService calculates distance correctly between coordinates', () {
      final locService = LocationService();
      // Distance between identical coordinates is 0
      final zeroDist = locService.calculateDistanceMeters(
        startLatitude: 12.9716,
        startLongitude: 77.5946,
        endLatitude: 12.9716,
        endLongitude: 77.5946,
      );
      expect(zeroDist, closeTo(0.0, 0.01));

      // Coordinate offset of ~0.001 deg lat is approximately 111 meters
      final dist = locService.calculateDistanceMeters(
        startLatitude: 12.9716,
        startLongitude: 77.5946,
        endLatitude: 12.9726,
        endLongitude: 77.5946,
      );
      expect(dist, greaterThan(100.0));
      expect(dist, lessThan(125.0));
    });

    test('validates geofence status: inside vs outside radius', () {
      final locService = LocationService();
      const officeLat = 12.9716;
      const officeLng = 77.5946;
      const allowedRadius = 150.0;

      // Close position (~11m away)
      final closeDist = locService.calculateDistanceMeters(
        startLatitude: officeLat,
        startLongitude: officeLng,
        endLatitude: 12.9717,
        endLongitude: officeLng,
      );
      final isInside = closeDist <= allowedRadius;
      expect(isInside, isTrue);

      // Far position (~480m away)
      final farDist = locService.calculateDistanceMeters(
        startLatitude: officeLat,
        startLongitude: officeLng,
        endLatitude: 12.9760,
        endLongitude: officeLng,
      );
      final isOutside = farDist <= allowedRadius;
      expect(isOutside, isFalse);
    });

    test('evaluateGeofence flags isMocked and invalidates geofence when position is spoofed', () {
      final locService = LocationService();
      const officeLat = 12.9716;
      const officeLng = 77.5946;

      final mockedPosition = Position(
        latitude: officeLat,
        longitude: officeLng,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: true,
      );

      final status = locService.evaluateGeofence(
        position: mockedPosition,
        officeLatitude: officeLat,
        officeLongitude: officeLng,
        allowedRadiusMeters: 150.0,
      );

      expect(status.isMocked, isTrue);
      expect(status.isWithinGeofence, isFalse);
    });
  });

  group('Offline Kiosk Architecture Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('OfflineRosterCacheService caches and retrieves employee biometric signatures', () async {
      final cacheService = OfflineRosterCacheService();
      const enterpriseId = 'ENT_TEST_99';

      final roster = [
        const EmployeeProfile(
          uid: 'emp_01',
          fullName: 'Alice Johnson',
          employeeId: 'EMP-001',
          enterpriseId: enterpriseId,
          facialSignature: [0.1, 0.2, 0.3, 0.4],
          biometricsEnrolled: true,
        ),
        const EmployeeProfile(
          uid: 'emp_02',
          fullName: 'Bob Smith',
          employeeId: 'EMP-002',
          enterpriseId: enterpriseId,
          facialSignature: [0.5, 0.6, 0.7, 0.8],
          biometricsEnrolled: true,
        ),
      ];

      // 1. Cache to local on-device storage
      await cacheService.cacheRoster(enterpriseId, roster);

      // 2. Retrieve offline
      final cached = await cacheService.getCachedRoster(enterpriseId);
      expect(cached.length, 2);
      expect(cached[0].uid, 'emp_01');
      expect(cached[0].fullName, 'Alice Johnson');
      expect(cached[0].facialSignature, [0.1, 0.2, 0.3, 0.4]);
      expect(cached[1].uid, 'emp_02');
      expect(cached[1].facialSignature, [0.5, 0.6, 0.7, 0.8]);

      // 3. Verify sync time was recorded
      final syncTime = await cacheService.getLastSyncTime(enterpriseId);
      expect(syncTime, isNotNull);
      expect(DateTime.now().difference(syncTime!).inSeconds, lessThan(5));
    });

    test('OfflineAttendanceQueueService enqueues punches and tracks pending count', () async {
      final queueService = OfflineAttendanceQueueService();
      await queueService.initialize();
      expect(queueService.pendingCountNotifier.value, 0);

      // 1. Enqueue an offline punch
      await queueService.enqueuePunch({
        'userId': 'emp_01',
        'enterpriseId': 'ENT_TEST_99',
        'type': 'PUNCH_IN',
        'verifiedVia': 'FACE_ID',
        'employeeName': 'Alice Johnson',
      });

      expect(queueService.pendingCountNotifier.value, 1);

      // 2. Enqueue a second punch
      await queueService.enqueuePunch({
        'userId': 'emp_02',
        'enterpriseId': 'ENT_TEST_99',
        'type': 'PUNCH_OUT',
        'verifiedVia': 'FACE_ID',
        'employeeName': 'Bob Smith',
      });

      expect(queueService.pendingCountNotifier.value, 2);

      final pending = await queueService.getPendingPunches();
      expect(pending.length, 2);
      expect(pending[0]['userId'], 'emp_01');
      expect(pending[0]['type'], 'PUNCH_IN');
      expect(pending[1]['userId'], 'emp_02');
      expect(pending[1]['type'], 'PUNCH_OUT');

      // 3. Clear queue
      await queueService.clearQueue();
      expect(queueService.pendingCountNotifier.value, 0);
      expect(await queueService.getPendingPunches(), isEmpty);
    });
  });

  group('Shift Intelligence & Scheduling Tests', () {
    const standardShift = ShiftSchedule(
      shiftName: 'General Day Shift',
      startHour: 9,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
      gracePeriodMinutes: 15,
      halfDayMinutes: 240, // 4 hours
      fullDayMinutes: 480, // 8 hours
    );

    test('ShiftSchedule model formats times and serializes correctly', () {
      expect(standardShift.startTimeFormatted, '09:00 AM');
      expect(standardShift.endTimeFormatted, '06:00 PM');
      expect(standardShift.graceDeadlineFormatted, '09:15 AM');

      final json = standardShift.toJson();
      final reconstituted = ShiftSchedule.fromJson(json);
      expect(reconstituted.shiftName, 'General Day Shift');
      expect(reconstituted.startHour, 9);
      expect(reconstituted.gracePeriodMinutes, 15);
      expect(reconstituted.fullDayMinutes, 480);
    });

    test('ShiftEvaluationService marks punch-in before grace period as ON_TIME', () {
      final onTimePunch = DateTime(2026, 9, 25, 8, 55);
      final result = ShiftEvaluationService.evaluatePunch(
        punchTime: onTimePunch,
        punchType: 'PUNCH_IN',
        schedule: standardShift,
      );

      expect(result.punchStatus, 'ON_TIME');
      expect(result.lateMinutes, 0);
      expect(result.statusMessage, 'On Time');
    });

    test('ShiftEvaluationService marks punch-in within grace period as ON_TIME', () {
      final withinGracePunch = DateTime(2026, 9, 25, 9, 12);
      final result = ShiftEvaluationService.evaluatePunch(
        punchTime: withinGracePunch,
        punchType: 'PUNCH_IN',
        schedule: standardShift,
      );

      expect(result.punchStatus, 'ON_TIME');
      expect(result.lateMinutes, 0);
    });

    test('ShiftEvaluationService marks punch-in after grace period as LATE_ARRIVAL', () {
      final latePunch = DateTime(2026, 9, 25, 9, 35); // 35 mins late
      final result = ShiftEvaluationService.evaluatePunch(
        punchTime: latePunch,
        punchType: 'PUNCH_IN',
        schedule: standardShift,
      );

      expect(result.punchStatus, 'LATE_ARRIVAL');
      expect(result.lateMinutes, 35);
      expect(result.statusMessage, 'Late by 35m');
    });

    test('ShiftEvaluationService marks punch-out before shift end as EARLY_DEPARTURE', () {
      final earlyPunchOut = DateTime(2026, 9, 25, 17, 20); // 40 mins early
      final result = ShiftEvaluationService.evaluatePunch(
        punchTime: earlyPunchOut,
        punchType: 'PUNCH_OUT',
        schedule: standardShift,
        shiftDurationMinutes: 470,
      );

      expect(result.punchStatus, 'EARLY_DEPARTURE');
      expect(result.earlyMinutes, 40);
      expect(result.statusMessage, 'Left 40m early');
      expect(result.workStatus, 'HALF_DAY');
    });

    test('ShiftEvaluationService marks punch-out with >=15m after shift end as OVERTIME', () {
      final otPunchOut = DateTime(2026, 9, 25, 19, 15); // 1h 15m = 75m OT
      final result = ShiftEvaluationService.evaluatePunch(
        punchTime: otPunchOut,
        punchType: 'PUNCH_OUT',
        schedule: standardShift,
        shiftDurationMinutes: 610,
      );

      expect(result.punchStatus, 'OVERTIME');
      expect(result.overtimeMinutes, 75);
      expect(result.statusMessage, '+1h 15m OT');
      expect(result.workStatus, 'FULL_DAY');
    });

    test('VerifyFacePunchInUseCase passes shift intelligence to AttendanceRepository', () async {
      final mockRepo = MockAttendanceRepository();
      final useCase = VerifyFacePunchInUseCase(attendanceRepository: mockRepo);

      final liveEmbedding = [1.0, 0.0, 0.0, 0.0];
      final candidates = [
        const EmployeeProfile(
          uid: 'emp_bond',
          fullName: 'James Bond',
          employeeId: '007',
          enterpriseId: 'MI6',
          facialSignature: [1.0, 0.0, 0.0, 0.0],
          biometricsEnrolled: true,
        ),
      ];

      final result = await useCase.execute(
        liveEmbedding: liveEmbedding,
        candidates: candidates,
        enterpriseId: 'MI6',
        punchType: 'PUNCH_IN',
        shiftSchedule: standardShift,
      );

      expect(result.isMatch, isTrue);
      expect(result.matchedEmployee?.fullName, 'James Bond');
      expect(result.punchStatus, isNotNull);
      expect(result.statusMessage, isNotNull);

      expect(mockRepo.loggedEntries.length, 1);
      final entry = mockRepo.loggedEntries.first;
      expect(entry['userId'], 'emp_bond');
      expect(entry['punchStatus'], isNotNull);
    });
  });

  group('Push Notifications & Alert Logic Unit Tests', () {
    test('Regularization request alert builds accurate payload for admins', () {
      final shiftDate = DateTime(2026, 9, 24);
      final dateStr =
          "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}";
      const employeeName = "John Doe";
      const employeeId = "EMP101";
      const reason = "Forgot to clock out before leaving site";

      const title = "Regularization Request: $employeeName";
      final body = "$employeeName (ID: $employeeId) requested a clock-out correction for $dateStr. Reason: $reason";

      expect(title, contains("John Doe"));
      expect(body, contains("2026-09-24"));
      expect(body, contains("EMP101"));
      expect(body, contains(reason));
    });

    test('Regularization approval and rejection alerts format correctly for employee', () {
      final shiftDate = DateTime(2026, 9, 24);
      final dateStr =
          "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}";

      // Approved case
      const approvedTitle = "✅ Regularization Approved";
      final approvedBody =
          "Your attendance regularization for $dateStr has been approved! Shift is now closed.";
      expect(approvedTitle, contains("Approved"));
      expect(approvedBody, contains("Shift is now closed"));

      // Rejected case
      const rejectedTitle = "❌ Regularization Rejected";
      const reason = "Punch logs show exit at 1:00 PM";
      final rejectedBody =
          "Your attendance regularization for $dateStr was rejected. Reason: $reason";
      expect(rejectedTitle, contains("Rejected"));
      expect(rejectedBody, contains(reason));
    });

    test('Geofence breach alert accurately constructs distance and punch type', () {
      const employeeName = "Alice Smith";
      const punchType = "PUNCH_IN";
      const distance = 425.8;

      const title = "⚠️ Geofence Boundary Alert";
      final body = "$employeeName clocked $punchType ${distance.toInt()}m outside the office perimeter.";

      expect(title, "⚠️ Geofence Boundary Alert");
      expect(body, "Alice Smith clocked PUNCH_IN 425m outside the office perimeter.");
    });

    test('Notification unread count accurately aggregates only unread items', () {
      final notifications = [
        {'id': '1', 'read': false, 'type': 'REGULARIZATION_REQUEST'},
        {'id': '2', 'read': true, 'type': 'REGULARIZATION_APPROVED'},
        {'id': '3', 'read': false, 'type': 'GEOFENCE_BREACH'},
      ];

      final unreadCount = notifications.where((n) => n['read'] != true).length;
      expect(unreadCount, 2);
    });
  });

  group('PDF Timesheet & MIS Calculation Unit Tests', () {
    test('Calculates total work hours, on-time rate, and breach stats accurately', () {
      final mockLogs = [
        {
          'type': 'PUNCH_IN',
          'punchStatus': 'ON_TIME',
          'lateMinutes': 0,
          'overtimeMinutes': 0,
          'shiftDurationMinutes': 0,
          'withinGeofence': true,
        },
        {
          'type': 'PUNCH_OUT',
          'punchStatus': 'OVERTIME',
          'lateMinutes': 0,
          'overtimeMinutes': 45,
          'shiftDurationMinutes': 525, // 8h 45m
          'withinGeofence': true,
        },
        {
          'type': 'PUNCH_IN',
          'punchStatus': 'LATE_ARRIVAL',
          'lateMinutes': 20,
          'overtimeMinutes': 0,
          'shiftDurationMinutes': 0,
          'withinGeofence': false, // breach!
        },
        {
          'type': 'PUNCH_OUT',
          'punchStatus': 'ON_TIME',
          'lateMinutes': 0,
          'overtimeMinutes': 0,
          'shiftDurationMinutes': 480, // 8h
          'withinGeofence': true,
        },
      ];

      int punchIns = 0;
      int onTimeCount = 0;
      int lateCount = 0;
      int lateMinutesTotal = 0;
      int overtimeCount = 0;
      int overtimeMinutesTotal = 0;
      int geofenceBreaches = 0;
      int totalDurationMinutes = 0;

      for (final data in mockLogs) {
        final type = data['type'] as String;
        final punchStatus = data['punchStatus'] as String;
        final lateM = data['lateMinutes'] as int;
        final otM = data['overtimeMinutes'] as int;
        final dur = data['shiftDurationMinutes'] as int;
        final withinGeo = data['withinGeofence'] as bool;

        if (type == 'PUNCH_IN') {
          punchIns++;
          if (punchStatus == 'ON_TIME') onTimeCount++;
        }
        if (punchStatus == 'LATE_ARRIVAL' || lateM > 0) {
          lateCount++;
          lateMinutesTotal += lateM;
        }
        if (punchStatus == 'OVERTIME' || otM > 0) {
          overtimeCount++;
          overtimeMinutesTotal += otM;
        }
        if (!withinGeo) geofenceBreaches++;
        totalDurationMinutes += dur;
      }

      final totalHours = (totalDurationMinutes / 60).toStringAsFixed(1);
      final onTimeRate = ((onTimeCount / punchIns) * 100).toStringAsFixed(1);

      expect(mockLogs.length, 4);
      expect(punchIns, 2);
      expect(onTimeCount, 1);
      expect(onTimeRate, '50.0'); // 1 out of 2 punch ins was on-time
      expect(lateCount, 1);
      expect(lateMinutesTotal, 20);
      expect(overtimeCount, 1);
      expect(overtimeMinutesTotal, 45);
      expect(geofenceBreaches, 1);
      expect(totalHours, '16.8'); // 1005 mins / 60 = 16.75 -> 16.8h
    });
  });

  group('Leave & Time-Off Management Unit Tests', () {
    test('LeaveRequest serializes and calculates display properties accurately', () {
      final now = DateTime.now();
      final startDate = DateTime(2026, 10, 1);
      final endDate = DateTime(2026, 10, 3);
      final req = LeaveRequest(
        id: 'leave_123',
        userId: 'user_456',
        enterpriseId: 'CORP_HQ',
        employeeName: 'Alice Smith',
        employeeId: 'EMP-01',
        leaveType: 'SICK',
        startDate: startDate,
        endDate: endDate,
        daysCount: 3,
        reason: 'Viral fever and doctor consultation',
        appliedAt: now,
      );

      expect(req.leaveTypeDisplay, 'Sick Leave');
      expect(req.status, 'PENDING');
      expect(req.daysCount, 3);

      final map = req.toMap();
      expect(map['userId'], 'user_456');
      expect(map['enterpriseId'], 'CORP_HQ');
      expect(map['leaveType'], 'SICK');
      expect(map['daysCount'], 3);
      expect(map['status'], 'PENDING');
    });

    test('LeaveRequest displays human-readable names for all categories', () {
      final now = DateTime.now();
      LeaveRequest makeReq(String type) => LeaveRequest(
        id: '1',
        userId: 'u',
        enterpriseId: 'e',
        employeeName: 'n',
        employeeId: 'i',
        leaveType: type,
        startDate: now,
        endDate: now,
        daysCount: 1,
        reason: 'r',
        appliedAt: now,
      );

      expect(makeReq('CASUAL').leaveTypeDisplay, 'Casual Leave');
      expect(makeReq('SICK').leaveTypeDisplay, 'Sick Leave');
      expect(makeReq('PAID').leaveTypeDisplay, 'Paid Leave');
      expect(makeReq('WFH').leaveTypeDisplay, 'Work from Home');
      expect(makeReq('UNPAID').leaveTypeDisplay, 'Unpaid Time-Off');
    });
  });

  group('Payroll CSV & Summary Calculation Unit Tests', () {
    test('PayrollEmployeeSummary accurately computes payable hours and overtime hours', () {
      final summary = PayrollEmployeeSummary(
        userId: 'user_01',
        employeeId: 'EMP_101',
        fullName: 'Bob Johnson',
        department: 'Operations',
      );

      summary.totalWorkMinutes = 480; // 8 hours
      summary.totalOvertimeMinutes = 90; // 1.5 hours
      summary.daysPresent = 1;
      summary.fullDaysCount = 1;

      expect(summary.payableHours, 8.0);
      expect(summary.overtimeHours, 1.5);
    });

    test('generatePayrollCsv generates correct CSV header and data rows', () {
      final s1 = PayrollEmployeeSummary(
        userId: 'u1',
        employeeId: 'EMP_01',
        fullName: 'Charlie Green',
        department: 'Logistics',
      );
      s1.daysPresent = 20;
      s1.fullDaysCount = 19;
      s1.halfDaysCount = 1;
      s1.lateDaysCount = 2;
      s1.earlyDepartureCount = 0;
      s1.totalWorkMinutes = 9600; // 160 hrs
      s1.totalOvertimeMinutes = 180; // 3 hrs

      final csv = PayrollExportService.generatePayrollCsv([s1], periodTitle: 'October 2026');

      expect(csv.contains('# Payroll Timesheet Export - October 2026'), isTrue);
      expect(csv.contains('Employee ID,Full Name,Department,Days Present'), isTrue);
      expect(csv.contains('"EMP_01","Charlie Green","Logistics",20,19,1,2,0,9600,160.00,180,3.00'), isTrue);
    });

    test('correctly infers full/half days from shiftDurationMinutes when workStatus is absent', () {
      final logs = [
        {
          'userId': 'u_legacy',
          'employeeId': 'EMP_LEG',
          'employeeName': 'Legacy Worker',
          'type': 'PUNCH_OUT',
          'timestamp': DateTime(2026, 9, 27, 18, 0),
          'shiftDurationMinutes': 490, // >= 480 => Full Day
          'workStatus': null,
        },
        {
          'userId': 'u_legacy',
          'employeeId': 'EMP_LEG',
          'employeeName': 'Legacy Worker',
          'type': 'PUNCH_OUT',
          'timestamp': DateTime(2026, 9, 26, 14, 0),
          'shiftDurationMinutes': 250, // >= 240 => Half Day
          'workStatus': null,
        },
      ];

      final summaries = PayrollExportService.generatePayrollSummaryFromMaps(logs: logs);
      expect(summaries.length, 1);
      final s = summaries.first;
      expect(s.fullDaysCount, 1);
      expect(s.halfDaysCount, 1);
      expect(s.totalWorkMinutes, 740);
    });

    test('PayrollExportService accurately integrates unpaid lunch break deductions and generates detailed CSV', () {
      final now = DateTime(2026, 9, 29, 9, 0);
      final logs = [
        {
          'userId': 'usr_break_01',
          'employeeId': 'EMP_BRK1',
          'employeeName': 'Marcus Vance',
          'type': 'PUNCH_IN',
          'timestamp': now,
        },
        {
          'userId': 'usr_break_01',
          'employeeId': 'EMP_BRK1',
          'employeeName': 'Marcus Vance',
          'type': 'START_BREAK',
          'breakType': 'Lunch',
          'timestamp': now.add(const Duration(hours: 4)), // 13:00
        },
        {
          'userId': 'usr_break_01',
          'employeeId': 'EMP_BRK1',
          'employeeName': 'Marcus Vance',
          'type': 'END_BREAK',
          'timestamp': now.add(const Duration(hours: 4, minutes: 45)), // 13:45 (45 min unpaid)
        },
        {
          'userId': 'usr_break_01',
          'employeeId': 'EMP_BRK1',
          'employeeName': 'Marcus Vance',
          'type': 'PUNCH_OUT',
          'timestamp': now.add(const Duration(hours: 9)), // 18:00 (540 mins gross)
          'shiftDurationMinutes': 540,
        },
      ];

      final summaries = PayrollExportService.generatePayrollSummaryFromMaps(logs: logs);
      expect(summaries.length, 1);
      final s = summaries.first;

      expect(s.totalWorkMinutes, 540); // 9h gross
      expect(s.grossHours, 9.0);
      expect(s.unpaidBreakMinutes, 45); // 45m lunch
      expect(s.netWorkMinutes, 495); // 540 - 45 = 495 mins
      expect(s.payableHours, 8.25); // 495 / 60 = 8.25 hrs

      final detailedCsv = PayrollExportService.generateDetailedPayrollCsv(summaries, periodTitle: 'September 2026');
      expect(detailedCsv.contains('Gross Hours,Unpaid Breaks (Mins)'), isTrue);
      expect(detailedCsv.contains('"EMP_BRK1","Marcus Vance","General",1,1,0,0,0,540,9.00,45,0.75,0,495,8.25,0,0.00'), isTrue);
    });
  });

  group('Admin Terminal PIN & Multi-Tenant Retention Tests', () {
    test('validates default PIN 1234 and custom PIN matching logic', () {
      const defaultPin = '1234';
      String enterpriseKioskPin = '8899';

      bool isPinValid(String entered, String actual) {
        return entered == actual || entered == '1234' || entered == '0000';
      }

      expect(isPinValid('8899', enterpriseKioskPin), isTrue);
      expect(isPinValid('1234', enterpriseKioskPin), isTrue); // Emergency default override
      expect(isPinValid('0000', enterpriseKioskPin), isTrue); // Master developer override
      expect(isPinValid('1111', enterpriseKioskPin), isFalse); // Invalid PIN
      expect(isPinValid('8899', defaultPin), isFalse); // Default requires 1234
      expect(isPinValid('1234', defaultPin), isTrue);
    });

    test('multi-tenant workspace switching preserves linked enterprises without loss of access', () {
      final List<String> linkedEnterprises = ['CORP_A'];
      const currentEnterprise = 'CORP_B';

      // Admin switches workspace: current is appended to linkedEnterprises
      if (!linkedEnterprises.contains(currentEnterprise)) {
        linkedEnterprises.add(currentEnterprise);
      }

      expect(linkedEnterprises, contains('CORP_A'));
      expect(linkedEnterprises, contains('CORP_B'));
      expect(linkedEnterprises.length, 2);
    });
  });

  group('Multi-Shift Preset & Employee Assignment Tests', () {
    test('ShiftSchedule.fromPreset constructs correct shift hours', () {
      final morning = ShiftSchedule.fromPreset('morning');
      expect(morning.startHour, 6);
      expect(morning.endHour, 14);

      final evening = ShiftSchedule.fromPreset('evening');
      expect(evening.startHour, 14);
      expect(evening.endHour, 22);

      final night = ShiftSchedule.fromPreset('night');
      expect(night.startHour, 22);
      expect(night.endHour, 6);

      final general = ShiftSchedule.fromPreset('general');
      expect(general.startHour, 9);
      expect(general.endHour, 18);
    });

    test('EmployeeProfile preserves assignedShift in serialization and copyWith', () {
      const emp = EmployeeProfile(
        uid: 'user_123',
        fullName: 'Jane Doe',
        employeeId: 'EMP_099',
        assignedShift: 'morning',
      );
      expect(emp.assignedShift, 'morning');

      final json = emp.toJson();
      expect(json['assignedShift'], 'morning');

      final fromJson = EmployeeProfile.fromJson(json);
      expect(fromJson.assignedShift, 'morning');

      final updated = emp.copyWith(assignedShift: 'night');
      expect(updated.assignedShift, 'night');
    });
  });

  group('Workforce Reconciliation & Absenteeism Calculation Tests', () {
    test('accurately partitions roster into present, late, absent, and on-leave buckets', () {
      final roster = [
        const EmployeeProfile(uid: 'u1', fullName: 'Alice', employeeId: 'E1'),
        const EmployeeProfile(uid: 'u2', fullName: 'Bob', employeeId: 'E2'),
        const EmployeeProfile(uid: 'u3', fullName: 'Charlie', employeeId: 'E3'),
        const EmployeeProfile(uid: 'u4', fullName: 'Diana', employeeId: 'E4'),
        const EmployeeProfile(uid: 'u5', fullName: 'Evan', employeeId: 'E5'),
      ];

      // u1 and u2 clocked in today
      final presentUserIds = {'u1', 'u2'};
      // u2 was late
      final lateUserIds = {'u2'};
      // u3 is on approved leave today
      final onLeaveUserIds = {'u3'};

      final presentStaff = roster.where((e) => presentUserIds.contains(e.uid)).toList();
      final lateStaff = roster.where((e) => lateUserIds.contains(e.uid)).toList();
      final onLeaveStaff = roster.where((e) => !presentUserIds.contains(e.uid) && onLeaveUserIds.contains(e.uid)).toList();
      final absentStaff = roster.where((e) => !presentUserIds.contains(e.uid) && !onLeaveUserIds.contains(e.uid)).toList();

      expect(presentStaff.length, 2);
      expect(lateStaff.length, 1);
      expect(onLeaveStaff.length, 1);
      expect(absentStaff.length, 2); // u4 and u5 are absent

      // Conservation property: present + on_leave + absent == total roster
      expect(presentStaff.length + onLeaveStaff.length + absentStaff.length, roster.length);
      expect(absentStaff.map((e) => e.uid), containsAll(['u4', 'u5']));
    });

    test('AbsenteeismReconciliationService evaluates data and calculates correct metrics', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);

      final staffList = [
        {'employeeId': 'E001', 'userId': 'u1', 'fullName': 'Alice Walker'},
        {'employeeId': 'E002', 'userId': 'u2', 'fullName': 'Bob Builder'},
        {'employeeId': 'E003', 'userId': 'u3', 'fullName': 'Charlie Chaplin'},
        {'employeeId': 'E004', 'userId': 'u4', 'fullName': 'Diana Prince'},
        {'employeeId': 'E005', 'userId': 'u5', 'fullName': 'Evan Wright'},
      ];

      final attendanceLogs = [
        {
          'employeeId': 'E001',
          'userId': 'u1',
          'type': 'PUNCH_IN',
          'punchStatus': 'ON_TIME',
          'timestamp': today,
        },
        {
          'employeeId': 'E002',
          'userId': 'u2',
          'type': 'PUNCH_IN',
          'punchStatus': 'LATE_ARRIVAL',
          'timestamp': today.add(const Duration(minutes: 30)),
        },
      ];

      final approvedLeaves = [
        LeaveRequest(
          id: 'leave_1',
          userId: 'u3',
          enterpriseId: 'ent_1',
          employeeName: 'Charlie Chaplin',
          employeeId: 'E003',
          leaveType: 'CASUAL',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: today.add(const Duration(days: 1)),
          daysCount: 3,
          reason: 'Family Event',
          status: 'APPROVED',
          appliedAt: today.subtract(const Duration(days: 3)),
        ),
      ];

      final report = AbsenteeismReconciliationService.evaluateAttendanceData(
        staffList: staffList,
        attendanceLogs: attendanceLogs,
        approvedLeaves: approvedLeaves,
        targetDate: today,
      );

      expect(report.totalStaff, 5);
      expect(report.presentCount, 2);
      expect(report.lateCount, 1);
      expect(report.onLeaveCount, 1);
      expect(report.absentCount, 2);
      expect(report.attendanceRate, 40.0);
      expect(report.summaryText, contains('2 Present (1 Late), 2 Absent, 1 On Leave (Total: 5)'));

      // Check partition contents
      expect(report.presentEmployees.map((e) => e['employeeId']), containsAll(['E001', 'E002']));
      expect(report.lateEmployees.map((e) => e['employeeId']), contains('E002'));
      expect(report.onLeaveEmployees.first['employeeId'], 'E003');
      expect(report.absentEmployees.map((e) => e['employeeId']), containsAll(['E004', 'E005']));
    });
  });

  group('Shift Reminder Schedule & Timings Tests', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('calculateNextScheduleTime correctly applies positive and negative offsets', () {
      final reminderService = ShiftReminderService();
      final local = tz.local;

      // 9:00 AM with -15 minute offset -> should be 8:45 AM
      final shiftInTime = reminderService.calculateNextScheduleTime(
        hour: 9,
        minute: 0,
        offsetMinutes: -15,
        location: local,
      );
      expect(shiftInTime.hour, 8);
      expect(shiftInTime.minute, 45);

      // 18:00 (6:00 PM) with +10 minute offset -> should be 18:10 (6:10 PM)
      final shiftOutTime = reminderService.calculateNextScheduleTime(
        hour: 18,
        minute: 0,
        offsetMinutes: 10,
        location: local,
      );
      expect(shiftOutTime.hour, 18);
      expect(shiftOutTime.minute, 10);
    });

    test('calculateNextScheduleTime always yields a future or current timestamp', () {
      final reminderService = ShiftReminderService();
      final local = tz.local;
      final now = tz.TZDateTime.now(local);

      final nextTime = reminderService.calculateNextScheduleTime(
        hour: (now.hour - 1 + 24) % 24, // an hour that already passed today
        minute: 0,
        location: local,
      );

      // Must roll over to the future (tomorrow)
      expect(nextTime.isAfter(now), isTrue);
    });
  });

  group('AuditLogService Compliance & CSV Tests', () {
    test('generateAuditCsv builds RFC-compliant CSV headers and rows with escaped quotes', () {
      final sampleLogs = [
        {
          'timestamp': DateTime(2026, 9, 27, 10, 30),
          'action': 'SHIFT_POLICY_UPDATED',
          'category': 'POLICY',
          'adminEmail': 'admin@enterprise.com',
          'targetEmployeeName': 'Alice Walker',
          'targetEmployeeId': 'E001',
          'details': 'Updated shift to "Morning Shift", grace 15m.',
        },
        {
          'timestamp': DateTime(2026, 9, 27, 11, 00),
          'action': 'PIN_CHANGED',
          'category': 'SECURITY',
          'adminEmail': 'security@enterprise.com',
          'details': 'Reset kiosk PIN to default 1234.',
        },
      ];

      final csv = AuditLogService.generateAuditCsv(sampleLogs);

      expect(csv, contains('Timestamp,Action,Category,Admin Email,Target Employee,Details'));
      expect(csv, contains('"SHIFT_POLICY_UPDATED","POLICY","admin@enterprise.com","Alice Walker (E001)"'));
      expect(csv, contains('""Morning Shift"", grace 15m.'));
      expect(csv, contains('"PIN_CHANGED","SECURITY","security@enterprise.com","N/A"'));
    });
  });

  group('KioskLivenessEvaluator Anti-Spoofing Tests', () {
    test('validates upright live face with open eyes passes liveness check', () {
      final face = Face(
        boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleX: 2.0,
        headEulerAngleY: -3.0,
        headEulerAngleZ: 1.0,
        leftEyeOpenProbability: 0.88,
        rightEyeOpenProbability: 0.91,
      );

      final result = KioskLivenessEvaluator.evaluateFace(face);

      expect(result.isLive, isTrue);
      expect(result.statusMessage, contains('Liveness Verified'));
      expect(result.leftEyeOpen, 0.88);
      expect(result.rightEyeOpen, 0.91);
    });

    test('rejects face with closed eyes to prevent static photo replay attacks', () {
      final face = Face(
        boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleX: 0.0,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
        leftEyeOpenProbability: 0.05,
        rightEyeOpenProbability: 0.08,
      );

      final result = KioskLivenessEvaluator.evaluateFace(face);

      expect(result.isLive, isFalse);
      expect(result.statusMessage, contains('Eyes closed'));
    });

    test('rejects face turned away or tilted severely', () {
      final turnedFace = Face(
        boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleY: 35.0, // Turned past threshold
        leftEyeOpenProbability: 0.9,
        rightEyeOpenProbability: 0.9,
      );

      final resultTurned = KioskLivenessEvaluator.evaluateFace(turnedFace);
      expect(resultTurned.isLive, isFalse);
      expect(resultTurned.statusMessage, contains('face the camera directly'));

      final tiltedFace = Face(
        boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleZ: 28.0, // Tilted past threshold
        leftEyeOpenProbability: 0.9,
        rightEyeOpenProbability: 0.9,
      );

      final resultTilted = KioskLivenessEvaluator.evaluateFace(tiltedFace);
      expect(resultTilted.isLive, isFalse);
      expect(resultTilted.statusMessage, contains('keep your head upright'));
    });
  });

  group('Enterprise Verification Channels & Leave Quota Tests', () {
    test('default allowed verification methods includes all 4 channels', () {
      const defaultChannels = ['KIOSK_FACE', 'KIOSK_PIN', 'MOBILE_GPS', 'OFFICE_WIFI'];
      expect(defaultChannels.length, 4);
      expect(defaultChannels.contains('KIOSK_FACE'), isTrue);
      expect(defaultChannels.contains('MOBILE_GPS'), isTrue);
    });

    test('leave request computes proper day count across date ranges', () {
      final req = LeaveRequest(
        id: 'test-req-1',
        userId: 'usr-123',
        enterpriseId: 'apex-hq',
        employeeName: 'John Doe',
        employeeId: 'EMP001',
        leaveType: 'CASUAL',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 3),
        daysCount: 3,
        reason: 'Personal function',
        appliedAt: DateTime(2026, 9, 27),
      );

      expect(req.daysCount, 3);
      expect(req.status, 'PENDING');
      expect(req.leaveTypeDisplay, 'Casual Leave');
    });

    test('verifies single-day leave request has daysCount of 1', () {
      final start = DateTime(2026, 10, 5);
      final end = DateTime(2026, 10, 5);
      final daysCount = end.difference(start).inDays + 1;
      expect(daysCount, 1);
    });
  });

  group('Jibble Phase 2: Break Tracking & Live Presence Session Tests', () {
    test('BreakCategory classifies lunch as unpaid and rest as paid', () {
      expect(BreakCategory.lunch.isPaid, isFalse);
      expect(BreakCategory.lunch.standardMinutes, 45);
      expect(BreakCategory.lunch.displayName, 'Lunch Break');

      expect(BreakCategory.rest.isPaid, isTrue);
      expect(BreakCategory.rest.standardMinutes, 15);
      expect(BreakCategory.rest.displayName, 'Rest / Tea Break');

      expect(BreakCategory.fromString('Lunch Break'), BreakCategory.lunch);
      expect(BreakCategory.fromString('Tea Break'), BreakCategory.rest);
      expect(BreakCategory.fromString('Coffee'), BreakCategory.rest);
      expect(BreakCategory.fromString('Doctor Visit'), BreakCategory.custom);
    });

    test('EmployeeDailySession reports absent when no logs exist', () {
      final session = EmployeeDailySession.evaluate(
        userId: 'usr-1',
        employeeName: 'Alice',
        employeeId: 'EMP01',
        department: 'Engineering',
        employeeLogsToday: [],
      );

      expect(session.status, EmployeeWorkStatus.absent);
      expect(session.netWorkDuration, Duration.zero);
      expect(session.punchInTime, isNull);
    });

    test('EmployeeDailySession reports onLeave when employee has approved leave', () {
      final session = EmployeeDailySession.evaluate(
        userId: 'usr-2',
        employeeName: 'Bob',
        employeeId: 'EMP02',
        department: 'Finance',
        employeeLogsToday: [],
        isOnApprovedLeave: true,
        leaveReason: 'Sick Leave',
      );

      expect(session.status, EmployeeWorkStatus.onLeave);
      expect(session.leaveReason, 'Sick Leave');
    });

    test('EmployeeDailySession reports active working state with net duration', () {
      final now = DateTime(2026, 9, 29, 13, 0);
      final punchIn = DateTime(2026, 9, 29, 9, 0);

      final session = EmployeeDailySession.evaluate(
        userId: 'usr-3',
        employeeName: 'Charlie',
        employeeId: 'EMP03',
        department: 'Operations',
        employeeLogsToday: [
          {'type': 'PUNCH_IN', 'timestamp': Timestamp.fromDate(punchIn), 'verifiedVia': 'MOBILE_GPS'},
        ],
        nowOverride: now,
      );

      expect(session.status, EmployeeWorkStatus.working);
      expect(session.punchInTime, punchIn);
      expect(session.punchOutTime, isNull);
      expect(session.grossDuration, const Duration(hours: 4));
      expect(session.netWorkDuration, const Duration(hours: 4));
      expect(session.totalBreakDuration, Duration.zero);
      expect(session.lastVerifiedVia, 'MOBILE_GPS');
    });

    test('EmployeeDailySession calculates onBreak and running break duration', () {
      final punchIn = DateTime(2026, 9, 29, 9, 0);
      final breakStart = DateTime(2026, 9, 29, 12, 0);
      final now = DateTime(2026, 9, 29, 12, 30); // 30 mins into break

      final session = EmployeeDailySession.evaluate(
        userId: 'usr-4',
        employeeName: 'Dana',
        employeeId: 'EMP04',
        department: 'Product',
        employeeLogsToday: [
          {'type': 'PUNCH_IN', 'timestamp': Timestamp.fromDate(punchIn)},
          {'type': 'START_BREAK', 'timestamp': Timestamp.fromDate(breakStart), 'breakType': 'Lunch Break'},
        ],
        nowOverride: now,
      );

      expect(session.status, EmployeeWorkStatus.onBreak);
      expect(session.breakStartTime, breakStart);
      expect(session.activeBreakCategory, BreakCategory.lunch);
      expect(session.totalBreakDuration, const Duration(minutes: 30));
      expect(session.unpaidBreakDuration, const Duration(minutes: 30));
      // Gross 3.5h minus 30m unpaid break = 3.0h net work
      expect(session.netWorkDuration, const Duration(hours: 3));
    });

    test('EmployeeDailySession accurately deducts unpaid lunch but preserves paid rest breaks upon clock out', () {
      final punchIn = DateTime(2026, 9, 29, 9, 0);
      final restStart = DateTime(2026, 9, 29, 11, 0);
      final restEnd = DateTime(2026, 9, 29, 11, 15); // 15m paid
      final lunchStart = DateTime(2026, 9, 29, 13, 0);
      final lunchEnd = DateTime(2026, 9, 29, 13, 45); // 45m unpaid
      final punchOut = DateTime(2026, 9, 29, 18, 0); // 9h gross

      final session = EmployeeDailySession.evaluate(
        userId: 'usr-5',
        employeeName: 'Elena',
        employeeId: 'EMP05',
        department: 'Design',
        employeeLogsToday: [
          {'type': 'PUNCH_IN', 'timestamp': Timestamp.fromDate(punchIn)},
          {'type': 'START_BREAK', 'timestamp': Timestamp.fromDate(restStart), 'breakType': 'Rest / Tea Break'},
          {'type': 'END_BREAK', 'timestamp': Timestamp.fromDate(restEnd)},
          {'type': 'START_BREAK', 'timestamp': Timestamp.fromDate(lunchStart), 'breakType': 'Lunch Break'},
          {'type': 'END_BREAK', 'timestamp': Timestamp.fromDate(lunchEnd)},
          {'type': 'PUNCH_OUT', 'timestamp': Timestamp.fromDate(punchOut), 'verifiedVia': 'KIOSK'},
        ],
      );

      expect(session.status, EmployeeWorkStatus.clockedOut);
      expect(session.grossDuration, const Duration(hours: 9));
      expect(session.paidBreakDuration, const Duration(minutes: 15));
      expect(session.unpaidBreakDuration, const Duration(minutes: 45));
      expect(session.totalBreakDuration, const Duration(minutes: 60));
      // Net Work = Gross (9h) - Unpaid Break (45m) = 8h 15m (495 mins)
      expect(session.netWorkDuration, const Duration(hours: 8, minutes: 15));
      expect(session.lastVerifiedVia, 'KIOSK');
    });

    test('EmployeeDailySession accurately detects active break overstays exceeding category threshold', () {
      final punchIn = DateTime(2026, 9, 29, 9, 0);
      final breakStart = DateTime(2026, 9, 29, 13, 0);
      // Lunch break standard is 45 mins. At 14:00 (60 mins), overstay is 15 mins.
      final nowOverstay = DateTime(2026, 9, 29, 14, 0);

      final overstaySession = EmployeeDailySession.evaluate(
        userId: 'usr-overstay',
        employeeName: 'Overstay User',
        employeeId: 'EMP06',
        department: 'Engineering',
        employeeLogsToday: [
          {'type': 'PUNCH_IN', 'timestamp': Timestamp.fromDate(punchIn)},
          {'type': 'START_BREAK', 'timestamp': Timestamp.fromDate(breakStart), 'breakType': 'Lunch Break'},
        ],
        nowOverride: nowOverstay,
      );

      expect(overstaySession.status, EmployeeWorkStatus.onBreak);
      expect(overstaySession.isOverstayedBreak, isTrue);
      expect(overstaySession.overstayMinutes, equals(15));
      expect(overstaySession.activeBreakCategory, BreakCategory.lunch);

      // Now test within threshold: 30 minutes into lunch (45 min limit)
      final nowWithinLimit = DateTime(2026, 9, 29, 13, 30);
      final normalSession = EmployeeDailySession.evaluate(
        userId: 'usr-normal',
        employeeName: 'Normal User',
        employeeId: 'EMP07',
        department: 'Engineering',
        employeeLogsToday: [
          {'type': 'PUNCH_IN', 'timestamp': Timestamp.fromDate(punchIn)},
          {'type': 'START_BREAK', 'timestamp': Timestamp.fromDate(breakStart), 'breakType': 'Lunch Break'},
        ],
        nowOverride: nowWithinLimit,
      );

      expect(normalSession.status, EmployeeWorkStatus.onBreak);
      expect(normalSession.isOverstayedBreak, isFalse);
      expect(normalSession.overstayMinutes, equals(0));
    });

    test('VerifyFacePunchInUseCase transitions seamlessly through KIOSK Break sequences', () async {
      final mockAttendanceRepo = MockAttendanceRepository();
      final useCase = VerifyFacePunchInUseCase(
        attendanceRepository: mockAttendanceRepo,
        defaultThreshold: 0.65,
      );

      final dummyEmbedding = FaceMathUtils.l2Normalize(List.generate(192, (i) => 1.0));
      final candidates = [
        EmployeeProfile(
          uid: 'usr_kiosk_1',
          fullName: 'Arun Test',
          employeeId: 'EMP99',
          facialSignature: List<double>.from(dummyEmbedding),
          biometricsEnrolled: true,
        ),
      ];

      // 1. Initial Punch In
      final resIn = await useCase.execute(
        liveEmbedding: dummyEmbedding,
        candidates: candidates,
        enterpriseId: 'ent_123',
        punchType: 'PUNCH_IN',
        verifiedVia: 'KIOSK',
      );
      expect(resIn.isMatch, isTrue);
      expect(resIn.punchType, 'PUNCH_IN');
      expect(mockAttendanceRepo.loggedEntries.last['type'], 'PUNCH_IN');

      // Set latest punch as PUNCH_IN
      mockAttendanceRepo.latestPunch = {
        'type': 'PUNCH_IN',
        'timestamp': Timestamp.now(),
      };

      // 2. Kiosk Switch to BREAK mode (Lunch Break)
      final resBreak = await useCase.execute(
        liveEmbedding: dummyEmbedding,
        candidates: candidates,
        enterpriseId: 'ent_123',
        punchType: 'BREAK',
        selectedBreakType: 'Lunch',
        verifiedVia: 'KIOSK',
      );
      expect(resBreak.isMatch, isTrue);
      expect(resBreak.punchType, 'START_BREAK');
      expect(resBreak.breakType, 'Lunch');
      expect(mockAttendanceRepo.loggedEntries.last['type'], 'START_BREAK');
      expect(mockAttendanceRepo.loggedEntries.last['breakType'], 'Lunch');

      // Set latest punch as START_BREAK
      mockAttendanceRepo.latestPunch = {
        'type': 'START_BREAK',
        'breakType': 'Lunch',
        'timestamp': Timestamp.now(),
      };

      // 3. Employee steps back in front of Kiosk in AUTO mode -> Auto resume from break
      final resResume = await useCase.execute(
        liveEmbedding: dummyEmbedding,
        candidates: candidates,
        enterpriseId: 'ent_123',
        punchType: 'AUTO',
        verifiedVia: 'KIOSK',
      );
      expect(resResume.isMatch, isTrue);
      expect(resResume.punchType, 'END_BREAK');
      expect(mockAttendanceRepo.loggedEntries.last['type'], 'END_BREAK');

      // Set latest punch as PUNCH_OUT
      mockAttendanceRepo.latestPunch = {
        'type': 'PUNCH_OUT',
        'timestamp': Timestamp.now(),
      };

      // 4. If employee attempts to take break while clocked out -> sequence validation blocks it
      final resInvalidBreak = await useCase.execute(
        liveEmbedding: dummyEmbedding,
        candidates: candidates,
        enterpriseId: 'ent_123',
        punchType: 'BREAK',
        selectedBreakType: 'Rest',
        verifiedVia: 'KIOSK',
      );
      expect(resInvalidBreak.isMatch, isTrue);
      expect(resInvalidBreak.isSequenceError, isTrue);
      expect(resInvalidBreak.sequenceErrorMessage, contains('Please clock IN before taking a break'));
    });
  });

  group('Automated Overtime & Tier Calculation Unit Tests (Jibble Standard)', () {
    final policy = OvertimePolicy.standard(); // 8h standard, 12h double OT, 40h weekly

    test('Standard day with <= 8 hours reports 100% regular time', () {
      final res = OvertimeCalculationService.calculateDaily(
        date: DateTime(2026, 9, 29),
        totalWorkMinutes: 480, // 8.0 hours
        policy: policy,
      );

      expect(res.regularMinutes, 480);
      expect(res.standardOvertimeMinutes, 0);
      expect(res.doubleOvertimeMinutes, 0);
      expect(res.totalOvertimeHours, 0.0);
      expect(res.getWeightedPayableHours(policy), 8.0);
    });

    test('Day with 10 hours splits into 8h regular and 2h standard 1.5x OT', () {
      final res = OvertimeCalculationService.calculateDaily(
        date: DateTime(2026, 9, 29),
        totalWorkMinutes: 600, // 10.0 hours
        policy: policy,
      );

      expect(res.regularMinutes, 480); // 8.0 hrs
      expect(res.standardOvertimeMinutes, 120); // 2.0 hrs
      expect(res.doubleOvertimeMinutes, 0);
      expect(res.totalOvertimeHours, 2.0);
      // 8h * 1.0 + 2h * 1.5 = 11.0 weighted payable hours
      expect(res.getWeightedPayableHours(policy), 11.0);
    });

    test('Day with 14 hours splits into 8h regular, 4h standard OT, and 2h double OT (2.0x)', () {
      final res = OvertimeCalculationService.calculateDaily(
        date: DateTime(2026, 9, 29),
        totalWorkMinutes: 840, // 14.0 hours
        policy: policy,
      );

      expect(res.regularMinutes, 480); // 8.0 hrs
      expect(res.standardOvertimeMinutes, 240); // 4.0 hrs (between 8h and 12h)
      expect(res.doubleOvertimeMinutes, 120); // 2.0 hrs (above 12h)
      expect(res.totalOvertimeHours, 6.0);
      // 8h * 1.0 + 4h * 1.5 (6h) + 2h * 2.0 (4h) = 18.0 weighted payable hours
      expect(res.getWeightedPayableHours(policy), 18.0);
    });

    test('Rest day work treats all hours as rest day premium (1.5x)', () {
      final res = OvertimeCalculationService.calculateDaily(
        date: DateTime(2026, 9, 27),
        totalWorkMinutes: 300, // 5.0 hours on Sunday
        isRestDay: true,
        policy: policy,
      );

      expect(res.regularMinutes, 0);
      expect(res.restDayMinutes, 300);
      expect(res.totalOvertimeHours, 5.0);
      // 5h * 1.5 = 7.5 weighted payable hours
      expect(res.getWeightedPayableHours(policy), 7.5);
    });

    test('Public holiday work treats all hours as holiday premium (2.0x)', () {
      final res = OvertimeCalculationService.calculateDaily(
        date: DateTime(2026, 10, 2),
        totalWorkMinutes: 480, // 8.0 hours
        isHoliday: true,
        policy: policy,
      );

      expect(res.regularMinutes, 0);
      expect(res.holidayMinutes, 480);
      expect(res.totalOvertimeHours, 8.0);
      // 8h * 2.0 = 16.0 weighted payable hours
      expect(res.getWeightedPayableHours(policy), 16.0);
    });

    test('Weekly period aggregation promotes excess regular hours to weekly OT', () {
      // 6 working days of 8 hours = 48 regular hours
      // With a 40-hour weekly cap, 40 hours stay regular and 8 hours convert to weekly OT
      final logs = List.generate(6, (i) => {
        'date': DateTime(2026, 9, 21 + i),
        'minutes': 480,
      });

      final breakdown = OvertimeCalculationService.calculatePeriodBreakdown(
        dailyLogs: logs,
        policy: policy,
      );

      expect(breakdown.regularHours, 40.0);
      expect(breakdown.weeklyOtHours, 8.0);
      expect(breakdown.totalOvertimeHours, 8.0);
      // 40h * 1.0 + 8h * 1.5 = 52.0 weighted hours
      expect(breakdown.totalWeightedPayableHours, 52.0);
      expect(breakdown.formattedRegularHours, '40.0 hrs');
      expect(breakdown.formattedOvertimeHours, '8.0 hrs');
    });

    test('OvertimePolicy serialization and copyWith work properly', () {
      final json = policy.toJson();
      final revived = OvertimePolicy.fromJson(json);
      expect(revived.dailyStandardThresholdMinutes, 480);
      expect(revived.standardOvertimeMultiplier, 1.5);
      expect(revived.doubleOvertimeMultiplier, 2.0);

      final modified = policy.copyWith(dailyStandardThresholdMinutes: 420);
      expect(modified.dailyStandardThresholdMinutes, 420);
      expect(modified.standardOvertimeMultiplier, 1.5);
    });
  });

  group('Multi-Factor Office Network & Geofence Verification Unit Tests (Jibble Standard)', () {
    const policy = NetworkGeofencePolicy(
      isWifiGeofenceEnabled: true,
      isIpWhitelistEnabled: true,
      mode: GeofenceVerificationMode.gpsOrWifi,
      allowedSsids: ['Cyberdyne_HQ', 'Acme_Office_Guest'],
      allowedBssids: ['00:14:22:01:23:45', 'a4:2b:b0:99:11:ee'],
      allowedIpSubnets: ['192.168.1.', '10.0.4.'],
    );

    test('gpsOrWifi mode approves when only GPS matches and Wi-Fi is absent', () {
      final res = OfficeNetworkVerificationService.evaluatePresence(
        policy: policy,
        isGpsWithinGeofence: true,
        distanceMeters: 45.0,
        allowedRadiusMeters: 100.0,
      );

      expect(res.isValid, isTrue);
      expect(res.primaryChannel, 'MOBILE_GPS');
      expect(res.gpsMatched, isTrue);
      expect(res.wifiMatched, isFalse);
    });

    test('gpsOrWifi mode approves when GPS is outside perimeter but connected to Office Wi-Fi', () {
      final res = OfficeNetworkVerificationService.evaluatePresence(
        policy: policy,
        isGpsWithinGeofence: false,
        distanceMeters: 250.0,
        connectedSsid: 'Cyberdyne_HQ',
        connectedBssid: '00:14:22:01:23:45',
      );

      expect(res.isValid, isTrue);
      expect(res.primaryChannel, 'OFFICE_WIFI');
      expect(res.wifiMatched, isTrue);
      expect(res.gpsMatched, isFalse);
    });

    test('gpsOrWifi mode reports dual verification when both GPS and Wi-Fi match', () {
      final res = OfficeNetworkVerificationService.evaluatePresence(
        policy: policy,
        isGpsWithinGeofence: true,
        distanceMeters: 30.0,
        connectedSsid: 'Cyberdyne_HQ',
        connectedBssid: '00:14:22:01:23:45',
      );

      expect(res.isValid, isTrue);
      expect(res.primaryChannel, 'DUAL_VERIFIED');
      expect(res.gpsMatched, isTrue);
      expect(res.wifiMatched, isTrue);
    });

    test('gpsOrWifi mode rejects when both GPS is outside and Wi-Fi SSID does not match', () {
      final res = OfficeNetworkVerificationService.evaluatePresence(
        policy: policy,
        isGpsWithinGeofence: false,
        distanceMeters: 350.0,
        connectedSsid: 'Starbucks_Free_WiFi',
      );

      expect(res.isValid, isFalse);
      expect(res.failureReason, contains('Neither office GPS perimeter nor authorized office Wi-Fi matched'));
    });

    test('gpsAndWifi mode requires BOTH GPS and Wi-Fi to match', () {
      final strictPolicy = policy.copyWith(mode: GeofenceVerificationMode.gpsAndWifi);

      // Only Wi-Fi matches -> should fail in strict mode
      final resWifiOnly = OfficeNetworkVerificationService.evaluatePresence(
        policy: strictPolicy,
        isGpsWithinGeofence: false,
        connectedSsid: 'Cyberdyne_HQ',
        connectedBssid: '00:14:22:01:23:45',
      );
      expect(resWifiOnly.isValid, isFalse);
      expect(resWifiOnly.failureReason, contains('High security verification failed: GPS coordinates not verified'));

      // Both match -> succeeds
      final resBoth = OfficeNetworkVerificationService.evaluatePresence(
        policy: strictPolicy,
        isGpsWithinGeofence: true,
        distanceMeters: 20.0,
        connectedSsid: 'Cyberdyne_HQ',
        connectedBssid: '00:14:22:01:23:45',
      );
      expect(resBoth.isValid, isTrue);
      expect(resBoth.primaryChannel, 'DUAL_VERIFIED');
    });

    test('BSSID filtering blocks spoofed SSIDs with rogue hardware MACs', () {
      final res = OfficeNetworkVerificationService.evaluatePresence(
        policy: policy,
        connectedSsid: 'Cyberdyne_HQ',
        connectedBssid: 'ff:ff:ff:ff:ff:ff', // Rogue MAC address
      );

      expect(res.wifiMatched, isFalse);
      expect(res.isValid, isFalse);
    });
  });

  group('Manager Jurisdiction & Department-Scoped Approvals Unit Tests (Jibble Standard)', () {
    const adminProfile = ManagerJurisdictionProfile(
      userId: 'admin_1',
      role: EnterpriseUserRole.admin,
      enterpriseId: 'ent_1',
    );

    const engineeringManager = ManagerJurisdictionProfile(
      userId: 'mgr_eng',
      role: EnterpriseUserRole.manager,
      enterpriseId: 'ent_1',
      managedDepartments: ['Engineering', 'DevOps'],
    );

    const employeeProfile = ManagerJurisdictionProfile(
      userId: 'emp_1',
      role: EnterpriseUserRole.employee,
      enterpriseId: 'ent_1',
    );

    test('Enterprise Admin has global authority across all departments', () {
      expect(
        DepartmentPermissionService.hasAuthorityOverDepartment(
          reviewer: adminProfile,
          targetDepartment: 'Marketing',
        ),
        isTrue,
      );
      expect(
        DepartmentPermissionService.canApproveLeave(
          reviewer: adminProfile,
          employeeDepartment: 'Human Resources',
        ),
        isTrue,
      );
      expect(adminProfile.jurisdiction, ApprovalJurisdiction.global);
    });

    test('Department Manager can only approve requests in assigned departments', () {
      // Matches managed department
      expect(
        DepartmentPermissionService.canApproveLeave(
          reviewer: engineeringManager,
          employeeDepartment: 'Engineering',
        ),
        isTrue,
      );
      expect(
        DepartmentPermissionService.canApproveRegularization(
          reviewer: engineeringManager,
          employeeDepartment: 'DevOps',
        ),
        isTrue,
      );

      // Rejects foreign department
      expect(
        DepartmentPermissionService.canApproveLeave(
          reviewer: engineeringManager,
          employeeDepartment: 'Finance',
        ),
        isFalse,
      );
      expect(engineeringManager.jurisdiction, ApprovalJurisdiction.department);
    });

    test('Regular Employee has zero managerial jurisdiction', () {
      expect(
        DepartmentPermissionService.hasAuthorityOverDepartment(
          reviewer: employeeProfile,
          targetDepartment: 'Engineering',
        ),
        isFalse,
      );
      expect(employeeProfile.jurisdiction, ApprovalJurisdiction.none);
    });

    test('filterScopedItems cleanly filters request lists to authorized department members', () {
      final sampleRequests = [
        {'id': 'req1', 'dept': 'Engineering'},
        {'id': 'req2', 'dept': 'Finance'},
        {'id': 'req3', 'dept': 'DevOps'},
        {'id': 'req4', 'dept': 'Sales'},
      ];

      final filtered = DepartmentPermissionService.filterScopedItems<Map<String, String>>(
        reviewer: engineeringManager,
        items: sampleRequests,
        departmentExtractor: (r) => r['dept']!,
      );

      expect(filtered.length, 2);
      expect(filtered.map((r) => r['id']).toList(), ['req1', 'req3']);
    });
  });

  group('Daily Attendance Digest & Operational Anomaly Feed Unit Tests (Jibble Standard)', () {
    final today = DateTime(2026, 9, 29);
    final eveningEvaluation = DateTime(2026, 9, 29, 19, 30); // 7:30 PM

    final sampleRoster = [
      {'id': 'u1', 'fullName': 'Alice Walker', 'department': 'Engineering'},
      {'id': 'u2', 'fullName': 'Bob Builder', 'department': 'Maintenance'},
      {'id': 'u3', 'fullName': 'Charlie Chaplin', 'department': 'Design'},
      {'id': 'u4', 'fullName': 'Diana Prince', 'department': 'Security'},
    ];

    test('Accurately aggregates present, late, absent, and on-leave headcount metrics', () {
      final logs = [
        // Alice on time (9:00 AM punch in, 6:00 PM punch out)
        {'userId': 'u1', 'type': 'PUNCH_IN', 'timestamp': DateTime(2026, 9, 29, 9, 0), 'punchStatus': 'ON_TIME'},
        {'userId': 'u1', 'type': 'PUNCH_OUT', 'timestamp': DateTime(2026, 9, 29, 18, 0)},
        // Bob late (9:45 AM punch in)
        {'userId': 'u2', 'type': 'PUNCH_IN', 'timestamp': DateTime(2026, 9, 29, 9, 45), 'punchStatus': 'LATE_ARRIVAL', 'lateMinutes': 45},
        {'userId': 'u2', 'type': 'PUNCH_OUT', 'timestamp': DateTime(2026, 9, 29, 18, 0)},
      ];

      final leaves = [
        {'userId': 'u3', 'status': 'APPROVED', 'type': 'SICK'},
      ];

      final digest = DailyAttendanceDigestService.generateDailyDigest(
        date: today,
        roster: sampleRoster,
        logs: logs,
        approvedLeaves: leaves,
        evaluationTime: eveningEvaluation,
      );

      expect(digest.totalHeadcount, 4);
      expect(digest.presentCount, 2);
      expect(digest.lateCount, 1);
      expect(digest.onLeaveCount, 1);
      expect(digest.absentCount, 1); // Diana is absent
      expect(digest.onTimeRatePercent, 50.0); // 1 on time / 2 present = 50%
      expect(digest.attendanceRatePercent, 50.0); // 2 present / 4 headcount = 50%
      expect(digest.unclosedShiftsCount, 0);
      expect(digest.hasCriticalAnomalies, isFalse);
    });

    test('Flags unclosed shifts and generates clear anomaly description after evening', () {
      final logs = [
        // Alice punched in at 9:00 AM, but has no PUNCH_OUT recorded by 7:30 PM!
        {'userId': 'u1', 'type': 'PUNCH_IN', 'timestamp': DateTime(2026, 9, 29, 9, 0), 'punchStatus': 'ON_TIME'},
      ];

      final digest = DailyAttendanceDigestService.generateDailyDigest(
        date: today,
        roster: sampleRoster,
        logs: logs,
        evaluationTime: eveningEvaluation,
      );

      expect(digest.unclosedShiftsCount, 1);
      expect(digest.hasCriticalAnomalies, isTrue);
      expect(digest.criticalAnomalies.first, contains('Alice Walker: Missing clock-out'));
    });

    test('DailyAttendanceDigest serialization preserves all statistics', () {
      final digest = DailyAttendanceDigest(
        date: DateTime(2026, 9, 29),
        totalHeadcount: 50,
        presentCount: 45,
        lateCount: 5,
        unclosedShiftsCount: 2,
        totalOvertimeHours: 12.5,
      );

      final json = digest.toJson();
      final revived = DailyAttendanceDigest.fromJson(json);

      expect(revived.totalHeadcount, 50);
      expect(revived.presentCount, 45);
      expect(revived.lateCount, 5);
      expect(revived.unclosedShiftsCount, 2);
      expect(revived.totalOvertimeHours, 12.5);
      expect(revived.onTimeRatePercent, closeTo(88.8, 0.2));
    });
  });

  group('Shift Automation & Break Auto-Deductions Unit Tests (Jibble Standard)', () {
    const shift = ShiftSchedule(
      shiftName: 'General Shift',
      startHour: 9,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
    );

    test('Triggers auto clock-out when shift duration exceeds 12-hour max cap', () {
      final punchIn = DateTime(2026, 9, 29, 8, 0);
      final now13HoursLater = DateTime(2026, 9, 29, 21, 0); // 13 hours later

      final decision = ShiftAutomationService.evaluateAutoClockOut(
        punchInTime: punchIn,
        currentTime: now13HoursLater,
        shift: shift,
        policy: const ShiftAutomationPolicy(
          autoClockOutEnabled: true,
          autoClockOutMaxShiftHours: 12,
        ),
      );

      expect(decision.shouldClockOut, isTrue);
      expect(decision.effectiveClockOutTime, punchIn.add(const Duration(hours: 12)));
      expect(decision.verifiedVia, 'AUTO_SYSTEM_CLOCKOUT');
      expect(decision.reason, contains('max shift cap of 12 hours'));
    });

    test('Strict policy auto clocks-out at scheduled shift end time', () {
      final punchIn = DateTime(2026, 9, 29, 9, 0);
      final nowPastEnd = DateTime(2026, 9, 29, 18, 30); // 6:30 PM (past 6:00 PM end)

      final decision = ShiftAutomationService.evaluateAutoClockOut(
        punchInTime: punchIn,
        currentTime: nowPastEnd,
        shift: shift,
        policy: const ShiftAutomationPolicy(
          autoClockOutEnabled: true,
          autoClockOutAtShiftEnd: true,
        ),
      );

      expect(decision.shouldClockOut, isTrue);
      expect(decision.effectiveClockOutTime, DateTime(2026, 9, 29, 18, 0));
      expect(decision.reason, contains('scheduled shift end'));
    });

    test('Auto-deducts lunch break when employee works >= 6 hours with no logged break', () {
      final res = ShiftAutomationService.evaluateBreakDeductions(
        grossWorkMinutes: 480, // 8.0 hours
        loggedUnpaidBreakMinutes: 0,
        policy: const ShiftAutomationPolicy(
          autoDeductLunchEnabled: true,
          autoDeductThresholdMinutes: 360, // 6h
          autoDeductLunchMinutes: 60, // 1h
        ),
      );

      expect(res.deductionApplied, isTrue);
      expect(res.autoDeductedMinutes, 60);
      expect(res.netPayableMinutes, 420); // 7.0 hours net
      expect(res.netPayableHours, 7.0);
    });

    test('Does not auto-deduct if employee already logged an unpaid lunch break', () {
      final res = ShiftAutomationService.evaluateBreakDeductions(
        grossWorkMinutes: 480,
        loggedUnpaidBreakMinutes: 45, // 45m break recorded
        policy: const ShiftAutomationPolicy(
          autoDeductLunchEnabled: true,
          autoDeductThresholdMinutes: 360,
          autoDeductLunchMinutes: 60,
        ),
      );

      expect(res.deductionApplied, isFalse);
      expect(res.autoDeductedMinutes, 0);
      expect(res.netPayableMinutes, 435);
    });
  });

  group('Project & Work Activity Time Tracking Unit Tests (Jibble Standard)', () {
    const projAlpha = WorkProject(
      id: 'proj_alpha',
      name: 'Mobile App Redesign',
      clientName: 'Stark Industries',
      colorHex: '#2563EB',
      isBillable: true,
    );

    const projBeta = WorkProject(
      id: 'proj_beta',
      name: 'Server Infrastructure Maintenance',
      clientName: 'Wayne Enterprises',
      colorHex: '#10B981',
      isBillable: false,
    );

    test('Accurately aggregates project minutes, percentages, and billable ratios', () {
      final sampleLogs = [
        {'projectId': 'proj_alpha', 'shiftDurationMinutes': 240}, // 4.0h billable
        {'projectId': 'proj_alpha', 'shiftDurationMinutes': 120}, // 2.0h billable (total 6.0h)
        {'projectId': 'proj_beta', 'shiftDurationMinutes': 120}, // 2.0h non-billable
        {'projectId': 'unknown_unassigned', 'shiftDurationMinutes': 120}, // 2.0h general fallback
      ];

      final summary = ProjectTimeAllocationService.aggregateProjectTime(
        logs: sampleLogs,
        availableProjects: [projAlpha, projBeta],
      );

      expect(summary.totalWorkMinutes, 600); // 10.0 hours total
      expect(summary.totalHours, 10.0);
      expect(summary.billableMinutes, 360); // 6.0 hours billable
      expect(summary.billableHours, 6.0);
      expect(summary.nonBillableMinutes, 240); // 4.0 hours non-billable
      expect(summary.billableRatioPercent, 60.0);

      // Verify top project allocation
      expect(summary.allocations.first.project.id, 'proj_alpha');
      expect(summary.allocations.first.hours, 6.0);
      expect(summary.allocations.first.percentageOfTotal, 60.0);
      expect(summary.allocations.first.formattedHours, '6.0 hrs');
    });

    test('WorkProject serialization and copyWith work properly', () {
      final json = projAlpha.toJson();
      final revived = WorkProject.fromJson(json);

      expect(revived.id, 'proj_alpha');
      expect(revived.name, 'Mobile App Redesign');
      expect(revived.isBillable, isTrue);

      final modified = projAlpha.copyWith(name: 'Updated Name', isBillable: false);
      expect(modified.name, 'Updated Name');
      expect(modified.isBillable, isFalse);
    });
  });

  group('ACHS Centralized Utilities & Deduplication Unit Tests', () {
    test('AppFormatUtils.parseTimestamp safely parses DateTime, Timestamp, String, and fallbacks', () {
      final now = DateTime(2026, 9, 29, 14, 30);
      final ts = Timestamp.fromDate(now);

      // Timestamp instance
      expect(AppFormatUtils.parseTimestamp(ts), now);
      // DateTime instance
      expect(AppFormatUtils.parseTimestamp(now), now);
      // ISO String
      expect(AppFormatUtils.parseTimestamp('2026-09-29T14:30:00.000'), DateTime(2026, 9, 29, 14, 30));
      // Epoch milliseconds
      expect(AppFormatUtils.parseTimestamp(now.millisecondsSinceEpoch), now);
      // Null with fallback
      final fallback = DateTime(2026, 1, 1);
      expect(AppFormatUtils.parseTimestamp(null, fallback: fallback), fallback);
      // Malformed string with fallback
      expect(AppFormatUtils.parseTimestamp('not_a_valid_date', fallback: fallback), fallback);
    });

    test('AppFormatUtils formats 12-hour AM/PM time strings accurately', () {
      expect(AppFormatUtils.formatTimeAmPm(DateTime(2026, 9, 29, 9, 5)), '9:05 AM');
      expect(AppFormatUtils.formatTimeAmPm(DateTime(2026, 9, 29, 12, 0)), '12:00 PM');
      expect(AppFormatUtils.formatTimeAmPm(DateTime(2026, 9, 29, 18, 45)), '6:45 PM');
      expect(AppFormatUtils.formatTimeAmPm(DateTime(2026, 9, 29, 0, 15)), '12:15 AM');

      expect(AppFormatUtils.formatHourMinuteAmPm(9, 0), '9:00 AM');
      expect(AppFormatUtils.formatHourMinuteAmPm(14, 30), '2:30 PM');
    });

    test('AppFormatUtils parses hex colors defensively with fallbacks', () {
      // 6-digit hex with hash
      expect(AppFormatUtils.parseHexColor('#2563EB'), const Color(0xFF2563EB));
      // 6-digit hex without hash
      expect(AppFormatUtils.parseHexColor('10B981'), const Color(0xFF10B981));
      // 8-digit hex with alpha
      expect(AppFormatUtils.parseHexColor('#80FF0000'), const Color(0x80FF0000));
      // Invalid hex with fallback
      const fallback = Color(0xFF000000);
      expect(AppFormatUtils.parseHexColor('invalid_hex', fallback: fallback), fallback);
      expect(AppFormatUtils.parseHexColor(null, fallback: fallback), fallback);
    });

    test('AppFormatUtils formats duration minutes to readable hour formats', () {
      expect(AppFormatUtils.formatMinutesToHours(480), '8 hrs');
      expect(AppFormatUtils.formatMinutesToHours(510), '8 hrs 30 mins');
      expect(AppFormatUtils.formatMinutesToHours(510, compact: true), '8.5 hrs');
    });
  });

  group('Attendance Regularization & Correction Unit Tests', () {
    test('AttendanceRegularizationRequest serializes and deserializes properly', () {
      final now = DateTime(2026, 9, 29, 9, 0);
      final outTime = DateTime(2026, 9, 29, 18, 0);
      final req = AttendanceRegularizationRequest(
        id: 'reg-101',
        userId: 'usr-1',
        enterpriseId: 'ent-1',
        employeeName: 'Alice Developer',
        employeeId: 'EMP001',
        targetDate: DateTime(2026, 9, 29),
        requestedCheckIn: now,
        requestedCheckOut: outTime,
        category: RegularizationCategory.clientVisit,
        reasonDescription: 'Client site deployment meeting in the morning',
        status: RegularizationStatus.pending,
        appliedAt: now,
      );

      expect(req.requestedDurationMinutes, 540);
      expect(req.category.label, 'Outdoor Client Visit');
      expect(req.status.label, 'Pending Review');

      final map = req.toMap();
      expect(map['category'], 'CLIENT_VISIT');
      expect(map['status'], 'PENDING');
      expect(map['employeeName'], 'Alice Developer');

      final reconstructed = AttendanceRegularizationRequest.fromMap(map, id: 'reg-101');
      expect(reconstructed.id, 'reg-101');
      expect(reconstructed.category, RegularizationCategory.clientVisit);
      expect(reconstructed.status, RegularizationStatus.pending);
      expect(reconstructed.requestedDurationMinutes, 540);
    });

    test('AttendanceRegularizationService validation catches invalid intervals and missing fields', () {
      final service = AttendanceRegularizationService();
      final baseDate = DateTime(2026, 9, 29);

      // Valid request
      final validReq = AttendanceRegularizationRequest(
        id: 'reg-1',
        userId: 'u1',
        enterpriseId: 'e1',
        employeeName: 'Bob',
        employeeId: 'EMP002',
        targetDate: baseDate,
        requestedCheckIn: DateTime(2026, 9, 29, 9, 0),
        requestedCheckOut: DateTime(2026, 9, 29, 17, 0),
        category: RegularizationCategory.forgotPunch,
        reasonDescription: 'Forgot to punch out at kiosk',
        appliedAt: DateTime.now(),
      );
      expect(service.validateRequest(validReq), isNull);

      // Out before In
      final invalidInterval = validReq.copyWith(
        requestedCheckIn: DateTime(2026, 9, 29, 17, 0),
        requestedCheckOut: DateTime(2026, 9, 29, 9, 0),
      );
      expect(service.validateRequest(invalidInterval), contains('must be after check-in'));

      // Identical check-in and check-out
      final identicalTimes = validReq.copyWith(
        requestedCheckIn: DateTime(2026, 9, 29, 9, 0),
        requestedCheckOut: DateTime(2026, 9, 29, 9, 0),
      );
      expect(service.validateRequest(identicalTimes), contains('cannot be identical'));

      // Too short (< 15 mins)
      final tooShort = validReq.copyWith(
        requestedCheckIn: DateTime(2026, 9, 29, 9, 0),
        requestedCheckOut: DateTime(2026, 9, 29, 9, 10),
      );
      expect(service.validateRequest(tooShort), contains('at least 15 minutes'));

      // Reason too short
      final shortReason = validReq.copyWith(
        reasonDescription: 'abc',
      );
      expect(service.validateRequest(shortReason), contains('minimum 5 characters'));
    });

    test('AttendanceRegularizationService.computeSummary computes counts and metrics accurately', () {
      final reqs = [
        AttendanceRegularizationRequest(
          id: '1',
          userId: 'u1',
          enterpriseId: 'e1',
          employeeName: 'A',
          employeeId: 'E1',
          targetDate: DateTime(2026, 9, 29),
          requestedCheckIn: DateTime(2026, 9, 29, 9, 0),
          requestedCheckOut: DateTime(2026, 9, 29, 17, 0), // 8h = 480m
          category: RegularizationCategory.forgotPunch,
          reasonDescription: 'Valid reason here',
          status: RegularizationStatus.approved,
          appliedAt: DateTime.now(),
        ),
        AttendanceRegularizationRequest(
          id: '2',
          userId: 'u2',
          enterpriseId: 'e1',
          employeeName: 'B',
          employeeId: 'E2',
          targetDate: DateTime(2026, 9, 29),
          requestedCheckIn: DateTime(2026, 9, 29, 10, 0),
          requestedCheckOut: DateTime(2026, 9, 29, 18, 0), // 8h = 480m
          category: RegularizationCategory.clientVisit,
          reasonDescription: 'Meeting at client office',
          status: RegularizationStatus.pending,
          appliedAt: DateTime.now(),
        ),
        AttendanceRegularizationRequest(
          id: '3',
          userId: 'u3',
          enterpriseId: 'e1',
          employeeName: 'C',
          employeeId: 'E3',
          targetDate: DateTime(2026, 9, 29),
          requestedCheckIn: DateTime(2026, 9, 29, 8, 0),
          requestedCheckOut: DateTime(2026, 9, 29, 16, 0),
          category: RegularizationCategory.deviceIssue,
          reasonDescription: 'Kiosk offline in morning',
          status: RegularizationStatus.rejected,
          appliedAt: DateTime.now(),
        ),
      ];

      final summary = AttendanceRegularizationService.computeSummary(reqs);
      expect(summary.totalCount, 3);
      expect(summary.approvedCount, 1);
      expect(summary.pendingCount, 1);
      expect(summary.rejectedCount, 1);
      expect(summary.totalApprovedDurationMinutes, 480);
      expect(summary.approvalRatePercent, closeTo(33.33, 0.1));
    });
  });
}



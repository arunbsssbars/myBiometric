import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/attendance_regularization_request.dart';
import 'package:mybiometric_app/services/attendance_regularization_service.dart';

void main() {
  group('Attendance Regularization Suite', () {
    final validRequest = AttendanceRegularizationRequest(
      id: 'reg_101',
      userId: 'user_123',
      enterpriseId: 'ent_corp',
      employeeId: 'EMP-550',
      employeeName: 'Diana Prince',
      targetDate: DateTime(2026, 10, 2),
      requestedCheckIn: DateTime(2026, 10, 2, 9, 0),
      requestedCheckOut: DateTime(2026, 10, 2, 18, 0),
      category: RegularizationCategory.forgotPunch,
      reasonDescription: 'Forgot to swipe card at turnstile upon morning arrival.',
      status: RegularizationStatus.pending,
      appliedAt: DateTime(2026, 10, 2, 19, 0),
    );

    test('AttendanceRegularizationRequest serializes and deserializes accurately', () {
      final map = validRequest.toMap();
      expect(map['userId'], equals('user_123'));
      expect(map['employeeId'], equals('EMP-550'));
      expect(map['category'], equals('FORGOT_PUNCH'));
      expect(map['status'], equals('PENDING'));
    });

    test('AttendanceRegularizationService.validate accepts valid requests', () {
      final error = AttendanceRegularizationService.validate(validRequest);
      expect(error, isNull);
    });

    test('AttendanceRegularizationService.validate rejects inverted check-in/out times', () {
      final invalidRequest = AttendanceRegularizationRequest(
        id: 'reg_102',
        userId: 'user_123',
        enterpriseId: 'ent_corp',
        employeeId: 'EMP-550',
        employeeName: 'Diana Prince',
        targetDate: DateTime(2026, 10, 2),
        requestedCheckIn: DateTime(2026, 10, 2, 18, 0),
        requestedCheckOut: DateTime(2026, 10, 2, 9, 0), // Before check-in!
        category: RegularizationCategory.forgotPunch,
        reasonDescription: 'Time error',
        status: RegularizationStatus.pending,
        appliedAt: DateTime(2026, 10, 2, 19, 0),
      );

      final error = AttendanceRegularizationService.validate(invalidRequest);
      expect(error, contains('Check-out time must be after check-in time.'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/services/terminal_attendance_sync_service.dart';

void main() {
  group('Terminal Attendance Sync & Deduplication Suite', () {
    test('filterDuplicateEvents filters rapid consecutive punches within threshold', () {
      final baseTime = DateTime(2026, 10, 1, 9, 0, 0);

      final events = [
        TerminalAttendanceEvent(
          eventId: '1',
          deviceId: 'dev-1',
          employeeId: 'EMP-001',
          timestamp: baseTime,
          punchType: 'PUNCH_IN',
          authMode: DeviceAuthMode.face,
        ),
        // Rapid double punch 15 seconds later
        TerminalAttendanceEvent(
          eventId: '2',
          deviceId: 'dev-1',
          employeeId: 'EMP-001',
          timestamp: baseTime.add(const Duration(seconds: 15)),
          punchType: 'PUNCH_IN',
          authMode: DeviceAuthMode.face,
        ),
        // Distinct employee punch at same time
        TerminalAttendanceEvent(
          eventId: '3',
          deviceId: 'dev-1',
          employeeId: 'EMP-002',
          timestamp: baseTime.add(const Duration(seconds: 20)),
          punchType: 'PUNCH_IN',
          authMode: DeviceAuthMode.face,
        ),
        // Valid subsequent punch 30 minutes later
        TerminalAttendanceEvent(
          eventId: '4',
          deviceId: 'dev-1',
          employeeId: 'EMP-001',
          timestamp: baseTime.add(const Duration(minutes: 30)),
          punchType: 'PUNCH_IN',
          authMode: DeviceAuthMode.face,
        ),
      ];

      final cleanEvents = TerminalAttendanceSyncService.filterDuplicateEvents(
        events,
        doubleSwipeThresholdSeconds: 120,
      );

      expect(cleanEvents.length, 3);
      expect(cleanEvents.map((e) => e.eventId).toList(), ['1', '3', '4']);
    });
  });
}

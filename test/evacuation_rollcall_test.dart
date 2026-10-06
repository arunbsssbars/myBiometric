import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/evacuation_roster.dart';
import 'package:mybiometric/services/evacuation_rollcall_service.dart';

void main() {
  group('EvacuationRollcallService Tests', () {
    test('Builds roll-call list filtered to currently active/clocked-in staff', () {
      final sessions = [
        {
          'userId': 'u1',
          'employeeName': 'Sarah Connor',
          'department': 'Operations',
          'lastLocation': 'Building A - Floor 2',
          'isClockedIn': true,
          'lastPunchTime': DateTime(2026, 10, 3, 9, 0),
        },
        {
          'userId': 'u2',
          'employeeName': 'John Connor',
          'department': 'Operations',
          'lastLocation': 'Building A - Floor 1',
          'isClockedIn': false, // Offsite / clocked out
          'lastPunchTime': DateTime(2026, 10, 3, 8, 30),
        },
      ];

      final roster = EvacuationRollcallService.buildRollcallList(activeSessions: sessions);
      expect(roster.length, equals(1));
      expect(roster.first.employeeName, equals('Sarah Connor'));
      expect(roster.first.isAccountedFor, isFalse);
    });

    test('Calculates live evacuation headcount summary', () {
      final evacuees = [
        EvacueeStatus(
          userId: 'u1',
          employeeName: 'Alice',
          department: 'Engineering',
          lastKnownLocation: 'Floor 3',
          lastPunchTime: DateTime.now(),
          isAccountedFor: true,
        ),
        EvacueeStatus(
          userId: 'u2',
          employeeName: 'Bob',
          department: 'Engineering',
          lastKnownLocation: 'Floor 3',
          lastPunchTime: DateTime.now(),
          isAccountedFor: false,
        ),
      ];

      final summary = EvacuationRollcallService.calculateSummary(evacuees);
      expect(summary.totalOnSite, equals(2));
      expect(summary.totalAccountedFor, equals(1));
      expect(summary.totalMissing, equals(1));
      expect(summary.accountedForPercent, equals(50.0));
    });
  });
}

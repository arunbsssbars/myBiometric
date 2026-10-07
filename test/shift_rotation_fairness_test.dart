import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/shift_rotation_fairness_service.dart';
import 'package:mybiometric/views/shift_rotation_fairness_card.dart';

void main() {
  group('ShiftRotationFairnessService Suite', () {
    late ShiftRotationFairnessService service;

    setUp(() {
      service = ShiftRotationFairnessService();
    });

    test('Identifies employee fatigue when excessive night shifts and consecutive days worked', () {
      const fatiguedEmployee = EmployeeShiftHistory(
        userId: 'USR_FATIGUED',
        employeeName: 'Oliver Twist',
        totalShifts: 20,
        nightShifts: 15, // 75% night shifts
        weekendShifts: 8,
        holidayShifts: 2,
        maxConsecutiveDays: 8, // Exceeds safe limit
      );

      final score = service.evaluateEmployee(fatiguedEmployee);

      expect(score.hasFatigueWarning, isTrue);
      expect(score.fatigueRiskScore, greaterThan(65.0));
      expect(score.nightLoadPercentage, equals(75.0));
    });

    test('Evaluates balanced employee within safe fatigue limits', () {
      const balancedEmployee = EmployeeShiftHistory(
        userId: 'USR_BALANCED',
        employeeName: 'Emma Watson',
        totalShifts: 20,
        nightShifts: 2,
        weekendShifts: 4,
        holidayShifts: 0,
        maxConsecutiveDays: 5,
      );

      final score = service.evaluateEmployee(balancedEmployee);

      expect(score.hasFatigueWarning, isFalse);
      expect(score.fatigueRiskScore, lessThan(50.0));
    });

    test('Evaluates department fairness report across team members', () {
      const team = [
        EmployeeShiftHistory(
          userId: '1',
          employeeName: 'A',
          totalShifts: 20,
          nightShifts: 5,
          weekendShifts: 4,
          holidayShifts: 0,
          maxConsecutiveDays: 5,
        ),
        EmployeeShiftHistory(
          userId: '2',
          employeeName: 'B',
          totalShifts: 20,
          nightShifts: 6,
          weekendShifts: 4,
          holidayShifts: 0,
          maxConsecutiveDays: 5,
        ),
      ];

      final report = service.evaluateDepartment(
        department: 'Logistics',
        members: team,
      );

      expect(report.totalTeamMembers, equals(2));
      expect(report.fatiguedMemberCount, equals(0));
      expect(report.teamFairnessIndex, greaterThan(90.0));
    });

    testWidgets('ShiftRotationFairnessCard renders without overflow across viewports', (tester) async {
      const score = ShiftEquityScore(
        userId: 'USR_TEST',
        employeeName: 'Peter Parker',
        fatigueRiskScore: 72.5,
        weekendLoadPercentage: 40.0,
        nightLoadPercentage: 60.0,
        hasFatigueWarning: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShiftRotationFairnessCard(
              score: score,
            ),
          ),
        ),
      );

      expect(find.text('Peter Parker'), findsOneWidget);
      expect(find.text('FATIGUE RISK'), findsOneWidget);
      expect(find.textContaining('72.5 / 100'), findsOneWidget);
    });
  });
}

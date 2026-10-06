import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/views/employee_presence_tile.dart';
import 'package:mybiometric_app/views/face_overlay_painter.dart';
import 'package:mybiometric_app/services/break_tracking_service.dart';
import 'package:mybiometric_app/core/design_system/design_system.dart';
import 'helpers/ui_test_helper.dart';

void main() {
  group('UI Layout, Overflow & Truncation Quality Suite', () {
    testWidgets('EmployeePresenceTile renders across all form factors without RenderFlex overflow',
        (WidgetTester tester) async {
      final now = DateTime(2026, 9, 29, 14, 0);

      final sampleSessions = [
        // 1. Active Working State
        EmployeeDailySession(
          userId: 'usr-1',
          employeeName: 'Sarah Connor',
          employeeId: 'EMP-001',
          department: 'Cyberdyne Operations',
          status: EmployeeWorkStatus.working,
          punchInTime: DateTime(2026, 9, 29, 9, 15),
          netWorkDuration: const Duration(hours: 4, minutes: 45),
          lastVerifiedVia: 'FACE_ID',
        ),

        // 2. Active Break (Standard Lunch)
        EmployeeDailySession(
          userId: 'usr-2',
          employeeName: 'John Doe',
          employeeId: 'EMP-002',
          department: 'Engineering',
          status: EmployeeWorkStatus.onBreak,
          breakStartTime: DateTime(2026, 9, 29, 13, 30),
          activeBreakCategory: BreakCategory.lunch,
          lastVerifiedVia: 'KIOSK',
        ),

        // 3. Overstayed Break Warning State (+20m excess)
        EmployeeDailySession(
          userId: 'usr-3',
          employeeName: 'Alexander Montgomery',
          employeeId: 'EMP-003',
          department: 'Enterprise Security Architecture',
          status: EmployeeWorkStatus.onBreak,
          breakStartTime: DateTime(2026, 9, 29, 12, 55),
          activeBreakCategory: BreakCategory.lunch,
          isOverstayedBreak: true,
          overstayMinutes: 20,
          lastVerifiedVia: 'MOBILE_GPS',
        ),

        // 4. Clocked Out State
        EmployeeDailySession(
          userId: 'usr-4',
          employeeName: 'Elena Rostova',
          employeeId: 'EMP-004',
          department: 'Product Design',
          status: EmployeeWorkStatus.clockedOut,
          punchInTime: DateTime(2026, 9, 29, 9, 0),
          punchOutTime: DateTime(2026, 9, 29, 18, 0),
          netWorkDuration: const Duration(hours: 8, minutes: 15),
          lastVerifiedVia: 'KIOSK_PIN',
        ),

        // 5. Absent State
        const EmployeeDailySession(
          userId: 'usr-5',
          employeeName: 'Marcus Wright',
          employeeId: 'EMP-005',
          department: 'Quality Assurance',
          status: EmployeeWorkStatus.absent,
        ),

        // 6. On Leave State
        const EmployeeDailySession(
          userId: 'usr-6',
          employeeName: 'Grace Brewster Murray Hopper',
          employeeId: 'EMP-006',
          department: 'Research & Advanced Computing',
          status: EmployeeWorkStatus.onLeave,
          leaveReason: 'Annual Statutory Vacation Leave',
        ),
      ];

      for (final session in sampleSessions) {
        await UiQualityTester.testResponsiveLayout(
          tester,
          child: EmployeePresenceTile(
            session: session,
            nowOverride: now,
          ),
          devices: UiTestDevice.all,
          fontScales: [UiFontScale.standard, UiFontScale.large, UiFontScale.extraLarge],
        );
      }
    });

    testWidgets('FaceHolePainter renders responsively across all screen geometries',
        (WidgetTester tester) async {
      await UiQualityTester.testResponsiveLayout(
        tester,
        child: SizedBox(
          height: 300,
          width: double.infinity,
          child: CustomPaint(
            painter: FaceHolePainter(
              borderColor: Colors.greenAccent,
              borderWidth: 3.5,
              progress: 0.75,
            ),
          ),
        ),
        devices: UiTestDevice.all,
      );
    });

    testWidgets('UiQualityTester detects smooth screen navigation transition without animation jank',
        (WidgetTester tester) async {
      final initialScreen = Scaffold(
        appBar: AppBar(title: const Text('Live Board')),
        body: Center(
          child: ElevatedButton(
            key: const ValueKey('open_details_btn'),
            onPressed: () {},
            child: const Text('View Employee Details'),
          ),
        ),
      );

      final destinationScreen = Scaffold(
        appBar: AppBar(title: const Text('Employee Profile')),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Detailed Timesheet & Biometric Status'),
        ),
      );

      await UiQualityTester.testScreenTransition(
        tester,
        initialScreen: initialScreen,
        destinationScreen: destinationScreen,
        triggerFinder: find.byKey(const ValueKey('open_details_btn')),
      );
    });

    testWidgets('detectUnsafeClipping reports zero text widgets clipped without ellipsis safeguard',
        (WidgetTester tester) async {
      final session = EmployeeDailySession(
        userId: 'usr-standard',
        employeeName: 'Standard User',
        employeeId: 'EMP-STD',
        department: 'Engineering',
        status: EmployeeWorkStatus.working,
        punchInTime: DateTime(2026, 9, 29, 9, 0),
        netWorkDuration: const Duration(hours: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 393,
              child: EmployeePresenceTile(session: session),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unsafeClipped = UiQualityTester.detectUnsafeClipping(tester);
      expect(unsafeClipped, isEmpty, reason: 'Expected all text widgets to have ellipsis safeguards when exceeding bounds');
    });
  });

  group('AQIL v2 WCAG 2.2 AA Accessibility & Dynamic Scaling Matrix', () {
    testWidgets('Interactive elements conform to Android and iOS minimum touch targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
                onPressed: () {},
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Verify Biometrics'),
              ),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('High contrast typography conforms to WCAG text contrast guideline in both themes',
        (WidgetTester tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: context.colors.surface,
                    child: Text(
                      'Biometric Verification Protocol Active',
                      style: context.text.titleMedium?.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
    });

    testWidgets('200% dynamic type scale (WCAG 1.4.4) renders without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Builder(
                  builder: (context) => Column(
                    children: [
                      SectionHeader(
                        icon: Icons.security_rounded,
                        title: 'Enterprise Security Policies',
                        subtitle: 'Biometric and geofence enforcement',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EmptyStateView(
                        icon: Icons.verified_user_rounded,
                        title: 'All Compliance Checks Passed',
                        message: 'No security policy exceptions recorded today.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

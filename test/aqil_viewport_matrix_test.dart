import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/core/design_system/design_system.dart';
import 'package:mybiometric/views/employee_presence_tile.dart';
import 'package:mybiometric/services/break_tracking_service.dart';

void main() {
  const viewports = <String, Size>{
    '320px_compact': Size(320, 568),
    '393px_standard': Size(393, 852),
    '412px_large_mobile': Size(412, 915),
    '800px_tablet_portrait': Size(800, 1280),
    '1280px_desktop_landscape': Size(1280, 800),
  };

  final themes = <String, ThemeData>{
    'Light': AppTheme.light(),
    'Dark': AppTheme.dark(),
  };

  group('AQIL v2 Complete Viewport Matrix (5 Form Factors × 2 Themes)', () {
    testWidgets('EmployeePresenceTile renders without overflow across all 10 matrix combinations',
        (WidgetTester tester) async {
      addTearDown(tester.view.reset);

      final session = EmployeeDailySession(
        userId: 'usr-matrix-1',
        employeeName: 'Dr. Jane Christopher-Smith',
        employeeId: 'EMP-CORP-9921',
        department: 'Advanced Cybernetics & Quantum Security',
        status: EmployeeWorkStatus.working,
        punchInTime: DateTime(2026, 10, 4, 8, 30),
        netWorkDuration: const Duration(hours: 6, minutes: 45),
        lastVerifiedVia: 'DEVICE_TERMINAL',
      );

      for (final themeEntry in themes.entries) {
        for (final vpEntry in viewports.entries) {
          tester.view.physicalSize = vpEntry.value * tester.view.devicePixelRatio;

          await tester.pumpWidget(
            MaterialApp(
              theme: themeEntry.value,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: EmployeePresenceTile(session: session),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow in EmployeePresenceTile at ${vpEntry.key} (${themeEntry.key})',
          );
        }
      }
    });

    testWidgets('Core Design System Components render across all 10 matrix combinations',
        (WidgetTester tester) async {
      addTearDown(tester.view.reset);

      for (final themeEntry in themes.entries) {
        for (final vpEntry in viewports.entries) {
          tester.view.physicalSize = vpEntry.value * tester.view.devicePixelRatio;

          await tester.pumpWidget(
            MaterialApp(
              theme: themeEntry.value,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Builder(
                    builder: (context) {
                      final s = context.status;
                      return Column(
                        children: [
                          SectionHeader(
                            icon: Icons.shield_outlined,
                            title: 'Workforce Compliance Matrix',
                            subtitle: 'Automated biometric audit log',
                            trailing: StatusPill(label: 'COMPLIANT', tone: s.success),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: KpiTile(
                                  label: 'Present',
                                  count: 42,
                                  tone: s.success,
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: KpiTile(
                                  label: 'On Break',
                                  count: 5,
                                  tone: s.warning,
                                  icon: Icons.timer_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: KpiTile(
                                  label: 'Absent',
                                  count: 2,
                                  tone: s.danger,
                                  icon: Icons.cancel_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const AppCardSkeleton(),
                          const SizedBox(height: AppSpacing.md),
                          const AppListSkeleton(itemCount: 2),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 200));
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow in Design System components at ${vpEntry.key} (${themeEntry.key})',
          );
        }
      }
    });
  });
}

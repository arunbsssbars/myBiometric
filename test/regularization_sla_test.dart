import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/regularization_sla.dart';
import 'package:mybiometric_app/services/regularization_sla_service.dart';

void main() {
  group('RegularizationSlaService Tests', () {
    const config = RegularizationSlaConfig(
      enterpriseId: 'ent-1',
      slaTargetHours: 48,
      warningThresholdHours: 36,
      autoEscalateOnBreach: true,
    );

    final now = DateTime(2026, 10, 5, 12, 0);

    test('Identifies ticket within SLA (< 36 hours elapsed)', () {
      final ticket = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 'tick-01',
        employeeName: 'Alice Smith',
        submittedAt: now.subtract(const Duration(hours: 10)),
        checkTime: now,
      );

      expect(ticket.status, equals(SlaStatus.withinSla));
      expect(ticket.isEscalated, isFalse);
      expect(ticket.elapsedHours, closeTo(10.0, 0.1));
      expect(ticket.remainingHours, closeTo(38.0, 0.1));
    });

    test('Identifies ticket in warning state (> 36 hours, < 48 hours)', () {
      final ticket = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 'tick-02',
        employeeName: 'Bob Jones',
        submittedAt: now.subtract(const Duration(hours: 40)),
        checkTime: now,
      );

      expect(ticket.status, equals(SlaStatus.warning));
      expect(ticket.isEscalated, isFalse);
      expect(ticket.remainingHours, closeTo(8.0, 0.1));
    });

    test('Auto-escalates ticket upon breaching 48 hour target', () {
      final ticket = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 'tick-03',
        employeeName: 'Charlie Brown',
        submittedAt: now.subtract(const Duration(hours: 52)),
        checkTime: now,
      );

      expect(ticket.status, equals(SlaStatus.escalated));
      expect(ticket.isEscalated, isTrue);
      expect(ticket.statusDescription, contains('Auto-escalated'));
    });

    test('Calculates aggregate queue summary accurately', () {
      final t1 = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 't1',
        employeeName: 'User 1',
        submittedAt: now.subtract(const Duration(hours: 10)),
        checkTime: now,
      );
      final t2 = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 't2',
        employeeName: 'User 2',
        submittedAt: now.subtract(const Duration(hours: 38)),
        checkTime: now,
      );
      final t3 = RegularizationSlaService.evaluateTicket(
        config: config,
        ticketId: 't3',
        employeeName: 'User 3',
        submittedAt: now.subtract(const Duration(hours: 50)),
        checkTime: now,
      );

      final summary = RegularizationSlaService.calculateQueueSummary([t1, t2, t3]);

      expect(summary.totalPending, equals(3));
      expect(summary.withinSlaCount, equals(1));
      expect(summary.warningCount, equals(1));
      expect(summary.escalatedCount, equals(1));
      expect(summary.averageAgingHours, closeTo(32.6, 0.2));
    });
  });
}

import '../domain/models/regularization_sla.dart';

/// Summary metrics of an enterprise's regularization queue
class RegularizationSlaSummary {
  final int totalPending;
  final int withinSlaCount;
  final int warningCount;
  final int breachedCount;
  final int escalatedCount;
  final double averageAgingHours;

  const RegularizationSlaSummary({
    required this.totalPending,
    required this.withinSlaCount,
    required this.warningCount,
    required this.breachedCount,
    required this.escalatedCount,
    required this.averageAgingHours,
  });
}

/// Service managing SLA lifecycle, aging, and escalation for regularization requests
class RegularizationSlaService {
  /// Evaluates SLA status for a single regularization ticket
  static RegularizationTicketSla evaluateTicket({
    required RegularizationSlaConfig config,
    required String ticketId,
    required String employeeName,
    required DateTime submittedAt,
    DateTime? checkTime,
    bool manuallyEscalated = false,
  }) {
    final now = checkTime ?? DateTime.now();
    final elapsedMinutes = now.difference(submittedAt).inMinutes;
    final elapsedHours = elapsedMinutes / 60.0;
    final remainingHours = (config.slaTargetHours - elapsedHours).clamp(0.0, double.infinity);

    SlaStatus status;
    bool isEscalated = manuallyEscalated;
    String description;

    if (manuallyEscalated) {
      status = SlaStatus.escalated;
      description = 'Escalated to senior administration';
    } else if (elapsedHours >= config.slaTargetHours) {
      if (config.autoEscalateOnBreach) {
        status = SlaStatus.escalated;
        isEscalated = true;
        description = 'Auto-escalated: SLA breached by ${(elapsedHours - config.slaTargetHours).toStringAsFixed(1)}h';
      } else {
        status = SlaStatus.breached;
        description = 'SLA Breached: Overdue by ${(elapsedHours - config.slaTargetHours).toStringAsFixed(1)}h';
      }
    } else if (elapsedHours >= config.warningThresholdHours) {
      status = SlaStatus.warning;
      description = 'Approaching SLA deadline (${remainingHours.toStringAsFixed(1)}h remaining)';
    } else {
      status = SlaStatus.withinSla;
      description = 'Within SLA (${remainingHours.toStringAsFixed(1)}h remaining)';
    }

    return RegularizationTicketSla(
      ticketId: ticketId,
      employeeName: employeeName,
      submittedAt: submittedAt,
      status: status,
      elapsedHours: elapsedHours,
      remainingHours: remainingHours,
      isEscalated: isEscalated,
      statusDescription: description,
    );
  }

  /// Calculates aggregate summary metrics across a batch of tickets
  static RegularizationSlaSummary calculateQueueSummary(
    List<RegularizationTicketSla> tickets,
  ) {
    if (tickets.isEmpty) {
      return const RegularizationSlaSummary(
        totalPending: 0,
        withinSlaCount: 0,
        warningCount: 0,
        breachedCount: 0,
        escalatedCount: 0,
        averageAgingHours: 0.0,
      );
    }

    int within = 0;
    int warning = 0;
    int breached = 0;
    int escalated = 0;
    double totalHours = 0.0;

    for (final t in tickets) {
      totalHours += t.elapsedHours;
      switch (t.status) {
        case SlaStatus.withinSla:
          within++;
          break;
        case SlaStatus.warning:
          warning++;
          break;
        case SlaStatus.breached:
          breached++;
          break;
        case SlaStatus.escalated:
          escalated++;
          break;
      }
    }

    return RegularizationSlaSummary(
      totalPending: tickets.length,
      withinSlaCount: within,
      warningCount: warning,
      breachedCount: breached,
      escalatedCount: escalated,
      averageAgingHours: totalHours / tickets.length,
    );
  }
}

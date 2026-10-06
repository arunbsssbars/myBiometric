import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_fleet_analytics.dart';

/// Service analyzing fleet-wide biometric terminal telemetry, throughput curves, and SLA uptime.
class TerminalFleetAnalyticsService {
  /// Aggregates hardware device telemetry and attendance events into an analytics report.
  static TerminalFleetAnalyticsReport generateFleetReport({
    required String enterpriseId,
    required List<BiometricTerminalDevice> devices,
    required List<TerminalAttendanceEvent> todayEvents,
  }) {
    final now = DateTime.now();
    final totalTerminals = devices.length;
    final onlineTerminals = devices.where((d) => d.status == DeviceConnectionStatus.online).length;

    final uptime = totalTerminals > 0
        ? ((onlineTerminals / totalTerminals) * 100.0)
        : 100.0;

    // Initialize 24 hourly buckets
    final hourlyMap = <int, TerminalThroughputBucket>{};
    for (int h = 0; h < 24; h++) {
      hourlyMap[h] = TerminalThroughputBucket(hourOfDay: h);
    }

    double totalSimilaritySum = 0.0;
    int similarityCount = 0;

    for (final event in todayEvents) {
      final h = event.timestamp.hour;
      final current = hourlyMap[h] ?? TerminalThroughputBucket(hourOfDay: h);

      final isFace = event.authMode == DeviceAuthMode.face;
      final isCard = event.authMode == DeviceAuthMode.card;

      if (event.similarityScore != null && isFace) {
        totalSimilaritySum += event.similarityScore!;
        similarityCount++;
      }

      hourlyMap[h] = TerminalThroughputBucket(
        hourOfDay: h,
        totalPunches: current.totalPunches + 1,
        faceMatches: current.faceMatches + (isFace ? 1 : 0),
        cardSwipes: current.cardSwipes + (isCard ? 1 : 0),
      );
    }

    // Determine Peak Hour
    int peakHour = 9;
    int maxPunches = 0;

    for (final entry in hourlyMap.entries) {
      if (entry.value.totalPunches > maxPunches) {
        maxPunches = entry.value.totalPunches;
        peakHour = entry.key;
      }
    }

    final avgSimilarity = similarityCount > 0
        ? (totalSimilaritySum / similarityCount)
        : 99.4;

    return TerminalFleetAnalyticsReport(
      enterpriseId: enterpriseId,
      totalTerminals: totalTerminals,
      onlineTerminals: onlineTerminals,
      fleetUptimePercent: double.parse(uptime.toStringAsFixed(1)),
      totalPunchesToday: todayEvents.length,
      peakHour: peakHour,
      peakHourPunchCount: maxPunches,
      averageFaceSimilarityScore: double.parse(avgSimilarity.toStringAsFixed(1)),
      hourlyThroughput: hourlyMap.values.toList(),
      generatedAt: now,
    );
  }
}

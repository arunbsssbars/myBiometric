import '../domain/models/biometric_qoe_telemetry.dart';

/// Service analyzing biometric verification pipeline latency and user experience
class BiometricQoEAnalyticsService {
  BiometricQoEAnalyticsService._internal();
  static final BiometricQoEAnalyticsService instance = BiometricQoEAnalyticsService._internal();

  /// Computes aggregate QoE statistics across a stream of verification sessions
  Map<String, dynamic> aggregateQoEPerformance(List<BiometricQoETelemetry> sessions) {
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageLatencyMs': 0,
        'p95LatencyMs': 0,
        'successRate': 100.0,
        'degradedPercentage': 0.0,
      };
    }

    final latencies = sessions.map((s) => s.totalVerificationLatencyMs).toList()..sort();
    final totalLatency = latencies.reduce((a, b) => a + b);
    final avgLatency = (totalLatency / latencies.length).round();

    final p95Index = (latencies.length * 0.95).clamp(0, latencies.length - 1).toInt();
    final p95Latency = latencies[p95Index];

    final successfulCount = sessions.where((s) => s.userSucceeded).length;
    final successRate = (successfulCount / sessions.length) * 100.0;

    final degradedCount = sessions.where((s) => s.qoeGrade != DeviceQoEState.optimal).length;
    final degradedPct = (degradedCount / sessions.length) * 100.0;

    return {
      'totalSessions': sessions.length,
      'averageLatencyMs': avgLatency,
      'p95LatencyMs': p95Latency,
      'successRate': double.parse(successRate.toStringAsFixed(1)),
      'degradedPercentage': double.parse(degradedPct.toStringAsFixed(1)),
    };
  }
}

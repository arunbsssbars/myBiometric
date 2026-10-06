import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_webhook_alert.dart';
import 'package:mybiometric_app/services/terminal_webhook_alert_service.dart';

void main() {
  group('TerminalWebhookAlertService Tests', () {
    const endpoint = TerminalWebhookEndpoint(
      endpointId: 'wh-slack-01',
      enterpriseId: 'ent-1',
      name: 'DevOps Slack Alerts',
      targetUrl: 'https://hooks.slack.com/services/T00/B00/X00',
      hmacSecret: 'super-secret-hmac-key',
      isEnabled: true,
      subscribedSeverities: [
        TerminalAlertSeverity.warning,
        TerminalAlertSeverity.critical,
      ],
    );

    final alert = TerminalWebhookAlertPayload(
      alertId: 'al-999',
      enterpriseId: 'ent-1',
      terminalId: 'term-zk-101',
      terminalName: 'Main Lobby ADMS Turnstile',
      eventType: TerminalAlertEventType.heartbeatLost,
      severity: TerminalAlertSeverity.critical,
      message: 'Terminal has missed 3 consecutive keepalive heartbeats',
      triggeredAt: DateTime(2026, 10, 5, 14, 0),
      diagnostics: {'consecutiveMisses': 3, 'lastRssi': -82},
    );

    test('Generates deterministic HMAC-SHA256 signature', () {
      final sig1 = TerminalWebhookAlertService.generateHmacSignature(
        payload: '{"test":"value"}',
        secret: 'test-secret',
      );
      final sig2 = TerminalWebhookAlertService.generateHmacSignature(
        payload: '{"test":"value"}',
        secret: 'test-secret',
      );
      expect(sig1, equals(sig2));
      expect(sig1.length, equals(64)); // SHA-256 hex string length
    });

    test('Prepares valid dispatch for subscribed critical event', () {
      final res = TerminalWebhookAlertService.prepareDispatch(
        endpoint: endpoint,
        alert: alert,
      );

      expect(res.isEligible, isTrue);
      expect(res.signature, startsWith('sha256='));
      expect(res.formattedBody['event'], equals('terminal.incident'));
      expect(res.formattedBody['severity'], equals('CRITICAL'));
      expect(res.formattedBody['terminal']['id'], equals('term-zk-101'));
    });

    test('Filters out alerts when endpoint is not subscribed to that severity', () {
      final infoAlert = TerminalWebhookAlertPayload(
        alertId: 'al-100',
        enterpriseId: 'ent-1',
        terminalId: 'term-zk-101',
        terminalName: 'Main Lobby',
        eventType: TerminalAlertEventType.rebootUnplanned,
        severity: TerminalAlertSeverity.info, // Endpoint only subscribed to warning & critical
        message: 'Routine periodic sync completed',
        triggeredAt: DateTime(2026, 10, 5),
      );

      final res = TerminalWebhookAlertService.prepareDispatch(
        endpoint: endpoint,
        alert: infoAlert,
      );

      expect(res.isEligible, isFalse);
    });

    test('Formats Slack message block accurately', () {
      final slack = TerminalWebhookAlertService.formatSlackBlock(alert);
      expect(slack['text'], contains('Main Lobby ADMS Turnstile'));
      expect(slack['blocks'], isNotEmpty);
    });

    test('Serializes and deserializes TerminalWebhookAlertPayload cleanly', () {
      final map = alert.toMap();
      final revived = TerminalWebhookAlertPayload.fromMap(map);

      expect(revived.alertId, equals(alert.alertId));
      expect(revived.terminalId, equals(alert.terminalId));
      expect(revived.eventType, equals(alert.eventType));
      expect(revived.severity, equals(alert.severity));
    });
  });
}

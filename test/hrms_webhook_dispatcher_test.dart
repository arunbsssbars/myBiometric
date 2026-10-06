import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/hrms_webhook_config.dart';
import 'package:mybiometric/services/hrms_webhook_dispatcher_service.dart';

void main() {
  group('HrmsWebhookDispatcherService Tests', () {
    const config = HrmsWebhookConfig(
      id: 'hook_01',
      enterpriseId: 'ent_demo',
      endpointUrl: 'https://hrms.enterprise.internal/api/attendance/webhook',
      secretToken: 'super_secure_webhook_secret_key',
      subscribedEvents: [
        HrmsEventType.punchRecorded,
        HrmsEventType.regularizationApproved,
      ],
      isActive: true,
    );

    test('Dispatches signed payload with HMAC header for subscribed event', () {
      final shouldSend = HrmsWebhookDispatcherService.shouldDispatch(
        config: config,
        eventType: HrmsEventType.punchRecorded,
      );
      expect(shouldSend, isTrue);

      final payload = HrmsWebhookDispatcherService.buildSignedWebhookPayload(
        config: config,
        eventType: HrmsEventType.punchRecorded,
        eventData: {
          'userId': 'usr-1',
          'type': 'PUNCH_IN',
          'time': '2026-10-03T09:00:00Z',
        },
      );

      final headers = payload['headers'] as Map<String, dynamic>;
      expect(headers['X-Biometric-Event'], equals('punchRecorded'));
      expect(headers['X-Biometric-Signature-256'], isNotEmpty);
    });

    test('Filters out non-subscribed events', () {
      final shouldSend = HrmsWebhookDispatcherService.shouldDispatch(
        config: config,
        eventType: HrmsEventType.leaveStatusChanged,
      );
      expect(shouldSend, isFalse);
    });
  });
}

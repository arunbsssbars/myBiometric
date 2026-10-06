import 'dart:convert';
import '../domain/models/hrms_webhook_config.dart';

/// Formats and dispatches payload events with HMAC SHA-256 signatures to HRMS endpoints
class HrmsWebhookDispatcherService {
  /// Builds a signed JSON payload message
  static Map<String, dynamic> buildSignedWebhookPayload({
    required HrmsWebhookConfig config,
    required HrmsEventType eventType,
    required Map<String, dynamic> eventData,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    final payloadMap = {
      'enterpriseId': config.enterpriseId,
      'eventType': eventType.name,
      'timestamp': now.toIso8601String(),
      'data': eventData,
    };

    final rawJson = jsonEncode(payloadMap);
    final signature = config.computeSignature(rawJson);

    return {
      'headers': {
        'Content-Type': 'application/json',
        'X-Biometric-Signature-256': signature,
        'X-Biometric-Event': eventType.name,
      },
      'body': rawJson,
    };
  }

  /// Checks if a config is subscribed to a given event
  static bool shouldDispatch({
    required HrmsWebhookConfig config,
    required HrmsEventType eventType,
  }) {
    if (!config.isActive) return false;
    return config.subscribedEvents.contains(eventType);
  }
}

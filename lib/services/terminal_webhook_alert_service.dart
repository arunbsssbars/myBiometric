import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/terminal_webhook_alert.dart';

/// Webhook dispatch result tracking
class WebhookDispatchResult {
  final String endpointId;
  final bool isEligible;
  final String signature;
  final Map<String, dynamic> formattedBody;

  const WebhookDispatchResult({
    required this.endpointId,
    required this.isEligible,
    required this.signature,
    required this.formattedBody,
  });
}

/// Service managing outbound incident webhooks and signature generation
class TerminalWebhookAlertService {
  /// Computes HMAC-SHA256 signature for a string payload and secret key
  static String generateHmacSignature({
    required String payload,
    required String secret,
  }) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Prepares an outbound dispatch packet for an external webhook endpoint
  static WebhookDispatchResult prepareDispatch({
    required TerminalWebhookEndpoint endpoint,
    required TerminalWebhookAlertPayload alert,
  }) {
    if (!endpoint.isEnabled) {
      return WebhookDispatchResult(
        endpointId: endpoint.endpointId,
        isEligible: false,
        signature: '',
        formattedBody: const {},
      );
    }

    final isSubscribed = endpoint.subscribedSeverities.contains(alert.severity);
    if (!isSubscribed) {
      return WebhookDispatchResult(
        endpointId: endpoint.endpointId,
        isEligible: false,
        signature: '',
        formattedBody: const {},
      );
    }

    // Build standard enterprise webhook envelope
    final payloadMap = {
      'event': 'terminal.incident',
      'alertId': alert.alertId,
      'timestamp': alert.triggeredAt.toIso8601String(),
      'severity': alert.severity.name.toUpperCase(),
      'terminal': {
        'id': alert.terminalId,
        'name': alert.terminalName,
      },
      'incident': {
        'type': alert.eventType.name,
        'message': alert.message,
        'diagnostics': alert.diagnostics,
      },
    };

    final jsonString = jsonEncode(payloadMap);
    final signature = generateHmacSignature(
      payload: jsonString,
      secret: endpoint.hmacSecret,
    );

    return WebhookDispatchResult(
      endpointId: endpoint.endpointId,
      isEligible: true,
      signature: 'sha256=$signature',
      formattedBody: payloadMap,
    );
  }

  /// Formats Slack-compatible message block
  static Map<String, dynamic> formatSlackBlock(TerminalWebhookAlertPayload alert) {
    final icon = alert.severity == TerminalAlertSeverity.critical ? '🚨' : '⚠️';
    return {
      'text': '$icon *Terminal Alert: ${alert.terminalName}*',
      'blocks': [
        {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': '$icon *${alert.severity.name.toUpperCase()}*: ${alert.message}\n*Terminal*: ${alert.terminalName} (`${alert.terminalId}`)',
          },
        },
      ],
    };
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Event triggers supported by HRMS webhook integrations
enum HrmsEventType {
  punchRecorded,
  regularizationApproved,
  leaveStatusChanged,
  dailySummaryClosed,
}

/// Webhook subscription configuration
class HrmsWebhookConfig {
  final String id;
  final String enterpriseId;
  final String endpointUrl;
  final String secretToken;
  final List<HrmsEventType> subscribedEvents;
  final bool isActive;

  const HrmsWebhookConfig({
    required this.id,
    required this.enterpriseId,
    required this.endpointUrl,
    required this.secretToken,
    required this.subscribedEvents,
    this.isActive = true,
  });

  String computeSignature(String payload) {
    final hmac = Hmac(sha256, utf8.encode(secretToken));
    return hmac.convert(utf8.encode(payload)).toString();
  }
}

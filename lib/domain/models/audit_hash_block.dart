import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Represents a tamper-evident cryptographically chained audit entry
class AuditHashBlock {
  final int sequenceIndex;
  final String eventType;
  final String actorUid;
  final String payloadSummary;
  final String previousBlockHash;
  final String currentBlockHash;
  final DateTime timestamp;

  const AuditHashBlock({
    required this.sequenceIndex,
    required this.eventType,
    required this.actorUid,
    required this.payloadSummary,
    required this.previousBlockHash,
    required this.currentBlockHash,
    required this.timestamp,
  });

  static String calculateHash({
    required int index,
    required String eventType,
    required String actorUid,
    required String payloadSummary,
    required String prevHash,
    required int timestampEpochMs,
  }) {
    final raw = '$index|$eventType|$actorUid|$payloadSummary|$prevHash|$timestampEpochMs';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}

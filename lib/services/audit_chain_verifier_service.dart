import '../domain/models/audit_hash_block.dart';

/// Service verifying the cryptographic integrity of the enterprise audit trail
class AuditChainVerifierService {
  /// Appends a new block to the hash chain
  static AuditHashBlock createNextBlock({
    required AuditHashBlock? previousBlock,
    required String eventType,
    required String actorUid,
    required String payloadSummary,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final index = previousBlock != null ? previousBlock.sequenceIndex + 1 : 0;
    final prevHash = previousBlock?.currentBlockHash ?? '0' * 64;

    final hash = AuditHashBlock.calculateHash(
      index: index,
      eventType: eventType,
      actorUid: actorUid,
      payloadSummary: payloadSummary,
      prevHash: prevHash,
      timestampEpochMs: now.millisecondsSinceEpoch,
    );

    return AuditHashBlock(
      sequenceIndex: index,
      eventType: eventType,
      actorUid: actorUid,
      payloadSummary: payloadSummary,
      previousBlockHash: prevHash,
      currentBlockHash: hash,
      timestamp: now,
    );
  }

  /// Verifies the full chain for any broken links or tampered data
  static bool verifyChainIntegrity(List<AuditHashBlock> chain) {
    if (chain.isEmpty) return true;

    for (int i = 0; i < chain.length; i++) {
      final current = chain[i];

      // Check previous hash link
      if (i == 0) {
        if (current.previousBlockHash != '0' * 64) return false;
      } else {
        final prev = chain[i - 1];
        if (current.previousBlockHash != prev.currentBlockHash) return false;
        if (current.sequenceIndex != prev.sequenceIndex + 1) return false;
      }

      // Re-calculate hash
      final expectedHash = AuditHashBlock.calculateHash(
        index: current.sequenceIndex,
        eventType: current.eventType,
        actorUid: current.actorUid,
        payloadSummary: current.payloadSummary,
        prevHash: current.previousBlockHash,
        timestampEpochMs: current.timestamp.millisecondsSinceEpoch,
      );

      if (current.currentBlockHash != expectedHash) return false;
    }

    return true;
  }
}

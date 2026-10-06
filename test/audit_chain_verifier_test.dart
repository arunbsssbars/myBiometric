import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/audit_hash_block.dart';
import 'package:mybiometric/services/audit_chain_verifier_service.dart';

void main() {
  group('AuditChainVerifierService Tests', () {
    test('Constructs and successfully validates cryptographic block chain', () {
      final block0 = AuditChainVerifierService.createNextBlock(
        previousBlock: null,
        eventType: 'USER_CREATED',
        actorUid: 'admin_1',
        payloadSummary: 'Created employee Alice',
        timestamp: DateTime(2026, 10, 1, 10, 0),
      );

      final block1 = AuditChainVerifierService.createNextBlock(
        previousBlock: block0,
        eventType: 'PIN_RESET',
        actorUid: 'admin_1',
        payloadSummary: 'Reset PIN for Bob',
        timestamp: DateTime(2026, 10, 1, 11, 0),
      );

      final chain = [block0, block1];
      final isValid = AuditChainVerifierService.verifyChainIntegrity(chain);
      expect(isValid, isTrue);
    });

    test('Detects tampering in chained audit log block', () {
      final block0 = AuditChainVerifierService.createNextBlock(
        previousBlock: null,
        eventType: 'USER_CREATED',
        actorUid: 'admin_1',
        payloadSummary: 'Created employee Alice',
        timestamp: DateTime(2026, 10, 1, 10, 0),
      );

      final block1 = AuditChainVerifierService.createNextBlock(
        previousBlock: block0,
        eventType: 'PIN_RESET',
        actorUid: 'admin_1',
        payloadSummary: 'Reset PIN for Bob',
        timestamp: DateTime(2026, 10, 1, 11, 0),
      );

      // Tampered block1 with modified actorUid
      final tamperedBlock1 = AuditHashBlock(
        sequenceIndex: block1.sequenceIndex,
        eventType: block1.eventType,
        actorUid: 'malicious_hacker', // Modified!
        payloadSummary: block1.payloadSummary,
        previousBlockHash: block1.previousBlockHash,
        currentBlockHash: block1.currentBlockHash,
        timestamp: block1.timestamp,
      );

      final tamperedChain = [block0, tamperedBlock1];
      final isValid = AuditChainVerifierService.verifyChainIntegrity(tamperedChain);
      expect(isValid, isFalse);
    });
  });
}

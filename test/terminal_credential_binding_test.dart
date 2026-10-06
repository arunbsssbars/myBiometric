import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_card_credential.dart';

void main() {
  group('Terminal Card Credential & RFID Binding Suite', () {
    test('TerminalCardCredential serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 1, 12, 0);
      final expiry = now.add(const Duration(days: 365));

      final card = TerminalCardCredential(
        id: 'card_A1B2C3D4',
        userId: 'usr-99',
        enterpriseId: 'ent-101',
        cardNumber: 'A1B2C3D4',
        cardType: TerminalCardType.mifare,
        status: TerminalCardStatus.active,
        assignedAt: now,
        expiresAt: expiry,
        notes: 'Executive Access RFID Smart Card',
      );

      expect(card.isValid, isTrue);

      final map = card.toMap();
      expect(map['cardNumber'], 'A1B2C3D4');
      expect(map['cardType'], 'mifare');
      expect(map['status'], 'active');
      expect(map['notes'], contains('Executive Access'));

      final revived = TerminalCardCredential.fromMap(map, id: 'card_A1B2C3D4');
      expect(revived.cardNumber, 'A1B2C3D4');
      expect(revived.cardType, TerminalCardType.mifare);
      expect(revived.isValid, isTrue);
    });

    test('toHikvisionCardInfoPayload generates standard ISAPI CardInfo schema', () {
      final card = TerminalCardCredential(
        id: 'card_88392100',
        userId: 'usr-100',
        enterpriseId: 'ent-101',
        cardNumber: '88392100',
        assignedAt: DateTime.now(),
      );

      final payload = card.toHikvisionCardInfoPayload(employeeNo: 'EMP-001');
      expect(payload.containsKey('CardInfo'), isTrue);

      final body = payload['CardInfo'] as Map<String, dynamic>;
      expect(body['employeeNo'], 'EMP-001');
      expect(body['cardNo'], '88392100');
      expect(body['status'], 'active');
      expect(body['cardType'], 'normalCard');
    });

    test('Expired card evaluates isValid as false', () {
      final expiredCard = TerminalCardCredential(
        id: 'card_expired',
        userId: 'usr-101',
        enterpriseId: 'ent-101',
        cardNumber: '11223344',
        assignedAt: DateTime(2025, 1, 1),
        expiresAt: DateTime(2025, 12, 31),
      );

      expect(expiredCard.isValid, isFalse);
    });
  });
}

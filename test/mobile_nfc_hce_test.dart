import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/mobile_virtual_nfc_badge.dart';
import 'package:mybiometric/services/mobile_nfc_hce_bridge_service.dart';

void main() {
  group('MobileNfcHceBridgeService Tests', () {
    late MobileNfcHceBridgeService service;

    setUp(() {
      service = MobileNfcHceBridgeService();
    });

    test('issues valid virtual badge with 14-char UID and AID', () {
      final badge = service.issueVirtualBadge(
        employeeId: 'EMP-442',
        enterpriseId: 'ENT-CORP',
      );

      expect(badge.cardUid.length, 14);
      expect(badge.applicationIdentifier, 'F0010203040506');
      expect(badge.isExpired, false);
      expect(badge.isHceActive, true);
    });

    test('processes APDU SELECT AID command and returns 9000 success', () {
      final badge = service.issueVirtualBadge(
        employeeId: 'EMP-442',
        enterpriseId: 'ENT-CORP',
      );

      // Select Application AID
      final selectResponse = service.processApduCommand(
        apduCommandHex: '00A4040007F001020304050600',
        badge: badge,
      );
      expect(selectResponse, '9000');

      // Read Binary / Card Data
      final readResponse = service.processApduCommand(
        apduCommandHex: '00B0000000',
        badge: badge,
      );
      expect(readResponse.endsWith('9000'), true);
      expect(readResponse.length > 4, true);
    });

    test('serialization roundtrip preserves virtual badge state', () {
      final badge = service.issueVirtualBadge(
        employeeId: 'EMP-442',
        enterpriseId: 'ENT-CORP',
      );

      final map = badge.toMap();
      final restored = MobileVirtualNfcBadge.fromMap(map);

      expect(restored.cardUid, badge.cardUid);
      expect(restored.employeeId, badge.employeeId);
      expect(restored.applicationIdentifier, badge.applicationIdentifier);
    });
  });
}

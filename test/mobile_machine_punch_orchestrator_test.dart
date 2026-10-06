import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/mobile_machine_punch_session.dart';
import 'package:mybiometric/services/mobile_machine_punch_orchestrator_service.dart';

void main() {
  group('MobileMachinePunchOrchestratorService Tests', () {
    late MobileMachinePunchOrchestratorService service;

    setUp(() {
      service = MobileMachinePunchOrchestratorService();
    });

    test('creates default active session', () {
      final session = service.createSession(
        employeeId: 'EMP-001',
        enterpriseId: 'ENT-CORP',
      );

      expect(session.employeeId, 'EMP-001');
      expect(session.activeChannel, MobileMachinePunchChannel.opticalQr);
      expect(session.isReady, true);
    });

    test('selects optimal channel according to hardware sensors', () {
      // 1. Camera view available -> optical QR
      expect(
        service.selectOptimalChannel(
          hasCameraView: true,
          hasBleHardware: true,
          hasNfcEnabled: true,
          isConnectedToOfficeWifi: true,
        ),
        MobileMachinePunchChannel.opticalQr,
      );

      // 2. No camera, but NFC enabled -> NFC badge
      expect(
        service.selectOptimalChannel(
          hasCameraView: false,
          hasBleHardware: true,
          hasNfcEnabled: true,
          isConnectedToOfficeWifi: true,
        ),
        MobileMachinePunchChannel.nfcVirtualBadge,
      );

      // 3. No camera, no NFC, but BLE hardware -> BLE proximity beacon
      expect(
        service.selectOptimalChannel(
          hasCameraView: false,
          hasBleHardware: true,
          hasNfcEnabled: false,
          isConnectedToOfficeWifi: true,
        ),
        MobileMachinePunchChannel.bleBeacon,
      );

      // 4. No near-field hardware, but connected to Wi-Fi -> LAN direct
      expect(
        service.selectOptimalChannel(
          hasCameraView: false,
          hasBleHardware: false,
          hasNfcEnabled: false,
          isConnectedToOfficeWifi: true,
        ),
        MobileMachinePunchChannel.localLanWifi,
      );

      // 5. Fallback -> Keypad TOTP
      expect(
        service.selectOptimalChannel(
          hasCameraView: false,
          hasBleHardware: false,
          hasNfcEnabled: false,
          isConnectedToOfficeWifi: false,
        ),
        MobileMachinePunchChannel.keypadTotp,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/kiosk_peripheral_status.dart';
import 'package:mybiometric/services/kiosk_peripheral_service.dart';

void main() {
  group('KioskPeripheralService Tests', () {
    test('Identifies healthy kiosk peripherals', () {
      final status = KioskPeripheralService.evaluateHealth(
        kioskId: 'kiosk_main_entrance',
        cameraFps: 30.0,
        printerHasPaper: true,
        relayResponding: true,
        storageFreeMb: 8500,
        batteryPercent: 100,
        isPluggedIn: true,
      );

      expect(status.requiresMaintenance, isFalse);
      expect(status.cameraStatus, equals(PeripheralHealthState.healthy));
      expect(status.magneticDoorRelayStatus, equals(PeripheralHealthState.healthy));
    });

    test('Flags maintenance when relay is disconnected or storage critically low', () {
      final status = KioskPeripheralService.evaluateHealth(
        kioskId: 'kiosk_back_gate',
        cameraFps: 30.0,
        printerHasPaper: false,
        relayResponding: false, // Critical failure
        storageFreeMb: 200, // < 500MB
        batteryPercent: 80,
        isPluggedIn: true,
      );

      expect(status.requiresMaintenance, isTrue);
      expect(status.magneticDoorRelayStatus, equals(PeripheralHealthState.critical));
      expect(status.thermalPrinterStatus, equals(PeripheralHealthState.warning));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_live_punch_receipt.dart';
import 'package:mybiometric_app/services/terminal_live_punch_receipt_service.dart';

void main() {
  group('TerminalLivePunchReceiptService Tests', () {
    late TerminalLivePunchReceiptService service;

    setUp(() {
      service = TerminalLivePunchReceiptService();
    });

    tearDown(() {
      service.dispose();
    });

    test('generates and emits terminal acknowledgement receipt to stream', () async {
      final expectation = expectLater(
        service.receiptStream,
        emits(predicate<TerminalLivePunchReceipt>((r) =>
            r.employeeId == 'EMP-11' &&
            r.accessGranted == true &&
            r.terminalDeviceName == 'Hikvision MinMoe')),
      );

      service.parseTerminalAck(
        terminalId: 'HIK-01',
        terminalDeviceName: 'Hikvision MinMoe',
        employeeId: 'EMP-11',
        punchType: 'PUNCH_IN',
        isSuccess: true,
      );

      await expectation;
    });

    test('properly formats failure receipt when access is rejected', () {
      final receipt = service.parseTerminalAck(
        terminalId: 'HIK-01',
        terminalDeviceName: 'Hikvision MinMoe',
        employeeId: 'EMP-99',
        punchType: 'PUNCH_OUT',
        isSuccess: false,
      );

      expect(receipt.accessGranted, false);
      expect(receipt.gateRelayOpenDurationMs, 0);
      expect(receipt.displayMessage.contains('Rejected'), true);
    });
  });
}

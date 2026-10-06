import 'dart:async';
import '../domain/models/terminal_live_punch_receipt.dart';

/// Service managing real-time feedback receipts streamed back from physical machines
class TerminalLivePunchReceiptService {
  final _receiptController = StreamController<TerminalLivePunchReceipt>.broadcast();

  Stream<TerminalLivePunchReceipt> get receiptStream => _receiptController.stream;

  void emitReceipt(TerminalLivePunchReceipt receipt) {
    _receiptController.add(receipt);
  }

  /// Parses raw ISAPI or ADMS acknowledgement packet from physical terminal
  TerminalLivePunchReceipt parseTerminalAck({
    required String terminalId,
    required String terminalDeviceName,
    required String employeeId,
    required String punchType,
    required bool isSuccess,
  }) {
    final receipt = TerminalLivePunchReceipt(
      receiptId: 'RCPT_${DateTime.now().millisecondsSinceEpoch}',
      terminalId: terminalId,
      terminalDeviceName: terminalDeviceName,
      employeeId: employeeId,
      punchType: punchType,
      terminalTimestamp: DateTime.now(),
      accessGranted: isSuccess,
      displayMessage: isSuccess
          ? 'Attendance Authenticated on $terminalDeviceName'
          : 'Attendance Rejected by $terminalDeviceName',
      gateRelayOpenDurationMs: isSuccess ? 3000 : 0,
    );

    emitReceipt(receipt);
    return receipt;
  }

  void dispose() {
    _receiptController.close();
  }
}

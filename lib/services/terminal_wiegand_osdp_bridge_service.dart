import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_auxiliary_reader.dart';

/// Decoded card result from a Wiegand or OSDP auxiliary reader bitstream.
class WiegandDecodedCard {
  final bool isValidParity;
  final int facilityCode;
  final int cardNumber;
  final AuxiliaryReaderProtocol protocol;

  const WiegandDecodedCard({
    required this.isValidParity,
    required this.facilityCode,
    required this.cardNumber,
    required this.protocol,
  });
}

/// Service managing hardware Wiegand 26/34/37 bit stream parsing and OSDP v2 reader integrations.
class TerminalWiegandOsdpBridgeService {
  /// Encodes facility code and card number into standard 26-bit Wiegand binary string.
  /// Format: [Even Parity (1b)] + [Facility Code (8b)] + [Card Number (16b)] + [Odd Parity (1b)]
  static String encodeWiegand26({required int facilityCode, required int cardNumber}) {
    final fcBits = (facilityCode & 0xFF).toRadixString(2).padLeft(8, '0');
    final cnBits = (cardNumber & 0xFFFF).toRadixString(2).padLeft(16, '0');

    final dataBits = fcBits + cnBits; // 24 bits

    // Calculate Even Parity on first 12 bits
    final first12 = dataBits.substring(0, 12);
    final evenParity = (first12.split('').where((b) => b == '1').length % 2 == 0) ? '0' : '1';

    // Calculate Odd Parity on last 12 bits
    final last12 = dataBits.substring(12, 24);
    final oddParity = (last12.split('').where((b) => b == '1').length % 2 == 0) ? '1' : '0';

    return '$evenParity$dataBits$oddParity';
  }

  /// Decodes a 26-bit Wiegand binary string into facility code and card number with parity validation.
  static WiegandDecodedCard decodeWiegand26(String bitStream) {
    if (bitStream.length != 26) {
      return const WiegandDecodedCard(
        isValidParity: false,
        facilityCode: 0,
        cardNumber: 0,
        protocol: AuxiliaryReaderProtocol.wiegand26,
      );
    }

    final evenParityBit = bitStream[0];
    final oddParityBit = bitStream[25];
    final fcBits = bitStream.substring(1, 9);
    final cnBits = bitStream.substring(9, 25);

    // Parity checks
    final first12 = bitStream.substring(1, 13);
    final computedEven = (first12.split('').where((b) => b == '1').length % 2 == 0) ? '0' : '1';

    final last12 = bitStream.substring(13, 25);
    final computedOdd = (last12.split('').where((b) => b == '1').length % 2 == 0) ? '1' : '0';

    final isValidParity = (evenParityBit == computedEven) && (oddParityBit == computedOdd);

    final facilityCode = int.tryParse(fcBits, radix: 2) ?? 0;
    final cardNumber = int.tryParse(cnBits, radix: 2) ?? 0;

    return WiegandDecodedCard(
      isValidParity: isValidParity,
      facilityCode: facilityCode,
      cardNumber: cardNumber,
      protocol: AuxiliaryReaderProtocol.wiegand26,
    );
  }

  /// Synthesizes an authentic terminal attendance event from an auxiliary reader swipe.
  static TerminalAttendanceEvent synthesizeAuxiliaryCardEvent({
    required BiometricTerminalDevice device,
    required TerminalAuxiliaryReaderConfig reader,
    required String employeeId,
    required String employeeName,
    required int cardNumber,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final punchType = reader.direction == 'ENTRY' ? 'PUNCH_IN' : 'PUNCH_OUT';

    return TerminalAttendanceEvent(
      eventId: 'AUX-${now.millisecondsSinceEpoch}-${reader.id}',
      deviceId: device.id,
      employeeId: employeeId,
      employeeName: employeeName,
      timestamp: now,
      punchType: punchType,
      authMode: DeviceAuthMode.card,
      cardNo: 'CARD-$cardNumber',
      similarityScore: 100.0,
      rawPayload: '{"auxiliaryReaderId": "${reader.id}", "protocol": "${reader.protocol.name}", "facilityCode": ${reader.facilityCode}}',
    );
  }
}

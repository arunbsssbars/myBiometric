import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/terminal_asset_scanner_service.dart';
import 'package:mybiometric/views/terminal_asset_scanner_card.dart';

void main() {
  group('TerminalAssetScannerService Suite', () {
    late TerminalAssetScannerService service;

    setUp(() {
      service = TerminalAssetScannerService();
      service.clearForTesting();
    });

    test('Checks out physical equipment barcode and registers active custody', () {
      final tx = service.checkoutAsset(
        assetBarcode: 'BARCODE_RADIO_99',
        assetName: 'Motorola Walkie-Talkie Ch 4',
        category: TrackedAssetCategory.radioWalkieTalkie,
        userId: 'GUARD_01',
        employeeName: 'Officer Jenny',
      );

      expect(tx.isReturned, isFalse);
      expect(service.hasUnreturnedEquipment('GUARD_01'), isTrue);
      expect(service.getActiveCustodyAssets('GUARD_01').length, equals(1));
    });

    test('Returns asset and marks custody resolved', () {
      service.checkoutAsset(
        assetBarcode: 'BARCODE_TOOL_01',
        assetName: 'Master Lock Key Ring',
        category: TrackedAssetCategory.toolingKey,
        userId: 'ENG_02',
        employeeName: 'Engineer Bob',
      );

      expect(service.hasUnreturnedEquipment('ENG_02'), isTrue);

      final returned = service.returnAsset('BARCODE_TOOL_01', 'ENG_02');
      expect(returned, isTrue);

      expect(service.hasUnreturnedEquipment('ENG_02'), isFalse);
      expect(service.getActiveCustodyAssets('ENG_02'), isEmpty);
    });

    testWidgets('TerminalAssetScannerCard renders without overflow across viewports', (tester) async {
      final tx = AssetCheckoutTransaction(
        transactionId: 'tx_test',
        assetBarcode: 'BC_LAPTOP_12',
        assetName: 'Dell Precision Mobile Workstation',
        category: TrackedAssetCategory.laptop,
        userId: 'USR_DEV',
        employeeName: 'Linus Torvalds',
        checkedOutAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalAssetScannerCard(
              transaction: tx,
              onReturn: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dell Precision Mobile Workstation'), findsOneWidget);
      expect(find.text('IN CUSTODY'), findsOneWidget);
      expect(find.text('Check In'), findsOneWidget);
    });
  });
}

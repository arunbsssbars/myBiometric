import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/domain/models/terminal_biometric_template.dart';
import 'package:mybiometric/services/terminal_biometric_template_service.dart';

void main() {
  group('Terminal Biometric Template & Feature Sync Suite', () {
    final testEmbeddings = List.generate(128, (i) => 0.123 * (i % 5));

    final testPackage = TerminalFaceTemplatePackage(
      employeeId: 'EMP-9021',
      employeeName: 'Sarah Connor',
      cardNo: 'CARD-778899',
      embeddingVector: testEmbeddings,
      faceBoundingBox: {'left': 0.2, 'top': 0.15, 'right': 0.8, 'bottom': 0.85},
      syncStatus: BiometricTemplateSyncStatus.pendingPush,
      updatedAt: DateTime(2026, 10, 2, 10, 0),
    );

    final testDevice = BiometricTerminalDevice(
      id: 'term_1',
      enterpriseId: 'ent_1',
      name: 'Lobby Face Terminal',
      modelName: 'DS-K1T671MF',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.50',
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalFaceTemplatePackage serializes and deserializes accurately', () {
      final json = testPackage.toJson();
      final reconstructed = TerminalFaceTemplatePackage.fromJson(json);

      expect(reconstructed.employeeId, equals('EMP-9021'));
      expect(reconstructed.employeeName, equals('Sarah Connor'));
      expect(reconstructed.cardNo, equals('CARD-778899'));
      expect(reconstructed.embeddingVector.length, equals(128));
      expect(reconstructed.syncStatus, equals(BiometricTemplateSyncStatus.pendingPush));
    });

    test('toHikvisionFaceDataRecord generates standard ISAPI facial record', () {
      final hikRecord = testPackage.toHikvisionFaceDataRecord(faceLibType: 'staticFD');

      expect(hikRecord['faceLibType'], equals('staticFD'));
      expect(hikRecord['FPID'], equals('EMP-9021'));
      expect(hikRecord['name'], equals('Sarah Connor'));
      expect(hikRecord['cardNo'], equals('CARD-778899'));
      expect(hikRecord['featureData'], isNotNull);
      expect(hikRecord['featureDataLen'], equals(512)); // 128 * 4 bytes for float32
    });

    test('toZkTecoBioDataRecord formats valid ADMS BIODATA payload', () {
      final zkRecord = testPackage.toZkTecoBioDataRecord(pin: 9021);

      expect(zkRecord, contains('BIODATA Pin=9021'));
      expect(zkRecord, contains('Type=9'));
      expect(zkRecord, contains('Tmp='));
    });

    test('TerminalBiometricTemplateService packages and batch pushes templates', () async {
      final service = TerminalBiometricTemplateService();
      final pkg = service.packageFaceTemplate(
        employeeId: 'EMP-100',
        employeeName: 'John Doe',
        embeddings: testEmbeddings,
        cardNo: 'C-100',
      );

      final result = await service.batchPushTemplates(
        enterpriseId: 'ent_1',
        devices: [testDevice],
        packages: [pkg],
      );

      expect(result.success, isTrue);
      expect(result.succeededCount, equals(1));
      expect(result.failedCount, equals(0));
      expect(result.terminalIds, contains('term_1'));
    });
  });
}

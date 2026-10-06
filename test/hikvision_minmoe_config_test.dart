import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_hardware_config.dart';
import 'package:mybiometric/services/hikvision_minmoe_config_service.dart';

void main() {
  group('HikvisionMinMoeConfigService Suite', () {
    const config = MinMoeHardwareConfig(
      terminalId: 'term_hik_gate1',
      deviceIp: '192.168.1.150',
      httpPort: 80,
      isapiPort: 8000,
      livenessMode: MinMoeLivenessMode.binocularStereoDepth,
      faceMatchThreshold: 0.88,
      recognitionDistanceCm: 150,
      whiteLightSupplementEnabled: true,
      whiteLightBrightnessPercent: 85,
      irIlluminationEnabled: true,
      voicePrompt: MinMoeAudioPrompt.accessGranted,
      volumeLevel: 80,
      tamperAlarmEnabled: true,
    );

    test('Generates syntactically valid ISAPI FaceRecognition XML payload', () {
      final xml = HikvisionMinMoeConfigService.instance.buildFaceRecognitionXml(config);

      expect(xml.contains('<FaceRecognition version="2.0"'), isTrue);
      expect(xml.contains('<matchThreshold>88</matchThreshold>'), isTrue);
      expect(xml.contains('<recognitionDistance>150</recognitionDistance>'), isTrue);
      expect(xml.contains('<livenessMode>binocularStereoDepth</livenessMode>'), isTrue);
      expect(xml.contains('<whiteLightSupplement>'), isTrue);
      expect(xml.contains('<brightness>85</brightness>'), isTrue);
    });

    test('Generates ISAPI Audio configuration XML with correct volume and chime', () {
      final audioXml = HikvisionMinMoeConfigService.instance.buildAudioConfigXml(config);

      expect(audioXml.contains('<AudioOutChannel version="2.0"'), isTrue);
      expect(audioXml.contains('<volume>80</volume>'), isTrue);
      expect(audioXml.contains('<promptSound>accessGranted</promptSound>'), isTrue);
    });

    test('Maps endpoints accurately for ISAPI HTTP deployment', () {
      final endpoints = HikvisionMinMoeConfigService.instance.buildIsapiEndpointMap(config);

      expect(endpoints['faceEndpoint'], equals('http://192.168.1.150:80/ISAPI/AccessControl/FaceRecognitionCfg'));
      expect(endpoints['audioEndpoint'], equals('http://192.168.1.150:80/ISAPI/System/Audio/AudioOutChannels/1'));
    });
  });
}

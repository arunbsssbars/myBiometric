import '../domain/models/minmoe_hardware_config.dart';

/// Service generating Hikvision ISAPI XML and JSON payloads for MinMoe terminals
class HikvisionMinMoeConfigService {
  HikvisionMinMoeConfigService._internal();
  static final HikvisionMinMoeConfigService instance = HikvisionMinMoeConfigService._internal();

  /// Generates the standard ISAPI FaceRecognition custom XML payload
  String buildFaceRecognitionXml(MinMoeHardwareConfig config) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<FaceRecognition version="2.0" xmlns="http://www.isapi.org/ver20/XMLSchema">
  <matchThreshold>${(config.faceMatchThreshold * 100).round()}</matchThreshold>
  <recognitionDistance>${config.recognitionDistanceCm}</recognitionDistance>
  <livenessMode>${config.livenessMode.name}</livenessMode>
  <whiteLightSupplement>
    <enabled>${config.whiteLightSupplementEnabled}</enabled>
    <brightness>${config.whiteLightBrightnessPercent}</brightness>
  </whiteLightSupplement>
  <irIllumination>
    <enabled>${config.irIlluminationEnabled}</enabled>
  </irIllumination>
</FaceRecognition>''';
  }

  /// Generates ISAPI Audio and Voice Prompt configuration XML
  String buildAudioConfigXml(MinMoeHardwareConfig config) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<AudioOutChannel version="2.0" xmlns="http://www.isapi.org/ver20/XMLSchema">
  <volume>${config.volumeLevel}</volume>
  <promptSound>${config.voicePrompt.name}</promptSound>
</AudioOutChannel>''';
  }

  /// Builds complete deployment payload ready for HTTP PUT /ISAPI/AccessControl/FaceRecognitionCfg
  Map<String, dynamic> buildIsapiEndpointMap(MinMoeHardwareConfig config) {
    return {
      'faceEndpoint': 'http://${config.deviceIp}:${config.httpPort}/ISAPI/AccessControl/FaceRecognitionCfg',
      'facePayload': buildFaceRecognitionXml(config),
      'audioEndpoint': 'http://${config.deviceIp}:${config.httpPort}/ISAPI/System/Audio/AudioOutChannels/1',
      'audioPayload': buildAudioConfigXml(config),
    };
  }
}

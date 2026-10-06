import '../domain/models/zkteco_biometric_template.dart';

/// Service generating ADMS server-push commands for syncing templates to ZKTeco machines
class ZktecoTemplateSyncService {
  ZktecoTemplateSyncService._internal();
  static final ZktecoTemplateSyncService instance = ZktecoTemplateSyncService._internal();

  /// Formats the standard ADMS `DATA UPDATE USER_TMP` command string
  String buildUpdateUserTemplateCommand({
    required int commandId,
    required ZktecoBiometricTemplate template,
  }) {
    // Format: C:<id>:DATA UPDATE FINGERTMP PIN=<pin>\tFID=<fid>\tSize=<size>\tValid=1\tTMP=<base64>
    return 'C:$commandId:DATA UPDATE FINGERTMP PIN=${template.pin}\tFID=${template.fingerId}\tSize=${template.templateSize}\tValid=1\tTMP=${template.templateBase64}';
  }

  /// Formats the standard ADMS `DATA UPDATE USER` command string
  String buildUpdateUserCommand({
    required int commandId,
    required String pin,
    required String name,
    required int privilege,
    String? cardNo,
    String? password,
  }) {
    final cardStr = cardNo != null ? '\tCard=$cardNo' : '';
    final passStr = password != null ? '\tPassword=$password' : '';
    return 'C:$commandId:DATA UPDATE USER PIN=$pin\tName=$name\tPri=$privilege$cardStr$passStr';
  }

  /// Parses a template upload line emitted by ZKTeco ADMS machines
  ZktecoBiometricTemplate? parseMachineUploadedTemplate(String rawLine) {
    if (!rawLine.contains('PIN=') || !rawLine.contains('TMP=')) return null;

    final Map<String, String> params = {};
    final tokens = rawLine.split(RegExp(r'[\t\s]+'));

    for (final token in tokens) {
      final pair = token.split('=');
      if (pair.length == 2) {
        params[pair[0].trim()] = pair[1].trim();
      }
    }

    final pin = params['PIN'];
    final tmp = params['TMP'];
    if (pin == null || tmp == null) return null;

    final fid = int.tryParse(params['FID'] ?? '0') ?? 0;
    final size = int.tryParse(params['Size'] ?? '${tmp.length}') ?? tmp.length;

    return ZktecoBiometricTemplate(
      pin: pin,
      fingerId: fid,
      templateBase64: tmp,
      templateSize: size,
    );
  }
}

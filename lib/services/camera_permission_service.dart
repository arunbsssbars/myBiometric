import 'package:permission_handler/permission_handler.dart';

class CameraPermissionService {
  /// Requests camera permission. Returns true if permission is granted.
  Future<bool> requestPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    // For permanently denied, open app settings.
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }
}

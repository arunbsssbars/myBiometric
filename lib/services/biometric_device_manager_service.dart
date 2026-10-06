import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import 'hikvision_isapi_service.dart';
import 'terminal_attendance_sync_service.dart';

/// Central management service for registering, monitoring, and synchronizing
/// physical biometric terminals across enterprise facilities and job sites.
class BiometricDeviceManagerService {
  final FirebaseFirestore _firestore;
  final HikvisionIsapiService _isapiService;
  final TerminalAttendanceSyncService _syncService;

  BiometricDeviceManagerService({
    FirebaseFirestore? firestore,
    HikvisionIsapiService? isapiService,
    TerminalAttendanceSyncService? syncService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _isapiService = isapiService ?? HikvisionIsapiService(),
        _syncService = syncService ?? TerminalAttendanceSyncService(firestore: firestore);

  /// Streams registered biometric terminals for an enterprise.
  Stream<List<BiometricTerminalDevice>> streamDevices(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BiometricTerminalDevice.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Registers a new physical biometric terminal into the enterprise network.
  Future<String> registerDevice({
    required String enterpriseId,
    required String name,
    required String modelName,
    required TerminalProtocol protocol,
    required String ipAddress,
    int port = 80,
    String? serialNumber,
    String? username,
    String? password,
    String? branchId,
    String? branchName,
    bool autoSyncEnabled = true,
    int syncIntervalMinutes = 15,
  }) async {
    final docRef = _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc();

    final device = BiometricTerminalDevice(
      id: docRef.id,
      enterpriseId: enterpriseId,
      name: name,
      modelName: modelName,
      protocol: protocol,
      ipAddress: ipAddress,
      port: port,
      serialNumber: serialNumber,
      username: username,
      password: password,
      branchId: branchId,
      branchName: branchName,
      status: DeviceConnectionStatus.offline,
      autoSyncEnabled: autoSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes,
      createdAt: DateTime.now(),
    );

    await docRef.set(device.toMap());
    return docRef.id;
  }

  /// Updates configuration parameters for an existing terminal.
  Future<void> updateDevice({
    required String enterpriseId,
    required BiometricTerminalDevice device,
  }) async {
    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc(device.id)
        .update(device.toMap());
  }

  /// Deletes a terminal registration from the enterprise database.
  Future<void> deleteDevice({
    required String enterpriseId,
    required String deviceId,
  }) async {
    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc(deviceId)
        .delete();
  }

  /// Pings and tests device connection, updating live status in Firestore.
  Future<Map<String, dynamic>> testAndRecordConnectionStatus({
    required String enterpriseId,
    required BiometricTerminalDevice device,
  }) async {
    final result = await _isapiService.testConnection(device);
    final isSuccess = result['success'] == true;

    final newStatus = isSuccess ? DeviceConnectionStatus.online : DeviceConnectionStatus.error;

    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc(device.id)
        .update({
      'status': newStatus.name,
      'lastHeartbeatAt': FieldValue.serverTimestamp(),
    });

    return result;
  }

  /// Triggers a live on-demand event fetch and database synchronization for a terminal.
  Future<TerminalSyncResult> triggerDeviceSync({
    required String enterpriseId,
    required BiometricTerminalDevice device,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (device.protocol == TerminalProtocol.hikvisionIsapi) {
      final events = await _isapiService.fetchAttendanceEvents(
        device,
        startTime: startTime,
        endTime: endTime,
      );

      final result = await _syncService.processAndPersistEvents(
        enterpriseId: enterpriseId,
        device: device,
        events: events,
      );

      return result;
    }

    return const TerminalSyncResult(
      totalReceived: 0,
      normalizedCount: 0,
      duplicateCount: 0,
      unmappedEmployeeCount: 0,
    );
  }
}

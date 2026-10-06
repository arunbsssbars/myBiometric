import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_access_schedule.dart';
import 'hikvision_isapi_service.dart';

/// Service managing physical access control schedules and pushing door rules to biometric terminals.
class TerminalAccessScheduleService {
  final FirebaseFirestore _firestore;
  final HikvisionIsapiService _isapiService;

  TerminalAccessScheduleService({
    FirebaseFirestore? firestore,
    HikvisionIsapiService? isapiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _isapiService = isapiService ?? HikvisionIsapiService();

  /// Streams configured access schedules for an enterprise.
  Stream<List<TerminalAccessSchedule>> streamSchedules(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('access_schedules')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TerminalAccessSchedule.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Saves or updates an access schedule.
  Future<void> saveSchedule(TerminalAccessSchedule schedule) async {
    await _firestore
        .collection('enterprises')
        .doc(schedule.enterpriseId)
        .collection('access_schedules')
        .doc(schedule.id)
        .set(schedule.toMap(), SetOptions(merge: true));
  }

  /// Pushes an access schedule configuration down to a physical Hikvision MinMoe terminal.
  Future<bool> pushScheduleToDevice({
    required BiometricTerminalDevice device,
    required TerminalAccessSchedule schedule,
  }) async {
    if (device.protocol != TerminalProtocol.hikvisionIsapi) {
      return true; // Not supported or non-ISAPI device
    }

    try {
      final payload = schedule.toHikvisionIsapiSchedule();
      final endpoint = '/ISAPI/AccessControl/TimeSchedule/${schedule.id}';
      final response = await _isapiService.sendDigestRequest(
        device: device,
        endpoint: endpoint,
        method: 'PUT',
        jsonBody: payload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Evaluates if a given swipe or punch is compliant with the access schedule.
  bool evaluateAccessCompliance({
    required TerminalAccessSchedule schedule,
    required DateTime timestamp,
    bool isManager = false,
  }) {
    return schedule.isAccessAuthorized(timestamp, isManager: isManager);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../services/offline_attendance_queue_service.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> logAttendance({
    required String userId,
    required String enterpriseId,
    required String type,
    String verifiedVia = 'FACE_ID',
    double? confidenceScore,
    int? shiftDurationMinutes,
    double? latitude,
    double? longitude,
    double? distanceFromOfficeMeters,
    bool? withinGeofence,
    String? employeeName,
    String? employeeIdCode,
    String? punchStatus,
    int? lateMinutes,
    int? earlyMinutes,
    int? overtimeMinutes,
    String? workStatus,
    String? breakType,
  }) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'enterpriseId': enterpriseId,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'verifiedVia': verifiedVia,
    };
    if (confidenceScore != null) data['confidenceScore'] = confidenceScore;
    if (shiftDurationMinutes != null) data['shiftDurationMinutes'] = shiftDurationMinutes;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (distanceFromOfficeMeters != null) data['distanceFromOfficeMeters'] = distanceFromOfficeMeters;
    if (withinGeofence != null) data['withinGeofence'] = withinGeofence;
    if (employeeName != null) data['employeeName'] = employeeName;
    if (employeeIdCode != null) {
      data['employeeIdCode'] = employeeIdCode;
      data['employeeId'] = employeeIdCode;
    }
    if (punchStatus != null) data['punchStatus'] = punchStatus;
    if (lateMinutes != null) data['lateMinutes'] = lateMinutes;
    if (earlyMinutes != null) data['earlyMinutes'] = earlyMinutes;
    if (overtimeMinutes != null) data['overtimeMinutes'] = overtimeMinutes;
    if (workStatus != null) data['workStatus'] = workStatus;
    if (breakType != null) data['breakType'] = breakType;

    try {
      await _firestore.collection('attendance_logs').add(data);
    } catch (e) {
      // Offline fallback: enqueue punch locally so it can sync when connectivity returns
      try {
        await OfflineAttendanceQueueService().enqueuePunch(data);
      } catch (_) {}
    }
  }

  @override
  Future<Map<String, dynamic>?> getLatestPunchToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection('attendance_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final todayLogs = snapshot.docs.where((doc) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return ts != null && ts.isAfter(startOfToday);
      }).toList();

      if (todayLogs.isEmpty) return null;

      todayLogs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });

      return todayLogs.first.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getLatestPunchTypeToday(String userId) async {
    final latest = await getLatestPunchToday(userId);
    return latest?['type'] as String?;
  }
}

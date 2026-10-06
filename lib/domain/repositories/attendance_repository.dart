/// Contract for logging and retrieving attendance logs.
abstract class AttendanceRepository {
  /// Records a punch in or punch out event with optional GPS geofencing metadata.
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
  });

  /// Retrieves the most recent punch information (type and timestamp) for a user today.
  Future<Map<String, dynamic>?> getLatestPunchToday(String userId);

  /// Retrieves the most recent punch type ('PUNCH_IN' or 'PUNCH_OUT') for a user today.
  Future<String?> getLatestPunchTypeToday(String userId);
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/employee_profile.dart';
import '../domain/models/shift_schedule.dart';

/// Service managing on-device persistence of employee biometric profiles
/// to enable 100% offline face recognition on Kiosk terminals.
class OfflineRosterCacheService {
  static final OfflineRosterCacheService _instance = OfflineRosterCacheService._internal();
  factory OfflineRosterCacheService() => _instance;
  OfflineRosterCacheService._internal();

  static const String _rosterPrefix = 'kiosk_roster_cache_';
  static const String _syncTimePrefix = 'kiosk_roster_last_sync_';
  static const String _shiftPrefix = 'kiosk_shift_cache_';

  /// Save employee profiles to local persistent storage
  Future<void> cacheRoster(String enterpriseId, List<EmployeeProfile> roster) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_rosterPrefix${enterpriseId.trim().toLowerCase()}';
      final jsonList = roster.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(key, jsonString);
      await prefs.setString(
        '$_syncTimePrefix${enterpriseId.trim().toLowerCase()}',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Retrieve locally cached roster for an enterprise
  Future<List<EmployeeProfile>> getCachedRoster(String enterpriseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_rosterPrefix${enterpriseId.trim().toLowerCase()}';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => EmployeeProfile.fromJson(item as Map<String, dynamic>))
          .where((p) => p.facialSignature != null && p.facialSignature!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the timestamp of the last successful roster synchronization
  Future<DateTime?> getLastSyncTime(String enterpriseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_syncTimePrefix${enterpriseId.trim().toLowerCase()}');
      if (raw != null) return DateTime.tryParse(raw);
    } catch (_) {}
    return null;
  }

  /// Clear the cached roster
  Future<void> clearCache(String enterpriseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_rosterPrefix${enterpriseId.trim().toLowerCase()}');
      await prefs.remove('$_syncTimePrefix${enterpriseId.trim().toLowerCase()}');
      await prefs.remove('$_shiftPrefix${enterpriseId.trim().toLowerCase()}');
    } catch (_) {}
  }

  /// Save shift schedule to local persistent storage
  Future<void> cacheShiftSchedule(String enterpriseId, ShiftSchedule schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_shiftPrefix${enterpriseId.trim().toLowerCase()}';
      await prefs.setString(key, jsonEncode(schedule.toJson()));
    } catch (_) {}
  }

  /// Retrieve locally cached shift schedule
  Future<ShiftSchedule?> getCachedShiftSchedule(String enterpriseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_shiftPrefix${enterpriseId.trim().toLowerCase()}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        return ShiftSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}

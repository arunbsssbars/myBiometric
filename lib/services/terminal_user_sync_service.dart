import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import 'hikvision_isapi_service.dart';

/// Summary result of synchronizing cloud employee roster to external hardware terminals.
class TerminalRosterSyncResult {
  final int totalTargeted;
  final int successCount;
  final int failedCount;
  final List<String> errorLogs;

  const TerminalRosterSyncResult({
    required this.totalTargeted,
    required this.successCount,
    required this.failedCount,
    this.errorLogs = const [],
  });
}

/// Service responsible for provisioning employees, cards, and permissions
/// from the cloud database down to physical biometric terminals (Hikvision, etc.).
class TerminalUserSyncService {
  final FirebaseFirestore _firestore;
  final HikvisionIsapiService _isapiService;

  TerminalUserSyncService({
    FirebaseFirestore? firestore,
    HikvisionIsapiService? isapiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _isapiService = isapiService ?? HikvisionIsapiService();

  /// Synchronizes all eligible enterprise employees to a designated physical terminal.
  Future<TerminalRosterSyncResult> syncEnterpriseRosterToDevice({
    required String enterpriseId,
    required BiometricTerminalDevice device,
    String? departmentFilter,
  }) async {
    final errorLogs = <String>[];
    int success = 0;
    int failed = 0;

    try {
      final employeesSnapshot = await _firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('employees')
          .get();

      final eligibleEmployees = employeesSnapshot.docs.where((doc) {
        final data = doc.data();
        if (departmentFilter != null && departmentFilter.isNotEmpty) {
          return data['department'] == departmentFilter;
        }
        if (device.branchId != null && device.branchId!.isNotEmpty) {
          final branchId = data['branchId']?.toString();
          if (branchId != null && branchId.isNotEmpty && branchId != device.branchId) {
            return false;
          }
        }
        return true;
      }).toList();

      for (final doc in eligibleEmployees) {
        final data = doc.data();
        final empId = (data['employeeId'] ?? doc.id).toString().trim();
        final fullName = (data['fullName'] ?? data['name'] ?? 'Employee').toString();
        final cardNo = data['cardNo']?.toString();
        final role = data['role']?.toString().toLowerCase() ?? 'employee';
        final userType = (role == 'admin' || role == 'manager') ? 'admin' : 'normal';

        if (device.protocol == TerminalProtocol.hikvisionIsapi) {
          final ok = await _isapiService.syncPersonToTerminal(
            device,
            employeeId: empId,
            fullName: fullName,
            cardNo: cardNo,
            userType: userType,
          );

          if (ok) {
            success++;
          } else {
            failed++;
            errorLogs.add('Failed to provision $fullName ($empId) to ${device.name}');
          }
        } else {
          // Generic or simulated sync
          success++;
        }
      }

      return TerminalRosterSyncResult(
        totalTargeted: eligibleEmployees.length,
        successCount: success,
        failedCount: failed,
        errorLogs: errorLogs,
      );
    } catch (e) {
      errorLogs.add('Roster sync aborted: $e');
      return TerminalRosterSyncResult(
        totalTargeted: 0,
        successCount: success,
        failedCount: failed,
        errorLogs: errorLogs,
      );
    }
  }

  /// Evaluates roster sync eligibility purely in memory.
  static List<Map<String, dynamic>> filterRosterForDevice({
    required List<Map<String, dynamic>> employees,
    String? branchId,
    String? department,
  }) {
    return employees.where((emp) {
      if (department != null && department.isNotEmpty) {
        if (emp['department'] != department) return false;
      }
      if (branchId != null && branchId.isNotEmpty) {
        final empBranch = emp['branchId']?.toString();
        if (empBranch != null && empBranch.isNotEmpty && empBranch != branchId) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/terminal_user_sync_service.dart';

void main() {
  group('Terminal Roster Sync Engine Suite', () {
    test('filterRosterForDevice filters employees matching device branch and department constraints', () {
      final roster = [
        {'id': '1', 'name': 'Arun Sharma', 'branchId': 'branch-hq', 'department': 'Engineering'},
        {'id': '2', 'name': 'Rajesh Kumar', 'branchId': 'branch-hq', 'department': 'Sales'},
        {'id': '3', 'name': 'Elena Rostova', 'branchId': 'branch-downtown', 'department': 'Engineering'},
        {'id': '4', 'name': 'Sarah Connor', 'branchId': '', 'department': 'Operations'},
      ];

      // Filter by branch HQ
      final hqEmployees = TerminalUserSyncService.filterRosterForDevice(
        employees: roster,
        branchId: 'branch-hq',
      );
      expect(hqEmployees.length, 3); // 2 in branch-hq + 1 with empty branch (global)

      // Filter by department Engineering
      final engEmployees = TerminalUserSyncService.filterRosterForDevice(
        employees: roster,
        department: 'Engineering',
      );
      expect(engEmployees.length, 2);

      // Filter by both branch HQ and Engineering
      final hqEng = TerminalUserSyncService.filterRosterForDevice(
        employees: roster,
        branchId: 'branch-hq',
        department: 'Engineering',
      );
      expect(hqEng.length, 1);
      expect(hqEng.first['name'], 'Arun Sharma');
    });
  });
}

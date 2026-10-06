import '../domain/models/department_role_policy.dart';

/// Service enforcing department-level permission boundaries and approval hierarchies
class DepartmentPermissionService {
  /// Check if the reviewer has authority over an employee in the specified department
  static bool hasAuthorityOverDepartment({
    required ManagerJurisdictionProfile reviewer,
    required String targetDepartment,
  }) {
    // 1. Global Admins have authority over everything
    if (reviewer.role.isAdministrative) return true;

    // 2. Regular Employees have no managerial authority
    if (reviewer.role == EnterpriseUserRole.employee) return false;

    // 3. Department Managers have authority if the target department is in their managed list
    if (reviewer.role == EnterpriseUserRole.manager) {
      if (reviewer.managedDepartments.isEmpty) return false;

      final normalizedTarget = targetDepartment.trim().toLowerCase();
      return reviewer.managedDepartments.any(
        (dept) => dept.trim().toLowerCase() == normalizedTarget,
      );
    }

    return false;
  }

  /// Check if the reviewer can approve a leave request for an employee
  static bool canApproveLeave({
    required ManagerJurisdictionProfile reviewer,
    required String employeeDepartment,
  }) {
    if (!reviewer.canApproveLeave) return false;
    return hasAuthorityOverDepartment(
      reviewer: reviewer,
      targetDepartment: employeeDepartment,
    );
  }

  /// Check if the reviewer can approve attendance regularization for an employee
  static bool canApproveRegularization({
    required ManagerJurisdictionProfile reviewer,
    required String employeeDepartment,
  }) {
    if (!reviewer.canApproveRegularization) return false;
    return hasAuthorityOverDepartment(
      reviewer: reviewer,
      targetDepartment: employeeDepartment,
    );
  }

  /// Filter a list of items (requests, logs, employees) to only those within the manager's scope
  static List<T> filterScopedItems<T>({
    required ManagerJurisdictionProfile reviewer,
    required List<T> items,
    required String Function(T item) departmentExtractor,
  }) {
    // Admins see all items
    if (reviewer.role.isAdministrative) return List.from(items);

    // Employees see none in management lists
    if (reviewer.role == EnterpriseUserRole.employee) return [];

    // Managers see only items matching their assigned departments
    return items.where((item) {
      final dept = departmentExtractor(item);
      return hasAuthorityOverDepartment(reviewer: reviewer, targetDepartment: dept);
    }).toList();
  }

  /// Generates human-readable jurisdiction summary
  static String getJurisdictionDescription(ManagerJurisdictionProfile profile) {
    switch (profile.jurisdiction) {
      case ApprovalJurisdiction.global:
        return 'Global Enterprise Scope (All Departments)';
      case ApprovalJurisdiction.department:
        if (profile.managedDepartments.length == 1) {
          return 'Department Scope: ${profile.managedDepartments.first}';
        }
        return 'Department Scope: ${profile.managedDepartments.join(', ')}';
      case ApprovalJurisdiction.none:
        return 'Individual Contributor (No Manager Scope)';
    }
  }
}

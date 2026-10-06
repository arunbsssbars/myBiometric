/// Hierarchy of user roles within an enterprise (Jibble-compliant)
enum EnterpriseUserRole {
  employee,
  manager,
  admin,
  superAdmin;

  static EnterpriseUserRole fromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'super_admin':
      case 'superadmin':
        return EnterpriseUserRole.superAdmin;
      case 'admin':
      case 'enterprise_admin':
        return EnterpriseUserRole.admin;
      case 'manager':
      case 'supervisor':
      case 'team_lead':
        return EnterpriseUserRole.manager;
      case 'employee':
      default:
        return EnterpriseUserRole.employee;
    }
  }

  bool get isAdministrative => this == admin || this == superAdmin;
  bool get isManagerOrAbove => this == manager || this == admin || this == superAdmin;
}

/// Scope of approval authority
enum ApprovalJurisdiction {
  global, // Enterprise-wide approval rights
  department, // Limited to assigned departments
  none, // Regular employee (no approval rights)
}

/// Model encapsulating an administrator or manager's operational jurisdiction
class ManagerJurisdictionProfile {
  final String userId;
  final EnterpriseUserRole role;
  final String enterpriseId;
  final List<String> managedDepartments;
  final bool canApproveLeave;
  final bool canApproveRegularization;
  final bool canEditTimesheets;

  const ManagerJurisdictionProfile({
    required this.userId,
    required this.role,
    required this.enterpriseId,
    this.managedDepartments = const [],
    this.canApproveLeave = true,
    this.canApproveRegularization = true,
    this.canEditTimesheets = true,
  });

  ApprovalJurisdiction get jurisdiction {
    if (role.isAdministrative) return ApprovalJurisdiction.global;
    if (role == EnterpriseUserRole.manager && managedDepartments.isNotEmpty) {
      return ApprovalJurisdiction.department;
    }
    return ApprovalJurisdiction.none;
  }

  factory ManagerJurisdictionProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ManagerJurisdictionProfile(
        userId: '',
        role: EnterpriseUserRole.employee,
        enterpriseId: '',
      );
    }

    return ManagerJurisdictionProfile(
      userId: json['userId'] as String? ?? json['uid'] as String? ?? '',
      role: EnterpriseUserRole.fromString(json['role'] as String?),
      enterpriseId: json['enterpriseId'] as String? ?? '',
      managedDepartments: (json['managedDepartments'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          (json['department'] != null ? [json['department'].toString().trim()] : const []),
      canApproveLeave: json['canApproveLeave'] as bool? ?? true,
      canApproveRegularization: json['canApproveRegularization'] as bool? ?? true,
      canEditTimesheets: json['canEditTimesheets'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role.name,
        'enterpriseId': enterpriseId,
        'managedDepartments': managedDepartments,
        'canApproveLeave': canApproveLeave,
        'canApproveRegularization': canApproveRegularization,
        'canEditTimesheets': canEditTimesheets,
      };
}

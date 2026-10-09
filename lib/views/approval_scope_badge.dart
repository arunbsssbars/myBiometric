import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/department_role_policy.dart';
import '../services/department_permission_service.dart';

/// Responsive Material 3 badge component indicating reviewer's approval scope
/// (Global Admin vs Department-Scoped Manager). Built strictly to AQIL standards.
class ApprovalScopeBadge extends StatelessWidget {
  final ManagerJurisdictionProfile profile;
  final VoidCallback? onSwitchDepartment;

  const ApprovalScopeBadge({
    super.key,
    required this.profile,
    this.onSwitchDepartment,
  });

  @override
  Widget build(BuildContext context) {
    final isGlobal = profile.role.isAdministrative;
    final isManager = profile.role == EnterpriseUserRole.manager;

    final primaryColor = isGlobal
        ? context.colors.tertiary
        : (isManager ? context.colors.primary : context.colors.onSurfaceVariant);

    final bgColor = primaryColor.withValues(alpha: 0.08);
    final borderColor = primaryColor.withValues(alpha: 0.22);

    final title = isGlobal
        ? 'Enterprise Admin'
        : (isManager ? 'Department Manager' : 'Employee');

    // Safe joined metadata using AQIL standard
    final metaItems = <String>[
      DepartmentPermissionService.getJurisdictionDescription(profile),
      if (profile.canApproveLeave && profile.canApproveRegularization)
        'Full Approvals'
      else if (profile.canApproveLeave)
        'Leave Only'
      else if (profile.canApproveRegularization)
        'Timesheet Only',
    ];
    final metaString = metaItems.join(' • ');

    final icon = isGlobal
        ? Icons.admin_panel_settings_rounded
        : (isManager ? Icons.manage_accounts_rounded : Icons.person_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  metaString,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: primaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onSwitchDepartment != null && isManager)
            IconButton(
              icon: Icon(Icons.filter_list_rounded, size: 18, color: primaryColor),
              onPressed: onSwitchDepartment,
              tooltip: 'Filter department',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

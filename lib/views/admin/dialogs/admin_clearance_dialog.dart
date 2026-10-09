import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../services/audit_log_service.dart';

/// Shows the enterprise clearance and permission configuration dialog for pending staff applicants.
Future<void> showEmployeeClearanceDialog({
  required BuildContext context,
  required String enterpriseId,
  required String companyName,
  required QueryDocumentSnapshot empDoc,
}) async {
  final data = empDoc.data() as Map<String, dynamic>;
  final name = (data['fullName'] as String?)?.trim() ?? (data['name'] as String?)?.trim() ?? 'Employee';
  final email = (data['email'] as String?)?.trim() ?? 'No email provided';
  final existingId = (data['employeeId'] as String?)?.trim();
  final defaultId = (existingId != null && existingId.isNotEmpty)
      ? existingId
      : 'EMP-${empDoc.id.length >= 5 ? empDoc.id.substring(0, 5).toUpperCase() : empDoc.id.toUpperCase()}';

  final idController = TextEditingController(text: defaultId);
  String selectedDept = (data['department'] as String?)?.trim() ?? 'General';
  const departments = ['General', 'Engineering', 'Operations', 'Sales', 'Marketing', 'HR', 'Finance', 'Support'];
  if (!departments.contains(selectedDept)) {
    selectedDept = 'General';
  }

  String selectedRole = (data['role'] as String?)?.trim() ?? 'employee';
  const roles = ['employee', 'supervisor', 'manager'];
  if (!roles.contains(selectedRole)) {
    selectedRole = 'employee';
  }

  // Default to Kiosk Face and Mobile GPS for new approved staff
  final Set<String> selectedChannels = {'KIOSK_FACE', 'MOBILE_GPS'};

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        final colors = dialogCtx.colors;
        final textTheme = dialogCtx.text;
        final statusTheme = dialogCtx.status;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Icon(Icons.security_rounded, color: colors.primary, size: 26),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Clearance & Permissions',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applicant Identity Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Employee ID
                  Text('Assign Employee ID', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      hintText: 'e.g. EMP-10492',
                      filled: true,
                      fillColor: colors.surfaceContainerLowest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Department & Role Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Department', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              initialValue: selectedDept,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colors.surfaceContainerLowest,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: departments
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedDept = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Role', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colors.surfaceContainerLowest,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: roles
                                  .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r[0].toUpperCase() + r.substring(1), style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedRole = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Permitted Attendance Verification Methods
                  Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 20, color: colors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Authorized Attendance Channels',
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Employee will strictly only see and be able to use the options enabled below:',
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.borderSubtle),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: selectedChannels.contains('KIOSK_FACE'),
                          title: const Text('Office Kiosk Facial Scan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Mark attendance via enterprise kiosk terminal', style: TextStyle(fontSize: 12)),
                          secondary: const Icon(Icons.camera_front_rounded, size: 22),
                          dense: true,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedChannels.add('KIOSK_FACE');
                              } else {
                                selectedChannels.remove('KIOSK_FACE');
                              }
                            });
                          },
                        ),
                        Divider(height: 1, color: colors.borderSubtle),
                        CheckboxListTile(
                          value: selectedChannels.contains('MOBILE_GPS'),
                          title: const Text('Mobile GPS Punch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Punch from personal phone inside office geofence', style: TextStyle(fontSize: 12)),
                          secondary: const Icon(Icons.location_on_outlined, size: 22),
                          dense: true,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedChannels.add('MOBILE_GPS');
                              } else {
                                selectedChannels.remove('MOBILE_GPS');
                              }
                            });
                          },
                        ),
                        Divider(height: 1, color: colors.borderSubtle),
                        CheckboxListTile(
                          value: selectedChannels.contains('OFFICE_WIFI'),
                          title: const Text('Office Wi-Fi Punch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Punch when connected to verified enterprise Wi-Fi', style: TextStyle(fontSize: 12)),
                          secondary: const Icon(Icons.wifi_rounded, size: 22),
                          dense: true,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedChannels.add('OFFICE_WIFI');
                              } else {
                                selectedChannels.remove('OFFICE_WIFI');
                              }
                            });
                          },
                        ),
                        Divider(height: 1, color: colors.borderSubtle),
                        CheckboxListTile(
                          value: selectedChannels.contains('PHONE_BIOMETRICS'),
                          title: const Text('Phone Local Biometrics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Use on-device fingerprint/FaceID on employee phone', style: TextStyle(fontSize: 12)),
                          secondary: const Icon(Icons.fingerprint_rounded, size: 22),
                          dense: true,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedChannels.add('PHONE_BIOMETRICS');
                              } else {
                                selectedChannels.remove('PHONE_BIOMETRICS');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  if (selectedChannels.isEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusTheme.warning.container.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: statusTheme.warning.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: statusTheme.warning.color, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Warning: No methods selected. The employee will not be able to punch until you assign at least one method.',
                              style: textTheme.bodySmall?.copyWith(color: statusTheme.warning.onContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              label: const Text('Grant Clearance & Approve'),
              onPressed: () => Navigator.pop(dialogCtx, true),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed != true) return;

  final assignedId = idController.text.trim().isNotEmpty ? idController.text.trim() : defaultId;
  final channelsList = selectedChannels.toList();

  try {
    // 1. Update User document with clearance and permitted channels
    await FirebaseFirestore.instance.collection('users').doc(empDoc.id).set({
      'approvalStatus': 'APPROVED',
      'status': 'ACTIVE',
      'employeeId': assignedId,
      'department': selectedDept,
      'role': selectedRole,
      'allowedVerificationMethods': channelsList,
      'clearanceGrantedAt': FieldValue.serverTimestamp(),
      'enterpriseId': enterpriseId,
    }, SetOptions(merge: true));

    // 2. Sync to enterprise employees subcollection
    await FirebaseFirestore.instance
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('employees')
        .doc(empDoc.id)
        .set({
      'fullName': name,
      'email': email,
      'employeeId': assignedId,
      'department': selectedDept,
      'role': selectedRole,
      'approvalStatus': 'APPROVED',
      'status': 'ACTIVE',
      'allowedVerificationMethods': channelsList,
      'clearanceGrantedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Log Audit Action
    AuditLogService().logAction(
      enterpriseId: enterpriseId,
      action: 'STAFF_CLEARANCE_APPROVED',
      category: AuditLogService.categoryStaff,
      targetEmployeeName: name,
      targetEmployeeId: assignedId,
      details: 'Approved staff clearance: Role=$selectedRole, Dept=$selectedDept, Channels=[${channelsList.join(", ")}].',
    );

    // 4. Send In-App Notification to Employee
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'target': 'USER',
        'userId': empDoc.id,
        'enterpriseId': enterpriseId,
        'title': 'Clearance Granted!',
        'body': 'Your access to $companyName has been approved by admin. Authorized channels: ${channelsList.join(", ")}.',
        'type': 'REGULARIZATION_APPROVED',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated $name with ${channelsList.length} authorized attendance methods!'),
          backgroundColor: context.status.success.color,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear employee: $e'), backgroundColor: context.status.danger.color),
      );
    }
  }
}

/// Rejects a pending join application for an employee.
Future<void> rejectPendingEmployee({
  required BuildContext context,
  required String enterpriseId,
  required QueryDocumentSnapshot empDoc,
}) async {
  final data = empDoc.data() as Map<String, dynamic>;
  final name = (data['fullName'] as String?)?.trim() ?? (data['name'] as String?)?.trim() ?? 'Employee';

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: const Text('Reject Join Request?'),
      content: Text('Are you sure you want to reject $name? Their join request will be removed from your company workspace.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.status.danger.color),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Reject Application'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await FirebaseFirestore.instance.collection('users').doc(empDoc.id).set({
      'approvalStatus': 'REJECTED',
      'status': 'UNASSIGNED',
      'enterpriseId': FieldValue.delete(),
      'rejectedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('employees')
          .doc(empDoc.id)
          .delete();
    } catch (_) {}

    AuditLogService().logAction(
      enterpriseId: enterpriseId,
      action: 'STAFF_JOIN_REJECTED',
      category: AuditLogService.categoryStaff,
      targetEmployeeName: name,
      details: 'Administrator rejected company join application for $name.',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected join request for $name.'),
          backgroundColor: context.status.warning.color,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $e'), backgroundColor: context.status.danger.color),
      );
    }
  }
}

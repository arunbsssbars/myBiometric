import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../services/audit_log_service.dart';
import '../../../services/database_service.dart';
import '../../add_staff_screen.dart';
import '../../bulk_roster_import_screen.dart';
import '../../face_enrollment_screen.dart';
import '../dialogs/admin_clearance_dialog.dart';

/// Enterprise Workforce Roster Tab:
/// - Search by name or employee ID
/// - Status filters (All, Face Active, Pending Scan)
/// - Pending Join Approvals (Self-registered applicants awaiting clearance)
/// - Staff Cards with avatar, verification channels, clearance status, and action sheet
/// - Add Staff and Bulk Roster Import shortcuts
class AdminWorkforceTab extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> staff;
  final List<QueryDocumentSnapshot> logs;
  final void Function(List<QueryDocumentSnapshot> logs, {String? employeeFilterName, String? dateRangeTitle}) onOpenPdfPreview;

  const AdminWorkforceTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.staff,
    required this.logs,
    required this.onOpenPdfPreview,
  });

  @override
  State<AdminWorkforceTab> createState() => _AdminWorkforceTabState();
}

class _AdminWorkforceTabState extends State<AdminWorkforceTab> {
  final DatabaseService _dbService = DatabaseService();
  String _staffSearchQuery = '';
  String _staffFilterStatus = 'ALL'; // 'ALL', 'ENROLLED', 'PENDING'

  @override
  Widget build(BuildContext context) {
    final pendingApprovalStaff = widget.staff.where((s) {
      final data = s.data() as Map<String, dynamic>;
      return (data['approvalStatus'] == 'PENDING_APPROVAL' || data['status'] == 'PENDING_APPROVAL');
    }).toList();

    final approvedStaff = widget.staff.where((s) {
      final data = s.data() as Map<String, dynamic>;
      return data['approvalStatus'] != 'PENDING_APPROVAL' && data['status'] != 'PENDING_APPROVAL';
    }).toList();

    final totalStaff = approvedStaff.length;
    final enrolledCount = approvedStaff.where((s) => (s.data() as Map<String, dynamic>)['biometricsEnrolled'] == true).length;
    final pendingCount = totalStaff - enrolledCount;

    final filteredStaff = approvedStaff.where((s) {
      final data = s.data() as Map<String, dynamic>;
      final name = (data['fullName'] as String?)?.toLowerCase() ??
          (data['name'] as String?)?.toLowerCase() ??
          '';
      final empId = (data['employeeId'] as String?)?.toLowerCase() ?? '';
      final isEnrolled = data['biometricsEnrolled'] == true;

      if (_staffFilterStatus == 'ENROLLED' && !isEnrolled) return false;
      if (_staffFilterStatus == 'PENDING' && isEnrolled) return false;

      if (_staffSearchQuery.isNotEmpty) {
        final q = _staffSearchQuery.toLowerCase();
        if (!name.contains(q) && !empId.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Staff Header Summary & Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: context.colors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _staffSearchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search staff by name or ID...',
                          hintStyle: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, size: 18, color: context.colors.onSurfaceVariant),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddStaffScreen(
                            enterpriseId: widget.enterpriseId,
                            companyName: widget.companyName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_rounded, size: 17),
                    label: Text('Add Staff', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: BorderSide(color: context.colors.borderSubtle),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BulkRosterImportScreen(
                            enterpriseId: widget.enterpriseId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_upload_outlined, size: 17),
                    label: Text('Bulk', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All ($totalStaff)'),
                      selected: _staffFilterStatus == 'ALL',
                      onSelected: (_) => setState(() => _staffFilterStatus = 'ALL'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: Text('Face Active ($enrolledCount)'),
                      selected: _staffFilterStatus == 'ENROLLED',
                      selectedColor: context.status.success.color.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _staffFilterStatus == 'ENROLLED' ? context.status.success.color : null,
                        fontWeight: _staffFilterStatus == 'ENROLLED' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _staffFilterStatus = 'ENROLLED'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: Text('Pending Scan ($pendingCount)'),
                      selected: _staffFilterStatus == 'PENDING',
                      selectedColor: context.status.warning.color.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _staffFilterStatus == 'PENDING' ? context.status.warning.color : null,
                        fontWeight: _staffFilterStatus == 'PENDING' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _staffFilterStatus = 'PENDING'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.colors.borderSubtle),

        if (pendingApprovalStaff.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.status.warning.container.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.status.warning.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: context.status.warning.color, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Pending Join Approvals (${pendingApprovalStaff.length})',
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.status.warning.onContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'These employees self-joined using your company code. Review and approve to complete their registration.',
                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...pendingApprovalStaff.map((pDoc) => _buildPendingApprovalCard(pDoc)),
              ],
            ),
          ),

        // Staff List
        Expanded(
          child: filteredStaff.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, color: context.colors.onSurfaceVariant.withValues(alpha: 0.6), size: 48),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _staffSearchQuery.isNotEmpty
                            ? 'No staff found matching "$_staffSearchQuery"'
                            : 'No staff profiles match this filter.',
                        style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStaff.length,
                  itemBuilder: (context, index) {
                    final empDoc = filteredStaff[index];
                    final data = empDoc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] as String?)?.trim() ??
                        (data['name'] as String?)?.trim() ??
                        (data['email'] as String?)?.split('@').first ??
                        'Employee';
                    final empId = data['employeeId'] ?? 'Unassigned';
                    final isEnrolled = data['biometricsEnrolled'] == true;
                    final role = data['role'] as String? ?? 'employee';
                    final isAdmin = role == 'enterprise_admin';
                    final dept = data['department'] as String? ?? 'General';
                    final enrolledAt = (data['biometricEnrolledAt'] as Timestamp?)?.toDate();

                    final employeeLogs = widget.logs.where((l) => (l.data() as Map<String, dynamic>)['userId'] == empDoc.id).toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.colors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.shadow.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _showStaffActionSheet(empDoc, employeeLogs),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isEnrolled
                                            ? context.status.success.color.withValues(alpha: 0.15)
                                            : context.status.warning.color.withValues(alpha: 0.15),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                          style: context.textStyles.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isEnrolled ? context.status.success.color : context.status.warning.color,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: isEnrolled ? context.status.success.color : context.status.warning.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: context.colors.surface, width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: context.textStyles.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: context.colors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: context.colors.primary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: context.textStyles.labelSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: context.colors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: $empId • $dept',
                                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEnrolled
                                          ? context.status.success.color.withValues(alpha: 0.1)
                                          : context.status.warning.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                    ),
                                    child: Text(
                                      isEnrolled ? 'Face Active' : 'Pending',
                                      style: context.textStyles.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isEnrolled ? context.status.success.color : context.status.warning.color,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert, color: context.colors.onSurfaceVariant, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    tooltip: 'Staff Actions',
                                    onPressed: () => _showStaffActionSheet(empDoc, employeeLogs),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Divider(height: 1, color: context.colors.borderSubtle),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.history_rounded, size: 13, color: context.colors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${employeeLogs.length} Records',
                                        style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  if (enrolledAt != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_outlined, size: 13, color: context.status.success.color),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Enrolled ${enrolledAt.toLocal().toString().substring(0, 10)}',
                                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalCard(QueryDocumentSnapshot empDoc) {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ?? (data['name'] as String?)?.trim() ?? 'New Employee';
    final email = (data['email'] as String?)?.trim() ?? 'No email';
    final empId = data['employeeId'] as String?;
    final dept = data['department'] as String? ?? 'General';
    final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.status.warning.border),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.status.warning.color.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.status.warning.color),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.status.warning.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'Awaiting Clearance',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.status.warning.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$email • ID: ${empId ?? "Pending"} • $dept',
                        style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (requestedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Requested: ${requestedAt.toLocal().toString().substring(0, 16)}',
                          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      side: BorderSide(color: context.status.danger.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    onPressed: () => rejectPendingEmployee(
                      context: context,
                      enterpriseId: widget.enterpriseId,
                      empDoc: empDoc,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    onPressed: () => showEmployeeClearanceDialog(
                      context: context,
                      enterpriseId: widget.enterpriseId,
                      companyName: widget.companyName,
                      empDoc: empDoc,
                    ),
                    icon: const Icon(Icons.verified_user_rounded, size: 16),
                    label: const Text('Review & Clear', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffActionSheet(QueryDocumentSnapshot empDoc, List<QueryDocumentSnapshot> employeeLogs) {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ??
        (data['name'] as String?)?.trim() ??
        (data['email'] as String?)?.split('@').first ??
        'Employee';
    final empId = data['employeeId'] ?? 'Unassigned';
    final isEnrolled = data['biometricsEnrolled'] == true;
    final role = data['role'] as String? ?? 'employee';
    final isAdmin = role == 'enterprise_admin';
    final dept = data['department'] as String? ?? 'General';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isEnrolled
                      ? context.status.success.container
                      : context.status.warning.container,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEnrolled
                          ? context.status.success.onContainer
                          : context.status.warning.onContainer,
                    ),
                  ),
                ),
                title: Text(name, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  'ID: $empId • Dept: $dept • ${isAdmin ? "Enterprise Admin" : "Employee"}',
                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary),
                title: Text('Export Timesheet (PDF)', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('${employeeLogs.length} attendance records found', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onOpenPdfPreview(
                    employeeLogs,
                    employeeFilterName: '$name ($empId)',
                    dateRangeTitle: 'All Records for $name',
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: context.colors.textSecondary),
                title: Text('Edit Staff Profile', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Update Name, Employee ID, or Department', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditEmployeeDialog(empDoc);
                },
              ),
              ListTile(
                leading: Icon(Icons.checklist_rtl_rounded, color: context.status.success.color),
                title: Text('Configure Verification Channels', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Assign Kiosk Face, PIN, Mobile GPS, or Wi-Fi methods', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showVerificationChannelsDialog(empDoc);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_front_rounded, color: context.colors.primary),
                title: Text('Re-Enroll Face Biometrics', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Launch camera to scan and register face signature', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceEnrollmentScreen(
                        fullName: name,
                        employeeId: empId,
                        enterpriseId: widget.enterpriseId,
                        targetUserId: empDoc.id,
                      ),
                    ),
                  );
                },
              ),
              if (isEnrolled)
                ListTile(
                  leading: Icon(Icons.face_retouching_natural, color: context.status.warning.color),
                  title: Text('Reset Face Biometrics', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Clear face signature so employee can re-scan', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        title: const Text('Reset Face Biometrics?'),
                        content: Text(
                          'This will delete the enrolled face data for $name ($empId). They will need to re-enroll before they can punch at kiosks.',
                          style: context.textStyles.bodyMedium,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.status.warning.color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Reset Face Data'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await _dbService.resetEmployeeBiometrics(empDoc.id, enterpriseId: widget.enterpriseId);
                        AuditLogService().logAction(
                          enterpriseId: widget.enterpriseId,
                          action: AuditLogService.actionBiometricReset,
                          category: AuditLogService.categoryStaff,
                          targetEmployeeId: empId,
                          targetEmployeeName: name,
                          details: 'Face biometrics reset for $name ($empId). Fresh enrollment required.',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Face ID for $name has been reset. Fresh enrollment required.'),
                              backgroundColor: context.status.warning.color,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error resetting face data: $e'), backgroundColor: context.status.danger.color),
                          );
                        }
                      }
                    }
                  },
                ),
              ListTile(
                leading: Icon(isAdmin ? Icons.person_outline : Icons.admin_panel_settings_outlined, color: context.colors.tertiary),
                title: Text(isAdmin ? 'Demote to Employee' : 'Promote to Enterprise Admin', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(isAdmin ? 'Revoke administrative dashboard access' : 'Grant full administrative management rights', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final newRole = isAdmin ? 'employee' : 'enterprise_admin';
                  try {
                    await _dbService.updateEmployeeProfile(
                      userId: empDoc.id,
                      fullName: name,
                      employeeId: empId,
                      role: newRole,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name is now ${newRole == 'enterprise_admin' ? "an Admin" : "an Employee"}.'),
                          backgroundColor: context.status.success.color,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating role: $e'), backgroundColor: context.status.danger.color),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: context.status.danger.color),
                title: Text('Remove from Enterprise', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.status.danger.color)),
                subtitle: Text('Unlink this employee from your company code', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      title: const Text('Remove Employee?'),
                      content: Text('Are you sure you want to remove $name ($empId) from this enterprise?', style: context.textStyles.bodyMedium),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.status.danger.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await _dbService.removeEnterpriseEmployee(userId: empDoc.id);
                      AuditLogService().logAction(
                        enterpriseId: widget.enterpriseId,
                        action: AuditLogService.actionStaffRemoved,
                        category: AuditLogService.categoryStaff,
                        targetEmployeeId: empId,
                        targetEmployeeName: name,
                        details: 'Removed employee $name ($empId) from enterprise roster.',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Employee $name removed from enterprise.'),
                            backgroundColor: context.status.danger.color,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error removing employee: $e'), backgroundColor: context.status.danger.color),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showVerificationChannelsDialog(QueryDocumentSnapshot empDoc) async {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ??
        (data['name'] as String?)?.trim() ??
        'Employee';
    final empId = data['employeeId'] ?? 'EMP';
    final existingMethods = (data['allowedVerificationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['KIOSK_FACE', 'KIOSK_PIN'];

    final selected = Set<String>.from(existingMethods);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
            title: Row(
              children: [
                Icon(Icons.checklist_rtl_rounded, color: context.status.success.color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Channels: $name',
                    style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select which methods $name ($empId) is authorized to use for clocking in and out:',
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: selected.contains('KIOSK_FACE'),
                    title: Text('Kiosk Face ID', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Automated facial recognition at physical kiosk terminals', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    activeColor: context.colors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selected.add('KIOSK_FACE');
                        } else {
                          selected.remove('KIOSK_FACE');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: selected.contains('KIOSK_PIN'),
                    title: Text('Kiosk Employee PIN Fallback', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('6-digit personal PIN entry when lighting or mask impedes face scan', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    activeColor: context.colors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selected.add('KIOSK_PIN');
                        } else {
                          selected.remove('KIOSK_PIN');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: selected.contains('MOBILE_GPS'),
                    title: Text('Mobile App with GPS Geofencing', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Allow employee to punch via their personal mobile phone on campus', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    activeColor: context.colors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selected.add('MOBILE_GPS');
                        } else {
                          selected.remove('MOBILE_GPS');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: selected.contains('OFFICE_WIFI'),
                    title: Text('Office Wi-Fi Verification', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Require employee connection to recognized office wireless router', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    activeColor: context.colors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selected.add('OFFICE_WIFI');
                        } else {
                          selected.remove('OFFICE_WIFI');
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                onPressed: isSaving || selected.isEmpty
                    ? null
                    : () async {
                        setModalState(() => isSaving = true);
                        try {
                          await _dbService.updateEmployeeAllowedVerificationMethods(
                            userId: empDoc.id,
                            methods: selected.toList(),
                          );
                          try {
                            await FirebaseFirestore.instance
                                .collection('enterprises')
                                .doc(widget.enterpriseId)
                                .collection('employees')
                                .doc(empDoc.id)
                                .set({
                              'allowedVerificationMethods': selected.toList(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                          } catch (_) {}
                          AuditLogService().logAction(
                            enterpriseId: widget.enterpriseId,
                            action: 'VERIFICATION_CHANNELS_UPDATED',
                            category: AuditLogService.categoryStaff,
                            targetEmployeeId: empId,
                            targetEmployeeName: name,
                            details: 'Updated verification channels for $name: [${selected.join(", ")}].',
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated verification methods for $name.'),
                                backgroundColor: context.status.success.color,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update channels: $e'),
                                backgroundColor: context.status.danger.color,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary))
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditEmployeeDialog(QueryDocumentSnapshot empDoc) async {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ??
        (data['name'] as String?)?.trim() ??
        (data['email'] as String?)?.split('@').first ??
        'Employee';
    final empId = data['employeeId'] ?? '';
    final dept = data['department'] as String? ?? 'General';
    final role = data['role'] as String? ?? 'employee';

    final nameController = TextEditingController(text: name);
    final idController = TextEditingController(text: empId);
    final deptController = TextEditingController(text: dept);
    String selectedRole = role;
    final shift = data['assignedShift'] as String? ?? 'GENERAL';
    String selectedShift = shift;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: context.colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Edit Staff Profile', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: deptController,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(value: 'enterprise_admin', child: Text('Enterprise Admin')),
                  ],
                  onChanged: (val) => setModalState(() => selectedRole = val ?? 'employee'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedShift,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Assigned Work Shift',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  selectedItemBuilder: (context) {
                    return [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'General Shift • 9:00 AM – 6:00 PM',
                          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Morning Shift • 6:00 AM – 2:00 PM',
                          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Evening Shift • 2:00 PM – 10:00 PM',
                          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Night Shift • 10:00 PM – 6:00 AM',
                          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ];
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'GENERAL',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('General Shift', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('9:00 AM – 6:00 PM (Standard 9-hr window)', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'MORNING',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Morning Shift', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('6:00 AM – 2:00 PM (Early morning 8-hr window)', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'EVENING',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Evening Shift', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('2:00 PM – 10:00 PM (Afternoon/evening 8-hr window)', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'NIGHT',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Night Shift', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('10:00 PM – 6:00 AM (Graveyard 8-hr window)', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) => setModalState(() => selectedShift = val ?? 'GENERAL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setModalState(() => isSubmitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final successColor = context.status.success.color;
                      final dangerColor = context.status.danger.color;
                      try {
                        await _dbService.updateEmployeeProfile(
                          userId: empDoc.id,
                          fullName: nameController.text.trim(),
                          employeeId: idController.text.trim(),
                          department: deptController.text.trim(),
                          role: selectedRole,
                          assignedShift: selectedShift,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Employee profile updated successfully!'),
                            backgroundColor: successColor,
                          ),
                        );
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: dangerColor),
                        );
                      }
                    },
              child: isSubmitting
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/network/network_connection_service.dart';
import '../../../domain/models/leave_request.dart';
import '../../../services/audit_log_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/leave_service.dart';
import '../dialogs/admin_clearance_dialog.dart';

/// Enterprise Approvals Tab:
/// 1. Pending Employee Join Requests (Applicant Clearance)
/// 2. Punch Regularization Requests (Missed Clock-Out Approvals)
/// 3. Leave Applications (Review & Quota Verification)
class AdminApprovalsTab extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> staff;

  const AdminApprovalsTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.staff,
  });

  @override
  State<AdminApprovalsTab> createState() => _AdminApprovalsTabState();
}

class _AdminApprovalsTabState extends State<AdminApprovalsTab> {
  final DatabaseService _dbService = DatabaseService();
  final LeaveService _leaveService = LeaveService();
  String _approvalsSubTab = 'JOIN_REQUESTS'; // 'JOIN_REQUESTS', 'REGULARIZATION', 'LEAVES'

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _dbService.getEnterpriseApprovalRequests(widget.enterpriseId),
      builder: (context, regSnapshot) {
        return StreamBuilder<List<LeaveRequest>>(
          stream: _leaveService.getEnterpriseLeaveRequests(widget.enterpriseId),
          builder: (context, leaveSnapshot) {
            final pendingJoinRequests = widget.staff.where((s) {
              final data = s.data() as Map<String, dynamic>;
              return data['approvalStatus'] == 'PENDING_APPROVAL' || data['status'] == 'PENDING_APPROVAL';
            }).toList();

            final allRegs = regSnapshot.data ?? [];
            final pendingRegs = allRegs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'PENDING';
            }).toList();
            final historyRegs = allRegs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] != 'PENDING';
            }).toList();

            final allLeaves = leaveSnapshot.data ?? [];
            final pendingLeaves = allLeaves.where((l) => l.status == 'PENDING').toList();
            final historyLeaves = allLeaves.where((l) => l.status != 'PENDING').toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Segmented Sub-Tab Selector
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'JOIN_REQUESTS',
                      label: Text(
                        'Join Requests (${pendingJoinRequests.length})',
                        style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: 'REGULARIZATION',
                      label: Text(
                        'Clock-Outs (${pendingRegs.length})',
                        style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.schedule, size: 14),
                    ),
                    ButtonSegment(
                      value: 'LEAVES',
                      label: Text(
                        'Leaves (${pendingLeaves.length})',
                        style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.beach_access, size: 14),
                    ),
                  ],
                  selected: {_approvalsSubTab},
                  onSelectionChanged: (set) => setState(() => _approvalsSubTab = set.first),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_approvalsSubTab == 'JOIN_REQUESTS') ...[
                  Row(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: context.status.warning.color, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Pending Employee Join Requests (${pendingJoinRequests.length})',
                          style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (pendingJoinRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, color: context.status.success.color, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'All Staff Registrations Approved',
                              style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No pending applicants awaiting company administrator approval.',
                              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...pendingJoinRequests.map((pDoc) => _buildPendingApprovalCard(pDoc)),
                ] else if (_approvalsSubTab == 'REGULARIZATION') ...[
                  // Regularization Flow
                  Row(
                    children: [
                      Icon(Icons.pending_actions, color: context.status.warning.color, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Pending Punch Regularizations (${pendingRegs.length})',
                          style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (pendingRegs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.done_all, color: context.status.success.color, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'No pending regularization requests.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingRegs.map((doc) => _buildPendingRequestCard(doc)),

                  if (historyRegs.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Icon(Icons.history, color: context.colors.onSurfaceVariant, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Reviewed Regularizations (${historyRegs.length})',
                            style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...historyRegs.map((doc) => _buildProcessedRequestCard(doc)),
                  ],
                ] else ...[
                  // Leave Applications Flow
                  Row(
                    children: [
                      Icon(Icons.beach_access_rounded, color: context.colors.primary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Pending Leave Applications (${pendingLeaves.length})',
                          style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (pendingLeaves.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.done_all, color: context.status.success.color, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'No pending leave applications.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingLeaves.map((req) => _buildAdminLeaveCard(req)),

                  if (historyLeaves.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Icon(Icons.history, color: context.colors.onSurfaceVariant, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Reviewed Leave Applications (${historyLeaves.length})',
                            style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...historyLeaves.map((req) => _buildAdminProcessedLeaveCard(req)),
                  ],
                ],
              ],
            );
          },
        );
      },
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

  Widget _buildPendingRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['employeeName'] ?? 'Employee';
    final empId = data['employeeId'] ?? 'N/A';
    final shiftDate = (data['shiftDate'] as Timestamp?)?.toDate();
    final punchIn = (data['punchInTime'] as Timestamp?)?.toDate();
    final reqPunchOut = (data['requestedPunchOutTime'] as Timestamp?)?.toDate();
    final reason = data['reason'] ?? 'No reason provided';

    final shiftDateStr = shiftDate != null
        ? "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}"
        : 'Unknown Date';

    final punchInStr = punchIn != null
        ? "${punchIn.hour.toString().padLeft(2, '0')}:${punchIn.minute.toString().padLeft(2, '0')}"
        : '--:--';

    final punchOutStr = reqPunchOut != null
        ? "${reqPunchOut.hour.toString().padLeft(2, '0')}:${reqPunchOut.minute.toString().padLeft(2, '0')}"
        : '--:--';

    String durationStr = '';
    if (punchIn != null && reqPunchOut != null) {
      final diff = reqPunchOut.difference(punchIn);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      durationStr = '${hours}h ${minutes}m';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.status.warning.color.withValues(alpha: 0.5), width: 1.5),
      ),
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.status.warning.color.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.status.warning.color),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('ID: $empId • Shift: $shiftDateStr',
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.status.warning.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'Clock-Out',
                    style: context.textStyles.labelSmall?.copyWith(color: context.status.warning.color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Punch In:', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      Text(punchInStr, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Requested Punch Out:', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      Text(punchOutStr, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary)),
                    ],
                  ),
                  if (durationStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Duration:', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                        Text(durationStr, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.colors.secondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reason: "$reason"',
              style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(doc.id, data),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      side: BorderSide(color: context.status.danger.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleApprove(doc.id, data),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.status.success.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessedRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['employeeName'] ?? 'Employee';
    final empId = data['employeeId'] ?? 'N/A';
    final status = data['status'] ?? 'UNKNOWN';
    final isApproved = status == 'APPROVED';
    final shiftDate = (data['shiftDate'] as Timestamp?)?.toDate();
    final shiftDateStr = shiftDate != null
        ? "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}"
        : 'Unknown Date';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      color: context.colors.surface,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: isApproved
              ? context.status.success.color.withValues(alpha: 0.15)
              : context.status.danger.color.withValues(alpha: 0.15),
          child: Icon(
            isApproved ? Icons.check : Icons.close,
            size: 16,
            color: isApproved ? context.status.success.color : context.status.danger.color,
          ),
        ),
        title: Text('$name ($empId)', style: context.textStyles.titleSmall?.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$shiftDateStr • ${isApproved ? "Approved" : "Rejected"}${data['rejectionReason'] != null ? " (${data['rejectionReason']})" : ""}',
          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isApproved
                ? context.status.success.color.withValues(alpha: 0.15)
                : context.status.danger.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isApproved ? context.status.success.color : context.status.danger.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLeaveCard(LeaveRequest req) {
    final startStr = "${req.startDate.year}-${req.startDate.month.toString().padLeft(2, '0')}-${req.startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${req.endDate.year}-${req.endDate.month.toString().padLeft(2, '0')}-${req.endDate.day.toString().padLeft(2, '0')}";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardCircular,
        side: BorderSide(color: context.status.warning.color.withValues(alpha: 0.5), width: 1.5),
      ),
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.status.warning.color.withValues(alpha: 0.15),
                  child: Text(
                    req.employeeName.isNotEmpty ? req.employeeName[0].toUpperCase() : 'E',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.status.warning.color),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.employeeName, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('ID: ${req.employeeId}',
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.badgeCircular,
                  ),
                  child: Text(
                    req.leaveTypeDisplay,
                    style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dates:', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      Text('$startStr to $endStr', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration:', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      Text('${req.daysCount} Day${req.daysCount > 1 ? "s" : ""}',
                          style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary)),
                    ],
                  ),
                  if (req.reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason: ', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                        Expanded(
                          child: Text(
                            '"${req.reason}"',
                            style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: context.colors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRejectLeave(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      side: BorderSide(color: context.status.danger.color),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonCircular),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleApproveLeave(req),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.status.success.color,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonCircular),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProcessedLeaveCard(LeaveRequest req) {
    final isApproved = req.status == 'APPROVED';
    final startStr = "${req.startDate.year}-${req.startDate.month.toString().padLeft(2, '0')}-${req.startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${req.endDate.year}-${req.endDate.month.toString().padLeft(2, '0')}-${req.endDate.day.toString().padLeft(2, '0')}";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardCircular,
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      color: context.colors.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isApproved ? context.status.success.color.withValues(alpha: 0.12) : context.status.danger.color.withValues(alpha: 0.12),
          child: Icon(isApproved ? Icons.check : Icons.close, color: isApproved ? context.status.success.color : context.status.danger.color, size: 20),
        ),
        title: Text(
          '${req.employeeName} (${req.leaveTypeDisplay})',
          style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$startStr to $endStr • ${req.daysCount}d • ${req.reviewNotes ?? req.status}',
          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isApproved ? context.status.success.color.withValues(alpha: 0.1) : context.status.danger.color.withValues(alpha: 0.1),
            borderRadius: AppRadius.badgeCircular,
          ),
          child: Text(
            req.status,
            style: TextStyle(
              color: isApproved ? context.status.success.color : context.status.danger.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove(String requestId, Map<String, dynamic> requestData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        actionsOverflowButtonSpacing: 8,
        title: const Text('Approve Regularization?', overflow: TextOverflow.ellipsis),
        content: Text(
          'Are you sure you want to approve the punch-out regularization for ${requestData['employeeName']} (${requestData['employeeId']})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.status.success.color),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
      if (!hasNet || !mounted) return;
      try {
        final adminUid = AuthService().currentUser?.uid ?? 'admin';
        await _dbService.approveRegularizationRequest(
          requestId: requestId,
          requestData: requestData,
          adminUid: adminUid,
        );
        AuditLogService().logAction(
          enterpriseId: widget.enterpriseId,
          action: AuditLogService.actionRegularizationApproved,
          category: AuditLogService.categoryApprovals,
          targetEmployeeId: requestData['employeeId']?.toString(),
          targetEmployeeName: requestData['employeeName']?.toString(),
          details: 'Approved clock-out regularization for ${requestData['employeeName']} (${requestData['employeeId']}). Shift closed.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Regularization approved successfully! Shift closed.'),
              backgroundColor: context.status.success.color,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error approving request: $e'), backgroundColor: context.status.danger.color),
          );
        }
      }
    }
  }

  Future<void> _handleReject(String requestId, [Map<String, dynamic>? requestData]) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        actionsOverflowButtonSpacing: 8,
        title: Row(
          children: [
            Icon(Icons.cancel, color: context.status.danger.color),
            const SizedBox(width: AppSpacing.xs),
            const Expanded(
              child: Text(
                'Reject Request?',
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
              Text('Enter optional reason for rejecting this regularization:', style: context.textStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'e.g. Discrepancy with CCTV / supervisor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.status.danger.color,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
      if (!hasNet || !mounted) return;
      try {
        final adminUid = AuthService().currentUser?.uid ?? 'admin';
        await _dbService.rejectRegularizationRequest(
          requestId: requestId,
          adminUid: adminUid,
          reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
        );
        AuditLogService().logAction(
          enterpriseId: widget.enterpriseId,
          action: AuditLogService.actionRegularizationRejected,
          category: AuditLogService.categoryApprovals,
          targetEmployeeId: requestData?['employeeId']?.toString(),
          targetEmployeeName: requestData?['employeeName']?.toString(),
          details: 'Declined regularization for ${requestData?['employeeName'] ?? 'Employee'}. Reason: ${reasonController.text.trim()}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Regularization request rejected.'),
              backgroundColor: context.status.warning.color,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting request: $e'), backgroundColor: context.status.danger.color),
          );
        }
      }
    }
  }

  Future<void> _handleApproveLeave(LeaveRequest req) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardCircular),
        actionsOverflowButtonSpacing: 8,
        title: const Text('Approve Leave Request?', overflow: TextOverflow.ellipsis),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approve ${req.leaveTypeDisplay} for ${req.employeeName} (${req.daysCount} days)?'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Approval Note (Optional)',
                  hintText: 'e.g. Approved. Please ensure handover.',
                  border: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: ctx.colors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: ctx.colors.borderSubtle)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.status.success.color),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
      if (!hasNet || !mounted) return;

      final user = AuthService().currentUser;
      final reviewer = user?.email?.split('@').first ?? 'Admin';
      await _leaveService.approveLeave(
        request: req,
        reviewerName: reviewer,
        reviewNotes: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave for ${req.employeeName} approved!'),
            backgroundColor: context.status.success.color,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectLeave(LeaveRequest req) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardCircular),
        actionsOverflowButtonSpacing: 8,
        title: const Text('Decline Leave Request?', overflow: TextOverflow.ellipsis),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Decline ${req.leaveTypeDisplay} for ${req.employeeName}?'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Reason for Declining (Optional)',
                  hintText: 'e.g. High workload during sprint',
                  border: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: ctx.colors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: ctx.colors.borderSubtle)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.status.danger.color),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
      if (!hasNet || !mounted) return;

      final user = AuthService().currentUser;
      final reviewer = user?.email?.split('@').first ?? 'Admin';
      await _leaveService.rejectLeave(
        request: req,
        reviewerName: reviewer,
        reviewNotes: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave for ${req.employeeName} declined.'),
            backgroundColor: context.status.warning.color,
          ),
        );
      }
    }
  }
}

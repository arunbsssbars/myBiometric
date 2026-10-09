import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../domain/models/leave_request.dart';
import '../../../services/audit_log_service.dart';
import '../../../services/executive_command_center_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/offline_attendance_queue_service.dart';
import '../../../services/payroll_export_service.dart';
import '../../add_staff_screen.dart';
import '../../attendance_analytics_view.dart';
import '../../enterprise_policies_hub_screen.dart';
import '../../executive_command_center_screen.dart';
import '../../whos_in_whos_out_board.dart';

/// Enterprise Overview Tab:
/// - Real-time On-Time arrival, late arrival, overtime stats
/// - Live Who's In / Who's Out workforce board
/// - Today's Workforce Digest & Absenteeism reconciliation cards (Present, Late, Absent, On Leave)
/// - Offline Punch Queue Sync Health card
/// - Policies & Security Hub card
/// - Quick Action Grid (Add Staff, Analytics, Payroll Export, Audit Trail, Fleet Cockpit)
/// - Recent Activity feed
class AdminOverviewTab extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> staff;
  final List<QueryDocumentSnapshot> logs;
  final void Function(List<QueryDocumentSnapshot> logs, {String? employeeFilterName, String? dateRangeTitle}) onOpenPdfPreview;
  final void Function(List<QueryDocumentSnapshot> logs, List<QueryDocumentSnapshot> staff) onExportCsv;
  final Future<void> Function() onRunDailyReconciliation;
  final bool isReconciling;

  const AdminOverviewTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.staff,
    required this.logs,
    required this.onOpenPdfPreview,
    required this.onExportCsv,
    required this.onRunDailyReconciliation,
    required this.isReconciling,
  });

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final todayLogs = widget.logs.where((doc) {
      final ts = (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return ts != null && ts.toDate().isAfter(startOfToday);
    }).toList();

    final presentUserIds = <String>{};
    final lateUserIds = <String>{};
    final onTimeUserIds = <String>{};
    int punchInCount = 0;
    int punchOutCount = 0;
    int onTimeCount = 0;
    int lateCount = 0;
    int totalOvertimeMins = 0;

    for (var l in todayLogs) {
      final data = l.data() as Map<String, dynamic>;
      final uid = data['userId'] as String? ?? '';
      final type = data['type'] as String? ?? '';
      final pStatus = data['punchStatus'] as String?;
      final ot = data['overtimeMinutes'] as int? ?? 0;

      if (type == 'PUNCH_IN') {
        presentUserIds.add(uid);
        punchInCount++;
        if (pStatus == 'LATE_ARRIVAL') {
          lateCount++;
          lateUserIds.add(uid);
        } else {
          onTimeCount++;
          onTimeUserIds.add(uid);
        }
      } else if (type == 'PUNCH_OUT') {
        punchOutCount++;
      }
      totalOvertimeMins += ot;
    }

    final totalArrivals = onTimeCount + lateCount;
    final onTimeRate = totalArrivals > 0 ? (onTimeCount * 100 ~/ totalArrivals) : 100;
    final otHoursStr = (totalOvertimeMins / 60).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Enterprise ID: ${widget.enterpriseId}',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Export Timesheet (PDF)',
                    onPressed: () => widget.onOpenPdfPreview(widget.logs, dateRangeTitle: 'Enterprise Attendance MIS'),
                    icon: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filledTonal(
                    tooltip: 'Export MIS Report (CSV)',
                    onPressed: () => widget.onExportCsv(widget.logs, widget.staff),
                    icon: const Icon(Icons.file_download_outlined),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Shift Intelligence Compliance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On-Time Arrival',
                        style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$onTimeRate%',
                          style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.status.success.color),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 32, width: 1, color: context.colors.borderSubtle),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Late Arrivals',
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$lateCount',
                            style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: lateCount > 0 ? context.status.warning.color : context.colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 32, width: 1, color: context.colors.borderSubtle),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overtime Today',
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${otHoursStr}h',
                            style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.colors.tertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Workforce Board
          WhosInWhosOutBoard(
            enterpriseId: widget.enterpriseId,
          ),
          const SizedBox(height: 16),

          // Daily Attendance & Absenteeism Reconciler
          StreamBuilder<List<LeaveRequest>>(
            stream: LeaveService().getEnterpriseLeaveRequests(widget.enterpriseId),
            builder: (context, leaveSnap) {
              final leaveList = leaveSnap.data ?? [];
              final activeLeaveMap = <String, LeaveRequest>{};
              for (var l in leaveList) {
                if (l.status == 'APPROVED') {
                  final start = DateTime(l.startDate.year, l.startDate.month, l.startDate.day);
                  final end = DateTime(l.endDate.year, l.endDate.month, l.endDate.day, 23, 59, 59);
                  if (now.isAfter(start.subtract(const Duration(seconds: 1))) &&
                      now.isBefore(end.add(const Duration(seconds: 1)))) {
                    activeLeaveMap[l.userId] = l;
                  }
                }
              }

              final presentStaff = widget.staff.where((s) => presentUserIds.contains(s.id)).toList();
              final lateStaff = widget.staff.where((s) => lateUserIds.contains(s.id)).toList();
              final onLeaveStaff = widget.staff.where((s) => !presentUserIds.contains(s.id) && activeLeaveMap.containsKey(s.id)).toList();
              final absentStaff = widget.staff.where((s) => !presentUserIds.contains(s.id) && !activeLeaveMap.containsKey(s.id)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Today's Workforce Digest",
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        onPressed: widget.isReconciling ? null : widget.onRunDailyReconciliation,
                        icon: widget.isReconciling
                            ? SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                              )
                            : Icon(Icons.fact_check_outlined, size: 15, color: context.colors.primary),
                        label: Text(
                          widget.isReconciling ? 'Reconciling...' : 'Reconcile Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 4 Reconciled Status Cards (Present, Late, Absent, On Leave)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScalerOf(context).scale(1.0) > 1.2 ? 0.95 : 1.08,
                    children: [
                      _buildStatCard(
                        title: 'Present Today',
                        value: '${presentStaff.length}',
                        subtitle: 'Punched In',
                        icon: Icons.check_circle_outline,
                        color: context.status.success.color,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Present Staff (${presentStaff.length})',
                          category: 'PRESENT',
                          categoryColor: context.status.success.color,
                          staffList: presentStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: widget.staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'Late Arrivals',
                        value: '${lateStaff.length}',
                        subtitle: 'After Shift Start',
                        icon: Icons.access_time_filled,
                        color: context.status.warning.color,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Late Arrivals (${lateStaff.length})',
                          category: 'LATE',
                          categoryColor: context.status.warning.color,
                          staffList: lateStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: widget.staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'Absent / Pending',
                        value: '${absentStaff.length}',
                        subtitle: 'Not Clocked In',
                        icon: Icons.cancel_outlined,
                        color: context.status.danger.color,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Absent / Pending Staff (${absentStaff.length})',
                          category: 'ABSENT',
                          categoryColor: context.status.danger.color,
                          staffList: absentStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: widget.staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'On Approved Leave',
                        value: '${onLeaveStaff.length}',
                        subtitle: 'Time-Off Active',
                        icon: Icons.beach_access,
                        color: context.colors.primary,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Staff On Leave (${onLeaveStaff.length})',
                          category: 'ON_LEAVE',
                          categoryColor: context.colors.primary,
                          staffList: onLeaveStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: widget.staff,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Offline Punch Queue Sync Health Card
          _buildSyncHealthCard(),

          const SizedBox(height: AppSpacing.sm),

          // Punch volume row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, color: context.status.success.color, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clock-In Events', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                            Text('$punchInCount punches', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_alt, color: context.colors.secondary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Punches', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                            Text('${punchInCount + punchOutCount} events', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Enterprise Policies & Security Hub Card
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnterprisePoliciesHubScreen(
                        enterpriseId: widget.enterpriseId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.admin_panel_settings_rounded, color: context.colors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enterprise Policies & Security Hub',
                              style: context.textStyles.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Geofencing, Wi-Fi Verification, Shifts & PIN Security',
                              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: context.colors.borderSubtle),
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Executive Quick Actions Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScalerOf(context).scale(1.0) > 1.2 ? 1.75 : 2.2,
            children: [
              _buildQuickActionCard(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: context.colors.primary,
                bgColor: context.colors.primary.withValues(alpha: 0.1),
                title: 'Add Staff',
                subtitle: 'Onboard employee',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddStaffScreen(
                        enterpriseId: widget.enterpriseId,
                        companyName: widget.companyName,
                      ),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.bar_chart_rounded,
                iconColor: context.colors.secondary,
                bgColor: context.colors.secondary.withValues(alpha: 0.1),
                title: 'Analytics',
                subtitle: 'Visual MIS graphs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceAnalyticsView(
                        enterpriseId: widget.enterpriseId,
                        companyName: widget.companyName,
                        logs: widget.logs,
                        staff: widget.staff,
                      ),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.table_chart_rounded,
                iconColor: context.status.success.color,
                bgColor: context.status.success.color.withValues(alpha: 0.1),
                title: 'Payroll Export',
                subtitle: 'CSV & hours MIS',
                onTap: () {
                  PayrollExportService.showExportDialog(
                    context,
                    logs: widget.logs,
                    staff: widget.staff,
                    periodTitle: widget.companyName.isNotEmpty ? widget.companyName : widget.enterpriseId,
                    enterpriseId: widget.enterpriseId,
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.security_rounded,
                iconColor: context.colors.tertiary,
                bgColor: context.colors.tertiary.withValues(alpha: 0.1),
                title: 'Audit Trail',
                subtitle: 'Compliance logs',
                onTap: _showAuditTrailSheet,
              ),
              _buildQuickActionCard(
                icon: Icons.speed_rounded,
                iconColor: Colors.deepPurple,
                bgColor: Colors.deepPurple.withValues(alpha: 0.1),
                title: 'Fleet Cockpit',
                subtitle: 'Real-time KPIs',
                onTap: () {
                  final metrics = ExecutiveCommandCenterService().synthesizeMetrics(
                    enterpriseId: widget.enterpriseId,
                    totalTerminals: 10,
                    onlineTerminals: 10,
                    totalEmployees: widget.staff.length,
                    onSiteEmployees: todayLogs.where((l) => (l.data() as Map<String, dynamic>?)?['type'] == 'PUNCH_IN').length,
                    punchesLastHour: todayLogs.length,
                    pendingRegularizations: 0,
                    tamperAlerts: 0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExecutiveCommandCenterScreen(
                        metrics: metrics,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            "Recent Enterprise Activity",
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (todayLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Text(
                'No attendance punches recorded yet today.',
                style: context.textStyles.bodyMedium?.copyWith(color: context.colors.textSecondary),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayLogs.take(5).length,
              itemBuilder: (context, index) {
                final doc = todayLogs[index];
                return _buildRecentLogTile(doc, widget.staff);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: card,
      );
    }
    return card;
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncHealthCard() {
    final queue = OfflineAttendanceQueueService();
    return ValueListenableBuilder<int>(
      valueListenable: queue.pendingCountNotifier,
      builder: (context, pendingCount, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: queue.lastSyncTimeNotifier,
          builder: (context, lastSyncTime, _) {
            final isSynced = pendingCount == 0;
            final syncTimeStr = lastSyncTime != null
                ? '${lastSyncTime.hour.toString().padLeft(2, '0')}:${lastSyncTime.minute.toString().padLeft(2, '0')}:${lastSyncTime.second.toString().padLeft(2, '0')}'
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSynced ? context.status.success.color.withValues(alpha: 0.08) : context.status.warning.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSynced ? context.status.success.color.withValues(alpha: 0.3) : context.status.warning.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                    color: isSynced ? context.status.success.color : context.status.warning.color,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSynced ? 'Offline Punch Queue Synced' : '$pendingCount Offline Punches Queued',
                          style: context.textStyles.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSynced ? context.status.success.color : context.status.warning.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          syncTimeStr != null ? 'Last sync: $syncTimeStr' : 'Auto-sync active (25s interval)',
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text('Sync Now', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final synced = await queue.syncPendingPunches();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(synced > 0 ? '$synced offline punches synced to cloud!' : 'Queue is empty. Everything up to date.'),
                            backgroundColor: context.status.success.color,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentLogTile(QueryDocumentSnapshot doc, List<QueryDocumentSnapshot> staff) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = data['userId'] as String? ?? '';
    final type = data['type'] as String? ?? 'PUNCH_IN';
    final ts = (data['timestamp'] as Timestamp?)?.toDate();
    final confidence = data['confidenceScore'] as num?;

    String name = 'Staff Member';
    String empId = '';
    for (var s in staff) {
      if (s.id == uid) {
        final sData = s.data() as Map<String, dynamic>;
        name = sData['fullName'] ?? sData['name'] ?? 'Staff Member';
        empId = sData['employeeId'] ?? '';
        break;
      }
    }

    final isPunchIn = type == 'PUNCH_IN';
    final timeStr = ts != null
        ? "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}"
        : "Just now";

    final verifiedVia = data['verifiedVia'] as String? ?? 'FACE_ID';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isPunchIn
                ? context.status.success.color.withValues(alpha: 0.12)
                : context.status.warning.color.withValues(alpha: 0.12),
            child: Icon(
              isPunchIn ? Icons.login_rounded : Icons.logout_rounded,
              color: isPunchIn ? context.status.success.color : context.status.warning.color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text('ID: $empId • $timeStr • $verifiedVia${confidence != null ? " (${(confidence * 100).toInt()}%)" : ""}',
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPunchIn ? context.status.success.color.withValues(alpha: 0.12) : context.status.warning.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              isPunchIn ? 'IN' : 'OUT',
              style: context.textStyles.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPunchIn ? context.status.success.color : context.status.warning.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceBreakdownSheet({
    required String title,
    required String category,
    required Color categoryColor,
    required List<QueryDocumentSnapshot> staffList,
    required List<QueryDocumentSnapshot> todayLogs,
    required Map<String, LeaveRequest> activeLeaveMap,
    required List<QueryDocumentSnapshot> allStaff,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filtered = staffList.where((s) {
              final d = s.data() as Map<String, dynamic>;
              final name = (d['fullName'] ?? d['name'] ?? '').toString().toLowerCase();
              final empId = (d['employeeId'] ?? '').toString().toLowerCase();
              final q = searchQuery.toLowerCase().trim();
              return q.isEmpty || name.contains(q) || empId.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.colors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              title,
                              style: context.textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(Icons.close, size: 20, color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    child: TextField(
                      onChanged: (val) => setSheetState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search staff by name or ID...',
                        prefixIcon: Icon(Icons.search, size: 18, color: context.colors.onSurfaceVariant),
                        isDense: true,
                        filled: true,
                        fillColor: context.colors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: context.colors.borderSubtle),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: context.colors.borderSubtle),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 40, color: context.colors.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No staff in this category.'
                                      : 'No staff matching "$searchQuery"',
                                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.borderSubtle),
                            itemBuilder: (context, idx) {
                              final staffDoc = filtered[idx];
                              final data = staffDoc.data() as Map<String, dynamic>;
                              final name = data['fullName'] ?? data['name'] ?? 'Staff Member';
                              final empId = data['employeeId'] ?? 'N/A';
                              final role = data['role'] ?? 'Employee';
                              final shift = data['assignedShift'] ?? 'General';

                              final userLogs = todayLogs.where((l) {
                                final d = l.data() as Map<String, dynamic>;
                                return d['userId'] == staffDoc.id;
                              }).toList();

                              userLogs.sort((a, b) {
                                final tA = ((a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                                final tB = ((b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
                                return tB.compareTo(tA);
                              });

                              final latestLog = userLogs.firstOrNull?.data() as Map<String, dynamic>?;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: categoryColor.withValues(alpha: 0.12),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: categoryColor),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: $empId • $role • Shift: $shift',
                                            style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    if (category == 'ON_LEAVE') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.colors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(AppRadius.xs),
                                        ),
                                        child: Text(
                                          activeLeaveMap[staffDoc.id]?.leaveTypeDisplay ?? 'ON LEAVE',
                                          style: context.textStyles.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      if (latestLog != null) ...[
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              (latestLog['timestamp'] as Timestamp?) != null
                                                  ? '${(latestLog['timestamp'] as Timestamp).toDate().hour.toString().padLeft(2, '0')}:${(latestLog['timestamp'] as Timestamp).toDate().minute.toString().padLeft(2, '0')}'
                                                  : 'Clocked In',
                                              style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: categoryColor),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              latestLog['verifiedVia'] ?? 'FACE_ID',
                                              style: context.textStyles.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAuditTrailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selectedCategory = 'ALL';

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            Color getCategoryColor(String cat) {
              switch (cat) {
                case 'SECURITY':
                  return sheetCtx.status.danger.color;
                case 'POLICY':
                  return sheetCtx.colors.primary;
                case 'ATTENDANCE':
                  return sheetCtx.colors.tertiary;
                case 'APPROVALS':
                  return sheetCtx.status.success.color;
                case 'STAFF':
                  return sheetCtx.colors.primary;
                default:
                  return sheetCtx.colors.textSecondary;
              }
            }

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.85,
              decoration: BoxDecoration(
                color: sheetCtx.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sheetCtx.colors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security_update_good_outlined, color: sheetCtx.colors.primary, size: 22),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Compliance Audit Trail',
                                  style: sheetCtx.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: sheetCtx.colors.textPrimary),
                                ),
                                Text(
                                  'Immutable log of administrative events',
                                  style: sheetCtx.textStyles.bodySmall?.copyWith(color: sheetCtx.colors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: sheetCtx.colors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: ['ALL', 'SECURITY', 'POLICY', 'ATTENDANCE', 'APPROVALS', 'STAFF'].map((cat) {
                        final isSel = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: sheetCtx.textStyles.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSel ? sheetCtx.colors.onPrimary : sheetCtx.colors.textSecondary,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: sheetCtx.colors.primary,
                            backgroundColor: sheetCtx.colors.surface,
                            checkmarkColor: sheetCtx.colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSel ? sheetCtx.colors.primary : sheetCtx.colors.borderSubtle),
                            ),
                            onSelected: (_) => setSheetState(() => selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(height: 1, color: sheetCtx.colors.borderSubtle),
                  Expanded(
                    child: StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: AuditLogService().streamAuditLogs(widget.enterpriseId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allDocs = snapshot.data ?? [];
                        final filteredDocs = selectedCategory == 'ALL'
                            ? allDocs
                            : allDocs.where((d) => (d.data() as Map<String, dynamic>)['category'] == selectedCategory).toList();

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 48, color: sheetCtx.colors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No audit records found.',
                                  style: sheetCtx.textStyles.bodyMedium?.copyWith(color: sheetCtx.colors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${filteredDocs.length} Event${filteredDocs.length == 1 ? '' : 's'}',
                                    style: sheetCtx.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: sheetCtx.colors.textSecondary),
                                  ),
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 14),
                                    label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      final rawLogs = filteredDocs.map((d) => d.data() as Map<String, dynamic>).toList();
                                      final csv = AuditLogService.generateAuditCsv(rawLogs);
                                      Clipboard.setData(ClipboardData(text: csv));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Audit log CSV copied to clipboard! Ready to paste/export.'),
                                          backgroundColor: sheetCtx.status.success.color,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                itemCount: filteredDocs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                                  final action = data['action']?.toString() ?? 'ACTION';
                                  final category = data['category']?.toString() ?? 'SYSTEM';
                                  final details = data['details']?.toString() ?? '';
                                  final adminEmail = data['adminEmail']?.toString() ?? 'Admin';
                                  final targetName = data['targetEmployeeName']?.toString();
                                  final targetId = data['targetEmployeeId']?.toString();
                                  final ts = (data['timestamp'] as Timestamp?)?.toDate();
                                  final timeStr = ts != null
                                      ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                      : 'Recent';

                                  final catColor = getCategoryColor(category);

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: sheetCtx.colors.surface,
                                      borderRadius: AppRadius.cardCircular,
                                      border: Border.all(color: sheetCtx.colors.borderSubtle),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(alpha: 0.1),
                                                borderRadius: AppRadius.badgeCircular,
                                              ),
                                              child: Text(
                                                action.replaceAll('_', ' '),
                                                style: TextStyle(
                                                  color: catColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              timeStr,
                                              style: sheetCtx.textStyles.bodySmall?.copyWith(color: sheetCtx.colors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          details,
                                          style: sheetCtx.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: sheetCtx.colors.textPrimary),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 13, color: sheetCtx.colors.textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'By: $adminEmail${targetName != null ? ' • Target: $targetName ($targetId)' : ''}',
                                                style: sheetCtx.textStyles.bodySmall?.copyWith(color: sheetCtx.colors.textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../main.dart' show performGlobalSignOut;
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/absenteeism_reconciliation_service.dart';
import '../services/audit_log_service.dart';
import '../services/offline_attendance_queue_service.dart';
import 'admin/tabs/admin_approvals_tab.dart';
import 'admin/tabs/admin_attendance_logs_tab.dart';
import 'admin/tabs/admin_overview_tab.dart';
import 'admin/tabs/admin_workforce_tab.dart';
import 'add_staff_screen.dart';
import 'bulk_roster_import_screen.dart';
import 'notification_center_sheet.dart';
import 'pdf_timesheet_preview_screen.dart';
import 'profile_settings_screen.dart';
import '../presentation/widgets/universal_command_palette.dart';

/// Enterprise Admin & MIS Command Shell.
///
/// Architected with feature-first Clean Modular Presentation:
/// 1. [AdminOverviewTab] - Real-time metrics, presence board, and quick actions
/// 2. [AdminWorkforceTab] - Roster management, applicant clearances, and channels
/// 3. [AdminAttendanceLogsTab] - Punch log audit, manual entries, and CSV/PDF
/// 4. [AdminApprovalsTab] - Multi-tier approvals (Join requests, Regularizations, Leaves)
///
/// Compliant with AQIL v2 responsive guidelines (320px - 1280px).
class EnterpriseAdminDashboardScreen extends StatefulWidget {
  final String enterpriseId;

  const EnterpriseAdminDashboardScreen({super.key, required this.enterpriseId});

  @override
  State<EnterpriseAdminDashboardScreen> createState() =>
      _EnterpriseAdminDashboardScreenState();
}

class _EnterpriseAdminDashboardScreenState
    extends State<EnterpriseAdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  String _companyName = '';
  String _tenantAdminEmail = '';
  bool _isReconciling = false;

  bool get _isSuperAdminUser {
    final email = AuthService().currentUser?.email?.toLowerCase().trim() ?? '';
    return email == 'arunbsssbars@gmail.com';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchEnterpriseName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEnterpriseName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('enterprises').doc(widget.enterpriseId).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _companyName = data['name'] ?? data['companyName'] ?? widget.enterpriseId;
          _tenantAdminEmail = data['adminEmail'] ?? data['contactEmail'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _runDailyReconciliation() async {
    if (_isReconciling) return;
    setState(() => _isReconciling = true);

    try {
      final report = await AbsenteeismReconciliationService().runReconciliation(
        enterpriseId: widget.enterpriseId,
        notifyAdmin: true,
      );

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: AuditLogService.actionDailyReconciliationRun,
        category: AuditLogService.categoryAttendance,
        details: 'Workforce attendance reconciled: ${report.summaryText}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: context.colors.onPrimary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Reconciled: ${report.summaryText}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: context.status.success.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconciliation failed: $e'),
          backgroundColor: context.status.danger.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReconciling = false);
      }
    }
  }

  void _openPdfPreview(
    List<QueryDocumentSnapshot> logs, {
    String? employeeFilterName,
    String? dateRangeTitle,
  }) {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No attendance records available to export for this selection.'),
          backgroundColor: context.status.warning.color,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfTimesheetPreviewScreen(
          enterpriseId: widget.enterpriseId,
          companyName: _companyName.isNotEmpty ? _companyName : widget.enterpriseId,
          logs: logs,
          employeeFilterName: employeeFilterName,
          dateRangeTitle: dateRangeTitle,
        ),
      ),
    );
  }

  void _exportCsv(List<QueryDocumentSnapshot> logs, List<QueryDocumentSnapshot> users) {
    final Map<String, String> userNames = {};
    final Map<String, String> userEmpIds = {};
    for (var u in users) {
      final data = u.data() as Map<String, dynamic>;
      userNames[u.id] = data['fullName'] ?? data['name'] ?? 'Unknown';
      userEmpIds[u.id] = data['employeeId'] ?? 'N/A';
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln("Log ID,User ID,Employee ID,Full Name,Punch Type,Timestamp,Verified Via,Confidence Score,Punch Status,Late (mins),Overtime (mins),Shift Duration (mins),Work Status");

    for (var doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['userId'] ?? '';
      final name = userNames[uid] ?? 'Unknown';
      final empId = userEmpIds[uid] ?? 'N/A';
      final type = data['type'] ?? '';
      final ts = (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? '';
      final via = data['verifiedVia'] ?? 'FACE_ID';
      final score = data['confidenceScore'] != null
          ? "${(data['confidenceScore'] * 100).toStringAsFixed(1)}%"
          : 'N/A';
      final pStatus = data['punchStatus'] ?? 'N/A';
      final lateM = data['lateMinutes']?.toString() ?? '0';
      final otM = data['overtimeMinutes']?.toString() ?? '0';
      final durM = data['shiftDurationMinutes']?.toString() ?? 'N/A';
      final wStatus = data['workStatus'] ?? 'N/A';

      csv.writeln('"${doc.id}","$uid","$empId","$name","$type","$ts","$via","$score","$pStatus","$lateM","$otM","$durM","$wStatus"');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(Icons.download_done, color: ctx.status.success.color),
            const SizedBox(width: AppSpacing.xs),
            const Text('MIS Report Export'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated CSV report containing ${logs.length} attendance records.', style: ctx.textStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: ctx.colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: ctx.colors.borderSubtle),
              ),
              child: Text(
                'Columns: Log ID, User ID, Employee ID, Full Name, Punch Type, Timestamp, Verified Via, Confidence Score.',
                style: ctx.textStyles.bodySmall?.copyWith(color: ctx.colors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('MIS CSV Report exported successfully!'),
                  backgroundColor: context.status.success.color,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  List<AppCommand> _getAdminCommands() {
    return [
      AppCommand(
        id: 'nav_overview',
        title: 'Switch to Overview Tab',
        subtitle: 'View real-time Who is In and attendance stats',
        category: 'Navigation',
        icon: Icons.dashboard_outlined,
        keywords: ['overview', 'dashboard', 'summary'],
        shortcutLabel: 'Tab 1',
        onExecute: () {
          if (mounted) _tabController.animateTo(0);
        },
      ),
      AppCommand(
        id: 'nav_workforce',
        title: 'Switch to Staff Roster Tab',
        subtitle: 'Manage workforce profiles and credentials',
        category: 'Navigation',
        icon: Icons.people_alt_outlined,
        keywords: ['staff', 'roster', 'employees', 'members'],
        shortcutLabel: 'Tab 2',
        onExecute: () {
          if (mounted) _tabController.animateTo(1);
        },
      ),
      AppCommand(
        id: 'nav_attendance_logs',
        title: 'Switch to Attendance Logs Tab',
        subtitle: 'Audit punch records and manual entries',
        category: 'Navigation',
        icon: Icons.history_rounded,
        keywords: ['punches', 'logs', 'history', 'records'],
        shortcutLabel: 'Tab 3',
        onExecute: () {
          if (mounted) _tabController.animateTo(2);
        },
      ),
      AppCommand(
        id: 'nav_approvals',
        title: 'Switch to Approvals Tab',
        subtitle: 'Review join requests, regularizations & leaves',
        category: 'Navigation',
        icon: Icons.fact_check_outlined,
        keywords: ['approvals', 'join', 'leaves', 'regularization'],
        shortcutLabel: 'Tab 4',
        onExecute: () {
          if (mounted) _tabController.animateTo(3);
        },
      ),
      AppCommand(
        id: 'action_add_staff',
        title: 'Add New Employee',
        subtitle: 'Onboard a new workforce member',
        category: 'Actions',
        icon: Icons.person_add_rounded,
        keywords: ['add employee', 'new staff', 'register'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddStaffScreen(enterpriseId: widget.enterpriseId, companyName: _companyName),
            ),
          );
        },
      ),
      AppCommand(
        id: 'action_bulk_import',
        title: 'Bulk Import Roster',
        subtitle: 'Upload CSV spreadsheet to import employees',
        category: 'Actions',
        icon: Icons.upload_file_rounded,
        keywords: ['bulk', 'import', 'csv', 'batch'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BulkRosterImportScreen(enterpriseId: widget.enterpriseId),
            ),
          );
        },
      ),
      AppCommand(
        id: 'action_profile_settings',
        title: 'Admin Profile Settings',
        subtitle: 'Manage administrative preferences',
        category: 'Settings',
        icon: Icons.manage_accounts_outlined,
        keywords: ['profile', 'account', 'company'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSettingsScreen(enterpriseId: widget.enterpriseId),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildSuperAdminInspectionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Super Admin Inspection Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Platform Oversight',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Inspecting tenant ${_companyName.isNotEmpty ? _companyName : widget.enterpriseId} (${widget.enterpriseId}). Local tenant admin: ${_tenantAdminEmail.isNotEmpty ? _tenantAdminEmail : "Not assigned"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarSyncIcon() {
    final queue = OfflineAttendanceQueueService();
    return ValueListenableBuilder<int>(
      valueListenable: queue.pendingCountNotifier,
      builder: (context, pendingCount, _) {
        final isSynced = pendingCount == 0;
        return IconButton(
          tooltip: isSynced ? 'Queue Synced' : '$pendingCount Offline Punches Queued',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                color: isSynced ? context.status.success.color : context.status.warning.color,
                size: 22,
              ),
              if (!isSynced)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.status.warning.color,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: context.colors.onPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommandPaletteHotKey(
      commandBuilder: _getAdminCommands,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Enterprise Admin & MIS',
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
          elevation: 0,
          actions: [
            UniversalCommandPalette.buildAppBarButton(
              context,
              commandBuilder: _getAdminCommands,
              iconColor: context.colors.textPrimary,
            ),
            _buildAppBarSyncIcon(),
            if (AuthService().currentUser != null)
              NotificationBadgeButton(
                userId: AuthService().currentUser!.uid,
                enterpriseId: widget.enterpriseId,
                isAdmin: true,
              ),
            PopupMenuButton<String>(
              tooltip: 'Admin Menu',
              icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary),
              onSelected: (val) async {
                if (val == 'toggle_theme') {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  AppThemeNotifier.instance.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                } else if (val == 'command_palette') {
                  UniversalCommandPalette.show(context, commands: _getAdminCommands());
                } else if (val == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSettingsScreen(enterpriseId: widget.enterpriseId),
                    ),
                  );
                } else if (val == 'logout') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      title: const Text('Sign Out of Admin?'),
                      content: const Text('Are you sure you want to end your administrative session?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: context.status.danger.color),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await performGlobalSignOut(context);
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle_theme',
                  child: Row(
                    children: [
                      Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: ctx.colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(Theme.of(context).brightness == Brightness.dark
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'command_palette',
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: ctx.colors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Command Palette')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: ctx.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Ctrl+K', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: ctx.colors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('Admin Profile & Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: ctx.status.danger.color, size: 20),
                      const SizedBox(width: 10),
                      Text('Sign Out Admin', style: TextStyle(color: ctx.status.danger.color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Staff Roster'),
              Tab(icon: Icon(Icons.history_outlined), text: 'Attendance Logs'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Approvals'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getEnterpriseEmployees(enterpriseId: widget.enterpriseId),
              builder: (context, staffSnapshot) {
                final staffDocs = staffSnapshot.data?.docs ?? [];

                return StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: _dbService.getEnterpriseAttendanceLogs(widget.enterpriseId),
                  builder: (context, logsSnapshot) {
                    final logs = logsSnapshot.data ?? [];

                    return Column(
                      children: [
                        if (_isSuperAdminUser) _buildSuperAdminInspectionBanner(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            children: [
                              AdminOverviewTab(
                                enterpriseId: widget.enterpriseId,
                                companyName: _companyName,
                                staff: staffDocs,
                                logs: logs,
                                onOpenPdfPreview: _openPdfPreview,
                                onExportCsv: _exportCsv,
                                onRunDailyReconciliation: _runDailyReconciliation,
                                isReconciling: _isReconciling,
                              ),
                              AdminWorkforceTab(
                                enterpriseId: widget.enterpriseId,
                                companyName: _companyName,
                                staff: staffDocs,
                                logs: logs,
                                onOpenPdfPreview: _openPdfPreview,
                              ),
                              AdminAttendanceLogsTab(
                                enterpriseId: widget.enterpriseId,
                                companyName: _companyName,
                                staff: staffDocs,
                                logs: logs,
                                onOpenPdfPreview: _openPdfPreview,
                              ),
                              AdminApprovalsTab(
                                enterpriseId: widget.enterpriseId,
                                companyName: _companyName,
                                staff: staffDocs,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

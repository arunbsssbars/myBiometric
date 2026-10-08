import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/leave_request.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';
import '../services/payroll_export_service.dart';
import '../services/absenteeism_reconciliation_service.dart';
import '../services/audit_log_service.dart';
import 'notification_center_sheet.dart';
import 'pdf_timesheet_preview_screen.dart';
import 'attendance_analytics_view.dart';
import 'face_enrollment_screen.dart';
import 'profile_settings_screen.dart';
import '../services/offline_attendance_queue_service.dart';
import '../core/network/network_connection_service.dart';
import 'whos_in_whos_out_board.dart';
import 'add_staff_screen.dart';
import 'bulk_roster_import_screen.dart';
import 'enterprise_policies_hub_screen.dart';
import 'executive_command_center_screen.dart';
import '../services/executive_command_center_service.dart';
import '../presentation/widgets/universal_command_palette.dart';
import '../main.dart';

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
  final LeaveService _leaveService = LeaveService();

  String _filterPunchType = 'ALL'; // 'ALL', 'PUNCH_IN', 'PUNCH_OUT'
  String _dateFilter = 'TODAY'; // 'TODAY', 'ALL'
  String _companyName = '';
  String _tenantAdminEmail = '';
  String _staffSearchQuery = '';
  String _staffFilterStatus = 'ALL'; // 'ALL', 'ENROLLED', 'PENDING'
  String _approvalsSubTab = 'REGULARIZATION'; // 'REGULARIZATION' or 'LEAVES'

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

  bool _isReconciling = false;

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          ? (data['confidenceScore'] * 100).toStringAsFixed(1) + "%"
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
        id: 'nav_live_roster',
        title: 'Switch to Live Roster Tab',
        subtitle: 'View real-time Who is In and Who is Out',
        category: 'Navigation',
        icon: Icons.group_outlined,
        keywords: ['staff', 'roster', 'presence', 'who is in', 'employees'],
        shortcutLabel: 'Tab 1',
        onExecute: () {
          if (mounted) _tabController.animateTo(0);
        },
      ),
      AppCommand(
        id: 'nav_attendance_logs',
        title: 'Switch to Attendance Logs Tab',
        subtitle: 'View detailed punch events, timestamps and scores',
        category: 'Navigation',
        icon: Icons.history_rounded,
        keywords: ['punches', 'logs', 'history', 'time', 'records'],
        shortcutLabel: 'Tab 2',
        onExecute: () {
          if (mounted) _tabController.animateTo(1);
        },
      ),
      AppCommand(
        id: 'nav_leave_approvals',
        title: 'Switch to Leave Approvals Tab',
        subtitle: 'Review pending vacation, sick and emergency leaves',
        category: 'Navigation',
        icon: Icons.event_available_outlined,
        keywords: ['leaves', 'vacation', 'sick', 'approvals', 'time off'],
        shortcutLabel: 'Tab 3',
        onExecute: () {
          if (mounted) _tabController.animateTo(2);
        },
      ),
      AppCommand(
        id: 'nav_analytics',
        title: 'Switch to Analytics & Heatmap Tab',
        subtitle: 'View punch trends, punctuality and overtime curves',
        category: 'Navigation',
        icon: Icons.analytics_outlined,
        keywords: ['analytics', 'metrics', 'trends', 'charts', 'heatmap'],
        shortcutLabel: 'Tab 4',
        onExecute: () {
          if (mounted) _tabController.animateTo(3);
        },
      ),
      AppCommand(
        id: 'nav_policies',
        title: 'Switch to Policies & Settings Tab',
        subtitle: 'Configure geofences, Wi-Fi networks and shift schedules',
        category: 'Navigation',
        icon: Icons.tune_rounded,
        keywords: ['policies', 'settings', 'geofence', 'wifi', 'shifts', 'pin'],
        shortcutLabel: 'Tab 5',
        onExecute: () {
          if (mounted) _tabController.animateTo(4);
        },
      ),
      AppCommand(
        id: 'action_add_staff',
        title: 'Add New Employee',
        subtitle: 'Onboard a new workforce member to this enterprise',
        category: 'Actions',
        icon: Icons.person_add_rounded,
        keywords: ['add employee', 'new staff', 'register', 'onboard'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddStaffScreen(enterpriseId: widget.enterpriseId),
            ),
          );
        },
      ),
      AppCommand(
        id: 'action_bulk_import',
        title: 'Bulk Import Roster (CSV / Excel)',
        subtitle: 'Upload CSV spreadsheet to import multiple employees at once',
        category: 'Actions',
        icon: Icons.upload_file_rounded,
        keywords: ['bulk', 'import', 'csv', 'excel', 'upload', 'batch'],
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
        id: 'action_export_mis',
        title: 'Export MIS Attendance Report',
        subtitle: 'Generate and download detailed attendance CSV export',
        category: 'Reports',
        icon: Icons.file_download_outlined,
        keywords: ['export', 'download', 'csv', 'report', 'mis', 'timesheet'],
        onExecute: () {
          _tabController.animateTo(2);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Switched to Attendance Logs. Tap Export CSV to download the report.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      AppCommand(
        id: 'action_audit_trail',
        title: 'View Immutable Audit Trail',
        subtitle: 'Inspect cryptographic enterprise audit log stream',
        category: 'Security',
        icon: Icons.security_rounded,
        keywords: ['audit', 'security', 'logs', 'immutable', 'trail'],
        onExecute: () {
          _showAuditTrailSheet();
        },
      ),
      AppCommand(
        id: 'action_profile_settings',
        title: 'Open Profile & Company Settings',
        subtitle: 'Manage administrative credentials and preferences',
        category: 'Settings',
        icon: Icons.manage_accounts_outlined,
        keywords: ['profile', 'account', 'password', 'company'],
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
            // Universal Command Palette trigger button (Mobile touch and Desktop click)
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
                } else if (val == 'audit') {
                  _showAuditTrailSheet();
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
                if (confirm == true) {
                  await performGlobalSignOut();
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
              PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    Icon(Icons.security_outlined, color: ctx.status.success.color, size: 20),
                    const SizedBox(width: 10),
                    const Text('Audit Trail Logs'),
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
                            _buildOverviewTab(staffDocs, logs),
                            _buildStaffRosterTab(staffDocs, logs),
                            _buildAttendanceLogsTab(staffDocs, logs),
                            _buildApprovalsTab(staffDocs),
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

  Widget _buildSuperAdminInspectionBanner() {
    final currentEmail = AuthService().currentUser?.email ?? 'Super Admin';
    final tenantAdmin = _tenantAdminEmail.isNotEmpty ? _tenantAdminEmail : 'Local Tenant Administrator';

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
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                    children: [
                      const TextSpan(text: 'You are signed in as Platform Super Admin ('),
                      TextSpan(
                        text: currentEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '). This workspace belongs to '),
                      TextSpan(
                        text: _companyName.isNotEmpty ? _companyName : widget.enterpriseId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ', whose local admin is '),
                      TextSpan(
                        text: tenantAdmin,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '. Profile and session details reflect your active Super Admin credentials.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    List<QueryDocumentSnapshot> staff,
    List<QueryDocumentSnapshot> logs,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final todayLogs = logs.where((doc) {
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

    final enrolledStaffCount = staff.where((s) {
      final data = s.data() as Map<String, dynamic>;
      return data['biometricsEnrolled'] == true;
    }).length;

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
                    onPressed: () => _openPdfPreview(logs, dateRangeTitle: 'Enterprise Attendance MIS'),
                    icon: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filledTonal(
                    tooltip: 'Export MIS Report (CSV)',
                    onPressed: () => _exportCsv(logs, staff),
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

          // Jibble Signature Live Workforce Board
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

              final presentStaff = staff.where((s) => presentUserIds.contains(s.id)).toList();
              final lateStaff = staff.where((s) => lateUserIds.contains(s.id)).toList();
              final onLeaveStaff = staff.where((s) => !presentUserIds.contains(s.id) && activeLeaveMap.containsKey(s.id)).toList();
              final absentStaff = staff.where((s) => !presentUserIds.contains(s.id) && !activeLeaveMap.containsKey(s.id)).toList();

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
                        onPressed: _isReconciling ? null : _runDailyReconciliation,
                        icon: _isReconciling
                            ? SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                              )
                            : Icon(Icons.fact_check_outlined, size: 15, color: context.colors.primary),
                        label: Text(
                          _isReconciling ? 'Reconciling...' : 'Reconcile Now',
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
                        subtitle: staff.isNotEmpty
                            ? '${((presentStaff.length / staff.length) * 100).toInt()}% Clocked In'
                            : '0% Clocked In',
                        icon: Icons.check_circle_outline,
                        color: context.status.success.color,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Present Staff (${presentStaff.length})',
                          category: 'PRESENT',
                          categoryColor: context.status.success.color,
                          staffList: presentStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'Late Arrivals',
                        value: '${lateStaff.length}',
                        subtitle: 'After Grace Period',
                        icon: Icons.alarm_outlined,
                        color: lateStaff.isNotEmpty ? context.status.warning.color : context.colors.textSecondary,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Late Arrivals (${lateStaff.length})',
                          category: 'LATE',
                          categoryColor: context.status.warning.color,
                          staffList: lateStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'Absent / Unclocked',
                        value: '${absentStaff.length}',
                        subtitle: 'Not Clocked In Today',
                        icon: Icons.cancel_outlined,
                        color: absentStaff.isNotEmpty ? context.status.danger.color : context.status.success.color,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Absent / Unclocked (${absentStaff.length})',
                          category: 'ABSENT',
                          categoryColor: context.status.danger.color,
                          staffList: absentStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: staff,
                        ),
                      ),
                      _buildStatCard(
                        title: 'On Approved Leave',
                        value: '${onLeaveStaff.length}',
                        subtitle: 'Scheduled Time-Off',
                        icon: Icons.event_available_outlined,
                        color: context.colors.tertiary,
                        onTap: () => _showAttendanceBreakdownSheet(
                          title: 'Staff On Leave (${onLeaveStaff.length})',
                          category: 'ON_LEAVE',
                          categoryColor: context.colors.tertiary,
                          staffList: onLeaveStaff,
                          todayLogs: todayLogs,
                          activeLeaveMap: activeLeaveMap,
                          allStaff: staff,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Secondary Activity Metrics (Punches & Biometrics)
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
                      Icon(Icons.fingerprint, color: context.colors.primary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Biometrics Active', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary)),
                            Text('$enrolledStaffCount / ${staff.length}', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
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
                              style: context.textStyles.bodySmall?.copyWith( color: context.colors.textSecondary),
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
                        companyName: _companyName,
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
                        companyName: _companyName,
                        logs: logs,
                        staff: staff,
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
                    logs: logs,
                    staff: staff,
                    periodTitle: _companyName.isNotEmpty ? _companyName : widget.enterpriseId,
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
                    totalEmployees: staff.length,
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
                return _buildLogListTile(doc, staff);
              },
            ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.labelLarge?.copyWith(
                        
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: context.textStyles.bodySmall?.copyWith(
                        
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
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

  Widget _buildAppBarSyncIcon() {
    final queue = OfflineAttendanceQueueService();
    return ValueListenableBuilder<int>(
      valueListenable: queue.pendingCountNotifier,
      builder: (context, pendingCount, _) {
        final hasPending = pendingCount > 0;
        return IconButton(
          tooltip: hasPending ? '$pendingCount offline punches queued. Tap to sync' : 'Offline Punch Sync Status',
          icon: Badge(
            isLabelVisible: hasPending,
            label: Text('$pendingCount', style: const TextStyle( fontWeight: FontWeight.bold)),
            backgroundColor: context.status.warning.color,
            child: Icon(
              hasPending ? Icons.cloud_sync_rounded : Icons.cloud_done_rounded,
              color: hasPending ? context.status.warning.color : context.status.success.color,
              size: 22,
            ),
          ),
          onPressed: _showSyncHealthModal,
        );
      },
    );
  }

  void _showSyncHealthModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Offline Attendance Sync Engine',
                      style: ctx.textStyles.titleMedium?.copyWith(
                        
                        fontWeight: FontWeight.bold,
                        color: ctx.colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSyncHealthCard(),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'The biometric queue periodically sends cached employee punches to Firestore when connectivity is restored.',
                  style: ctx.textStyles.bodySmall?.copyWith(color: ctx.colors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildStaffRosterTab(List<QueryDocumentSnapshot> staff, List<QueryDocumentSnapshot> logs) {
    final pendingApprovalStaff = staff.where((s) {
      final data = s.data() as Map<String, dynamic>;
      return (data['approvalStatus'] == 'PENDING_APPROVAL' || data['status'] == 'PENDING_APPROVAL');
    }).toList();

    final approvedStaff = staff.where((s) {
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
                            companyName: _companyName,
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

                    final employeeLogs = logs.where((l) => (l.data() as Map<String, dynamic>)['userId'] == empDoc.id).toList();

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

  Widget _buildAttendanceLogsTab(
    List<QueryDocumentSnapshot> staff,
    List<QueryDocumentSnapshot> logs,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final filteredLogs = logs.where((l) {
      final data = l.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final ts = (data['timestamp'] as Timestamp?)?.toDate();

      if (_filterPunchType != 'ALL' && type != _filterPunchType) return false;
      if (_dateFilter == 'TODAY' && (ts == null || !ts.isAfter(startOfToday))) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Bar (2-tier responsive layout)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          color: context.colors.surface,
          child: Column(
            children: [
              // Tier 1: Filter Dropdowns
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dateFilter,
                          isExpanded: true,
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                          items: const [
                            DropdownMenuItem(value: 'TODAY', child: Text('Today Only')),
                            DropdownMenuItem(value: 'ALL', child: Text('All Time')),
                          ],
                          onChanged: (val) => setState(() => _dateFilter = val ?? 'TODAY'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterPunchType,
                          isExpanded: true,
                          style: context.textStyles.bodySmall?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Punches')),
                            DropdownMenuItem(value: 'PUNCH_IN', child: Text('Punch In')),
                            DropdownMenuItem(value: 'PUNCH_OUT', child: Text('Punch Out')),
                          ],
                          onChanged: (val) => setState(() => _filterPunchType = val ?? 'ALL'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Tier 2: Record Count & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '${filteredLogs.length} Records',
                      style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 15),
                          label: Text('Manual Punch', style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                          onPressed: () => _showManualPunchDialog(staff),
                        ),
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary, size: 17),
                          tooltip: 'Export PDF',
                          onPressed: () => _openPdfPreview(
                            filteredLogs,
                            dateRangeTitle: _dateFilter == 'TODAY' ? 'Today Only' : 'All Time Logs',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.colors.borderSubtle),

        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Text(
                    'No attendance logs match the filter.',
                    style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredLogs[index];
                    return _buildLogListTile(doc, staff);
                  },
                ),
        ),
      ],
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
                                    if (category == 'ABSENT') ...[
                                      FilledButton.tonal(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          _showManualPunchDialog(allStaff);
                                        },
                                        child: Text('Manual Punch', style: context.textStyles.labelSmall),
                                      ),
                                    ] else if (category == 'ON_LEAVE') ...[
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

  Widget _buildLogListTile(
    QueryDocumentSnapshot doc,
    List<QueryDocumentSnapshot> staff,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = data['userId'] as String? ?? '';
    final type = data['type'] as String? ?? 'PUNCH_IN';
    final ts = (data['timestamp'] as Timestamp?)?.toDate();
    final confidence = data['confidenceScore'] as num?;

    // Find staff details
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

    final withinGeofence = data['withinGeofence'] as bool?;
    final distance = (data['distanceFromOfficeMeters'] as num?)?.toDouble();
    final punchStatus = data['punchStatus'] as String?;
    final verifiedVia = data['verifiedVia'] as String? ?? 'FACE_ID';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Employee ID and Status Pills
          Row(
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
                    Text(
                      name,
                      style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (empId.isNotEmpty)
                      Text(
                        'ID: $empId',
                        style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (punchStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: punchStatus == 'LATE_ARRIVAL'
                        ? context.status.warning.color.withValues(alpha: 0.12)
                        : (punchStatus == 'OVERTIME'
                            ? context.colors.primary.withValues(alpha: 0.12)
                            : context.status.success.color.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    punchStatus == 'LATE_ARRIVAL'
                        ? 'Late (${data['lateMinutes'] ?? 0}m)'
                        : (punchStatus == 'OVERTIME'
                            ? '+${data['overtimeMinutes'] ?? 0}m OT'
                            : 'On Time'),
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: punchStatus == 'LATE_ARRIVAL'
                          ? context.status.warning.color
                          : (punchStatus == 'OVERTIME' ? context.colors.primary : context.status.success.color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPunchIn
                      ? context.status.success.color.withValues(alpha: 0.12)
                      : context.status.warning.color.withValues(alpha: 0.12),
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
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: context.colors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),
          // Sub-details row with Wrap to prevent any horizontal overflow
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    verifiedVia == 'FACE_ID' ? Icons.face_rounded : (verifiedVia == 'MANUAL_OVERRIDE' ? Icons.edit_note_rounded : Icons.pin_rounded),
                    size: 13,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$verifiedVia${confidence != null ? " (${(confidence * 100).toInt()}%)" : ""}',
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              if (withinGeofence != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      withinGeofence ? Icons.location_on_rounded : Icons.warning_amber_rounded,
                      size: 13,
                      color: withinGeofence ? context.status.success.color : context.status.warning.color,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      withinGeofence ? 'Campus (${distance?.toInt() ?? 0}m)' : 'Breach (${distance?.toInt() ?? 0}m)',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: withinGeofence ? context.status.success.color : context.status.warning.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab([List<QueryDocumentSnapshot> staff = const []]) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _dbService.getEnterpriseApprovalRequests(widget.enterpriseId),
      builder: (context, regSnapshot) {
        return StreamBuilder<List<LeaveRequest>>(
          stream: _leaveService.getEnterpriseLeaveRequests(widget.enterpriseId),
          builder: (context, leaveSnapshot) {
            final pendingJoinRequests = staff.where((s) {
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
                              'No pending leave requests awaiting approval.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingLeaves.map((leave) => _buildAdminLeaveCard(leave)),

                  if (historyLeaves.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Icon(Icons.history, color: context.colors.onSurfaceVariant, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Reviewed Leaves (${historyLeaves.length})',
                            style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...historyLeaves.map((leave) => _buildAdminProcessedLeaveCard(leave)),
                  ],
                ],
              ],
            );
          },
        );
      },
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Actual In', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(punchInStr,
                                style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.status.success.color)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 14, color: context.colors.onSurfaceVariant),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Requested Out', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(punchOutStr,
                                style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary)),
                          ],
                        ),
                      ),
                      if (durationStr.isNotEmpty) ...[
                        Icon(Icons.timelapse, size: 14, color: context.colors.onSurfaceVariant),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Duration', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(durationStr,
                                  style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reason: "$reason"',
                      style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(doc.id, data),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      side: BorderSide(color: context.status.danger.color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleApprove(doc.id, data),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.status.success.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      minimumSize: const Size(0, 48),
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
        leading: CircleAvatar(
          backgroundColor: isApproved
              ? context.status.success.color.withValues(alpha: 0.12)
              : context.status.danger.color.withValues(alpha: 0.12),
          child: Icon(
            isApproved ? Icons.check : Icons.close,
            color: isApproved ? context.status.success.color : context.status.danger.color,
            size: 20,
          ),
        ),
        title: Text(name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: $empId • Shift: $shiftDateStr',
            style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isApproved
                ? context.status.success.color.withValues(alpha: 0.1)
                : context.status.danger.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            status,
            style: context.textStyles.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isApproved ? context.status.success.color : context.status.danger.color,
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
        title: Row(
          children: [
            Icon(Icons.check_circle, color: context.status.success.color),
            const SizedBox(width: AppSpacing.xs),
            const Expanded(
              child: Text(
                'Approve Clock-Out?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'This will record a regularized PUNCH_OUT for ${requestData['employeeName']} and close their shift.',
            style: context.textStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.status.success.color,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval'),
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

  Widget _buildPendingApprovalCard(QueryDocumentSnapshot empDoc) {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ??
        (data['name'] as String?)?.trim() ??
        (data['email'] as String?)?.split('@').first ??
        'New Applicant';
    final email = (data['email'] as String?) ?? 'No email';
    final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate() ??
        (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.status.warning.border),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.status.warning.container,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.status.warning.onContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.status.warning.container,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  'PENDING',
                  style: context.textStyles.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.status.warning.onContainer,
                  ),
                ),
              ),
            ],
          ),
          if (requestedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Applied: ${requestedAt.day}/${requestedAt.month}/${requestedAt.year} at ${requestedAt.hour.toString().padLeft(2, '0')}:${requestedAt.minute.toString().padLeft(2, '0')}',
              style: context.textStyles.bodySmall?.copyWith(fontSize: 11, color: context.colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.status.danger.color,
                  side: BorderSide(color: context.status.danger.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                onPressed: () => _rejectPendingEmployee(empDoc),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.status.success.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                onPressed: () => _approvePendingEmployee(empDoc),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve & Add to Roster'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approvePendingEmployee(QueryDocumentSnapshot empDoc) async {
    final data = empDoc.data() as Map<String, dynamic>;
    final name = (data['fullName'] as String?)?.trim() ?? (data['name'] as String?)?.trim() ?? 'Employee';
    final existingId = (data['employeeId'] as String?)?.trim();
    final empId = (existingId != null && existingId.isNotEmpty) ? existingId : 'EMP-${empDoc.id.length >= 5 ? empDoc.id.substring(0, 5).toUpperCase() : empDoc.id.toUpperCase()}';
    final currentAdmin = AuthService().currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(empDoc.id).set({
        'approvalStatus': 'APPROVED',
        'status': 'ACTIVE',
        'employeeId': empId,
        'allowedVerificationMethods': ['MOBILE_GPS', 'KIOSK_FACE', 'PHONE_BIOMETRICS'],
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentAdmin?.uid ?? '',
        'linkedEnterprises': FieldValue.arrayUnion([widget.enterpriseId]),
      }, SetOptions(merge: true));

      try {
        await FirebaseFirestore.instance
            .collection('enterprises')
            .doc(widget.enterpriseId)
            .collection('employees')
            .doc(empDoc.id)
            .set({
          'approvalStatus': 'APPROVED',
          'status': 'ACTIVE',
          'employeeId': empId,
          'approvedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: 'STAFF_JOIN_APPROVED',
        category: AuditLogService.categoryStaff,
        targetEmployeeId: empId,
        targetEmployeeName: name,
        details: 'Administrator approved company join application for $name ($empId).',
      );

      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'target': 'USER',
          'userId': empDoc.id,
          'enterpriseId': widget.enterpriseId,
          'title': 'Join Request Approved!',
          'body': 'Your request to join $_companyName has been approved. You now have full access to company attendance.',
          'type': 'REGULARIZATION_APPROVED',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved $name! Registration completed with $_companyName.'),
            backgroundColor: context.status.success.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve employee: $e'), backgroundColor: context.status.danger.color),
        );
      }
    }
  }

  Future<void> _rejectPendingEmployee(QueryDocumentSnapshot empDoc) async {
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
            .doc(widget.enterpriseId)
            .collection('employees')
            .doc(empDoc.id)
            .delete();
      } catch (_) {}

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: 'STAFF_JOIN_REJECTED',
        category: AuditLogService.categoryStaff,
        targetEmployeeName: name,
        details: 'Administrator rejected company join application for $name.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected join request for $name.'),
            backgroundColor: context.status.warning.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e'), backgroundColor: context.status.danger.color),
        );
      }
    }
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
                  _openPdfPreview(
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
                        await _dbService.resetEmployeeBiometrics(empDoc.id);
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
        ['KIOSK_FACE', 'KIOSK_PIN', 'MOBILE_GPS', 'OFFICE_WIFI'];

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

  Future<void> _showManualPunchDialog(List<QueryDocumentSnapshot> staff) async {
    if (staff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('No employees found to log manual punch for.'), backgroundColor: context.status.warning.color),
      );
      return;
    }

    String selectedUserId = staff.first.id;
    String punchType = 'PUNCH_IN';
    DateTime punchDate = DateTime.now();
    TimeOfDay punchTime = TimeOfDay.now();
    final notesController = TextEditingController(text: 'Manual entry by Administrator');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.cardCircular),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dialogCtx.colors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.buttonCircular,
                  ),
                  child: Icon(Icons.edit_calendar_rounded, color: dialogCtx.colors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manual Punch Entry',
                    style: dialogCtx.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: dialogCtx.colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Employee:', style: dialogCtx.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: dialogCtx.colors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: dialogCtx.colors.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: dialogCtx.colors.borderSubtle)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: staff.map((s) {
                      final data = s.data() as Map<String, dynamic>;
                      final name = data['fullName'] ?? data['name'] ?? 'Staff Member';
                      final empId = data['employeeId'] ?? '';
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '$name ${empId.isNotEmpty ? "($empId)" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedUserId = val ?? staff.first.id),
                  ),
                  const SizedBox(height: 14),
                  Text('Punch Type:', style: dialogCtx.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: dialogCtx.colors.textSecondary)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'PUNCH_IN',
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: Text('Punch In', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment<String>(
                          value: 'PUNCH_OUT',
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: Text('Punch Out', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                      selected: {punchType},
                      onSelectionChanged: (newSelection) {
                        setModalState(() => punchType = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: punchType == 'PUNCH_IN'
                            ? dialogCtx.status.success.color.withValues(alpha: 0.18)
                            : dialogCtx.status.warning.color.withValues(alpha: 0.18),
                        selectedForegroundColor: punchType == 'PUNCH_IN'
                            ? dialogCtx.status.success.color
                            : dialogCtx.status.warning.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Date of Punch:', style: dialogCtx.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: dialogCtx.colors.textSecondary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: punchDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setModalState(() => punchDate = picked);
                    },
                    borderRadius: AppRadius.buttonCircular,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: dialogCtx.colors.surfaceContainerLowest,
                        borderRadius: AppRadius.buttonCircular,
                        border: Border.all(color: dialogCtx.colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: dialogCtx.colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${punchDate.day.toString().padLeft(2, '0')} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][punchDate.month - 1]} ${punchDate.year}",
                              style: dialogCtx.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: dialogCtx.colors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Change', style: dialogCtx.textStyles.labelSmall?.copyWith(color: dialogCtx.colors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Time of Punch:', style: dialogCtx.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: dialogCtx.colors.textSecondary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: dialogCtx, initialTime: punchTime);
                      if (picked != null) setModalState(() => punchTime = picked);
                    },
                    borderRadius: AppRadius.buttonCircular,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: dialogCtx.colors.surfaceContainerLowest,
                        borderRadius: AppRadius.buttonCircular,
                        border: Border.all(color: dialogCtx.colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: dialogCtx.colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              punchTime.format(dialogCtx),
                              style: dialogCtx.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: dialogCtx.colors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Change', style: dialogCtx.textStyles.labelSmall?.copyWith(color: dialogCtx.colors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Justification',
                      border: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: dialogCtx.colors.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.buttonCircular, borderSide: BorderSide(color: dialogCtx.colors.borderSubtle)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final successColor = context.status.success.color;
                        final dangerColor = context.status.danger.color;
                        final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
                        if (!hasNet) return;

                        setModalState(() => isSubmitting = true);
                        try {
                          final selectedDoc = staff.firstWhere((s) => s.id == selectedUserId);
                          final data = selectedDoc.data() as Map<String, dynamic>;
                          final name = data['fullName'] ?? data['name'] ?? 'Staff Member';
                          final empId = data['employeeId'] ?? 'N/A';

                          final combinedDateTime = DateTime(
                            punchDate.year,
                            punchDate.month,
                            punchDate.day,
                            punchTime.hour,
                            punchTime.minute,
                          );

                          final shift = await _dbService.getEnterpriseShiftSchedule(widget.enterpriseId);

                          await _dbService.logManualAttendance(
                            userId: selectedUserId,
                            enterpriseId: widget.enterpriseId,
                            type: punchType,
                            timestamp: combinedDateTime,
                            employeeName: name,
                            employeeId: empId,
                            notes: notesController.text.trim(),
                            schedule: shift,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Manual $punchType recorded for $name.'),
                              backgroundColor: successColor,
                            ),
                          );
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error recording punch: $e'), backgroundColor: dangerColor),
                          );
                        }
                      },
                child: isSubmitting
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: dialogCtx.colors.onPrimary))
                    : const Text('Record Punch'),
              ),
            ],
          );
        },
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
        side: BorderSide(color: context.colors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    req.employeeName.isNotEmpty ? req.employeeName[0].toUpperCase() : 'E',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.employeeName, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary), overflow: TextOverflow.ellipsis),
                      Text('ID: ${req.employeeId}', style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.badgeCircular,
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      req.leaveTypeDisplay,
                      style: context.text.labelSmall?.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLowest,
                borderRadius: AppRadius.buttonCircular,
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 15, color: context.colors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$startStr to $endStr',
                          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${req.daysCount} day${req.daysCount > 1 ? 's' : ''}',
                        style: TextStyle(fontWeight: FontWeight.bold,  color: context.colors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Reason: "${req.reason}"', style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: context.colors.textSecondary)),
                  const SizedBox(height: 6),
                  FutureBuilder<Map<String, int>>(
                    future: _leaveService.getEmployeeLeaveBalances(widget.enterpriseId, req.userId),
                    builder: (context, balanceSnapshot) {
                      final balances = balanceSnapshot.data;
                      final remaining = balances != null ? balances[req.leaveType] : null;
                      return Row(
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              remaining != null
                                  ? 'Remaining Quota: $remaining days'
                                  : 'Checking quota balance...',
                              style: TextStyle(
                                
                                fontWeight: FontWeight.w600,
                                color: remaining != null && remaining < req.daysCount
                                    ? context.status.danger.color
                                    : context.colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
          style: context.textStyles.bodySmall?.copyWith( color: context.colors.textSecondary),
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
                  // Drag handle
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

                  // Header
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
                                  style: sheetCtx.textStyles.bodySmall?.copyWith( color: sheetCtx.colors.textSecondary),
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

                  // Category Filter Chips
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

                  // Logs Stream
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
                            // Export CSV header bar
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
                                    label: const Text('Export CSV', style: TextStyle( fontWeight: FontWeight.bold)),
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

                            // List of audit cards
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
                                              style: sheetCtx.textStyles.bodySmall?.copyWith( color: sheetCtx.colors.textSecondary),
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
                                                style: sheetCtx.textStyles.bodySmall?.copyWith( color: sheetCtx.colors.textSecondary),
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

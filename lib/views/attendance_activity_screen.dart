import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'pdf_timesheet_preview_screen.dart';

/// Dedicated screen for employee and enterprise attendance activity logs.
/// Supports dual tabs ('My Activity' and 'Enterprise Activity'), month filtering,
/// PDF export, and clean overflow-proof activity cards with light motion.
///
/// Fully token-driven (AQIL v2): zero hardcoded hex colors, zero fixed font sizes,
/// theme-aware M3 card and tab styling, and defensive ellipsis constraints.
class AttendanceActivityScreen extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final String userRole;

  const AttendanceActivityScreen({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    this.userRole = 'employee',
  });

  @override
  State<AttendanceActivityScreen> createState() => _AttendanceActivityScreenState();
}

class _AttendanceActivityScreenState extends State<AttendanceActivityScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final canViewBoth = widget.userRole == 'enterprise_admin';
    _tabController = TabController(length: canViewBoth ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final month = int.tryParse(parts[1]) ?? 1;
      return '${_monthName(month)} $year';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isEnterpriseAdmin = widget.userRole == 'enterprise_admin';
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Activity',
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // PDF Export Button
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: isEnterpriseAdmin && _tabController.index == 1
                ? _dbService.getEnterpriseAttendanceLogs(widget.enterpriseId)
                : (user != null ? _dbService.getUserAttendanceLogs(user.uid) : const Stream.empty()),
            builder: (context, actSnap) {
              final currentLogs = actSnap.data ?? [];
              return IconButton(
                icon: Icon(Icons.picture_as_pdf_outlined, color: colors.primary),
                tooltip: 'Export Timesheet (PDF)',
                onPressed: currentLogs.isEmpty
                    ? null
                    : () {
                        final empName = user?.displayName ?? user?.email ?? 'My Timesheet';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfTimesheetPreviewScreen(
                              enterpriseId: widget.enterpriseId,
                              companyName: widget.companyName.isNotEmpty ? widget.companyName : widget.enterpriseId,
                              logs: currentLogs,
                              employeeFilterName: isEnterpriseAdmin && _tabController.index == 1 ? null : empName,
                              dateRangeTitle: _selectedMonth != null ? _formatMonthKey(_selectedMonth!) : 'Complete History',
                            ),
                          ),
                        );
                      },
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: isEnterpriseAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'My Activity', icon: Icon(Icons.person_pin_circle_outlined, size: AppSizes.iconMd)),
                  Tab(text: 'Enterprise Activity', icon: Icon(Icons.corporate_fare_rounded, size: AppSizes.iconMd)),
                ],
              )
            : null,
      ),
      body: user == null
          ? const Center(child: Text('User not signed in.'))
          : isEnterpriseAdmin
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogsList(
                      stream: _dbService.getUserAttendanceLogs(user.uid),
                      isEnterprise: false,
                    ),
                    _buildLogsList(
                      stream: _dbService.getEnterpriseAttendanceLogs(widget.enterpriseId),
                      isEnterprise: true,
                    ),
                  ],
                )
              : _buildLogsList(
                  stream: _dbService.getUserAttendanceLogs(user.uid),
                  isEnterprise: false,
                ),
    );
  }

  Widget _buildLogsList({
    required Stream<List<QueryDocumentSnapshot>> stream,
    required bool isEnterprise,
  }) {
    final colors = context.colors;

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppListSkeleton(itemCount: 4);
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ErrorStateView(
                message: 'Failed to load activity logs: ${snapshot.error}',
              ),
            ),
          );
        }

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EmptyStateView(
                icon: Icons.history_toggle_off,
                title: isEnterprise ? 'No enterprise attendance records yet' : 'No personal attendance records yet',
                message: isEnterprise
                    ? 'Clock-in entries from Kiosks and Mobile will appear here.'
                    : 'Your punches from Mobile and Office Kiosks will appear here.',
              ),
            ),
          );
        }

        // Group docs month-wise
        final Map<String, List<QueryDocumentSnapshot>> monthGroups = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final monthKey = '${ts.year}-${ts.month.toString().padLeft(2, '0')}';
          monthGroups.putIfAbsent(monthKey, () => []).add(doc);
        }

        final sortedMonths = monthGroups.keys.toList()..sort((a, b) => b.compareTo(a));

        final displayMonths = _selectedMonth != null && monthGroups.containsKey(_selectedMonth)
            ? [_selectedMonth!]
            : sortedMonths;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          children: [
            // Month Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                    child: FilterChip(
                      label: const Text('All History'),
                      selected: _selectedMonth == null,
                      onSelected: (val) => setState(() => _selectedMonth = null),
                    ),
                  ),
                  ...sortedMonths.map((m) {
                    final isSel = _selectedMonth == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                      child: FilterChip(
                        label: Text(_formatMonthKey(m)),
                        selected: isSel,
                        onSelected: (val) => setState(() => _selectedMonth = val ? m : null),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Render Groups
            ...displayMonths.map((mKey) {
              final groupDocs = monthGroups[mKey] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      _formatMonthKey(mKey),
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...groupDocs.map((doc) => _buildLogItem(doc, isEnterprise)),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLogItem(QueryDocumentSnapshot doc, bool isEnterprise) {
    final data = doc.data() as Map<String, dynamic>;
    final isPunchIn = data['type'] == 'PUNCH_IN';
    final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final verifiedVia = (data['verifiedVia'] as String?) ?? 'MANUAL';
    final punchStatus = data['punchStatus'] as String?;
    final shiftDurationMinutes = data['shiftDurationMinutes'] as int?;
    final employeeName = (data['employeeName'] as String?) ?? (data['employeeId'] as String?) ?? 'Staff';

    final colors = context.colors;
    final status = context.status;
    final tone = isPunchIn ? status.success : status.danger;

    final timeStr = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    final dateStr = '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            // Status Icon Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tone.container,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                isPunchIn ? Icons.login_rounded : Icons.logout_rounded,
                color: tone.onContainer,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Middle: Name / Punch type & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isPunchIn ? 'Clock In' : 'Clock Out',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tone.onContainer,
                        ),
                      ),
                      if (isEnterprise) ...[
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: Text(
                            '• $employeeName',
                            style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      '$dateStr • $timeStr',
                      if (shiftDurationMinutes != null && shiftDurationMinutes > 0)
                        '(${shiftDurationMinutes ~/ 60}h ${shiftDurationMinutes % 60}m)'
                    ].join(' '),
                    style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Trailing: Verification badge & status pill
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width * 0.32).clamp(70.0, 140.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: AppRadius.brXs,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      verifiedVia == 'DEVICE_TERMINAL'
                          ? ((data['terminalName'] as String?) ?? 'MinMoe Terminal')
                          : verifiedVia.replaceAll('_', ' '),
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (punchStatus != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      punchStatus == 'LATE_ARRIVAL'
                          ? 'Late'
                          : (punchStatus == 'EARLY_DEPARTURE' ? 'Early' : 'On-Time'),
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: punchStatus == 'LATE_ARRIVAL' ? status.danger.onContainer : status.success.onContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

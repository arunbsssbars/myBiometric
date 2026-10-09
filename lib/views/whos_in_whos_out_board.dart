import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/database_service.dart';
import '../services/break_tracking_service.dart';
import '../domain/models/shift_schedule.dart';
import 'employee_presence_tile.dart';

/// Real-time live workforce status board inspired by Jibble.
/// Displays live attendance state for every employee in an enterprise:
/// - In Office (Working / On Break)
/// - Clocked Out
/// - Not In / Absent
/// - On Leave
/// With live running duration tickers, capacity meter, search & department filtering.
///
/// Fully token-driven (AQIL v2 Phase 0): no hardcoded colors or font sizes,
/// light/dark aware, adaptive KPI grid, and explicit loading/error/empty states.
class WhosInWhosOutBoard extends StatefulWidget {
  final String enterpriseId;
  final ShiftSchedule schedule;

  const WhosInWhosOutBoard({
    super.key,
    required this.enterpriseId,
    this.schedule = const ShiftSchedule(),
  });

  @override
  State<WhosInWhosOutBoard> createState() => _WhosInWhosOutBoardState();
}

enum _FilterOption {
  all,
  inOffice,
  working,
  onBreak,
  overstayed,
  clockedOut,
  absent,
  onLeave,
}

/// Aggregated counts for the board header.
class _PresenceCounts {
  final int total;
  final int working;
  final int onBreak;
  final int overstayed;
  final int clockedOut;
  final int absent;
  final int onLeave;

  const _PresenceCounts({
    required this.total,
    required this.working,
    required this.onBreak,
    required this.overstayed,
    required this.clockedOut,
    required this.absent,
    required this.onLeave,
  });

  int get inOffice => working + onBreak;
  int get capacityPercent => total > 0 ? ((inOffice / total) * 100).round() : 0;
}

class _WhosInWhosOutBoardState extends State<WhosInWhosOutBoard> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  _FilterOption _selectedFilter = _FilterOption.all;
  String _selectedDepartment = 'All';
  String _searchQuery = '';
  Timer? _tickerTimer;

  /// KPI tiles switch from a 2×2 grid to a single row above this card width.
  static const double _kpiSingleRowMinWidth = 480;

  @override
  void initState() {
    super.initState();
    // Live ticker timer to recalculate running durations every 30 seconds
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _dbService.getEnterpriseEmployeesStream(widget.enterpriseId),
      builder: (context, empSnap) {
        return StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _dbService.getEnterpriseAttendanceToday(widget.enterpriseId),
          builder: (context, logsSnap) {
            return StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _dbService.getEnterpriseLeavesToday(widget.enterpriseId),
              builder: (context, leavesSnap) {
                // Phase 4: explicit error & loading states
                if (empSnap.hasError || logsSnap.hasError || leavesSnap.hasError) {
                  return _buildShell(
                    context,
                    child: ErrorStateView(
                      message: 'Unable to load live workforce presence. Check your connection and try again.',
                      onRetry: () => setState(() {}),
                    ),
                  );
                }
                if (!empSnap.hasData && empSnap.connectionState == ConnectionState.waiting) {
                  return _buildShell(context, child: _buildLoadingSkeleton());
                }

                final empDocs = empSnap.data ?? [];
                final logsDocs = logsSnap.data ?? [];
                final leavesDocs = leavesSnap.data ?? [];

                // Map of approved leaves by userId
                final Map<String, String> approvedLeavesByUser = {};
                for (final doc in leavesDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uId = data['userId'] as String?;
                  if (uId != null && uId.isNotEmpty) {
                    approvedLeavesByUser[uId] = (data['reason'] as String?) ?? 'Approved Leave';
                  }
                }

                // Group today's logs by userId
                final Map<String, List<Map<String, dynamic>>> logsByUser = {};
                for (final doc in logsDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uId = data['userId'] as String? ?? data['employeeId'] as String?;
                  if (uId != null && uId.isNotEmpty) {
                    logsByUser.putIfAbsent(uId, () => []).add(data);
                  }
                }

                // Distinct departments
                final Set<String> departments = {'All'};
                final List<EmployeeDailySession> allSessions = [];

                for (final doc in empDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uId = doc.id;
                  final empId = (data['employeeId'] as String?)?.trim() ?? 'EMP';
                  final name = (data['fullName'] as String?)?.trim() ??
                      (data['name'] as String?)?.trim() ??
                      (data['email'] as String?)?.split('@').first ??
                      'Employee';
                  final dept = (data['department'] as String?)?.trim() ?? 'General';
                  if (dept.isNotEmpty) departments.add(dept);

                  // Match logs by either doc.id or employeeId
                  final userLogs = logsByUser[uId] ?? logsByUser[empId] ?? [];
                  final isOnLeave = approvedLeavesByUser.containsKey(uId) || approvedLeavesByUser.containsKey(empId);
                  final leaveReason = approvedLeavesByUser[uId] ?? approvedLeavesByUser[empId];

                  final session = EmployeeDailySession.evaluate(
                    userId: uId,
                    employeeName: name,
                    employeeId: empId,
                    department: dept,
                    employeeLogsToday: userLogs,
                    isOnApprovedLeave: isOnLeave,
                    leaveReason: leaveReason,
                  );
                  allSessions.add(session);
                }

                // Sort: Working & Break first, then Clocked Out, On Leave, then Absent
                allSessions.sort((a, b) {
                  int rank(EmployeeWorkStatus s) {
                    switch (s) {
                      case EmployeeWorkStatus.working:
                        return 0;
                      case EmployeeWorkStatus.onBreak:
                        return 1;
                      case EmployeeWorkStatus.clockedOut:
                        return 2;
                      case EmployeeWorkStatus.onLeave:
                        return 3;
                      case EmployeeWorkStatus.absent:
                        return 4;
                    }
                  }

                  final rA = rank(a.status);
                  final rB = rank(b.status);
                  if (rA != rB) return rA.compareTo(rB);
                  return a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
                });

                // Compute counts
                int countOf(EmployeeWorkStatus s) => allSessions.where((x) => x.status == s).length;
                final counts = _PresenceCounts(
                  total: allSessions.length,
                  working: countOf(EmployeeWorkStatus.working),
                  onBreak: countOf(EmployeeWorkStatus.onBreak),
                  overstayed: allSessions.where((s) => s.isOverstayedBreak).length,
                  clockedOut: countOf(EmployeeWorkStatus.clockedOut),
                  absent: countOf(EmployeeWorkStatus.absent),
                  onLeave: countOf(EmployeeWorkStatus.onLeave),
                );

                // Apply filtering
                final filteredSessions = allSessions.where((session) {
                  // Department filter
                  if (_selectedDepartment != 'All' && session.department != _selectedDepartment) {
                    return false;
                  }

                  // Status chip filter
                  switch (_selectedFilter) {
                    case _FilterOption.all:
                      break;
                    case _FilterOption.inOffice:
                      if (session.status != EmployeeWorkStatus.working && session.status != EmployeeWorkStatus.onBreak) {
                        return false;
                      }
                      break;
                    case _FilterOption.working:
                      if (session.status != EmployeeWorkStatus.working) return false;
                      break;
                    case _FilterOption.onBreak:
                      if (session.status != EmployeeWorkStatus.onBreak) return false;
                      break;
                    case _FilterOption.overstayed:
                      if (!session.isOverstayedBreak) return false;
                      break;
                    case _FilterOption.clockedOut:
                      if (session.status != EmployeeWorkStatus.clockedOut) return false;
                      break;
                    case _FilterOption.absent:
                      if (session.status != EmployeeWorkStatus.absent) return false;
                      break;
                    case _FilterOption.onLeave:
                      if (session.status != EmployeeWorkStatus.onLeave) return false;
                      break;
                  }

                  // Search query filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchName = session.employeeName.toLowerCase().contains(q);
                    final matchId = session.employeeId.toLowerCase().contains(q);
                    final matchDept = session.department.toLowerCase().contains(q);
                    if (!matchName && !matchId && !matchDept) return false;
                  }

                  return true;
                }).toList();

                return _buildShell(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPresenceSummary(context, counts),
                      const SizedBox(height: AppSpacing.md),
                      _buildSearchAndDepartmentRow(context, departments),
                      const SizedBox(height: AppSpacing.md),
                      _buildFilterChips(context, counts),
                      const SizedBox(height: AppSpacing.md),
                      if (filteredSessions.isEmpty)
                        EmptyStateView(
                          icon: Icons.person_search_rounded,
                          title: allSessions.isEmpty ? 'No employees yet' : 'No employees match your filters',
                          message: allSessions.isEmpty
                              ? 'Add staff to your enterprise to see live presence here.'
                              : 'Try a different status, department or search term.',
                          actionLabel: allSessions.isEmpty ? null : 'Clear filters',
                          onAction: allSessions.isEmpty ? null : _clearFilters,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSessions.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) => _buildEmployeePresenceTile(filteredSessions[idx]),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedFilter = _FilterOption.all;
      _selectedDepartment = 'All';
    });
  }

  /// Card chrome + header shared by all states.
  Widget _buildShell(BuildContext context, {required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              icon: Icons.people_alt_rounded,
              title: "Who's In / Who's Out",
              subtitle: 'Live real-time workforce presence',
              trailing: Semantics(
                label: 'Live updates enabled',
                child: StatusPill(
                  label: 'LIVE',
                  tone: context.status.success,
                  icon: Icons.fiber_manual_record,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 112),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 48),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 56),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 56),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 56),
      ],
    );
  }

  Widget _buildPresenceSummary(BuildContext context, _PresenceCounts c) {
    final colors = context.colors;
    final status = context.status;
    final capacityTone = c.capacityPercent >= 60 ? status.success : status.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Workforce Presence',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${c.inOffice} / ${c.total} on-site today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(label: '${c.capacityPercent}% present', tone: capacityTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Proportional multi-segmented bar
          Semantics(
            label: '${c.working} working, ${c.onBreak} on break, ${c.clockedOut} clocked out, '
                '${c.absent} not in, ${c.onLeave} on leave',
            child: ClipRRect(
              borderRadius: AppRadius.brSm,
              child: SizedBox(
                height: AppSpacing.sm,
                child: c.total == 0
                    ? ColoredBox(color: colors.surfaceContainerHigh)
                    : Row(
                        children: [
                          for (final (count, tone) in [
                            (c.working, status.success),
                            (c.onBreak, status.warning),
                            (c.clockedOut, status.neutral),
                            (c.absent, status.danger),
                            (c.onLeave, status.info),
                          ])
                            if (count > 0) Expanded(flex: count, child: ColoredBox(color: tone.color)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildKpiGrid(context, c),
        ],
      ),
    );
  }

  /// Adaptive KPI grid: 2×2 on narrow cards, single row of 4 on wider cards.
  Widget _buildKpiGrid(BuildContext context, _PresenceCounts c) {
    final status = context.status;
    final tiles = [
      KpiTile(label: 'Working', count: c.working, tone: status.success, icon: Icons.work_outline_rounded),
      KpiTile(
        label: 'On break',
        count: c.onBreak,
        tone: status.warning,
        icon: Icons.coffee_rounded,
        note: c.overstayed > 0 ? '${c.overstayed} over limit' : null,
      ),
      KpiTile(label: 'Clocked out', count: c.clockedOut, tone: status.neutral, icon: Icons.logout_rounded),
      KpiTile(
        label: 'Away / not in',
        count: c.absent + c.onLeave,
        tone: status.danger,
        icon: Icons.person_off_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kpiSingleRowMinWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(children: [Expanded(child: tiles[0]), const SizedBox(width: AppSpacing.sm), Expanded(child: tiles[1])]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [Expanded(child: tiles[2]), const SizedBox(width: AppSpacing.sm), Expanded(child: tiles[3])]),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndDepartmentRow(BuildContext context, Set<String> departments) {
    final colors = context.colors;
    final searchField = TextField(
      controller: _searchController,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search staff by name, ID or department',
        prefixIcon: Icon(Icons.search, size: AppSizes.iconMd, color: colors.onSurfaceVariant),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear, size: AppSizes.iconMd),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
    );

    if (departments.length <= 2) return searchField;

    final departmentField = DropdownButtonFormField<String>(
      initialValue: _selectedDepartment,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Department'),
      style: context.text.bodyMedium?.copyWith(color: colors.onSurface),
      items: departments
          .map((d) => DropdownMenuItem<String>(
                value: d,
                child: Text(d, maxLines: 1, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedDepartment = val);
      },
    );

    // Stack vertically on compact widths so neither field gets crushed at large font scales.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.medium * 0.75) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [searchField, const SizedBox(height: AppSpacing.sm), departmentField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 2, child: departmentField),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, _PresenceCounts c) {
    final status = context.status;
    final chips = <Widget>[
      _buildFilterChip(context, 'All', _FilterOption.all, c.total, Icons.groups_rounded, null),
      _buildFilterChip(context, 'In office', _FilterOption.inOffice, c.inOffice, Icons.apartment_rounded, status.success),
      _buildFilterChip(context, 'Working', _FilterOption.working, c.working, Icons.work_outline_rounded, status.success),
      _buildFilterChip(context, 'On break', _FilterOption.onBreak, c.onBreak, Icons.coffee_rounded, status.warning),
      if (c.overstayed > 0)
        _buildFilterChip(context, 'Overstayed', _FilterOption.overstayed, c.overstayed, Icons.warning_amber_rounded, status.danger),
      _buildFilterChip(context, 'Clocked out', _FilterOption.clockedOut, c.clockedOut, Icons.logout_rounded, status.neutral),
      _buildFilterChip(context, 'Not in', _FilterOption.absent, c.absent, Icons.person_off_outlined, status.danger),
      if (c.onLeave > 0)
        _buildFilterChip(context, 'On leave', _FilterOption.onLeave, c.onLeave, Icons.beach_access_rounded, status.info),
    ];

    // Compact: single horizontally scrollable row. Medium+: wrap so all filters are visible.
    if (context.windowSize.isCompact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              chips[i],
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: chips);
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    _FilterOption option,
    int count,
    IconData icon,
    StatusTone? tone,
  ) {
    final colors = context.colors;
    final isSelected = _selectedFilter == option;
    final fg = isSelected ? colors.onPrimary : colors.onSurfaceVariant;
    return ChoiceChip(
      avatar: Icon(icon, size: AppSizes.iconSm, color: isSelected ? colors.onPrimary : (tone?.color ?? fg)),
      label: Text(
        '$label ($count)',
        style: context.text.labelMedium?.copyWith(
          color: fg,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      tooltip: '$label: $count employees',
      onSelected: (_) => setState(() => _selectedFilter = option),
    );
  }

  Widget _buildEmployeePresenceTile(EmployeeDailySession session) {
    return EmployeePresenceTile(
      session: session,
      onTap: () => _showEmployeeActionSheet(session),
    );
  }

  /// Token-driven tonal filled button whose colors stay AA-compliant in both themes.
  ButtonStyle _toneButtonStyle(StatusTone tone) => FilledButton.styleFrom(
        backgroundColor: tone.onContainer,
        foregroundColor: tone.container,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      );

  Future<void> _runAdminAction(BuildContext sheetContext, Future<void> Function() action, String successMessage) async {
    Navigator.pop(sheetContext);
    await action();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  void _showEmployeeActionSheet(EmployeeDailySession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.colors;
        final status = ctx.status;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        session.employeeName.isNotEmpty ? session.employeeName[0].toUpperCase() : 'E',
                        style: ctx.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            [session.employeeId, session.department].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ctx.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Shift & attendance metrics
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSheetMetric(ctx, 'Punch in', _formatTime(session.punchInTime), Icons.login_rounded, status.success.color)),
                      Expanded(child: _buildSheetMetric(ctx, 'Breaks', _formatDuration(session.totalBreakDuration), Icons.coffee_rounded, status.warning.color)),
                      Expanded(child: _buildSheetMetric(ctx, 'Punch out', _formatTime(session.punchOutTime), Icons.logout_rounded, status.neutral.onContainer)),
                      Expanded(child: _buildSheetMetric(ctx, 'Net work', _formatDuration(session.netWorkDuration), Icons.schedule_rounded, colors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Semantics(
                  header: true,
                  child: Text(
                    'Admin quick actions',
                    style: ctx.text.titleSmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Dynamic action buttons according to status
                if (session.status == EmployeeWorkStatus.onBreak)
                  FilledButton.icon(
                    style: _toneButtonStyle(status.warning),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Force end break & resume work'),
                    onPressed: () => _runAdminAction(
                      ctx,
                      () => _dbService.logBreak(
                        userId: session.userId,
                        enterpriseId: widget.enterpriseId,
                        type: 'END_BREAK',
                        employeeName: session.employeeName,
                        employeeId: session.employeeId,
                        verifiedVia: 'ADMIN_MANUAL',
                        notes: 'Break ended by Admin',
                      ),
                      'Ended break for ${session.employeeName}',
                    ),
                  )
                else if (session.status == EmployeeWorkStatus.working)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: status.warning.onContainer,
                            side: BorderSide(color: status.warning.onContainer),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          icon: const Icon(Icons.coffee_rounded, size: AppSizes.iconMd),
                          label: const Text('Take break', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => _runAdminAction(
                            ctx,
                            () => _dbService.logBreak(
                              userId: session.userId,
                              enterpriseId: widget.enterpriseId,
                              type: 'START_BREAK',
                              breakType: 'Lunch',
                              employeeName: session.employeeName,
                              employeeId: session.employeeId,
                              verifiedVia: 'ADMIN_MANUAL',
                              notes: 'Break logged by Admin',
                            ),
                            'Started lunch break for ${session.employeeName}',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: colors.onError,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: AppSizes.iconMd),
                          label: const Text('Clock out', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () {
                            final now = DateTime.now();
                            final inTime = session.punchInTime ?? now;
                            _runAdminAction(
                              ctx,
                              () => _dbService.logManualAttendance(
                                userId: session.userId,
                                enterpriseId: widget.enterpriseId,
                                type: 'PUNCH_OUT',
                                timestamp: now,
                                employeeName: session.employeeName,
                                employeeId: session.employeeId,
                                shiftDurationMinutes: now.difference(inTime).inMinutes,
                                notes: 'Clocked out by Admin',
                              ),
                              'Clocked out ${session.employeeName}',
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else if (session.status == EmployeeWorkStatus.clockedOut || session.status == EmployeeWorkStatus.absent)
                  FilledButton.icon(
                    style: _toneButtonStyle(status.success),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Admin clock in employee'),
                    onPressed: () => _runAdminAction(
                      ctx,
                      () => _dbService.logManualAttendance(
                        userId: session.userId,
                        enterpriseId: widget.enterpriseId,
                        type: 'PUNCH_IN',
                        timestamp: DateTime.now(),
                        employeeName: session.employeeName,
                        employeeId: session.employeeId,
                        notes: 'Clocked in by Admin',
                      ),
                      'Clocked in ${session.employeeName}',
                    ),
                  )
                else if (session.status == EmployeeWorkStatus.onLeave)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: status.info.container,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: status.info.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.beach_access_rounded, color: status.info.onContainer, size: AppSizes.iconMd),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'On approved leave: ${session.leaveReason ?? "Leave"}',
                            style: ctx.text.bodyMedium?.copyWith(
                              color: status.info.onContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetMetric(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

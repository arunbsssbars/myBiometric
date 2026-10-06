import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/audit_log_service.dart';
import '../domain/models/attendance_regularization_request.dart';
import '../core/utils/app_format_utils.dart';
import '../core/network/network_connection_service.dart';

/// Employee-facing self-service Attendance Correction & Regularization Hub.
/// Allows employees to review missed punches, submit regularization requests,
/// track approval progress, and cancel pending requests.
///
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class AttendanceRegularizationHubScreen extends StatefulWidget {
  final String enterpriseId;
  final String? employeeName;
  final String? employeeId;

  const AttendanceRegularizationHubScreen({
    super.key,
    required this.enterpriseId,
    this.employeeName,
    this.employeeId,
  });

  @override
  State<AttendanceRegularizationHubScreen> createState() =>
      _AttendanceRegularizationHubScreenState();
}

class _AttendanceRegularizationHubScreenState
    extends State<AttendanceRegularizationHubScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNewRequestSheet(BuildContext context, {Map<String, dynamic>? unclosedShift}) {
    final colors = context.colors;
    final statusTheme = context.status;
    final textTheme = context.text;
    final now = DateTime.now();

    DateTime selectedDate = unclosedShift != null && unclosedShift['shiftDate'] != null
        ? (unclosedShift['shiftDate'] as DateTime)
        : now.subtract(const Duration(days: 1));
    TimeOfDay clockInTime = unclosedShift != null && unclosedShift['punchInTime'] != null
        ? TimeOfDay.fromDateTime(unclosedShift['punchInTime'] as DateTime)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay clockOutTime = const TimeOfDay(hour: 18, minute: 0);
    RegularizationCategory selectedCategory = RegularizationCategory.forgotPunch;
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.modal),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(Icons.edit_calendar_rounded,
                            color: colors.primary, size: AppSizes.iconMd),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Request Regularization',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: AppSizes.iconMd),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Shift Date Picker
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: now.subtract(const Duration(days: 30)),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Shift Date',
                                    style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  AppFormatUtils.formatDate(selectedDate),
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // In & Out Times
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: clockInTime,
                            );
                            if (picked != null) {
                              setSheetState(() => clockInTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clock In Time',
                                    style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  clockInTime.format(context),
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: clockOutTime,
                            );
                            if (picked != null) {
                              setSheetState(() => clockOutTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clock Out Time',
                                    style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  clockOutTime.format(context),
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Selector
                  Text('Correction Reason Category:',
                      style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: RegularizationCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Reason Note
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Detailed Explanation',
                      hintText: 'Please describe why this shift correction is needed...',
                      hintStyle: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(errorText!, style: textTheme.bodySmall?.copyWith(color: colors.error)),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final reason = reasonController.text.trim();
                            if (reason.isEmpty) {
                              setSheetState(() => errorText = 'Please provide an explanation.');
                              return;
                            }

                            final hasNet =
                                await NetworkConnectionService.checkConnectionAndNotify(context);
                            if (!hasNet) return;

                            setSheetState(() => isSubmitting = true);

                            try {
                              final user = AuthService().currentUser!;
                              final punchInDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                clockInTime.hour,
                                clockInTime.minute,
                              );
                              final punchOutDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                clockOutTime.hour,
                                clockOutTime.minute,
                              );

                              await _dbService.submitRegularizationRequest(
                                userId: user.uid,
                                enterpriseId: widget.enterpriseId,
                                employeeName: widget.employeeName ?? user.displayName ?? 'Employee',
                                employeeId: widget.employeeId ?? 'EMP',
                                originalPunchInId: unclosedShift?['docId'],
                                shiftDate: selectedDate,
                                punchInTime: punchInDateTime,
                                requestedPunchOutTime: punchOutDateTime,
                                reason: '${selectedCategory.label}: $reason',
                              );

                              AuditLogService().logAction(
                                enterpriseId: widget.enterpriseId,
                                action: 'REGULARIZATION_SUBMITTED',
                                category: AuditLogService.categoryApprovals,
                                details: 'Submitted correction for ${AppFormatUtils.formatDate(selectedDate)}',
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Regularization request submitted to Administrator!'),
                                    backgroundColor: statusTheme.success.color,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                isSubmitting = false;
                                errorText = 'Failed to submit: $e';
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Request'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final currentUid = user?.uid ?? '';
    final colors = context.colors;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Attendance Regularization',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'Review History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
        onPressed: () => _showNewRequestSheet(context),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _dbService.getUserApprovalRequests(currentUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];
          final pendingDocs = docs.where((d) => (d.data() as Map)['status'] == 'PENDING').toList();
          final historyDocs = docs.where((d) => (d.data() as Map)['status'] != 'PENDING').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(pendingDocs, isPending: true),
              _buildRequestList(historyDocs, isPending: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<QueryDocumentSnapshot> docs, {required bool isPending}) {
    final colors = context.colors;
    final textTheme = context.text;

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending ? Icons.check_circle_outline_rounded : Icons.history_rounded,
                  size: 40,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isPending ? 'No Pending Requests' : 'No Past Requests',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isPending
                    ? 'All your attendance regularization requests have been reviewed.'
                    : 'Your completed regularization history will appear here.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 80),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] as String? ?? 'PENDING').toUpperCase();
        final reason = data['reason'] as String? ?? 'Correction requested';
        final shiftDate = (data['shiftDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final requestedOut = (data['requestedPunchOutTime'] as Timestamp?)?.toDate();
        final punchIn = (data['punchInTime'] as Timestamp?)?.toDate();

        Color statusColor;
        Color statusBg;
        IconData statusIcon;

        final statusTokens = context.status;

        switch (status) {
          case 'APPROVED':
            statusColor = statusTokens.success.color;
            statusBg = statusTokens.success.container;
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'REJECTED':
            statusColor = statusTokens.danger.color;
            statusBg = statusTokens.danger.container;
            statusIcon = Icons.cancel_rounded;
            break;
          default:
            statusColor = statusTokens.warning.color;
            statusBg = statusTokens.warning.container;
            statusIcon = Icons.hourglass_top_rounded;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          status,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatUtils.formatDate(shiftDate),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (punchIn != null || requestedOut != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Shift: ${punchIn != null ? AppFormatUtils.formatTimeOfDay(TimeOfDay.fromDateTime(punchIn)) : '--'} &rarr; ${requestedOut != null ? AppFormatUtils.formatTimeOfDay(TimeOfDay.fromDateTime(requestedOut)) : '--'}',
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                reason,
                style: textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isPending) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.error,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Cancel Request'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Cancel Regularization Request?'),
                          content: const Text(
                              'Are you sure you want to withdraw this correction request?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Keep'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: colors.error),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Cancel Request'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('approval_requests')
                            .doc(doc.id)
                            .delete();
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

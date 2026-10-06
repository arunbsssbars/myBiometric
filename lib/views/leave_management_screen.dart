import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/leave_request.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';

/// Comprehensive Leave & Time-Off Management Screen.
///
/// Fully token-driven (AQIL v2): zero hardcoded hex colors, zero fixed font sizes,
/// theme-aware M3 card and dialog styling, and accessible touch targets.
class LeaveManagementScreen extends StatefulWidget {
  final String enterpriseId;
  final String companyName;

  const LeaveManagementScreen({
    super.key,
    required this.enterpriseId,
    required this.companyName,
  });

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  String _statusFilter = 'ALL';

  void _showApplyLeaveSheet(BuildContext context, String employeeName, String employeeId) {
    String selectedType = 'CASUAL';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final daysCount = endDate.difference(startDate).inDays + 1;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final colors = ctx.colors;
          final status = ctx.status;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xl,
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.beach_access_rounded, color: colors.primary, size: AppSizes.iconLg),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Apply for Leave / Time-Off',
                            style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: AppSizes.iconMd),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Leave Type:',
                      style: ctx.text.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _buildTypeChip('CASUAL', 'Casual Leave', selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildTypeChip('SICK', 'Sick Leave', selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildTypeChip('PAID', 'Paid Leave', selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildTypeChip('WFH', 'Work From Home', selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildTypeChip('UNPAID', 'Unpaid Time-Off', selectedType, (v) => setModalState(() => selectedType = v)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Date Range:',
                      style: ctx.text.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: AppSizes.iconSm),
                            label: Text(
                              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                              style: ctx.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                });
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: Icon(Icons.arrow_forward, size: 14, color: colors.outline),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: AppSizes.iconSm),
                            label: Text(
                              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                              style: ctx.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Total duration: $daysCount day${daysCount > 1 ? 's' : ''}',
                      style: ctx.text.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colors.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Justification',
                        hintText: 'e.g. Attending family function / Doctor appointment',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(errorText!, style: ctx.text.bodySmall?.copyWith(color: colors.error)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final reason = reasonController.text.trim();
                              if (reason.isEmpty) {
                                setModalState(() => errorText = 'Please provide a brief reason.');
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final user = AuthService().currentUser!;
                                final req = LeaveRequest(
                                  id: '',
                                  userId: user.uid,
                                  enterpriseId: widget.enterpriseId,
                                  employeeName: employeeName,
                                  employeeId: employeeId,
                                  leaveType: selectedType,
                                  startDate: startDate,
                                  endDate: endDate,
                                  daysCount: daysCount,
                                  reason: reason,
                                  appliedAt: DateTime.now(),
                                );

                                await _leaveService.applyLeave(request: req);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Leave request submitted to Administrator!'),
                                      backgroundColor: status.success.color,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  errorText = 'Failed to submit: $e';
                                });
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: ctx.colors.onPrimary, strokeWidth: 2))
                          : Text('Submit Leave Request', style: ctx.text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, String selected, ValueChanged<String> onSelected) {
    final isSelected = selected == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not signed in.')));
    }

    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leave & Time-Off',
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnap) {
          final uData = (userSnap.data?.data() as Map<String, dynamic>?) ?? {};
          final empName = uData['fullName'] ?? uData['name'] ?? user.email?.split('@').first ?? 'Employee';
          final empId = uData['employeeId'] ?? 'Unassigned';

          return StreamBuilder<List<LeaveRequest>>(
            stream: _leaveService.getUserLeaveRequests(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppListSkeleton(itemCount: 4);
              }

              final leaves = snapshot.data ?? [];
              final pendingCount = leaves.where((l) => l.status == 'PENDING').length;
              final approvedCount = leaves.where((l) => l.status == 'APPROVED').length;

              final filteredLeaves = leaves.where((l) {
                if (_statusFilter == 'ALL') return true;
                return l.status == _statusFilter;
              }).toList();

              return Column(
                children: [
                  // Summary Banner
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: AppRadius.brLg,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                empName,
                                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainer,
                                borderRadius: AppRadius.brSm,
                              ),
                              child: Text(
                                'ID: $empId',
                                style: context.text.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(context, 'Total Applied', '${leaves.length}'),
                            _buildStatColumn(context, 'Pending', '$pendingCount'),
                            _buildStatColumn(context, 'Approved', '$approvedCount'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Requests (${leaves.length})'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('PENDING', 'Pending ($pendingCount)'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('APPROVED', 'Approved ($approvedCount)'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('REJECTED', 'Declined'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Leave Cards List
                  Expanded(
                    child: filteredLeaves.isEmpty
                        ? Center(
                            child: EmptyStateView(
                              icon: Icons.beach_access_outlined,
                              title: _statusFilter == 'ALL'
                                  ? 'No leave requests submitted yet.'
                                  : 'No $_statusFilter leave requests found.',
                              message: 'Tap the button below to submit a time-off or leave request.',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            itemCount: filteredLeaves.length,
                            itemBuilder: (context, index) {
                              final req = filteredLeaves[index];
                              return _buildLeaveCard(context, req);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snap) {
          final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
          final name = data['fullName'] ?? data['name'] ?? user.email?.split('@').first ?? 'Employee';
          final id = data['employeeId'] ?? 'N/A';

          return FloatingActionButton.extended(
            onPressed: () => _showApplyLeaveSheet(context, name, id),
            icon: const Icon(Icons.add),
            label: const Text('Apply Leave'),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildLeaveCard(BuildContext context, LeaveRequest req) {
    final status = context.status;
    final colors = context.colors;

    StatusTone tone;
    switch (req.status) {
      case 'APPROVED':
        tone = status.success;
        break;
      case 'REJECTED':
        tone = status.danger;
        break;
      case 'PENDING':
      default:
        tone = status.warning;
        break;
    }

    final startStr = "${req.startDate.year}-${req.startDate.month.toString().padLeft(2, '0')}-${req.startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${req.endDate.year}-${req.endDate.month.toString().padLeft(2, '0')}-${req.endDate.day.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      req.leaveTypeDisplay,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusPill(label: req.status, tone: tone),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.date_range_outlined, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    '$startStr  to  $endStr',
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${req.daysCount} day${req.daysCount > 1 ? 's' : ''}',
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: "${req.reason}"',
              style: context.text.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colors.onSurface,
              ),
            ),
            if (req.reviewNotes != null && req.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  'Admin Note: ${req.reviewNotes}',
                  style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/network/network_connection_service.dart';
import '../../../services/database_service.dart';

/// Enterprise Admin Attendance Logs Tab:
/// - Filters by date (Today vs All) and punch type (In vs Out vs All)
/// - Attendance record cards with face confidence, geofence audit, late/OT status
/// - Manual punch entry dialog
/// - PDF report export
class AdminAttendanceLogsTab extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> staff;
  final List<QueryDocumentSnapshot> logs;
  final void Function(List<QueryDocumentSnapshot> logs, {String? employeeFilterName, String? dateRangeTitle}) onOpenPdfPreview;

  const AdminAttendanceLogsTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.staff,
    required this.logs,
    required this.onOpenPdfPreview,
  });

  @override
  State<AdminAttendanceLogsTab> createState() => _AdminAttendanceLogsTabState();
}

class _AdminAttendanceLogsTabState extends State<AdminAttendanceLogsTab> {
  final DatabaseService _dbService = DatabaseService();
  String _filterPunchType = 'ALL'; // 'ALL', 'PUNCH_IN', 'PUNCH_OUT'
  String _dateFilter = 'TODAY'; // 'TODAY', 'ALL'

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final filteredLogs = widget.logs.where((l) {
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
                          onPressed: () => _showManualPunchDialog(widget.staff),
                        ),
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary, size: 17),
                          tooltip: 'Export PDF',
                          onPressed: () => widget.onOpenPdfPreview(
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
                    return _buildLogListTile(doc, widget.staff);
                  },
                ),
        ),
      ],
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
    final notesController = TextEditingController(text: 'Manual entry by Admin');
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
}

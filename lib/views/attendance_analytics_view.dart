import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';

class AttendanceAnalyticsView extends StatefulWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> logs;
  final List<QueryDocumentSnapshot> staff;

  const AttendanceAnalyticsView({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.logs,
    required this.staff,
  });

  @override
  State<AttendanceAnalyticsView> createState() => _AttendanceAnalyticsViewState();
}

class _AttendanceAnalyticsViewState extends State<AttendanceAnalyticsView> {
  int _selectedPeriodDays = 7; // 7 days or 30 days

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: _selectedPeriodDays));

    final periodLogs = widget.logs.where((doc) {
      final ts = (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return ts != null && ts.toDate().isAfter(cutoffDate);
    }).toList();

    final punchIns = periodLogs.where((l) {
      return (l.data() as Map<String, dynamic>)['type'] == 'PUNCH_IN';
    }).toList();

    int onTimeCount = 0;
    int lateCount = 0;
    int totalOvertimeMins = 0;
    final Map<int, int> weekdayOnTime = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final Map<int, int> weekdayLate = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final Map<String, int> deptPunchCount = {};
    final Map<String, int> channelPunchCount = {
      'Mobile Face / Biometric': 0,
      'Hardware Machine (MinMoe/ZKTeco)': 0,
      'Office Kiosk / Wi-Fi': 0,
      'Admin Regularized': 0,
    };

    // Build user ID to Department lookup
    final Map<String, String> userDept = {};
    for (var s in widget.staff) {
      final d = s.data() as Map<String, dynamic>;
      userDept[s.id] = d['department'] ?? 'General';
    }

    for (var p in punchIns) {
      final data = p.data() as Map<String, dynamic>;
      final status = data['punchStatus'] ?? 'ON_TIME';
      final ts = (data['timestamp'] as Timestamp).toDate();
      final uid = data['userId'] ?? '';
      final dept = userDept[uid] ?? 'General';
      final verifiedVia = (data['verifiedVia'] ?? '').toString().toUpperCase();

      deptPunchCount[dept] = (deptPunchCount[dept] ?? 0) + 1;

      if (verifiedVia == 'DEVICE_TERMINAL' || verifiedVia.contains('ISAPI') || verifiedVia.contains('ISUP') || verifiedVia.contains('ZKTECO')) {
        channelPunchCount['Hardware Machine (MinMoe/ZKTeco)'] = (channelPunchCount['Hardware Machine (MinMoe/ZKTeco)'] ?? 0) + 1;
      } else if (verifiedVia == 'FACE_ID' || verifiedVia == 'PHONE_BIOMETRICS' || verifiedVia == 'MOBILE_GPS') {
        channelPunchCount['Mobile Face / Biometric'] = (channelPunchCount['Mobile Face / Biometric'] ?? 0) + 1;
      } else if (verifiedVia == 'OFFICE_WIFI' || verifiedVia == 'KIOSK' || verifiedVia == 'KIOSK_PIN') {
        channelPunchCount['Office Kiosk / Wi-Fi'] = (channelPunchCount['Office Kiosk / Wi-Fi'] ?? 0) + 1;
      } else {
        channelPunchCount['Admin Regularized'] = (channelPunchCount['Admin Regularized'] ?? 0) + 1;
      }

      if (status == 'LATE_ARRIVAL' || (data['lateMinutes'] != null && (data['lateMinutes'] as num) > 0)) {
        lateCount++;
        weekdayLate[ts.weekday] = (weekdayLate[ts.weekday] ?? 0) + 1;
      } else {
        onTimeCount++;
        weekdayOnTime[ts.weekday] = (weekdayOnTime[ts.weekday] ?? 0) + 1;
      }

      if (data['overtimeMinutes'] != null) {
        totalOvertimeMins += (data['overtimeMinutes'] as num).toInt();
      }
    }

    final totalPunches = onTimeCount + lateCount;
    final punctualityRate = totalPunches > 0 ? (onTimeCount / totalPunches * 100).round() : 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Visual Analytics',
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector Chips
            Row(
              children: [
                Text(
                  'Period:',
                  style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('Past 7 Days'),
                  selected: _selectedPeriodDays == 7,
                  selectedColor: context.colors.primary,
                  labelStyle: context.text.labelMedium?.copyWith(
                    color: _selectedPeriodDays == 7 ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedPeriodDays = 7),
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: const Text('Past 30 Days'),
                  selected: _selectedPeriodDays == 30,
                  selectedColor: context.colors.primary,
                  labelStyle: context.text.labelMedium?.copyWith(
                    color: _selectedPeriodDays == 30 ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedPeriodDays = 30),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Punctuality Health Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: punctualityRate / 100.0,
                          strokeWidth: 8,
                          backgroundColor: context.colors.outlineVariant.withValues(alpha: 0.3),
                          color: punctualityRate >= 85
                              ? context.status.success.color
                              : (punctualityRate >= 70 ? context.status.warning.color : context.status.danger.color),
                        ),
                      ),
                      Text(
                        '$punctualityRate%',
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punctuality Score',
                          style: context.text.titleMedium?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$onTimeCount on-time • $lateCount late arrivals',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Overtime: ${totalOvertimeMins ~/ 60}h ${totalOvertimeMins % 60}m',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weekly Trend Bar Chart
            const SectionHeader(
              icon: Icons.calendar_view_week,
              title: 'Weekly Day-by-Day Punctuality',
              subtitle: 'Green represents on-time arrivals, Amber represents late arrivals.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildDayRow('Mon', weekdayOnTime[1] ?? 0, weekdayLate[1] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Tue', weekdayOnTime[2] ?? 0, weekdayLate[2] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Wed', weekdayOnTime[3] ?? 0, weekdayLate[3] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Thu', weekdayOnTime[4] ?? 0, weekdayLate[4] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Fri', weekdayOnTime[5] ?? 0, weekdayLate[5] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Sat', weekdayOnTime[6] ?? 0, weekdayLate[6] ?? 0),
                  const Divider(height: AppSpacing.md),
                  _buildDayRow('Sun', weekdayOnTime[7] ?? 0, weekdayLate[7] ?? 0),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Department Attendance Distribution
            const SectionHeader(
              icon: Icons.business,
              title: 'Department Punch Volume',
              subtitle: 'Relative breakdown of punches per registered department.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: deptPunchCount.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.bar_chart_outlined,
                      title: 'No Punch Data',
                      message: 'No attendance punches recorded in this period.',
                    )
                  : Column(
                      children: deptPunchCount.entries.map((entry) {
                        final maxVal = deptPunchCount.values.reduce((a, b) => a > b ? a : b);
                        final fraction = maxVal > 0 ? entry.value / maxVal : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${entry.value} punches',
                                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 8,
                                  backgroundColor: context.colors.surfaceContainerHighest,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Verification & Terminal Channel Distribution
            const SectionHeader(
              icon: Icons.fingerprint,
              title: 'Verification Channel & Hardware Machines',
              subtitle: 'Attendance source distribution across registered capture channels.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                children: channelPunchCount.entries.map((entry) {
                  final totalChannelPunches = channelPunchCount.values.fold(0, (a, b) => a + b);
                  final fraction = totalChannelPunches > 0 ? entry.value / totalChannelPunches : 0.0;
                  final percentage = totalChannelPunches > 0 ? (fraction * 100).round() : 0;

                  Color barColor = context.colors.primary;
                  if (entry.key.contains('Hardware')) {
                    barColor = context.colors.tertiary;
                  } else if (entry.key.contains('Mobile')) {
                    barColor = context.status.success.color;
                  } else if (entry.key.contains('Kiosk')) {
                    barColor = context.colors.primary;
                  } else {
                    barColor = context.status.warning.color;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                entry.key,
                                style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${entry.value} ($percentage%)',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: context.colors.surfaceContainerHighest,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String day, int onTime, int late) {
    final total = onTime + late;
    const maxReference = 10;
    final onTimeWidth = total > 0 ? (onTime / (total > maxReference ? total : maxReference)) : 0.0;
    final lateWidth = total > 0 ? (late / (total > maxReference ? total : maxReference)) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            day,
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Container(
              height: 14,
              color: context.colors.surfaceContainerHighest,
              child: Row(
                children: [
                  if (onTime > 0)
                    Flexible(
                      flex: (onTimeWidth * 100).toInt().clamp(1, 100),
                      child: Container(color: context.status.success.color),
                    ),
                  if (late > 0)
                    Flexible(
                      flex: (lateWidth * 100).toInt().clamp(1, 100),
                      child: Container(color: context.status.warning.color),
                    ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 60,
          child: Text(
            total > 0 ? '$onTime / $late' : '-',
            textAlign: TextAlign.end,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

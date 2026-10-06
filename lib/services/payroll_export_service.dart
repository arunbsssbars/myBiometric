import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import '../views/pdf_timesheet_preview_screen.dart';
import 'break_tracking_service.dart';

class PayrollEmployeeSummary {
  final String userId;
  final String employeeId;
  final String fullName;
  final String department;
  int daysPresent = 0;
  int fullDaysCount = 0;
  int halfDaysCount = 0;
  int lateDaysCount = 0;
  int earlyDepartureCount = 0;
  int totalWorkMinutes = 0;
  int totalOvertimeMinutes = 0;
  int totalBreakMinutes = 0;
  int unpaidBreakMinutes = 0;
  int paidBreakMinutes = 0;

  PayrollEmployeeSummary({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.department,
    this.totalBreakMinutes = 0,
    this.unpaidBreakMinutes = 0,
    this.paidBreakMinutes = 0,
  });

  /// Net work minutes after unpaid break deductions (or totalWorkMinutes if no unpaid breaks recorded)
  int get netWorkMinutes {
    final net = totalWorkMinutes - unpaidBreakMinutes;
    return net > 0 ? net : 0;
  }

  double get payableHours => (unpaidBreakMinutes > 0 ? netWorkMinutes : totalWorkMinutes) / 60.0;
  double get grossHours => totalWorkMinutes / 60.0;
  double get unpaidBreakHours => unpaidBreakMinutes / 60.0;
  double get paidBreakHours => paidBreakMinutes / 60.0;
  double get totalBreakHours => totalBreakMinutes / 60.0;
  double get overtimeHours => totalOvertimeMinutes / 60.0;
}

class PayrollExportService {
  /// Generate aggregated payroll summary records for each staff member across logs
  static List<PayrollEmployeeSummary> generatePayrollSummary({
    required List<QueryDocumentSnapshot> logs,
    required List<QueryDocumentSnapshot> staff,
  }) {
    return generatePayrollSummaryFromMaps(
      logs: logs.map((l) => l.data() as Map<String, dynamic>).toList(),
      staff: staff.map((s) {
        final m = Map<String, dynamic>.from(s.data() as Map);
        m['id'] = s.id;
        return m;
      }).toList(),
    );
  }

  /// Generate aggregated payroll summary records from raw data maps (for offline use, export caches, or testing)
  static List<PayrollEmployeeSummary> generatePayrollSummaryFromMaps({
    required List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> staff = const [],
  }) {
    final Map<String, PayrollEmployeeSummary> summaries = {};

    // 1. Initialize summary for all staff
    for (var s in staff) {
      final name = s['fullName'] ?? s['name'] ?? 'Staff Member';
      final empId = s['employeeId'] ?? 'N/A';
      final dept = s['department'] ?? 'General';
      final id = (s['id'] ?? s['uid'] ?? empId) as String;
      summaries[id] = PayrollEmployeeSummary(
        userId: id,
        employeeId: empId,
        fullName: name,
        department: dept,
      );
    }

    // 2. Track unique days worked per user and group daily logs for break tracking
    final Map<String, Set<String>> userDays = {};
    final Map<String, Map<String, List<Map<String, dynamic>>>> userDayLogs = {};

    for (var data in logs) {
      final uid = data['userId'] as String? ?? '';
      if (!summaries.containsKey(uid)) {
        // Unknown user fallback
        final name = data['employeeName'] ?? 'Employee';
        final empId = data['employeeId'] ?? 'N/A';
        summaries[uid] = PayrollEmployeeSummary(
          userId: uid,
          employeeId: empId,
          fullName: name,
          department: 'General',
        );
      }

      final summary = summaries[uid]!;
      final rawTs = data['timestamp'];
      DateTime? ts;
      if (rawTs is Timestamp) {
        ts = rawTs.toDate();
      } else if (rawTs is DateTime) {
        ts = rawTs;
      } else if (rawTs is String) {
        ts = DateTime.tryParse(rawTs);
      }

      if (ts != null) {
        final dayKey = '${ts.year}-${ts.month}-${ts.day}';
        userDays.putIfAbsent(uid, () => <String>{}).add(dayKey);
        userDayLogs.putIfAbsent(uid, () => <String, List<Map<String, dynamic>>>{});
        userDayLogs[uid]!.putIfAbsent(dayKey, () => <Map<String, dynamic>>[]).add(data);
      }

      // Check punch status
      final pStatus = data['punchStatus'] as String?;
      if (pStatus == 'LATE_ARRIVAL' || (data['lateMinutes'] != null && (data['lateMinutes'] as num) > 0)) {
        summary.lateDaysCount++;
      }
      if (pStatus == 'EARLY_DEPARTURE' || (data['earlyMinutes'] != null && (data['earlyMinutes'] as num) > 0)) {
        summary.earlyDepartureCount++;
      }

      // Overtime
      if (data['overtimeMinutes'] != null) {
        summary.totalOvertimeMinutes += (data['overtimeMinutes'] as num).toInt();
      }

      // Shift duration
      if (data['shiftDurationMinutes'] != null) {
        final mins = (data['shiftDurationMinutes'] as num).toInt();
        summary.totalWorkMinutes += mins;
      }

      // Full / Half Day
      final workStatus = data['workStatus'] as String?;
      if (workStatus == 'FULL_DAY') {
        summary.fullDaysCount++;
      } else if (workStatus == 'HALF_DAY') {
        summary.halfDaysCount++;
      } else if (workStatus == null && data['shiftDurationMinutes'] != null) {
        final mins = (data['shiftDurationMinutes'] as num).toInt();
        if (mins >= 480) {
          summary.fullDaysCount++;
        } else if (mins >= 240) {
          summary.halfDaysCount++;
        }
      }
    }

    // Assign days present
    userDays.forEach((uid, days) {
      if (summaries.containsKey(uid)) {
        summaries[uid]!.daysPresent = days.length;
      }
    });

    // 3. Calculate break deductions and Jibble-grade session evaluations
    userDayLogs.forEach((uid, daysMap) {
      final summary = summaries[uid];
      if (summary == null) return;
      daysMap.forEach((dayKey, dayLogs) {
        final hasBreakEvents = dayLogs.any((l) {
          final t = l['type'];
          return t == 'START_BREAK' || t == 'END_BREAK';
        });
        if (hasBreakEvents) {
          final session = EmployeeDailySession.evaluate(
            userId: uid,
            employeeName: summary.fullName,
            employeeId: summary.employeeId,
            department: summary.department,
            employeeLogsToday: dayLogs,
          );
          summary.unpaidBreakMinutes += session.unpaidBreakDuration.inMinutes;
          summary.paidBreakMinutes += session.paidBreakDuration.inMinutes;
          summary.totalBreakMinutes += session.totalBreakDuration.inMinutes;
        }
      });
    });

    final list = summaries.values.toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  /// Generate detailed CSV with explicit Gross, Unpaid Breaks, and Net Work columns
  static String generateDetailedPayrollCsv(List<PayrollEmployeeSummary> summaries, {String periodTitle = ''}) {
    final buffer = StringBuffer();
    if (periodTitle.isNotEmpty) {
      buffer.writeln('# Detailed Payroll Timesheet Export - $periodTitle');
    }
    buffer.writeln(
      'Employee ID,Full Name,Department,Days Present,Full Days,Half Days,Late Arrivals,Early Departures,Gross Minutes,Gross Hours,Unpaid Breaks (Mins),Unpaid Breaks (Hours),Paid Breaks (Mins),Net Work (Mins),Payable Hours,Overtime (Mins),Overtime Hours',
    );

    for (var s in summaries) {
      buffer.writeln(
        '"${s.employeeId}","${s.fullName}","${s.department}",${s.daysPresent},${s.fullDaysCount},${s.halfDaysCount},${s.lateDaysCount},${s.earlyDepartureCount},${s.totalWorkMinutes},${s.grossHours.toStringAsFixed(2)},${s.unpaidBreakMinutes},${s.unpaidBreakHours.toStringAsFixed(2)},${s.paidBreakMinutes},${s.netWorkMinutes},${s.payableHours.toStringAsFixed(2)},${s.totalOvertimeMinutes},${s.overtimeHours.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Generate CSV string suitable for Microsoft Excel or Google Sheets
  static String generatePayrollCsv(List<PayrollEmployeeSummary> summaries, {String periodTitle = ''}) {
    final buffer = StringBuffer();
    if (periodTitle.isNotEmpty) {
      buffer.writeln('# Payroll Timesheet Export - $periodTitle');
    }
    buffer.writeln(
      'Employee ID,Full Name,Department,Days Present,Full Days,Half Days,Late Arrivals,Early Departures,Total Work (Mins),Payable Hours,Overtime (Mins),Overtime Hours',
    );

    for (var s in summaries) {
      buffer.writeln(
        '"${s.employeeId}","${s.fullName}","${s.department}",${s.daysPresent},${s.fullDaysCount},${s.halfDaysCount},${s.lateDaysCount},${s.earlyDepartureCount},${s.totalWorkMinutes},${s.payableHours.toStringAsFixed(2)},${s.totalOvertimeMinutes},${s.overtimeHours.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Display a modal dialog to preview, filter, copy, or export the payroll timesheet as CSV or PDF
  static void showExportDialog(
    BuildContext context, {
    required List<QueryDocumentSnapshot> logs,
    required List<QueryDocumentSnapshot> staff,
    String periodTitle = 'Current Period',
    String enterpriseId = '',
  }) {
    String selectedRange = 'All Time';
    DateTimeRange? customRange;
    String selectedDept = 'All Departments';

    final Set<String> depts = {'All Departments'};
    for (var s in staff) {
      final d = s.data() as Map<String, dynamic>;
      final dept = (d['department'] as String?)?.trim();
      if (dept != null && dept.isNotEmpty) {
        depts.add(dept);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final now = DateTime.now();

          // 1. Filter logs by date range
          final filteredLogs = logs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime? ts;
            final rawTs = data['timestamp'];
            if (rawTs is Timestamp) {
              ts = rawTs.toDate();
            } else if (rawTs is String) {
              ts = DateTime.tryParse(rawTs);
            }
            if (ts == null) return true;

            switch (selectedRange) {
              case 'Today':
                return ts.year == now.year && ts.month == now.month && ts.day == now.day;
              case 'Last 7 Days':
                final sevenDaysAgo = now.subtract(const Duration(days: 7));
                return ts.isAfter(sevenDaysAgo);
              case 'This Month':
                return ts.year == now.year && ts.month == now.month;
              case 'Custom':
                if (customRange == null) return true;
                final start = DateTime(customRange!.start.year, customRange!.start.month, customRange!.start.day);
                final end = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day, 23, 59, 59);
                return ts.isAfter(start.subtract(const Duration(seconds: 1))) &&
                    ts.isBefore(end.add(const Duration(seconds: 1)));
              case 'All Time':
              default:
                return true;
            }
          }).toList();

          // 2. Filter staff by department
          final filteredStaff = selectedDept == 'All Departments'
              ? staff
              : staff.where((s) {
                  final d = s.data() as Map<String, dynamic>;
                  return (d['department'] as String?)?.trim() == selectedDept;
                }).toList();

          // 3. Filter logs by staff department if dept selected
          final staffIds = filteredStaff.map((s) => s.id).toSet();
          final effectiveLogs = selectedDept == 'All Departments'
              ? filteredLogs
              : filteredLogs.where((l) {
                  final data = l.data() as Map<String, dynamic>;
                  return staffIds.contains(data['userId']);
                }).toList();

          final summaries = generatePayrollSummary(logs: effectiveLogs, staff: filteredStaff);
          final activeDateLabel = selectedRange == 'Custom' && customRange != null
              ? '${customRange!.start.day}/${customRange!.start.month} - ${customRange!.end.day}/${customRange!.end.month}'
              : selectedRange;
          final exportTitle = '$periodTitle ($activeDateLabel - $selectedDept)';
          final csvContent = generatePayrollCsv(summaries, periodTitle: exportTitle);

          final totalPayable = summaries.fold<double>(0.0, (acc, s) => acc + s.payableHours);
          final totalOt = summaries.fold<double>(0.0, (acc, s) => acc + s.overtimeHours);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.table_chart_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Timesheet & Payroll Export',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Filter Chips
                    const Text('Date Range Filter:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['All Time', 'Today', 'Last 7 Days', 'This Month', 'Custom'].map((preset) {
                        final isSelected = selectedRange == preset;
                        return ChoiceChip(
                          label: Text(
                            preset == 'Custom' && customRange != null
                                ? '${customRange!.start.day}/${customRange!.start.month} - ${customRange!.end.day}/${customRange!.end.month}'
                                : preset,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          onSelected: (val) async {
                            if (!val) return;
                            if (preset == 'Custom') {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                initialDateRange: customRange ??
                                    DateTimeRange(
                                      start: DateTime.now().subtract(const Duration(days: 30)),
                                      end: DateTime.now(),
                                    ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedRange = 'Custom';
                                  customRange = picked;
                                });
                              }
                            } else {
                              setModalState(() {
                                selectedRange = preset;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Department Filter Dropdown
                    Row(
                      children: [
                        const Text('Department: ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDept,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) => setModalState(() => selectedDept = val ?? 'All Departments'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Metrics Summary Cards
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricColumn('Staff', '${summaries.length}'),
                          _buildMetricColumn('Punches', '${effectiveLogs.length}'),
                          _buildMetricColumn('Payable Hrs', totalPayable.toStringAsFixed(1)),
                          if (summaries.any((s) => s.unpaidBreakMinutes > 0))
                            _buildMetricColumn('Breaks', '${(summaries.fold<int>(0, (acc, s) => acc + s.unpaidBreakMinutes) / 60.0).toStringAsFixed(1)}h'),
                          _buildMetricColumn('OT Hrs', totalOt.toStringAsFixed(1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CSV Monospace Preview
                    Container(
                      height: 120,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          csvContent,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFF2563EB)),
                label: const Text('PDF Report', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfTimesheetPreviewScreen(
                        enterpriseId: enterpriseId.isNotEmpty ? enterpriseId : 'ENT',
                        companyName: periodTitle,
                        logs: effectiveLogs,
                        dateRangeTitle: activeDateLabel,
                      ),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded, size: 15),
                label: const Text('Share CSV', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final bytes = Uint8List.fromList(utf8.encode(csvContent));
                  final filename = 'Timesheet_${activeDateLabel.replaceAll('/', '-').replaceAll(' ', '_')}.csv';
                  await Printing.sharePdf(bytes: bytes, filename: filename);
                },
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy CSV', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csvContent));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payroll CSV copied to clipboard! Paste directly into Excel.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }
}

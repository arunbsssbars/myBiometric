import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for generating professional, printable PDF attendance timesheets and MIS reports.
class PdfTimesheetService {
  static final PdfTimesheetService _instance = PdfTimesheetService._internal();
  factory PdfTimesheetService() => _instance;
  PdfTimesheetService._internal();

  /// Build a multi-page PDF document containing company header, KPI summary, and itemized logs
  Future<Uint8List> generateTimesheetPdf({
    required String enterpriseId,
    required String companyName,
    required List<QueryDocumentSnapshot> logs,
    String? employeeFilterName,
    String? dateRangeTitle,
  }) async {
    final pdf = pw.Document();

    // 1. Calculate Summary KPIs
    int totalPunches = logs.length;
    int punchIns = 0;
    int punchOuts = 0;
    int breaksCount = 0;
    int onTimeCount = 0;
    int lateCount = 0;
    int lateMinutesTotal = 0;
    int overtimeCount = 0;
    int overtimeMinutesTotal = 0;
    int geofenceBreaches = 0;
    int totalDurationMinutes = 0;

    for (final doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final punchStatus = data['punchStatus'] as String? ?? '';
      final lateM = data['lateMinutes'] as int? ?? 0;
      final otM = data['overtimeMinutes'] as int? ?? 0;
      final dur = data['shiftDurationMinutes'] as int? ?? 0;
      final withinGeo = data['withinGeofence'] as bool?;

      if (type == 'PUNCH_IN') {
        punchIns++;
        if (punchStatus == 'ON_TIME') onTimeCount++;
      } else if (type == 'PUNCH_OUT') {
        punchOuts++;
      } else if (type == 'START_BREAK') {
        breaksCount++;
      }
      if (punchStatus == 'LATE_ARRIVAL' || lateM > 0) {
        lateCount++;
        lateMinutesTotal += lateM;
      }
      if (punchStatus == 'OVERTIME' || otM > 0) {
        overtimeCount++;
        overtimeMinutesTotal += otM;
      }
      if (withinGeo == false) {
        geofenceBreaches++;
      }
      totalDurationMinutes += dur;
    }

    final totalHoursWorked = (totalDurationMinutes / 60).toStringAsFixed(1);
    final onTimePercentage =
        punchIns > 0 ? ((onTimeCount / punchIns) * 100).toStringAsFixed(1) : '100.0';

    final now = DateTime.now();
    final generatedDateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Theme Colors
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // Deep Navy
    const secondaryColor = PdfColor.fromInt(0xFF2563EB); // Royal Blue
    const lightGrey = PdfColor.fromInt(0xFFF1F5F9);
    const borderGrey = PdfColor.fromInt(0xFFE2E8F0);
    const textDark = PdfColor.fromInt(0xFF0F172A);
    const textMuted = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: borderGrey, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName.isNotEmpty ? companyName : enterpriseId,
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Enterprise Code: $enterpriseId',
                      style: const pw.TextStyle(color: textMuted, fontSize: 10),
                    ),
                    if (employeeFilterName != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Employee: $employeeFilterName',
                        style: pw.TextStyle(color: secondaryColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ATTENDANCE TIMESHEET & MIS',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Period: ${dateRangeTitle ?? "All Recorded Logs"}',
                      style: const pw.TextStyle(color: textMuted, fontSize: 9),
                    ),
                    pw.Text(
                      'Generated: $generatedDateStr',
                      style: const pw.TextStyle(color: textMuted, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'myBiometric Automated Enterprise Attendance System',
                  style: const pw.TextStyle(color: textMuted, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: textMuted, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Cards
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryKpi('Punches (In/Out)', '$totalPunches ($punchIns/$punchOuts)', primaryColor),
                  _buildSummaryKpi('Work Hours', '${totalHoursWorked}h', primaryColor),
                  if (breaksCount > 0)
                    _buildSummaryKpi('Breaks', '$breaksCount', const PdfColor.fromInt(0xFFD97706)),
                  _buildSummaryKpi('On-Time %', '$onTimePercentage%', const PdfColor.fromInt(0xFF10B981)),
                  _buildSummaryKpi('Late Arrivals', '$lateCount (${lateMinutesTotal}m)', const PdfColor.fromInt(0xFFF59E0B)),
                  _buildSummaryKpi('Overtime', '$overtimeCount (${overtimeMinutesTotal}m)', const PdfColor.fromInt(0xFF8B5CF6)),
                  _buildSummaryKpi('Geofence Alert', '$geofenceBreaches', const PdfColor.fromInt(0xFFEF4444)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Itemized Logs Table
            pw.Text(
              'Itemized Attendance Records (${logs.length} logs)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDark),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: textDark),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              headers: [
                'Date & Time',
                'Employee Name (ID)',
                'Punch',
                'Method',
                'Shift Intelligence Status',
                'Duration',
                'Geofence',
              ],
              data: logs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = (d['timestamp'] as Timestamp?)?.toDate();
                final dateStr = ts != null
                    ? "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}"
                    : '-';

                final empName = d['employeeName'] as String? ?? 'Employee';
                final empId = d['employeeId'] as String? ?? d['userId']?.toString().substring(0, 5) ?? '';
                final rawType = d['type'] as String? ?? '-';
                final breakType = d['breakType'] as String?;
                String punchType = rawType;
                if (rawType == 'START_BREAK') {
                  punchType = breakType != null ? 'START BREAK\n($breakType)' : 'START BREAK';
                } else if (rawType == 'END_BREAK') {
                  punchType = 'END BREAK';
                }
                final rawMethod = d['verifiedVia'] as String? ?? 'FACE_ID';
                String method = rawMethod;
                if (rawMethod == 'DEVICE_TERMINAL') {
                  final tName = d['terminalName'] as String?;
                  final tModel = d['terminalModel'] as String?;
                  method = tName != null ? 'Terminal\n($tName)' : (tModel != null ? 'Terminal\n($tModel)' : 'MinMoe Terminal');
                }

                // Shift tags
                final pStatus = d['punchStatus'] as String?;
                final lateM = d['lateMinutes'] as int? ?? 0;
                final otM = d['overtimeMinutes'] as int? ?? 0;
                String shiftLabel = 'Regular';
                if (pStatus == 'ON_TIME') shiftLabel = 'On Time';
                if (pStatus == 'LATE_ARRIVAL' || lateM > 0) shiftLabel = 'Late (${lateM}m)';
                if (pStatus == 'EARLY_DEPARTURE') shiftLabel = 'Early Departure';
                if (pStatus == 'OVERTIME' || otM > 0) shiftLabel = 'Overtime (+${otM}m)';

                final durM = d['shiftDurationMinutes'] as int?;
                final durStr = durM != null ? '${durM ~/ 60}h ${durM % 60}m' : '-';

                final geo = d['withinGeofence'] as bool?;
                final geoStr = geo == null ? '-' : (geo ? 'Inside' : 'Outside Perimeter');

                return [
                  dateStr,
                  '$empName\n($empId)',
                  punchType,
                  method,
                  shiftLabel,
                  durStr,
                  geoStr,
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 24),

            // Sign-off / Verification section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        'Employee Signature / Acknowledgment',
                        style: const pw.TextStyle(fontSize: 8, color: textMuted),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        'HR / Authorized Enterprise Sign-off',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 8, color: textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryKpi(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColor.fromInt(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// Direct quick share or print
  Future<void> printOrShareTimesheet({
    required String enterpriseId,
    required String companyName,
    required List<QueryDocumentSnapshot> logs,
    String? employeeFilterName,
  }) async {
    final pdfBytes = await generateTimesheetPdf(
      enterpriseId: enterpriseId,
      companyName: companyName,
      logs: logs,
      employeeFilterName: employeeFilterName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Timesheet_${enterpriseId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}

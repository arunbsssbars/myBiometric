import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/pdf_timesheet_service.dart';

class PdfTimesheetPreviewScreen extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final List<QueryDocumentSnapshot> logs;
  final String? employeeFilterName;
  final String? dateRangeTitle;

  const PdfTimesheetPreviewScreen({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.logs,
    this.employeeFilterName,
    this.dateRangeTitle,
  });

  @override
  Widget build(BuildContext context) {
    final title = employeeFilterName != null
        ? '$employeeFilterName - Timesheet'
        : 'Enterprise Attendance Timesheet';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () async {
              final bytes = await PdfTimesheetService().generateTimesheetPdf(
                enterpriseId: enterpriseId,
                companyName: companyName,
                logs: logs,
                employeeFilterName: employeeFilterName,
                dateRangeTitle: dateRangeTitle,
              );
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'Timesheet_${enterpriseId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        maxPageWidth: 700,
        pdfFileName: 'Timesheet_$enterpriseId.pdf',
        build: (format) => PdfTimesheetService().generateTimesheetPdf(
          enterpriseId: enterpriseId,
          companyName: companyName,
          logs: logs,
          employeeFilterName: employeeFilterName,
          dateRangeTitle: dateRangeTitle,
        ),
      ),
    );
  }
}

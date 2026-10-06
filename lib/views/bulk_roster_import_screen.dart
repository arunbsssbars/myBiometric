import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/models/bulk_roster_import.dart';
import '../services/bulk_roster_service.dart';
import '../core/design_system/design_system.dart';
import 'bulk_roster_card.dart';

class BulkRosterImportScreen extends StatefulWidget {
  final String enterpriseId;

  const BulkRosterImportScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  State<BulkRosterImportScreen> createState() => _BulkRosterImportScreenState();
}

class _BulkRosterImportScreenState extends State<BulkRosterImportScreen> {
  final TextEditingController _csvController = TextEditingController();
  late final BulkRosterService _rosterService;
  BulkImportResult? _importResult;
  bool _isImporting = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _rosterService = BulkRosterService();
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _loadSampleTemplate() {
    setState(() {
      _csvController.text = BulkRosterService.generateCsvTemplate();
      _importResult = null;
    });
  }

  void _copyTemplateToClipboard() {
    Clipboard.setData(ClipboardData(text: BulkRosterService.generateCsvTemplate()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standard CSV template copied to clipboard!')),
    );
  }

  Future<void> _validateCsv() async {
    final text = _csvController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste or enter CSV data first.')),
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      // Fetch existing employee IDs and emails for duplication check
      final existingDocs = await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(widget.enterpriseId)
          .collection('employees')
          .get();

      final existingIds = <String>{};
      final existingEmails = <String>{};

      for (final doc in existingDocs.docs) {
        final data = doc.data();
        final id = data['employeeId']?.toString();
        final email = data['email']?.toString();
        if (id != null && id.isNotEmpty) existingIds.add(id);
        if (email != null && email.isNotEmpty) existingEmails.add(email);
      }

      final result = _rosterService.parseCsvContent(
        text,
        existingEmployeeIds: existingIds,
        existingEmails: existingEmails,
      );

      setState(() {
        _importResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error validating CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _executeImport() async {
    if (_importResult == null || !_importResult!.canImport) return;

    final messenger = ScaffoldMessenger.of(context);
    final validRecords = _importResult!.validRecords;

    setState(() => _isImporting = true);

    try {
      final importedCount = await _rosterService.executeBatchImport(
        widget.enterpriseId,
        validRecords,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: context.status.success.color, size: 28),
                const SizedBox(width: 8),
                const Expanded(child: Text('Onboarding Complete')),
              ],
            ),
            content: Text(
              'Successfully enrolled $importedCount new staff members into organization roster.',
              style: context.text.bodyMedium,
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // return to dashboard
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bulk Staff Onboarding',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_rounded),
            tooltip: 'Copy Template',
            onPressed: _copyTemplateToClipboard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Instructions Banner
          Card(
            elevation: 0,
            color: context.status.info.container,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.status.info.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: context.status.info.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CSV Format Requirements',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.status.info.onContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Columns: Full Name, Employee ID, Email, Role, Department, Branch ID, Assigned Shift\nRoles supported: employee, manager, supervisor, admin.',
                    style: context.text.bodySmall?.copyWith(color: context.status.info.onContainer),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.download_rounded, size: 16),
                        label: Text('Load Sample Data', style: context.text.labelSmall),
                        onPressed: _loadSampleTemplate,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.copy_rounded, size: 16),
                        label: Text('Copy CSV Template', style: context.text.labelSmall),
                        onPressed: _copyTemplateToClipboard,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // CSV Input Area
          Text(
            'Paste CSV Content',
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _csvController,
            maxLines: 6,
            style: context.text.bodySmall?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Full Name,Employee ID,Email,Role,Department,Branch ID,Assigned Shift\n...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Validate Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              icon: _isValidating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.fact_check_outlined),
              label: const Text('Validate & Parse Roster'),
              onPressed: _isValidating || _isImporting ? null : _validateCsv,
            ),
          ),

          // Validation Results Feed
          if (_importResult != null) ...[
            const SizedBox(height: 20),
            BulkRosterSummaryBar(result: _importResult!),
            const SizedBox(height: 12),
            Text(
              'Parsed Records Preview (${_importResult!.records.length})',
              style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._importResult!.records.map((record) => BulkRosterRecordCard(record: record)),
            const SizedBox(height: 20),

            // Execute Import Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: _isImporting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: context.colors.onPrimary, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isImporting
                      ? 'Enrolling Staff...'
                      : 'Enroll ${_importResult!.validCount} Valid Employee${_importResult!.validCount == 1 ? "" : "s"}',
                ),
                onPressed: _isImporting || !_importResult!.canImport ? null : _executeImport,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


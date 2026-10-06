import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../domain/models/labor_compliance_policy.dart';
import '../services/compliance_audit_service.dart';
import '../core/design_system/design_system.dart';
import 'compliance_audit_card.dart';

class ComplianceAuditScreen extends StatefulWidget {
  final String enterpriseId;

  const ComplianceAuditScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  State<ComplianceAuditScreen> createState() => _ComplianceAuditScreenState();
}

class _ComplianceAuditScreenState extends State<ComplianceAuditScreen> {
  late final ComplianceAuditService _auditService;
  ComplianceSeverity? _selectedSeverityFilter;

  @override
  void initState() {
    super.initState();
    _auditService = ComplianceAuditService();
  }

  void _openPolicySettingsSheet(LaborCompliancePolicy currentPolicy) {
    double minRest = currentPolicy.minRestHoursBetweenShifts;
    int maxConsec = currentPolicy.maxConsecutiveWorkdays;
    double maxWeekly = currentPolicy.maxWeeklyWorkHours;
    double maxDaily = currentPolicy.maxDailyWorkHours;
    bool enforced = currentPolicy.isEnforced;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Labor & Statutory Policy',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure enterprise statutory limits for rest periods, consecutive workdays, and maximum hours.',
                      style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enforce Compliance Engine'),
                      subtitle: const Text('Actively audit and flag non-compliant shifts'),
                      value: enforced,
                      onChanged: (val) {
                        setModalState(() => enforced = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Min Rest Between Shifts: ${minRest.toStringAsFixed(1)} hours',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: minRest,
                      min: 8.0,
                      max: 16.0,
                      divisions: 16,
                      label: '${minRest.toStringAsFixed(1)}h',
                      onChanged: enforced
                          ? (val) {
                              setModalState(() => minRest = val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Max Consecutive Workdays: $maxConsec days',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: maxConsec.toDouble(),
                      min: 4.0,
                      max: 12.0,
                      divisions: 8,
                      label: '$maxConsec days',
                      onChanged: enforced
                          ? (val) {
                              setModalState(() => maxConsec = val.toInt());
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Max Weekly Hours: ${maxWeekly.toStringAsFixed(0)} hours',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: maxWeekly,
                      min: 30.0,
                      max: 60.0,
                      divisions: 30,
                      label: '${maxWeekly.toStringAsFixed(0)}h',
                      onChanged: enforced
                          ? (val) {
                              setModalState(() => maxWeekly = val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Max Daily Work Hours: ${maxDaily.toStringAsFixed(1)} hours',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: maxDaily,
                      min: 8.0,
                      max: 16.0,
                      divisions: 16,
                      label: '${maxDaily.toStringAsFixed(1)}h',
                      onChanged: enforced
                          ? (val) {
                              setModalState(() => maxDaily = val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Compliance Settings'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final updated = currentPolicy.copyWith(
                            minRestHoursBetweenShifts: minRest,
                            maxConsecutiveWorkdays: maxConsec,
                            maxWeeklyWorkHours: maxWeekly,
                            maxDailyWorkHours: maxDaily,
                            isEnforced: enforced,
                            updatedAt: DateTime.now(),
                          );
                          Navigator.pop(ctx);
                          try {
                            await _auditService.saveLaborCompliancePolicy(widget.enterpriseId, updated);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Labor policy updated successfully')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to update policy: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Labor & Rest Compliance',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<LaborCompliancePolicy>(
        stream: _auditService.streamLaborCompliancePolicy(widget.enterpriseId),
        builder: (context, policySnap) {
          final policy = policySnap.data ?? LaborCompliancePolicy.defaultPolicy();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('enterprises')
                .doc(widget.enterpriseId)
                .collection('employees')
                .snapshots(),
            builder: (context, rosterSnap) {
              final rosterDocs = rosterSnap.data?.docs ?? [];
              final roster = rosterDocs
                  .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enterprises')
                    .doc(widget.enterpriseId)
                    .collection('attendance_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(300)
                    .snapshots(),
                builder: (context, logsSnap) {
                  final logDocs = logsSnap.data?.docs ?? [];
                  final logs = logDocs
                      .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                      .toList();

                  final report = _auditService.auditCompliance(
                    roster: roster,
                    logs: logs,
                    policy: policy,
                  );

                  final filteredIncidents = _selectedSeverityFilter == null
                      ? report.incidents
                      : report.incidents.where((i) => i.severity == _selectedSeverityFilter).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ComplianceAuditScoreCard(
                        report: report,
                        policy: policy,
                        onConfigurePolicy: () => _openPolicySettingsSheet(policy),
                      ),
                      const SizedBox(height: 16),
                      _buildFiltersRow(context, report),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Incident Feed (${filteredIncidents.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Policy Rules'),
                            onPressed: () => _openPolicySettingsSheet(policy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (filteredIncidents.isEmpty)
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 48,
                                  color: context.status.success.color,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '100% Labor Standard Compliant',
                                  style: context.text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No rest period, consecutive shift, or excessive hour violations detected.',
                                  textAlign: TextAlign.center,
                                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredIncidents.map((incident) => ComplianceIncidentCard(incident: incident)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, ComplianceAuditReport report) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text('All (${report.incidents.length})'),
            selected: _selectedSeverityFilter == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedSeverityFilter = null);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Violations (${report.totalViolations})'),
            selected: _selectedSeverityFilter == ComplianceSeverity.violation,
            selectedColor: context.status.danger.color.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _selectedSeverityFilter = selected ? ComplianceSeverity.violation : null;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Warnings (${report.totalWarnings})'),
            selected: _selectedSeverityFilter == ComplianceSeverity.warning,
            selectedColor: context.status.warning.color.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _selectedSeverityFilter = selected ? ComplianceSeverity.warning : null;
              });
            },
          ),
        ],
      ),
    );
  }
}


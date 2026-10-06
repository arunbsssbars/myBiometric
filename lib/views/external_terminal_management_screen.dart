import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../services/biometric_device_manager_service.dart';
import '../services/terminal_user_sync_service.dart';
import 'terminal_device_card.dart';
import 'terminal_fleet_topology_view.dart';
import 'terminal_diagnostic_sheet.dart';
import 'terminal_biometric_template_sheet.dart';
import 'terminal_remote_control_sheet.dart';

/// Enterprise External Biometric Machines & Hardware Terminals Management Screen.
/// Supports Hikvision MinMoe (DS-K1T343EFWX, DS-K1T343MWX), ZKTeco, and Push SDK bridges.
class ExternalTerminalManagementScreen extends StatefulWidget {
  final String enterpriseId;

  const ExternalTerminalManagementScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  State<ExternalTerminalManagementScreen> createState() => _ExternalTerminalManagementScreenState();
}

class _ExternalTerminalManagementScreenState extends State<ExternalTerminalManagementScreen> {
  late final BiometricDeviceManagerService _deviceManager;
  late final TerminalUserSyncService _rosterSyncService;
  bool _isPerformingAction = false;
  bool _isTopologyMode = false;

  @override
  void initState() {
    super.initState();
    _deviceManager = BiometricDeviceManagerService();
    _rosterSyncService = TerminalUserSyncService();
  }

  void _showAddEditDeviceDialog([BiometricTerminalDevice? existing]) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final modelCtrl = TextEditingController(text: existing?.modelName ?? 'DS-K1T343EFWX');
    final ipCtrl = TextEditingController(text: existing?.ipAddress ?? '192.168.1.150');
    final portCtrl = TextEditingController(text: existing != null ? existing.port.toString() : '80');
    final userCtrl = TextEditingController(text: existing?.username ?? 'admin');
    final passCtrl = TextEditingController(text: existing?.password ?? '');
    final serialCtrl = TextEditingController(text: existing?.serialNumber ?? '');
    final branchNameCtrl = TextEditingController(text: existing?.branchName ?? 'Headquarters');
    TerminalProtocol selectedProtocol = existing?.protocol ?? TerminalProtocol.hikvisionIsapi;
    bool autoSync = existing?.autoSyncEnabled ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final colors = context.colors;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(Icons.fingerprint_rounded, color: colors.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isEditing ? 'Configure Terminal' : 'Register Biometric Terminal',
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Device Name / Location *',
                          hintText: 'e.g., Main Entrance DS-K1T343',
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: branchNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name',
                          hintText: 'e.g., Headquarters, Factory 1',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: modelCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Model Number',
                                hintText: 'DS-K1T343EFWX',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: DropdownButtonFormField<TerminalProtocol>(
                              initialValue: selectedProtocol,
                              decoration: const InputDecoration(
                                labelText: 'Protocol',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: TerminalProtocol.hikvisionIsapi,
                                  child: Text('Hikvision ISAPI'),
                                ),
                                DropdownMenuItem(
                                  value: TerminalProtocol.hikvisionIsupPush,
                                  child: Text('Hikvision ISUP 5.0'),
                                ),
                                DropdownMenuItem(
                                  value: TerminalProtocol.zkTecoAdms,
                                  child: Text('ZKTeco ADMS / Push'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedProtocol = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: ipCtrl,
                              decoration: const InputDecoration(
                                labelText: 'IP Address / Domain *',
                                hintText: '192.168.1.150',
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: portCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: '80',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: userCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                hintText: 'admin',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextFormField(
                              controller: passCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: isEditing ? 'Password (blank to keep)' : 'Password *',
                                hintText: '••••••••',
                                isDense: true,
                              ),
                              validator: (v) {
                                if (!isEditing && (v == null || v.trim().isEmpty)) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: serialCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number (Optional)',
                          hintText: 'e.g., F12345678',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Auto-Sync Logs Periodically', style: context.text.bodyMedium),
                        value: autoSync,
                        onChanged: (val) => setModalState(() => autoSync = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.onPrimary),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final port = int.tryParse(portCtrl.text.trim()) ?? 80;
                    final serialNum = serialCtrl.text.trim().isNotEmpty ? serialCtrl.text.trim() : null;
                    if (isEditing) {
                      final updated = existing.copyWith(
                        name: nameCtrl.text.trim(),
                        modelName: modelCtrl.text.trim(),
                        serialNumber: serialNum,
                        protocol: selectedProtocol,
                        ipAddress: ipCtrl.text.trim(),
                        port: port,
                        username: userCtrl.text.trim(),
                        password: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : existing.password,
                        branchName: branchNameCtrl.text.trim(),
                        autoSyncEnabled: autoSync,
                      );
                      await _deviceManager.updateDevice(
                        enterpriseId: widget.enterpriseId,
                        device: updated,
                      );
                    } else {
                      await _deviceManager.registerDevice(
                        enterpriseId: widget.enterpriseId,
                        name: nameCtrl.text.trim(),
                        modelName: modelCtrl.text.trim(),
                        serialNumber: serialNum,
                        protocol: selectedProtocol,
                        ipAddress: ipCtrl.text.trim(),
                        port: port,
                        username: userCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                        branchName: branchNameCtrl.text.trim(),
                        autoSyncEnabled: autoSync,
                      );
                    }
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Register Terminal'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _testConnection(BiometricTerminalDevice device) async {
    setState(() => _isPerformingAction = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    final status = context.status;
    try {
      final res = await _deviceManager.testAndRecordConnectionStatus(
        enterpriseId: widget.enterpriseId,
        device: device,
      );
      final isSuccess = res['success'] == true;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Test completed'),
          backgroundColor: isSuccess ? status.success.color : colors.error,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Test connection error: $e'), backgroundColor: colors.error),
      );
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  Future<void> _syncDeviceLogs(BiometricTerminalDevice device) async {
    setState(() => _isPerformingAction = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    final status = context.status;
    try {
      final res = await _deviceManager.triggerDeviceSync(
        enterpriseId: widget.enterpriseId,
        device: device,
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sync Complete: ${res.normalizedCount} new punches imported, ${res.duplicateCount} duplicates skipped.',
          ),
          backgroundColor: status.success.color,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sync error: $e'), backgroundColor: colors.error),
      );
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  Future<void> _pushStaffRoster(BiometricTerminalDevice device) async {
    setState(() => _isPerformingAction = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    try {
      final res = await _rosterSyncService.syncEnterpriseRosterToDevice(
        enterpriseId: widget.enterpriseId,
        device: device,
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Provisioning Complete: ${res.successCount}/${res.totalTargeted} employees synced to ${device.name}.',
          ),
          backgroundColor: colors.primary,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Roster push error: $e'), backgroundColor: colors.error),
      );
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biometric Hardware Terminals',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(_isTopologyMode ? Icons.view_agenda_outlined : Icons.account_tree_outlined),
            tooltip: _isTopologyMode ? 'Switch to Cards' : 'Branch Topology',
            onPressed: () => setState(() => _isTopologyMode = !_isTopologyMode),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Device',
            onPressed: () => _showAddEditDeviceDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<BiometricTerminalDevice>>(
        stream: _deviceManager.streamDevices(widget.enterpriseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_isPerformingAction) ...[
                LinearProgressIndicator(minHeight: 3, color: colors.primary),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Header Status Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.brLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Hikvision & Hardware Bridge',
                            style: context.text.titleMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: colors.onPrimary.withValues(alpha: 0.2),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(
                            'ISAPI / ISUP 5.0',
                            style: context.text.labelSmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Unified attendance ingestion from physical face/fingerprint terminals and mobile application.',
                      style: context.text.bodySmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeaderMetric(context, 'Terminals', '${devices.length}'),
                        Container(width: 1, height: 24, color: colors.onPrimary.withValues(alpha: 0.24)),
                        _buildHeaderMetric(
                          context,
                          'Online',
                          '${devices.where((d) => d.status == DeviceConnectionStatus.online).length}',
                        ),
                        Container(width: 1, height: 24, color: colors.onPrimary.withValues(alpha: 0.24)),
                        _buildHeaderMetric(
                          context,
                          'Synced Events',
                          '${devices.fold<int>(0, (sum, d) => sum + d.totalEventsSynced)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Machines (${devices.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddEditDeviceDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Device'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              if (devices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.devices_other_rounded, size: 48, color: colors.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No Biometric Terminals Registered',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Connect Hikvision MinMoe (DS-K1T343EFWX) or ZKTeco devices via ISAPI or ISUP 5.0 push.',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _showAddEditDeviceDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Register First Terminal'),
                      ),
                    ],
                  ),
                )
              else if (_isTopologyMode)
                TerminalFleetTopologyView(
                  devices: devices,
                  onTestDevice: _testConnection,
                  onSyncDevice: _syncDeviceLogs,
                )
              else
                ...devices.map((device) => TerminalDeviceCard(
                      device: device,
                      onTestConnection: () => _testConnection(device),
                      onSyncNow: () => _syncDeviceLogs(device),
                      onProvisionUsers: () => _pushStaffRoster(device),
                      onRemoteControl: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TerminalRemoteControlSheet(
                          enterpriseId: widget.enterpriseId,
                          device: device,
                        ),
                      ),
                      onSyncTemplates: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TerminalBiometricTemplateSheet(
                          enterpriseId: widget.enterpriseId,
                          devices: devices,
                          employeeId: 'all',
                          employeeName: 'Fleet Employees',
                        ),
                      ),
                      onProbeDiagnostics: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TerminalDiagnosticSheet(
                          enterpriseId: widget.enterpriseId,
                          device: device,
                        ),
                      ),
                      onEdit: () => _showAddEditDeviceDialog(device),
                      onDelete: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Delete Terminal?'),
                            content: Text('Are you sure you want to remove terminal "${device.name}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  _deviceManager.deleteDevice(
                                    enterpriseId: widget.enterpriseId,
                                    deviceId: device.id,
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderMetric(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: context.text.titleLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

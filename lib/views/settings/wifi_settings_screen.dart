import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../services/database_service.dart';
import '../../core/network/network_connection_service.dart';
import '../../services/audit_log_service.dart';

/// Enterprise Office Wi-Fi Verification Policy Screen.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class WifiSettingsScreen extends StatefulWidget {
  final String enterpriseId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? enterpriseData;

  const WifiSettingsScreen({
    super.key,
    required this.enterpriseId,
    this.initialData,
    this.enterpriseData,
  });

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  bool _enabled = false;
  final List<String> _allowedSsids = [];
  final _ssidController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.enterpriseData ?? widget.initialData ?? {};
    _enabled = d['wifiGeofencingEnabled'] == true;
    final ssids = d['allowedWifiSsids'] as List<dynamic>?;
    if (ssids != null) {
      _allowedSsids.addAll(ssids.map((e) => e.toString()));
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    super.dispose();
  }

  void _addSsid() {
    final text = _ssidController.text.trim();
    if (text.isEmpty) return;
    if (_allowedSsids.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSID is already in allowed list.')),
      );
      return;
    }
    setState(() {
      _allowedSsids.add(text);
      _ssidController.clear();
    });
  }

  void _removeSsid(String ssid) {
    setState(() {
      _allowedSsids.remove(ssid);
    });
  }

  Future<void> _saveSettings() async {
    final statusTheme = context.status;
    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await DatabaseService().updateEnterpriseWifi(
        enterpriseId: widget.enterpriseId,
        enabled: _enabled,
        allowedSsids: _allowedSsids,
      );

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: AuditLogService.actionWifiPolicyUpdated,
        category: AuditLogService.categoryPolicy,
        details: 'Office Wi-Fi policy updated: ${_enabled ? "Enabled" : "Disabled"}, ${_allowedSsids.length} SSIDs allowed.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wi-Fi verification settings saved!'),
            backgroundColor: statusTheme.success.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving Wi-Fi settings: $e'),
            backgroundColor: statusTheme.danger.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Office Wi-Fi Verification',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
        foregroundColor: colors.onSurface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Enable Wi-Fi Network Check',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Require mobile clock-ins to be connected to authorized office Wi-Fi networks',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                value: _enabled,
                activeTrackColor: colors.primary,
                onChanged: (val) => setState(() => _enabled = val),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // SSID Management Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authorized Office Wi-Fi SSIDs',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Add network names (SSIDs) permitted for employee mobile attendance.',
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ssidController,
                          decoration: InputDecoration(
                            labelText: 'Network Name (SSID)',
                            hintText: 'e.g. AcmeCorp_Office_5G',
                            prefixIcon: const Icon(Icons.wifi_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                          onSubmitted: (_) => _addSsid(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: _addSsid,
                        icon: const Icon(Icons.add_rounded, size: AppSizes.iconSm),
                        label: Text('Add', style: textTheme.labelLarge),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_allowedSsids.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          'No SSIDs configured. Add your office Wi-Fi names above.',
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _allowedSsids.map((ssid) {
                        return Chip(
                          avatar: Icon(Icons.wifi_lock_rounded, size: AppSizes.iconSm, color: colors.primary),
                          label: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width - 120).clamp(100.0, 400.0)),
                            child: Text(
                              ssid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          backgroundColor: colors.primaryContainer.withValues(alpha: 0.4),
                          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                          deleteIcon: Icon(Icons.close_rounded, size: AppSizes.iconSm, color: statusTheme.danger.color),
                          onDeleted: () => _removeSsid(ssid),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      'Save Wi-Fi Configuration',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

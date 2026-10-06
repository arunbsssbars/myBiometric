import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../services/database_service.dart';
import '../../core/network/network_connection_service.dart';
import '../../services/audit_log_service.dart';

/// Configuration definition for an enterprise verification method.
class ChannelDefinition {
  final String title;
  final String subtitle;
  final IconData icon;

  const ChannelDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Global Enterprise Verification Channels Settings Screen.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class VerificationChannelsSettingsScreen extends StatefulWidget {
  final String enterpriseId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? enterpriseData;

  const VerificationChannelsSettingsScreen({
    super.key,
    required this.enterpriseId,
    this.initialData,
    this.enterpriseData,
  });

  @override
  State<VerificationChannelsSettingsScreen> createState() => _VerificationChannelsSettingsScreenState();
}

class _VerificationChannelsSettingsScreenState extends State<VerificationChannelsSettingsScreen> {
  final Set<String> _enabledChannels = {};
  bool _isSaving = false;

  static const Map<String, ChannelDefinition> _channelDefinitions = {
    'KIOSK_FACE': ChannelDefinition(
      title: 'Kiosk Facial Recognition',
      subtitle: 'Shared office tablet face recognition punch',
      icon: Icons.face_retouching_natural_rounded,
    ),
    'KIOSK_PIN': ChannelDefinition(
      title: 'Kiosk Employee PIN Punch',
      subtitle: 'Keypad punch using Employee ID and secret PIN',
      icon: Icons.pin_outlined,
    ),
    'MOBILE_GPS': ChannelDefinition(
      title: 'Mobile GPS Geofence Punch',
      subtitle: 'Personal phone punch restricted to office GPS coordinates',
      icon: Icons.location_on_outlined,
    ),
    'OFFICE_WIFI': ChannelDefinition(
      title: 'Office Wi-Fi Network Check',
      subtitle: 'Verify personal mobile is connected to approved office Wi-Fi',
      icon: Icons.wifi_lock_rounded,
    ),
    'PHONE_BIOMETRICS': ChannelDefinition(
      title: 'Phone Fingerprint & Face Unlock',
      subtitle: 'Personal device local biometric sensor authentication',
      icon: Icons.fingerprint_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    final d = widget.enterpriseData ?? widget.initialData ?? {};
    final channels = d['defaultAllowedVerificationMethods'] as List<dynamic>?;
    if (channels != null && channels.isNotEmpty) {
      _enabledChannels.addAll(channels.map((e) => e.toString()));
    } else {
      _enabledChannels.addAll(_channelDefinitions.keys);
    }
  }

  Future<void> _handleSave() async {
    final statusTheme = context.status;
    if (_enabledChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('At least one verification channel must be enabled.'),
          backgroundColor: statusTheme.danger.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet) return;

    setState(() => _isSaving = true);
    try {
      await DatabaseService().updateEnterpriseDefaultChannels(
        enterpriseId: widget.enterpriseId,
        channels: _enabledChannels.toList(),
      );

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: AuditLogService.actionPolicyUpdated,
        category: AuditLogService.categoryPolicy,
        details: 'Global verification channels updated: ${_enabledChannels.join(", ")}.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Global verification channels policy saved!'),
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
            content: Text('Error saving channels: $e'),
            backgroundColor: statusTheme.danger.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getChannelColor(BuildContext context, String key) {
    final colors = context.colors;
    final statusTheme = context.status;
    switch (key) {
      case 'KIOSK_FACE':
        return statusTheme.success.color;
      case 'KIOSK_PIN':
        return colors.primary;
      case 'MOBILE_GPS':
        return statusTheme.warning.color;
      case 'OFFICE_WIFI':
        return statusTheme.info.color;
      case 'PHONE_BIOMETRICS':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Global Verification Channels',
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
            // Explanation Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.hub_outlined, color: colors.primary, size: AppSizes.iconLg),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Configure default verification channels for all employees. You can also customize permissions on a per-employee basis from the Staff Roster.',
                      style: textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Channel Switches
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _channelDefinitions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 64,
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final key = _channelDefinitions.keys.elementAt(index);
                  final def = _channelDefinitions[key]!;
                  final isChecked = _enabledChannels.contains(key);
                  final channelColor = _getChannelColor(context, key);

                  return SwitchListTile.adaptive(
                    value: isChecked,
                    activeTrackColor: channelColor,
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          _enabledChannels.add(key);
                        } else {
                          _enabledChannels.remove(key);
                        }
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: channelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(def.icon, color: channelColor, size: AppSizes.iconMd),
                    ),
                    title: Text(
                      def.title,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      def.subtitle,
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  );
                },
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
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      'Save Global Channels Policy',
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

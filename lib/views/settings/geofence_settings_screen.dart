import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/audit_log_service.dart';
import '../../core/network/network_connection_service.dart';

/// Enterprise GPS Geofence Policy configuration screen.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class GeofenceSettingsScreen extends StatefulWidget {
  final String enterpriseId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? enterpriseData;

  const GeofenceSettingsScreen({
    super.key,
    required this.enterpriseId,
    this.initialData,
    this.enterpriseData,
  });

  @override
  State<GeofenceSettingsScreen> createState() => _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends State<GeofenceSettingsScreen> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  bool _enabled = false;
  bool _isLoadingGps = false;
  bool _isSaving = false;
  String? _statusMessage;
  bool? _testWithinGeofence;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _loadData() {
    final d = widget.enterpriseData ?? widget.initialData ?? {};
    _enabled = d['geofencingEnabled'] == true;
    _latController.text = (d['officeLatitude'] as num?)?.toString() ?? '0.0';
    _lngController.text = (d['officeLongitude'] as num?)?.toString() ?? '0.0';
    _radiusController.text = (d['geofenceRadiusMeters'] as num?)?.toString() ?? '200';
  }

  Future<void> _fetchCurrentGps() async {
    setState(() => _isLoadingGps = true);
    final loc = await LocationService().getCurrentPosition();
    setState(() => _isLoadingGps = false);

    if (!mounted) return;
    final statusTheme = context.status;

    if (loc != null) {
      setState(() {
        _latController.text = loc.latitude.toStringAsFixed(6);
        _lngController.text = loc.longitude.toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acquired GPS: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}'),
          backgroundColor: statusTheme.success.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not acquire GPS position. Ensure location services are enabled.'),
          backgroundColor: statusTheme.danger.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testCurrentPosition() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final rad = double.tryParse(_radiusController.text.trim()) ?? 200.0;

    if (lat == null || lng == null) {
      setState(() => _statusMessage = 'Please enter valid office coordinates first.');
      return;
    }

    setState(() {
      _isLoadingGps = true;
      _statusMessage = null;
    });

    final loc = await LocationService().getCurrentPosition();
    setState(() => _isLoadingGps = false);

    if (loc == null) {
      setState(() => _statusMessage = 'Failed to get current GPS reading.');
      return;
    }

    final dist = LocationService().calculateDistanceMeters(
      startLatitude: lat,
      startLongitude: lng,
      endLatitude: loc.latitude,
      endLongitude: loc.longitude,
    );
    final inside = dist <= rad;

    setState(() {
      _testWithinGeofence = inside;
      _statusMessage = inside
          ? 'You are within the office geofence (${dist.toInt()}m from center).'
          : 'You are outside the geofence (${dist.toInt()}m from center, radius is ${rad.toInt()}m).';
    });
  }

  Future<void> _saveSettings() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim()) ?? 200.0;
    final statusTheme = context.status;

    if (_enabled && (lat == null || lng == null || (lat == 0.0 && lng == 0.0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid office latitude and longitude.'),
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
      await DatabaseService().updateEnterpriseGeofence(
        enterpriseId: widget.enterpriseId,
        geofencingEnabled: _enabled,
        officeLatitude: lat ?? 0.0,
        officeLongitude: lng ?? 0.0,
        geofenceRadiusMeters: radius,
      );

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: AuditLogService.actionGeofenceUpdated,
        category: AuditLogService.categoryPolicy,
        details: 'Geofence updated: ${_enabled ? "Enabled" : "Disabled"}, Radius: ${radius.toInt()}m.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Geofence configuration saved successfully!'),
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
            content: Text('Error saving geofence: $e'),
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
          'GPS Geofence Policy',
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
            // Master Switch Card
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
                  'Enable GPS Geofencing',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Restrict mobile employee punches to the registered office boundary radius',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                value: _enabled,
                activeTrackColor: colors.primary,
                onChanged: (val) => setState(() => _enabled = val),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Coordinates Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Office Center Location',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.tonalIcon(
                        onPressed: _isLoadingGps ? null : _fetchCurrentGps,
                        icon: _isLoadingGps
                            ? SizedBox(
                                width: AppSizes.iconSm,
                                height: AppSizes.iconSm,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                              )
                            : Icon(Icons.my_location_rounded, size: AppSizes.iconSm),
                        label: Text('Get GPS', style: textTheme.labelSmall),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. 12.971598',
                      prefixIcon: const Icon(Icons.pin_drop_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. 77.594562',
                      prefixIcon: const Icon(Icons.explore_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Geofence Radius (Meters)',
                      hintText: 'e.g. 200',
                      prefixIcon: const Icon(Icons.radar_rounded),
                      suffixText: 'meters',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Diagnostic Verification Card
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
                    'Geofence Calibration & Test',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Test whether your current device location falls inside the configured radius.',
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _isLoadingGps ? null : _testCurrentPosition,
                    icon: Icon(Icons.check_circle_outline_rounded, size: AppSizes.iconSm),
                    label: Text('Test Location Match', style: textTheme.labelLarge),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _testWithinGeofence == true
                            ? statusTheme.success.container
                            : statusTheme.danger.container,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: _testWithinGeofence == true
                              ? statusTheme.success.color.withValues(alpha: 0.3)
                              : statusTheme.danger.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testWithinGeofence == true ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: _testWithinGeofence == true
                                ? statusTheme.success.color
                                : statusTheme.danger.color,
                            size: AppSizes.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: textTheme.bodySmall?.copyWith(
                                color: _testWithinGeofence == true
                                    ? statusTheme.success.onContainer
                                    : statusTheme.danger.onContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      'Save Geofence Settings',
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

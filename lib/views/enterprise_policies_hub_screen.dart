import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/shift_schedule.dart';
import '../services/database_service.dart';
import 'settings/geofence_settings_screen.dart';
import 'settings/wifi_settings_screen.dart';
import 'settings/shift_schedule_settings_screen.dart';
import 'settings/admin_pin_settings_screen.dart';
import 'settings/verification_channels_settings_screen.dart';
import 'branch_management_screen.dart';
import 'compliance_audit_screen.dart';
import 'shift_swap_management_screen.dart';
import 'external_terminal_management_screen.dart';
import 'terminal_punch_injection_screen.dart';
import 'executive_command_center_screen.dart';
import '../services/auth_service.dart';

/// Unified Enterprise Policies & Configuration Hub.
/// Centralizes Geofencing, Wi-Fi, Shift Scheduling, PIN Security, and Verification Channels.
///
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class EnterprisePoliciesHubScreen extends StatelessWidget {
  final String enterpriseId;

  const EnterprisePoliciesHubScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Enterprise Policies & Controls',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getEnterpriseStream(enterpriseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entData = snapshot.data?.data() as Map<String, dynamic>?;

          // GPS Geofence details
          final isGeoEnabled = entData?['geofencingEnabled'] == true;
          final radius = (entData?['geofenceRadiusMeters'] as num?)?.toDouble() ?? 150.0;
          final locName = entData?['locationName'] as String? ?? 'Office Campus';

          // Shift details
          final shiftMap = entData?['shiftSchedule'] as Map<String, dynamic>?;
          final currentShift = shiftMap != null ? ShiftSchedule.fromJson(shiftMap) : const ShiftSchedule();

          // Wi-Fi details
          final isWifiEnabled = entData?['wifiGeofencingEnabled'] == true;
          final allowedSsids = (entData?['allowedWifiSsids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          // PIN details
          final kioskPin = entData?['kioskPin'] as String?;
          final isCustomPin = kioskPin != null && kioskPin.isNotEmpty && kioskPin != '1234';

          // Channels details
          final allowedMethods = (entData?['allowedVerificationMethods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            children: [
              // Executive Hub Header Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer,
                      colors.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.security_rounded, color: colors.primary, size: AppSizes.iconLg),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Policy Center',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Configure organizational security rules, perimeter bounds & schedules.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SECURITY & LOCATION PERIMETERS',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 1. GPS Geofence Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.location_on_rounded,
                iconColor: isGeoEnabled ? statusTheme.success.color : colors.onSurfaceVariant,
                iconBg: isGeoEnabled ? statusTheme.success.container : colors.surfaceContainerHighest,
                title: 'GPS Geofencing Perimeter',
                description: isGeoEnabled
                    ? 'Active: $locName (${radius.toInt()}m radius restriction)'
                    : 'Disabled: Employees can punch from any GPS coordinate',
                badgeText: isGeoEnabled ? 'ENFORCED' : 'OFF',
                badgeColor: isGeoEnabled ? statusTheme.success.color : colors.onSurfaceVariant,
                badgeBg: isGeoEnabled ? statusTheme.success.container : colors.surfaceContainerHighest,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GeofenceSettingsScreen(
                        enterpriseId: enterpriseId,
                        enterpriseData: entData,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 2. Office Wi-Fi Geofencing Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.wifi_rounded,
                iconColor: isWifiEnabled ? colors.primary : colors.onSurfaceVariant,
                iconBg: isWifiEnabled ? colors.primaryContainer.withValues(alpha: 0.5) : colors.surfaceContainerHighest,
                title: 'Office Wi-Fi Perimeter',
                description: isWifiEnabled
                    ? '${allowedSsids.length} authorized SSID network${allowedSsids.length == 1 ? "" : "s"} enrolled'
                    : 'Disabled: Punches allowed on cellular / external networks',
                badgeText: isWifiEnabled ? 'ACTIVE' : 'OFF',
                badgeColor: isWifiEnabled ? colors.primary : colors.onSurfaceVariant,
                badgeBg: isWifiEnabled ? colors.primaryContainer.withValues(alpha: 0.5) : colors.surfaceContainerHighest,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WifiSettingsScreen(
                        enterpriseId: enterpriseId,
                        enterpriseData: entData,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 3. Multi-Branch & Job Sites Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.location_city_rounded,
                iconColor: colors.primary,
                iconBg: colors.primaryContainer.withValues(alpha: 0.4),
                title: 'Multi-Branch & Geo-Fences',
                description: 'Manage individual branches, perimeter polygons & site managers.',
                badgeText: 'MULTI-SITE',
                badgeColor: colors.primary,
                badgeBg: colors.primaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BranchManagementScreen(
                        enterpriseId: enterpriseId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 4. Verification Channels Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.checklist_rounded,
                iconColor: colors.secondary,
                iconBg: colors.secondaryContainer.withValues(alpha: 0.4),
                title: 'Allowed Verification Channels',
                description: allowedMethods.isNotEmpty
                    ? '${allowedMethods.length} methods enabled: ${allowedMethods.join(", ")}'
                    : 'Defaults enabled: Face ID, Kiosk & Mobile GPS',
                badgeText: '${allowedMethods.length} ACTIVE',
                badgeColor: colors.secondary,
                badgeBg: colors.secondaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerificationChannelsSettingsScreen(
                        enterpriseId: enterpriseId,
                        enterpriseData: entData,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 5. Compliance & Labor Standards Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.policy_rounded,
                iconColor: statusTheme.success.color,
                iconBg: statusTheme.success.container,
                title: 'Compliance & Labor Standards',
                description: 'Overtime caps, mandatory rest periods, consecutive work day limits & automated violation alerts.',
                badgeText: 'AUDITED',
                badgeColor: statusTheme.success.color,
                badgeBg: statusTheme.success.container,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplianceAuditScreen(
                        enterpriseId: enterpriseId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'WORKFORCE & SHIFT AUTOMATION',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 6. Shift Schedule Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.schedule_rounded,
                iconColor: colors.tertiary,
                iconBg: colors.tertiaryContainer.withValues(alpha: 0.4),
                title: 'Standard Shift & Overtime',
                description: shiftMap != null
                    ? '${currentShift.shiftName} (${currentShift.startTimeFormatted} - ${currentShift.endTimeFormatted}) • Grace: ${currentShift.gracePeriodMinutes}m • ${currentShift.nominalDurationFormatted}'
                    : 'Default shift: ${currentShift.startTimeFormatted} - ${currentShift.endTimeFormatted} • Grace: ${currentShift.gracePeriodMinutes}m',
                badgeText: shiftMap != null ? 'SCHEDULED' : 'DEFAULT',
                badgeColor: colors.tertiary,
                badgeBg: colors.tertiaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftScheduleSettingsScreen(
                        enterpriseId: enterpriseId,
                        enterpriseData: entData,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 7. Peer Shift Swapping Management Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.swap_horizontal_circle_rounded,
                iconColor: statusTheme.warning.color,
                iconBg: statusTheme.warning.container,
                title: 'Shift Swap Approvals',
                description: 'Review and approve peer shift swaps, coverage trades & emergency schedule handovers.',
                badgeText: 'ROSTER',
                badgeColor: statusTheme.warning.color,
                badgeBg: statusTheme.warning.container,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftSwapManagementScreen(
                        enterpriseId: enterpriseId,
                        currentUserId: AuthService().currentUser?.uid ?? '',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 8. Physical Biometric Terminals Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.devices_other_rounded,
                iconColor: colors.primary,
                iconBg: colors.primaryContainer.withValues(alpha: 0.4),
                title: 'Physical Biometric Machines',
                description: 'Hikvision MinMoe, ZKTeco ADMS, direct IP push & local hardware fleet synchronizer.',
                badgeText: 'FLEET',
                badgeColor: colors.primary,
                badgeBg: colors.primaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExternalTerminalManagementScreen(
                        enterpriseId: enterpriseId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SECURITY & HARDWARE CONTROLS',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 9. Admin & Kiosk PIN Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.pin_rounded,
                iconColor: isCustomPin ? statusTheme.success.color : statusTheme.warning.color,
                iconBg: isCustomPin ? statusTheme.success.container : statusTheme.warning.container,
                title: 'Kiosk Admin Security PIN',
                description: isCustomPin
                    ? 'Secure custom PIN active • Used to exit kiosk mode'
                    : 'Default PIN in use (1234) • Change recommended',
                badgeText: isCustomPin ? 'SECURE' : 'DEFAULT',
                badgeColor: isCustomPin ? statusTheme.success.color : statusTheme.warning.color,
                badgeBg: isCustomPin ? statusTheme.success.container : statusTheme.warning.container,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPinSettingsScreen(
                        enterpriseId: enterpriseId,
                        enterpriseData: entData,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 10. Hardware Punch Injection / Testing Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.fingerprint_rounded,
                iconColor: colors.secondary,
                iconBg: colors.secondaryContainer.withValues(alpha: 0.4),
                title: 'Hardware Punch Ingestion Simulator',
                description: 'Test physical biometric terminal event streams, live payloads & relay callbacks.',
                badgeText: 'DIAGNOSTIC',
                badgeColor: colors.secondary,
                badgeBg: colors.secondaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TerminalPunchInjectionScreen(
                        enterpriseId: enterpriseId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'FLEET COMMAND & REAL-TIME INTELLIGENCE',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 11. Executive Command Center Cockpit Tile
              _buildPolicyCard(
                context: context,
                icon: Icons.dashboard_customize_rounded,
                iconColor: colors.primary,
                iconBg: colors.primaryContainer.withValues(alpha: 0.4),
                title: 'Executive Workforce Command Center',
                description: 'Real-time fleet uptime, punch velocity, tamper alarms, and on-site workforce presence.',
                badgeText: 'COCKPIT',
                badgeColor: colors.primary,
                badgeBg: colors.primaryContainer.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExecutiveCommandCenterScreen(
                        enterpriseId: enterpriseId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPolicyCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              badgeText,
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: AppSizes.iconMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

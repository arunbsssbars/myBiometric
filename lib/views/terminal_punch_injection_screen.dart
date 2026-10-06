import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../services/auth_service.dart';
import '../services/biometric_device_manager_service.dart';
import 'terminal_event_log_tile.dart';
import 'terminal_hardware_punch_card.dart';

/// Workspace screen providing complete control to record, simulate, and inject
/// attendance through physical biometric machines with indistinguishable platform perception.
/// Fully token-driven (AQIL v2): Zero hardcoded hex colors or fonts.
class TerminalPunchInjectionScreen extends StatefulWidget {
  final String enterpriseId;
  final String? initialUserId;
  final String? initialEmployeeId;
  final String? initialEmployeeName;

  const TerminalPunchInjectionScreen({
    super.key,
    required this.enterpriseId,
    this.initialUserId,
    this.initialEmployeeId,
    this.initialEmployeeName,
  });

  @override
  State<TerminalPunchInjectionScreen> createState() => _TerminalPunchInjectionScreenState();
}

class _TerminalPunchInjectionScreenState extends State<TerminalPunchInjectionScreen> {
  late final BiometricDeviceManagerService _deviceManager;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _deviceManager = BiometricDeviceManagerService();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.status;
    final user = AuthService().currentUser;
    final effectiveUserId = widget.initialUserId ?? user?.uid ?? 'usr_admin';
    final effectiveName = widget.initialEmployeeName ?? user?.displayName ?? 'Staff Member';
    final effectiveEmployeeId = widget.initialEmployeeId ?? 'EMP-001';

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Biometric Terminal Controller',
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      body: StreamBuilder<List<BiometricTerminalDevice>>(
        stream: _deviceManager.streamDevices(widget.enterpriseId),
        builder: (context, deviceSnap) {
          if (deviceSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = deviceSnap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Main Interactive Hardware Terminal Card
              TerminalHardwarePunchCard(
                availableDevices: devices,
                enterpriseId: widget.enterpriseId,
                userId: effectiveUserId,
                employeeId: effectiveEmployeeId,
                employeeName: effectiveName,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Recent Terminal Punches Feed Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Hardware Punch Stream',
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: status.success.container,
                      borderRadius: AppRadius.brSm,
                      border: Border.all(color: status.success.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, size: 8, color: status.success.color),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'LIVE',
                          style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: status.success.onContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Stream of Recent Hardware Punches
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('enterprises')
                    .doc(widget.enterpriseId)
                    .collection('attendance_logs')
                    .where('verifiedVia', isEqualTo: 'DEVICE_TERMINAL')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, logSnap) {
                  if (logSnap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final docs = logSnap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Center(
                        child: Text(
                          'No hardware terminal punches logged yet.',
                          style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final map = d.data() as Map<String, dynamic>;
                      final ts = (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                      final event = TerminalAttendanceEvent(
                        eventId: d.id,
                        deviceId: (map['terminalDeviceId'] ?? '').toString(),
                        employeeId: (map['employeeId'] ?? '').toString(),
                        employeeName: map['employeeName'] as String?,
                        timestamp: ts,
                        punchType: (map['type'] ?? 'PUNCH_IN').toString(),
                        authMode: DeviceAuthMode.values.firstWhere(
                          (e) => e.name == map['authMode'],
                          orElse: () => DeviceAuthMode.face,
                        ),
                      );

                      return TerminalEventLogTile(event: event);
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

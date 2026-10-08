import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/shift_evaluation_service.dart';
import '../services/shift_reminder_service.dart';
import '../core/network/network_connection_service.dart';
import '../domain/models/shift_schedule.dart';
import '../services/break_tracking_service.dart';
import 'mobile_machine_punch_hub_card.dart';

/// Interactive, responsive mobile punch card for employees on HomeScreen.
/// Provides live clocked-in elapsed timer, shift target progress, GPS geofence pill,
/// and instant one-tap biometric/GPS clock-in and clock-out with rapid punch-out safeguard.
///
/// Fully token-driven (AQIL v2): zero hardcoded hex colors, zero fixed font sizes,
/// accessible minimum touch targets (>= 48dp), and defensive overflow safeguards.
class MobilePunchCard extends StatefulWidget {
  final String enterpriseId;
  final Map<String, dynamic>? userData;

  const MobilePunchCard({
    super.key,
    required this.enterpriseId,
    this.userData,
  });

  @override
  State<MobilePunchCard> createState() => _MobilePunchCardState();
}

class _MobilePunchCardState extends State<MobilePunchCard> {
  final DatabaseService _dbService = DatabaseService();
  Timer? _tickerTimer;
  bool _isPunching = false;
  bool _isCheckingGps = false;
  GeofenceStatus? _geofenceStatus;
  String? _lastScheduledShiftKey;

  @override
  void initState() {
    super.initState();
    // Ticker timer to update elapsed work time every 30 seconds
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _checkGpsProximity();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkGpsProximity() async {
    if (_isCheckingGps) return;
    setState(() => _isCheckingGps = true);
    try {
      final entDoc = await _dbService.getEnterprise(widget.enterpriseId);
      if (entDoc.exists && entDoc.data() != null) {
        final data = entDoc.data() as Map<String, dynamic>;
        final enabled = data['geofencingEnabled'] == true;
        final lat = (data['officeLatitude'] as num?)?.toDouble();
        final lng = (data['officeLongitude'] as num?)?.toDouble();
        final radius = (data['geofenceRadiusMeters'] as num?)?.toDouble() ?? 150.0;

        if (enabled && lat != null && lng != null) {
          final pos = await LocationService().getCurrentPosition();
          if (pos != null && mounted) {
            final status = LocationService().evaluateGeofence(
              position: pos,
              officeLatitude: lat,
              officeLongitude: lng,
              allowedRadiusMeters: radius,
            );
            setState(() {
              _geofenceStatus = status;
              _isCheckingGps = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isCheckingGps = false);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _handlePunch({
    required bool clockIn,
    required ShiftSchedule schedule,
    required Map<String, dynamic>? latestPunch,
    required String employeeName,
    required String employeeId,
    required String userId,
    int? netDurationMinutes,
  }) async {
    if (_isPunching) return;

    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet || !mounted) return;

    final statusColors = context.status;
    final themeColors = context.colors;

    // Check allowed verification methods configured by Admin
    final allowedMethods = (widget.userData?['allowedVerificationMethods'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    if (allowedMethods != null && allowedMethods.isNotEmpty && !allowedMethods.contains('MOBILE_GPS')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mobile GPS clock-in is disabled for your account. Please use the Office Kiosk.'),
          backgroundColor: statusColors.warning.color,
        ),
      );
      return;
    }

    // Reject GPS spoofing / mock locations
    if (_geofenceStatus?.isMocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.security, color: themeColors.onError, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Mock location detected! Please disable GPS spoofing to record attendance.',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: themeColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!clockIn && latestPunch != null) {
      final punchInTs = (latestPunch['timestamp'] as Timestamp?)?.toDate();
      if (punchInTs != null) {
        final elapsed = DateTime.now().difference(punchInTs);
        if (elapsed.inMinutes < 15) {
          int countdown = 10;
          Timer? timer;
          final confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StatefulBuilder(
              builder: (dialogCtx, setDialogState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
                  if (countdown > 1) {
                    setDialogState(() => countdown--);
                  } else {
                    t.cancel();
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx, false);
                  }
                });

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: statusColors.warning.color, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Early Clock Out Warning',
                          style: dialogCtx.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You clocked in just ${elapsed.inMinutes} minute${elapsed.inMinutes == 1 ? "" : "s"} ago.',
                        style: dialogCtx.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Do you really want to clock out now? If this was a mistake, press "Keep Clocked In" or wait for auto-undo.',
                        style: dialogCtx.text.bodySmall?.copyWith(color: themeColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LinearProgressIndicator(
                        value: countdown / 10.0,
                        backgroundColor: themeColors.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColors.warning.color),
                        minHeight: 4,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton.icon(
                      icon: const Icon(Icons.undo, size: AppSizes.iconSm),
                      onPressed: () {
                        timer?.cancel();
                        Navigator.pop(ctx, false);
                      },
                      label: Text('Keep Clocked In (Undo ${countdown}s)'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: themeColors.error,
                        foregroundColor: themeColors.onError,
                      ),
                      onPressed: () {
                        timer?.cancel();
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Confirm Clock Out'),
                    ),
                  ],
                );
              },
            ),
          );
          timer?.cancel();
          if (confirm != true) return;
        }
      }
    }

    if (!mounted) return;

    setState(() => _isPunching = true);
    final now = DateTime.now();

    try {
      // Calculate duration if clocking out (deducting unpaid breaks)
      int? shiftDurationMinutes;
      if (!clockIn) {
        if (netDurationMinutes != null && netDurationMinutes > 0) {
          shiftDurationMinutes = netDurationMinutes;
        } else if (latestPunch != null) {
          final punchInTs = (latestPunch['timestamp'] as Timestamp?)?.toDate();
          if (punchInTs != null) {
            final diff = now.difference(punchInTs).inMinutes;
            shiftDurationMinutes = diff > 0 ? diff : 1;
          }
        }
      }

      final eval = ShiftEvaluationService.evaluatePunch(
        punchTime: now,
        punchType: clockIn ? 'PUNCH_IN' : 'PUNCH_OUT',
        schedule: schedule,
        shiftDurationMinutes: shiftDurationMinutes,
      );

      final messenger = ScaffoldMessenger.of(context);

      await _dbService.logAttendance(
        userId: userId,
        enterpriseId: widget.enterpriseId,
        type: clockIn ? 'PUNCH_IN' : 'PUNCH_OUT',
        verifiedVia: 'MOBILE_GPS',
        employeeName: employeeName,
        employeeId: employeeId,
        punchStatus: eval.punchStatus,
        lateMinutes: eval.lateMinutes,
        earlyMinutes: eval.earlyMinutes,
        overtimeMinutes: eval.overtimeMinutes,
        workStatus: eval.workStatus,
        shiftDurationMinutes: shiftDurationMinutes,
      );

      // Cancel proactive shift reminder upon punch event
      if (clockIn) {
        ShiftReminderService().cancelShiftInReminder();
      } else {
        ShiftReminderService().cancelShiftOutReminder();
      }

      HapticFeedback.mediumImpact();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                clockIn ? Icons.login_rounded : Icons.logout_rounded,
                color: themeColors.onPrimary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  clockIn
                      ? 'Clocked IN successfully at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} (${eval.statusMessage})'
                      : 'Clocked OUT successfully. Net shift duration: ${_formatDuration(Duration(minutes: shiftDurationMinutes ?? 0))}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: clockIn ? statusColors.success.color : statusColors.danger.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording attendance: $e'),
            backgroundColor: themeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPunching = false);
      }
    }
  }

  Future<void> _handleBreak({
    required bool isStart,
    String breakType = 'Lunch Break',
    required String employeeName,
    required String employeeId,
    required String userId,
  }) async {
    if (_isPunching) return;
    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet || !mounted) return;

    final statusColors = context.status;
    final themeColors = context.colors;

    setState(() => _isPunching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _dbService.logBreak(
        userId: userId,
        enterpriseId: widget.enterpriseId,
        isStart: isStart,
        breakType: breakType,
        employeeName: employeeName,
        employeeId: employeeId,
        verifiedVia: 'MOBILE_GPS',
      );

      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isStart ? Icons.coffee_rounded : Icons.work_rounded, color: themeColors.onPrimary, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isStart ? 'Started $breakType. Enjoy your break!' : 'Break ended. Welcome back to work!',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: isStart ? statusColors.warning.color : statusColors.success.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error recording break: $e'),
            backgroundColor: themeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPunching = false);
    }
  }

  void _showTakeBreakModal({
    required BuildContext context,
    required String employeeName,
    required String employeeId,
    required String userId,
  }) {
    final colors = context.colors;
    final status = context.status;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Break Type',
                    style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: AppSizes.iconMd),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Work breaks help maintain productivity. Lunch breaks are unpaid deductions, while rest breaks are paid.',
                style: ctx.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd,
                  side: BorderSide(color: colors.outlineVariant),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: status.warning.container,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(Icons.lunch_dining_rounded, color: status.warning.onContainer),
                ),
                title: Text('Lunch Break', style: ctx.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Standard 45m • Unpaid deduction', style: ctx.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.outline),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleBreak(
                    isStart: true,
                    breakType: 'Lunch Break',
                    employeeName: employeeName,
                    employeeId: employeeId,
                    userId: userId,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd,
                  side: BorderSide(color: colors.outlineVariant),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(Icons.coffee_rounded, color: colors.primary),
                ),
                title: Text('Rest / Tea Break', style: ctx.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Standard 15m • Paid break time', style: ctx.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.outline),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleBreak(
                    isStart: true,
                    breakType: 'Rest / Tea Break',
                    employeeName: employeeName,
                    employeeId: employeeId,
                    userId: userId,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    final name = (widget.userData?['fullName'] as String?)?.trim() ??
        (widget.userData?['name'] as String?)?.trim() ??
        (user.displayName ?? user.email?.split('@').first ?? 'Employee');
    final empId = widget.userData?['employeeId'] as String? ?? 'EMP';

    final colors = context.colors;
    final status = context.status;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.getEnterpriseStream(widget.enterpriseId),
      builder: (context, entSnap) {
        final entData = entSnap.data?.data() as Map<String, dynamic>?;
        final shiftMap = entData?['shiftSchedule'] as Map<String, dynamic>?;
        final schedule = shiftMap != null ? ShiftSchedule.fromJson(shiftMap) : const ShiftSchedule();

        final shiftKey = '${schedule.startHour}:${schedule.startMinute}-${schedule.endHour}:${schedule.endMinute}';
        if (_lastScheduledShiftKey != shiftKey) {
          _lastScheduledShiftKey = shiftKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ShiftReminderService().scheduleShiftReminders(
              schedule: schedule,
              companyName: (entData?['name'] as String?) ?? 'Office',
            );
          });
        }

        return StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _dbService.getUserActivityToday(user.uid),
          builder: (context, logsSnap) {
            final todayDocs = logsSnap.data ?? [];
            final todayLogMaps = todayDocs.map((d) => d.data() as Map<String, dynamic>).toList();

            final session = EmployeeDailySession.evaluate(
              userId: user.uid,
              employeeName: name,
              employeeId: empId,
              department: (widget.userData?['department'] as String?) ?? 'Staff',
              employeeLogsToday: todayLogMaps,
            );

            final isWorking = session.status == EmployeeWorkStatus.working;
            final isOnBreak = session.status == EmployeeWorkStatus.onBreak;
            final isClockedIn = isWorking || isOnBreak;
            final latestData = todayLogMaps.isNotEmpty ? todayLogMaps.first : null;

            final userMethodsRaw = widget.userData?['allowedVerificationMethods'] as List<dynamic>?;
            final entMethodsRaw = entData?['defaultAllowedVerificationMethods'] as List<dynamic>?;
            final List<String> effectiveMethods = (userMethodsRaw != null && userMethodsRaw.isNotEmpty)
                ? userMethodsRaw.map((e) => e.toString()).toList()
                : (entMethodsRaw != null && entMethodsRaw.isNotEmpty)
                    ? entMethodsRaw.map((e) => e.toString()).toList()
                    : const ['MOBILE_GPS', 'KIOSK_FACE', 'PHONE_BIOMETRICS', 'OFFICE_WIFI', 'KIOSK_PIN'];

            final bool isMobileGpsAllowed = effectiveMethods.contains('MOBILE_GPS');
            final bool isTerminalAllowed = effectiveMethods.any((m) =>
                m == 'TERMINAL_QR' ||
                m == 'TERMINAL_NFC' ||
                m == 'TERMINAL_BLE' ||
                m == 'OFFICE_WIFI' ||
                m == 'KIOSK_PIN' ||
                m == 'KIOSK_FACE');

            Color themeBorder;
            Color cardBg;

            if (isOnBreak) {
              themeBorder = status.warning.border;
              cardBg = status.warning.container.withValues(alpha: 0.35);
            } else if (isWorking) {
              themeBorder = status.success.border;
              cardBg = status.success.container.withValues(alpha: 0.35);
            } else {
              themeBorder = colors.outlineVariant;
              cardBg = colors.surface;
            }

            return Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: themeBorder,
                  width: isClockedIn ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Status badge & Shift Timing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusPill(
                          label: isOnBreak
                              ? 'ON BREAK (${session.activeBreakCategory?.displayName ?? "Break"})'
                              : (isWorking
                                  ? 'CLOCKED IN'
                                  : (session.status == EmployeeWorkStatus.clockedOut ? 'CLOCKED OUT' : 'NOT CLOCKED IN')),
                          tone: isOnBreak
                              ? status.warning
                              : (isWorking
                                  ? status.success
                                  : (session.status == EmployeeWorkStatus.clockedOut ? status.neutral : status.neutral)),
                          icon: isClockedIn ? Icons.fiber_manual_record : Icons.radio_button_unchecked,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 12, color: colors.onSurfaceVariant),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    '${schedule.startTimeFormatted} – ${schedule.endTimeFormatted}',
                                    style: context.text.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Active State Display
                    if (isOnBreak && session.breakStartTime != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Break Started At', style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${session.breakStartTime!.hour.toString().padLeft(2, '0')}:${session.breakStartTime!.minute.toString().padLeft(2, '0')} ',
                                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Break Elapsed', style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                _formatDuration(DateTime.now().difference(session.breakStartTime!)),
                                style: context.text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: status.warning.onContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: AppRadius.brXs,
                        child: LinearProgressIndicator(
                          value: (DateTime.now().difference(session.breakStartTime!).inMinutes /
                                  (session.activeBreakCategory?.standardMinutes ?? 30))
                              .clamp(0.0, 1.0),
                          backgroundColor: status.warning.container,
                          valueColor: AlwaysStoppedAnimation<Color>(status.warning.color),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Standard: ${session.activeBreakCategory?.standardMinutes ?? 30}m (${session.activeBreakCategory?.isPaid == true ? "Paid" : "Unpaid"})',
                              style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Net Work: ${_formatDuration(session.netWorkDuration)}',
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: status.success.onContainer,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isWorking && session.punchInTime != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Clocked In At', style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${session.punchInTime!.hour.toString().padLeft(2, '0')}:${session.punchInTime!.minute.toString().padLeft(2, '0')}',
                                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Net Work Time', style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                _formatDuration(session.netWorkDuration),
                                style: context.text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: status.success.onContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: AppRadius.brXs,
                        child: LinearProgressIndicator(
                          value: (session.netWorkDuration.inMinutes /
                                  (schedule.fullDayMinutes > 0 ? schedule.fullDayMinutes : 480))
                              .clamp(0.0, 1.0),
                          backgroundColor: colors.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(status.success.color),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Target: ${schedule.fullDayMinutes ~/ 60}h Day',
                              style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            session.totalBreakDuration > Duration.zero
                                ? 'Breaks: ${_formatDuration(session.totalBreakDuration)}'
                                : (latestData?['punchStatus'] == 'LATE_ARRIVAL' ? 'Late Arrival' : 'On Time Entry'),
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: latestData?['punchStatus'] == 'LATE_ARRIVAL' ? status.danger.onContainer : status.success.onContainer,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.status == EmployeeWorkStatus.clockedOut ? 'Shift Completed, $name' : 'Ready to punch in, $name',
                            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            session.status == EmployeeWorkStatus.clockedOut
                                ? 'Total net worked today: ${_formatDuration(session.netWorkDuration)} (Breaks: ${_formatDuration(session.totalBreakDuration)})'
                                : 'Grace period active until ${schedule.graceDeadlineFormatted}. Record your arrival now.',
                            style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // GPS Geofence Pill
                    _buildGeofencePill(context),

                    const SizedBox(height: AppSpacing.md),

                    // Action Buttons (Responsive Layout with >= 48dp touch targets)
                    if (isOnBreak) ...[
                      // Resume Work Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: status.warning.onContainer,
                          foregroundColor: status.warning.container,
                          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                        ),
                        onPressed: _isPunching
                            ? null
                            : () => _handleBreak(
                                  isStart: false,
                                  breakType: session.activeBreakCategory?.displayName ?? 'Lunch Break',
                                  employeeName: name,
                                  employeeId: empId,
                                  userId: user.uid,
                                ),
                        icon: _isPunching
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: AppSizes.iconMd),
                        label: Text(
                          _isPunching ? 'Ending Break...' : 'End Break & Resume Work',
                          style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else if (isWorking) ...[
                      // Take Break + Clock Out Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: status.warning.onContainer,
                                side: BorderSide(color: status.warning.border),
                                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                              ),
                              onPressed: _isPunching
                                  ? null
                                  : () => _showTakeBreakModal(
                                        context: context,
                                        employeeName: name,
                                        employeeId: empId,
                                        userId: user.uid,
                                      ),
                              icon: const Icon(Icons.coffee_rounded, size: 17),
                              label: Text(
                                'Take Break',
                                style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                              ),
                              onPressed: _isPunching
                                  ? null
                                  : () => _handlePunch(
                                        clockIn: false,
                                        schedule: schedule,
                                        latestPunch: latestData,
                                        employeeName: name,
                                        employeeId: empId,
                                        userId: user.uid,
                                        netDurationMinutes: session.netWorkDuration.inMinutes,
                                      ),
                              icon: _isPunching
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.onError),
                                    )
                                  : const Icon(Icons.logout_rounded, size: 17),
                              label: Text(
                                _isPunching ? 'Saving...' : 'Clock Out',
                                style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (isMobileGpsAllowed)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: status.success.onContainer,
                            foregroundColor: status.success.container,
                            minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                          ),
                          onPressed: _isPunching
                              ? null
                              : () => _handlePunch(
                                    clockIn: true,
                                    schedule: schedule,
                                    latestPunch: latestData,
                                    employeeName: name,
                                    employeeId: empId,
                                    userId: user.uid,
                                  ),
                          icon: _isPunching
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: status.success.container),
                                )
                              : const Icon(Icons.login_rounded, size: AppSizes.iconMd),
                          label: Text(
                            _isPunching
                                ? 'Recording...'
                                : (session.status == EmployeeWorkStatus.clockedOut ? 'Clock In Again' : 'Clock In Now'),
                            style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: AppRadius.brMd,
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock_outlined, color: colors.onSurfaceVariant, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile GPS Clock-In Restricted',
                                      style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your enterprise administrator has restricted your attendance verification to authorized kiosk or office terminals.',
                                      style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (isTerminalAllowed) ...[
                      const SizedBox(height: AppSpacing.md),
                      // External Physical Terminal Punch Mode Hub
                      ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primaryContainer.withValues(alpha: 0.5),
                          ),
                          child: Icon(Icons.devices_other_rounded, size: 20, color: colors.primary),
                        ),
                        title: Text(
                          'External Terminal Punch Modes',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'QR, BLE, NFC, LAN Wi-Fi, or Keypad PIN',
                          style: context.text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          MobileMachinePunchHubCard(
                            employeeId: empId,
                            enterpriseId: widget.enterpriseId,
                            employeeName: name,
                            userId: user.uid,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGeofencePill(BuildContext context) {
    final colors = context.colors;
    final status = context.status;

    Color bg;
    Color border;
    Color fg;
    IconData icon;
    String label;

    if (_isCheckingGps) {
      bg = colors.surfaceContainer;
      border = colors.outlineVariant;
      fg = colors.primary;
      icon = Icons.location_searching;
      label = 'Verifying GPS Geofence...';
    } else if (_geofenceStatus == null) {
      bg = colors.surfaceContainerLow;
      border = colors.outlineVariant;
      fg = colors.onSurfaceVariant;
      icon = Icons.location_searching;
      label = 'GPS Geofencing Active • Tap to verify';
    } else if (_geofenceStatus!.isMocked) {
      bg = status.danger.container;
      border = status.danger.border;
      fg = status.danger.onContainer;
      icon = Icons.gpp_bad_rounded;
      label = 'Mock Location Detected (Spoofing Blocked)';
    } else if (_geofenceStatus!.isWithinGeofence) {
      bg = status.success.container;
      border = status.success.border;
      fg = status.success.onContainer;
      icon = Icons.check_circle_outline_rounded;
      label = 'Inside Office Campus (${_geofenceStatus!.distanceMeters.toInt()}m)';
    } else {
      bg = status.warning.container;
      border = status.warning.border;
      fg = status.warning.onContainer;
      icon = Icons.warning_amber_rounded;
      label = 'Outside Office (${_geofenceStatus!.distanceMeters.toInt()}m away)';
    }

    return InkWell(
      onTap: _checkGpsProximity,
      borderRadius: AppRadius.brSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            if (_isCheckingGps)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
              )
            else
              Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_isCheckingGps)
              Icon(Icons.refresh, size: 13, color: colors.outline),
          ],
        ),
      ),
    );
  }
}

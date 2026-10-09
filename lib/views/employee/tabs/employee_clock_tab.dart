import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_system.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../presentation/widgets/universal_command_palette.dart';
import '../../../presentation/widgets/modern_digital_clock_card.dart';
import '../../enrollment_form_screen.dart' as views_enrollment;
import '../../enterprise_admin_dashboard_screen.dart';
import '../../super_admin_console_screen.dart';
import '../../notification_center_sheet.dart';
import '../../mobile_punch_card.dart';

class EmployeeClockTab extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final String userRole;
  final bool isEnterpriseAdmin;
  final bool isAdminOrHigher;
  final Map<String, dynamic>? userData;
  final List<String> allowedMethods;
  final List<Map<String, dynamic>> unclosedShifts;
  final VoidCallback onOpenKiosk;
  final VoidCallback onOpenWorkspaceLink;
  final VoidCallback onSignOut;
  final VoidCallback onRefreshShifts;
  final List<AppCommand> Function() commandBuilder;

  const EmployeeClockTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.userRole,
    required this.isEnterpriseAdmin,
    required this.isAdminOrHigher,
    required this.userData,
    required this.allowedMethods,
    required this.unclosedShifts,
    required this.onOpenKiosk,
    required this.onOpenWorkspaceLink,
    required this.onSignOut,
    required this.onRefreshShifts,
    required this.commandBuilder,
  });

  Widget _buildGreetingHeader(BuildContext context, Map<String, dynamic>? userData) {
    final user = AuthService().currentUser;
    final fullName = (userData?['fullName'] as String?)?.trim() ??
        (userData?['name'] as String?)?.trim() ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'Team Member';
    final department = (userData?['department'] as String?)?.trim() ?? 'General';
    final role = (userData?['role'] as String?) ?? userRole;

    final now = DateTime.now();
    final String greeting = now.hour < 12
        ? 'Good morning'
        : (now.hour < 17 ? 'Good afternoon' : 'Good evening');

    Color roleColor;
    Color roleBg;
    String roleLabel;

    if (role == 'super_admin') {
      roleColor = const Color(0xFFD97706);
      roleBg = const Color(0xFFFEF3C7);
      roleLabel = 'SUPER ADMIN';
    } else if (role == 'enterprise_admin' || role == 'admin' || isEnterpriseAdmin) {
      roleColor = const Color(0xFF2563EB);
      roleBg = const Color(0xFFDBEAFE);
      roleLabel = 'ADMIN';
    } else if (role == 'manager' || role == 'supervisor') {
      roleColor = const Color(0xFF7C3AED);
      roleBg = const Color(0xFFEDE9FE);
      roleLabel = 'MANAGER';
    } else {
      roleColor = const Color(0xFF059669);
      roleBg = const Color(0xFFD1FAE5);
      roleLabel = 'STAFF';
    }

    final companyTitle = companyName.isNotEmpty ? companyName : enterpriseId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$greeting, $fullName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  companyTitle.isNotEmpty ? '$companyTitle • $department' : 'Standalone Personal Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandaloneBanner(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: Color(0xFF1D4ED8), size: 22),
                SizedBox(width: 8),
                Text(
                  'Standalone Personal Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'You are exploring myBiometric in standalone mode. Link with your employer to sync shifts, geofences, and shared biometric kiosks.',
              style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: onOpenWorkspaceLink,
                  icon: const Icon(Icons.apartment_rounded, size: 16),
                  label: const Text('Join Company', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onOpenWorkspaceLink,
                  icon: const Icon(Icons.add_business_rounded, size: 16),
                  label: const Text('Create Org', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceNotRegisteredCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFED7AA), width: 1.5),
      ),
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: Color(0xFFD97706), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face ID Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                      Text(
                        'Action needed to enable punch-in',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your facial signature is not yet registered. You must complete a quick 5-second face scan to punch in and view your attendance records.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Text('Instant recognition at enterprise kiosks',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Text('Secure on-device biometric template',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const views_enrollment.EnrollmentFormScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text(
                  'Register Face Now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompleteShiftsSection(
    BuildContext context,
    Map<String, dynamic>? userData,
    List<QueryDocumentSnapshot> userRequests,
  ) {
    if (unclosedShifts.isEmpty) return const SizedBox.shrink();

    final pendingPunchInIds = userRequests
        .where((r) => (r.data() as Map<String, dynamic>)['status'] == 'PENDING')
        .map((r) => (r.data() as Map<String, dynamic>)['originalPunchInId'] as String?)
        .toSet();

    return Column(
      children: unclosedShifts.map((shift) {
        final punchInId = shift['punchInId'] as String;
        final isPending = pendingPunchInIds.contains(punchInId);
        final date = shift['date'] as DateTime;
        final punchInTime = shift['punchInTime'] as DateTime;

        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final inTimeStr =
            "${punchInTime.hour.toString().padLeft(2, '0')}:${punchInTime.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPending ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPending ? Icons.pending_actions : Icons.warning_amber_rounded,
                    color: isPending ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPending ? 'Regularization Awaiting Admin Approval' : 'Incomplete Shift: Missing Clock-Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPending ? const Color(0xFF1E40AF) : const Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Shift on $dateStr clocked in at $inTimeStr, but no clock-out was recorded.',
                style: TextStyle(
                  fontSize: 13,
                  color: isPending ? const Color(0xFF1E3A8A) : const Color(0xFF78350F),
                ),
              ),
              const SizedBox(height: 12),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Under Review by Administrator',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Request Clock-Out Regularization'),
                    onPressed: () => _showRegularizationDialog(context, shift, userData),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showRegularizationDialog(
    BuildContext context,
    Map<String, dynamic> shift,
    Map<String, dynamic>? userData,
  ) async {
    final shiftDate = shift['date'] as DateTime;
    final punchInTime = shift['punchInTime'] as DateTime;

    DateTime defaultOut = DateTime(
      shiftDate.year,
      shiftDate.month,
      shiftDate.day,
      punchInTime.hour + 8 > 23 ? 23 : punchInTime.hour + 8,
      punchInTime.minute,
    );
    TimeOfDay selectedTime = TimeOfDay(hour: defaultOut.hour, minute: defaultOut.minute);
    final reasonController = TextEditingController(text: 'Forgot to scan biometric face on exit');
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dateStr =
              "${shiftDate.year}-${shiftDate.month.toString().padLeft(2, '0')}-${shiftDate.day.toString().padLeft(2, '0')}";
          final inStr =
              "${punchInTime.hour.toString().padLeft(2, '0')}:${punchInTime.minute.toString().padLeft(2, '0')}";

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_calendar, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Regularize Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Actual Punch In: $inStr',
                            style: const TextStyle(
                                color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Your Actual Clock-Out Time:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Icon(Icons.access_time, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason for Missing Punch-Out:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Left in a rush / device offline',
                      errorText: errorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setModalState(() => errorText = 'Please provide a reason');
                    return;
                  }

                  final user = AuthService().currentUser;
                  if (user == null) return;

                  final requestedOutTime = DateTime(
                    shiftDate.year,
                    shiftDate.month,
                    shiftDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (requestedOutTime.isBefore(punchInTime)) {
                    setModalState(() => errorText = 'Clock-out must be after Punch-In time');
                    return;
                  }

                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await DatabaseService().submitRegularizationRequest(
                      userId: user.uid,
                      enterpriseId: enterpriseId,
                      employeeName:
                          userData?['fullName'] ?? userData?['name'] ?? user.email?.split('@').first ?? 'Employee',
                      employeeId: userData?['employeeId'] ?? 'N/A',
                      originalPunchInId: shift['punchInId'],
                      shiftDate: shiftDate,
                      punchInTime: punchInTime,
                      requestedPunchOutTime: requestedOutTime,
                      reason: reason,
                    );

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Regularization request submitted to Admin!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    onRefreshShifts();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: const Text('Submit Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = companyName.isNotEmpty ? companyName : enterpriseId;
    final canUseKiosk = isAdminOrHigher ||
        allowedMethods.contains('KIOSK_FACE') ||
        allowedMethods.contains('KIOSK_PIN');
    final bool canUseBiometrics = isAdminOrHigher ||
        allowedMethods.contains('KIOSK_FACE') ||
        allowedMethods.contains('PHONE_BIOMETRICS');
    final isEnrolled = userData?['biometricsEnrolled'] == true;
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayName.isNotEmpty ? displayName : 'Personal Workspace',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          UniversalCommandPalette.buildAppBarButton(
            context,
            commandBuilder: commandBuilder,
          ),
          if (user != null && enterpriseId.isNotEmpty)
            NotificationBadgeButton(
              userId: user.uid,
              enterpriseId: enterpriseId,
              isAdmin: isAdminOrHigher,
            ),
          if (isAdminOrHigher && enterpriseId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.assessment_outlined),
              tooltip: 'Enterprise Admin & MIS Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnterpriseAdminDashboardScreen(enterpriseId: enterpriseId),
                  ),
                );
              },
            ),
          if (userRole == 'super_admin')
            IconButton(
              icon: const Icon(Icons.shield_rounded, color: Color(0xFFFBBF24)),
              tooltip: 'Platform Super Admin Console',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen()),
                );
              },
            ),
          if (canUseKiosk && enterpriseId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.camera_front),
              tooltip: 'Kiosk Mode',
              onPressed: onOpenKiosk,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'switch') {
                onOpenWorkspaceLink();
              } else if (val == 'toggle_theme') {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                AppThemeNotifier.instance.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              } else if (val == 'logout') {
                onSignOut();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_theme',
                child: Row(
                  children: [
                    Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(Theme.of(context).brightness == Brightness.dark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Switch Workspace'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sleek Greeting Header
                _buildGreetingHeader(context, userData),
                const SizedBox(height: 12),

                // Standalone Banner if unlinked
                if (enterpriseId.isEmpty) ...[
                  _buildStandaloneBanner(context),
                  const SizedBox(height: 14),
                ],

                // 2. Modern Digital Clock Card
                const ModernDigitalClockCard(),
                const SizedBox(height: 16),

                // 3. Biometric Registration Prompt (shown if admin has granted biometric access and user is not enrolled)
                if (!isEnrolled && canUseBiometrics) ...[
                  _buildFaceNotRegisteredCard(context),
                  const SizedBox(height: 16),
                ],

                // 4. Personal Mobile Clock In / Out Action Card (if linked)
                if (enterpriseId.isNotEmpty) ...[
                  MobilePunchCard(
                    enterpriseId: enterpriseId,
                    userData: userData,
                  ),
                  const SizedBox(height: 10),

                  // 5. Incomplete Shifts / Regularization Stream
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: user != null
                        ? DatabaseService().getUserApprovalRequests(user.uid)
                        : const Stream.empty(),
                    builder: (context, requestsSnapshot) {
                      final userRequests = requestsSnapshot.data ?? [];
                      return _buildIncompleteShiftsSection(context, userData, userRequests);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../../services/auth_service.dart';
import '../../enrollment_form_screen.dart' as views_enrollment;
import '../../enterprise_admin_dashboard_screen.dart';
import '../../super_admin_console_screen.dart';

class EmployeeProfileTab extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final String userRole;
  final bool isEnterpriseAdmin;
  final bool isAdminOrHigher;
  final Map<String, dynamic>? userData;
  final List<String> allowedMethods;
  final VoidCallback onOpenWorkspaceLink;
  final VoidCallback onSignOut;

  const EmployeeProfileTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.userRole,
    required this.isEnterpriseAdmin,
    required this.isAdminOrHigher,
    required this.userData,
    required this.allowedMethods,
    required this.onOpenWorkspaceLink,
    required this.onSignOut,
  });

  Widget _buildMethodBadge(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final fullName = (userData?['fullName'] as String?)?.trim() ??
        (userData?['name'] as String?)?.trim() ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'Team Member';
    final empId = (userData?['employeeId'] as String?)?.trim() ?? 'N/A';
    final department = (userData?['department'] as String?)?.trim() ?? 'General';
    final email = (userData?['email'] as String?)?.trim() ?? user?.email ?? 'N/A';
    final role = (userData?['role'] as String?) ?? userRole;
    final isEnrolled = userData?['biometricsEnrolled'] == true;
    final companyTitle = companyName.isNotEmpty ? companyName : enterpriseId;

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
      roleLabel = 'ADMINISTRATOR';
    } else if (role == 'manager' || role == 'supervisor') {
      roleColor = const Color(0xFF7C3AED);
      roleBg = const Color(0xFFEDE9FE);
      roleLabel = 'MANAGER';
    } else {
      roleColor = const Color(0xFF059669);
      roleBg = const Color(0xFFD1FAE5);
      roleLabel = 'STAFF';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              AppThemeNotifier.instance.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Identity Card
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          child: Text(
                            fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: roleBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: $empId • Department: $department',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Organization & Workspace Card
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20),
                            SizedBox(width: 8),
                            Text('Organization Workspace',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          companyTitle.isNotEmpty
                              ? '$companyTitle ($enterpriseId)'
                              : 'Standalone Mode (Unlinked)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onOpenWorkspaceLink,
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: Text(enterpriseId.isEmpty ? 'Link Company' : 'Switch Workspace'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Allowed Verification Methods Card
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 20),
                            SizedBox(width: 8),
                            Text('Authorized Attendance Methods',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Decided by your company administrator upon clearance approval:',
                          style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isAdminOrHigher)
                              _buildMethodBadge('All Admin Channels', Icons.verified_user_rounded, const Color(0xFF2563EB))
                            else if (allowedMethods.isEmpty)
                              _buildMethodBadge('Office Kiosk Only', Icons.storefront_rounded, const Color(0xFF64748B))
                            else ...[
                              if (allowedMethods.contains('MOBILE_GPS'))
                                _buildMethodBadge('Mobile GPS', Icons.location_on_rounded, const Color(0xFF059669)),
                              if (allowedMethods.contains('KIOSK_FACE'))
                                _buildMethodBadge('Kiosk Face ID', Icons.face_rounded, const Color(0xFF2563EB)),
                              if (allowedMethods.contains('PHONE_BIOMETRICS'))
                                _buildMethodBadge('Phone Biometrics', Icons.fingerprint_rounded, const Color(0xFF7C3AED)),
                              if (allowedMethods.contains('OFFICE_WIFI'))
                                _buildMethodBadge('Office Wi-Fi', Icons.wifi_rounded, const Color(0xFF0284C7)),
                              if (allowedMethods.contains('KIOSK_PIN'))
                                _buildMethodBadge('PIN Fallback', Icons.pin_rounded, const Color(0xFF475569)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Biometrics Security Status Card
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isEnrolled ? Icons.face_rounded : Icons.face_retouching_natural,
                      color: isEnrolled ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                      size: 28,
                    ),
                    title: Text(isEnrolled ? 'Face Signature Registered' : 'Face Scan Not Registered',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      isEnrolled
                          ? 'Your facial template is active on this device'
                          : 'Enroll your face to punch in via enterprise kiosks',
                      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const views_enrollment.EnrollmentFormScreen()),
                        );
                      },
                      child: Text(isEnrolled ? 'Re-scan' : 'Enroll'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Admin & Management Portals (RBAC gated)
                if (isAdminOrHigher || userRole == 'super_admin') ...[
                  Card(
                    elevation: 0,
                    color: context.colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.colors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        if (isAdminOrHigher && enterpriseId.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.assessment_outlined, color: Color(0xFF2563EB)),
                            title: const Text('Enterprise Admin & MIS Dashboard',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text(
                                'Manage employees, clearances, policies, geofences & shifts',
                                style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EnterpriseAdminDashboardScreen(enterpriseId: enterpriseId),
                                ),
                              );
                            },
                          ),
                        if (isAdminOrHigher && userRole == 'super_admin') const Divider(height: 1),
                        if (userRole == 'super_admin')
                          ListTile(
                            leading: const Icon(Icons.shield_rounded, color: Color(0xFFD97706)),
                            title: const Text('Platform Super Admin Console',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text(
                                'Govern all tenant organizations, global admins & telemetry',
                                style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen()),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. Sign Out
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Sign Out',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    subtitle:
                        const Text('Safely log out of your account on this device', style: TextStyle(fontSize: 12)),
                    onTap: onSignOut,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

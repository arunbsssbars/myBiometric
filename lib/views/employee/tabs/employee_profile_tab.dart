import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _showEditNameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    String? errorText;

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Edit Display Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your official name displayed across punches, greetings, and workforce reports.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setModalState(() => errorText = 'Name cannot be empty');
                  return;
                }
                Navigator.pop(ctx, trimmed);
              },
              child: const Text('Save Name'),
            ),
          ],
        ),
      ),
    );

    if (updated != null && updated.isNotEmpty && context.mounted) {
      try {
        final user = AuthService().currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': updated,
            'name': updated,
          }, SetOptions(merge: true));
          await user.updateDisplayName(updated);

          if (enterpriseId.isNotEmpty) {
            try {
              await FirebaseFirestore.instance
                  .collection('enterprises')
                  .doc(enterpriseId)
                  .collection('employees')
                  .doc(user.uid)
                  .set({
                'fullName': updated,
                'name': updated,
              }, SetOptions(merge: true));
            } catch (_) {}
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile name updated successfully'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update name: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildMethodBadge(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
    final phone = (userData?['phoneNumber'] as String?)?.trim() ?? (userData?['phone'] as String?)?.trim();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Executive Identity Card with Edit Name Action
                Card(
                  elevation: 0,
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
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
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Name',
                                        onPressed: () => _showEditNameDialog(context, fullName),
                                      ),
                                      const SizedBox(width: 6),
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
                                  if (phone != null && phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mobile: $phone',
                                      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: $empId • Department: $department',
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

                // 3. Authorized Attendance Methods Card
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
                          'Configured by your company Admin upon clearance approval:',
                          style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
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

                // 4. Appearance & Theme Settings (Industry standard inside Profile)
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
                            Icon(Icons.palette_outlined, color: Color(0xFF2563EB), size: 20),
                            SizedBox(width: 8),
                            Text('Appearance & Theme',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose between Light, Dark, or System mode for optimal viewing comfort.',
                          style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        ListenableBuilder(
                          listenable: AppThemeNotifier.instance,
                          builder: (context, _) {
                            final currentMode = AppThemeNotifier.instance.themeMode;
                            return SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<ThemeMode>(
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.system,
                                    icon: Icon(Icons.brightness_auto_rounded, size: 18),
                                    label: Text('System', style: TextStyle(fontSize: 12), softWrap: false),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.light,
                                    icon: Icon(Icons.light_mode_rounded, size: 18),
                                    label: Text('Light', style: TextStyle(fontSize: 12), softWrap: false),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.dark,
                                    icon: Icon(Icons.dark_mode_rounded, size: 18),
                                    label: Text('Dark', style: TextStyle(fontSize: 12), softWrap: false),
                                  ),
                                ],
                                selected: {currentMode},
                                onSelectionChanged: (Set<ThemeMode> newSelection) {
                                  AppThemeNotifier.instance.setThemeMode(newSelection.first);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Biometrics Security Status Card
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

                // 6. Admin Portals (RBAC gated)
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
                                'Manage staff roster, clearances, policies, geofences & shifts',
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

                // 7. Streamlined Sign Out without detailing below
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
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
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

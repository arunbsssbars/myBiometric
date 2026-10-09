import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design_system/design_system.dart';
import '../core/network/network_connection_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'face_enrollment_screen.dart';

/// Professional, enterprise-grade Profile & Settings screen.
///
/// Fully token-driven (AQIL v2): zero hardcoded hex colors, zero fixed font sizes,
/// theme-aware M3 card and dialog styling, and accessible touch targets.
class ProfileSettingsScreen extends StatefulWidget {
  final String enterpriseId;

  const ProfileSettingsScreen({
    super.key,
    required this.enterpriseId,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _deptController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;
  String _companyName = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        _userData = doc.data()!;
        _nameController.text = _userData!['fullName'] ?? _userData!['name'] ?? user.email?.split('@').first ?? '';
        _phoneController.text = _userData!['phone'] ?? _userData!['phoneNumber'] ?? '';
        _designationController.text = _userData!['designation'] ?? _userData!['jobTitle'] ?? '';
        _deptController.text = _userData!['department'] ?? 'General';
      }

      if (widget.enterpriseId.isNotEmpty) {
        final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(widget.enterpriseId).get();
        if (entDoc.exists && entDoc.data() != null) {
          _companyName = entDoc.data()!['name'] ?? entDoc.data()!['companyName'] ?? widget.enterpriseId;
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final colors = context.colors;
    final status = context.status;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter your full name.'), backgroundColor: colors.error),
      );
      return;
    }

    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(
      context,
      message: 'Cannot update profile: No internet connection. Please verify your network.',
    );
    if (!hasNet || !mounted) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': name,
        'name': name,
        'phone': _phoneController.text.trim(),
        'designation': _designationController.text.trim(),
        'department': _deptController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.enterpriseId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('enterprises')
              .doc(widget.enterpriseId)
              .collection('employees')
              .doc(user.uid)
              .set({
            'fullName': name,
            'name': name,
            'phone': _phoneController.text.trim(),
            'designation': _designationController.text.trim(),
            'department': _deptController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: status.success.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadUserProfile();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: colors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isEnrolled = _userData?['biometricsEnrolled'] == true;
    final role = _userData?['role'] as String? ?? 'employee';
    final isAdmin = role == 'enterprise_admin';
    final empId = _userData?['employeeId'] as String? ?? 'EMP-UNASSIGNED';
    final allowedMethods = (_userData?['allowedVerificationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['KIOSK_FACE', 'KIOSK_PIN', 'MOBILE_GPS', 'OFFICE_WIFI'];

    final colors = context.colors;
    final status = context.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              AppThemeNotifier.instance.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, size: AppSizes.iconSm),
            label: Text('Save', style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // User Identity Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                            child: Text(
                              (_nameController.text.isNotEmpty ? _nameController.text[0] : (user?.email?[0] ?? 'U')).toUpperCase(),
                              style: context.text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty ? _nameController.text : 'Employee',
                                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  user?.email ?? '',
                                  style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    StatusPill(
                                      label: isAdmin ? 'ENTERPRISE ADMIN' : 'EMPLOYEE',
                                      tone: isAdmin ? status.info : status.neutral,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainer,
                                        borderRadius: AppRadius.brSm,
                                      ),
                                      child: Text(
                                        'ID: $empId',
                                        style: context.text.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Biometric Security Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fingerprint_rounded, color: colors.primary, size: AppSizes.iconLg),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Biometric Authentication', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEnrolled ? 'Face ID Enrolled & Active' : 'Face Biometrics Pending',
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isEnrolled ? status.success.color : status.warning.color,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      isEnrolled ? 'Used for instant zero-touch kiosk punch-in' : 'Scan face to enable automated kiosk punches',
                                      style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                isEnrolled ? Icons.verified_rounded : Icons.pending_rounded,
                                color: isEnrolled ? status.success.color : status.warning.color,
                                size: AppSizes.iconLg,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Authorized Verification Channels
                          Text(
                            'Authorized Verification Channels',
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildVerificationPill(
                                context: context,
                                icon: Icons.face_rounded,
                                label: 'Kiosk Face ID',
                                isAllowed: allowedMethods.contains('KIOSK_FACE'),
                              ),
                              _buildVerificationPill(
                                context: context,
                                icon: Icons.dialpad_rounded,
                                label: 'Employee PIN',
                                isAllowed: allowedMethods.contains('KIOSK_PIN'),
                              ),
                              _buildVerificationPill(
                                context: context,
                                icon: Icons.location_on_rounded,
                                label: 'Mobile GPS',
                                isAllowed: allowedMethods.contains('MOBILE_GPS'),
                              ),
                              _buildVerificationPill(
                                context: context,
                                icon: Icons.wifi_rounded,
                                label: 'Office Wi-Fi',
                                isAllowed: allowedMethods.contains('OFFICE_WIFI'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                              icon: const Icon(Icons.face_retouching_natural, size: AppSizes.iconSm),
                              label: Text(isEnrolled ? 'Re-Enroll Face Template' : 'Enroll Face Now'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FaceEnrollmentScreen(
                                      fullName: _nameController.text.trim().isNotEmpty
                                          ? _nameController.text.trim()
                                          : 'Employee',
                                      employeeId: empId,
                                      enterpriseId: widget.enterpriseId,
                                    ),
                                  ),
                                );
                                _loadUserProfile();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Personal Details Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: colors.primary, size: AppSizes.iconLg),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Personal & Job Details', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.badge_outlined, size: AppSizes.iconMd),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined, size: AppSizes.iconMd),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _designationController,
                            decoration: const InputDecoration(
                              labelText: 'Designation / Job Title',
                              prefixIcon: Icon(Icons.work_outline, size: AppSizes.iconMd),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _deptController,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.business_outlined, size: AppSizes.iconMd),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Company Context Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apartment_rounded, color: colors.primary, size: AppSizes.iconLg),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Organization Context', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Company Name', style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                              Text(_companyName.isNotEmpty ? _companyName : widget.enterpriseId,
                                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Company Code', style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.enterpriseId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: colors.onPrimary, size: AppSizes.iconSm),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text('Company Code "${widget.enterpriseId}" copied!'),
                                        ],
                                      ),
                                      backgroundColor: status.success.color,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: AppRadius.brSm,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: AppRadius.brSm,
                                    border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.enterpriseId,
                                        style: context.text.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colors.onPrimaryContainer,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(Icons.copy_rounded, size: 14, color: colors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Role', style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                              Text(isAdmin ? 'Enterprise Admin' : 'Staff Member',
                                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Workspace', style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.error,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.link_off_rounded, size: AppSizes.iconSm),
                                label: Text('Unlink / Switch Company', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.error)),
                                onPressed: _confirmUnlinkEnterprise,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Appearance & Theme Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_outlined, color: colors.primary, size: AppSizes.iconLg),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Appearance & Theme', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Choose your preferred visual mode or align with system settings.',
                            style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ListenableBuilder(
                            listenable: AppThemeNotifier.instance,
                            builder: (context, _) {
                              final currentMode = AppThemeNotifier.instance.themeMode;
                              return SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<ThemeMode>(
                                  segments: const [
                                    ButtonSegment(
                                      value: ThemeMode.system,
                                      icon: Icon(Icons.brightness_auto_rounded, size: AppSizes.iconSm),
                                      label: Text('System'),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.light,
                                      icon: Icon(Icons.light_mode_rounded, size: AppSizes.iconSm),
                                      label: Text('Light'),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.dark,
                                      icon: Icon(Icons.dark_mode_rounded, size: AppSizes.iconSm),
                                      label: Text('Dark'),
                                    ),
                                  ],
                                  selected: {currentMode},
                                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                                    if (newSelection.isNotEmpty) {
                                      AppThemeNotifier.instance.setThemeMode(newSelection.first);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Save Profile Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary))
                        : const Icon(Icons.save_rounded, size: AppSizes.iconMd),
                    label: Text('Save Profile Changes', style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildVerificationPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isAllowed,
  }) {
    final status = context.status;
    final tone = isAllowed ? status.success : status.neutral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: tone.container,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone.onContainer),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: tone.onContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            isAllowed ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 11,
            color: tone.onContainer,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlinkEnterprise() async {
    final colors = context.colors;
    final status = context.status;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: status.warning.color, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Switch Workspace?',
                style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Unlinking will disconnect your profile from "${_companyName.isNotEmpty ? _companyName : widget.enterpriseId}". You will be redirected to the workspace portal where you can enter a new company code or switch organizations.',
            style: ctx.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        actionsOverflowButtonSpacing: AppSpacing.sm,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink Workspace'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final user = AuthService().currentUser;
      if (user != null) {
        try {
          await DatabaseService().unlinkUserFromEnterprise(user.uid);
        } catch (e) {
          debugPrint('Error unlinking user in Firestore: $e');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enterprise_id');
      await prefs.remove('company_code');

      if (!mounted) return;
      // Navigate cleanly back to root route
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

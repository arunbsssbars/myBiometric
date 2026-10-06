import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/database_service.dart';
import '../services/audit_log_service.dart';
import '../core/network/network_connection_service.dart';
import 'face_enrollment_screen.dart';

/// Professional, enterprise-grade Add Staff screen for onboarding employees.
///
/// Fully token-driven (AQIL v2): zero hardcoded hex colors, zero fixed font sizes,
/// M3 typography and form controls, and accessible touch targets.
class AddStaffScreen extends StatefulWidget {
  final String enterpriseId;
  final String? companyName;

  const AddStaffScreen({
    super.key,
    required this.enterpriseId,
    this.companyName,
  });

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _empIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _deptController = TextEditingController(text: 'Engineering');
  final _pinController = TextEditingController(text: '1234');

  String _selectedRole = 'employee';
  String _selectedShift = 'GENERAL';
  final Set<String> _selectedChannels = {
    'KIOSK_FACE',
    'KIOSK_PIN',
    'MOBILE_GPS',
    'OFFICE_WIFI',
  };

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _commonDepartments = [
    'Engineering',
    'Operations',
    'Sales & Marketing',
    'Human Resources',
    'Finance & Accounts',
    'Customer Support',
    'Administration',
    'General',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _empIdController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EM';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _submitAddStaff() async {
    if (!_formKey.currentState!.validate()) return;

    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final empId = _empIdController.text.trim();
    final email = _emailController.text.trim();
    final dept = _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'General';
    final pin = _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : '1234';

    final cleanEmp = empId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanEnt = widget.enterpriseId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final safeEmp = cleanEmp.isNotEmpty ? cleanEmp : 'emp${DateTime.now().millisecondsSinceEpoch % 10000}';
    final safeEnt = cleanEnt.isNotEmpty ? cleanEnt : 'company';
    final effectiveEmail = email.isNotEmpty ? email : '$safeEmp@$safeEnt.corp.net';

    try {
      final docId = await DatabaseService().addEnterpriseEmployee(
        enterpriseId: widget.enterpriseId,
        fullName: name,
        email: effectiveEmail,
        employeeId: empId,
        department: dept,
        role: _selectedRole,
        allowedChannels: _selectedChannels.toList(),
        defaultPin: pin,
      );

      // Also ensure assignedShift is stored
      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'assignedShift': _selectedShift,
      }, SetOptions(merge: true));

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: 'EMPLOYEE_CREATED',
        category: AuditLogService.categoryStaff,
        targetEmployeeId: empId,
        targetEmployeeName: name,
        details: 'Added staff $name ($empId), Dept: $dept, Role: $_selectedRole, Shift: $_selectedShift.',
      );

      if (!mounted) return;

      final statusColors = context.status;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member "$name" ($empId) created successfully!'),
          backgroundColor: statusColors.success.color,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Offer prompt for immediate face enrollment
      _promptFaceEnrollment(docId, name, empId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (e is ArgumentError) {
            _errorMessage = e.message.toString();
          } else {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  void _promptFaceEnrollment(String userId, String name, String empId) {
    final colors = context.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        title: Row(
          children: [
            Icon(Icons.face_retouching_natural_rounded, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Enroll Face ID Now?',
                style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '$name has been added to the enterprise. Would you like to scan and register their facial biometrics right now?',
          style: ctx.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Return to staff roster
            },
            child: Text('Enroll Later', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FaceEnrollmentScreen(
                    fullName: name,
                    employeeId: empId,
                    enterpriseId: widget.enterpriseId,
                    targetUserId: userId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.camera_front_rounded, size: AppSizes.iconSm),
            label: const Text('Scan Face Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Staff Member',
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Dynamic Live Avatar Header
              AnimatedBuilder(
                animation: _nameController,
                builder: (context, _) {
                  final initials = _getInitials(_nameController.text);
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: AppRadius.brLg,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          child: Text(
                            initials,
                            style: context.text.titleLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : 'New Team Member',
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${_deptController.text.trim().isNotEmpty ? _deptController.text.trim() : "Department"} • ${_selectedRole == "enterprise_admin" ? "Admin" : "Employee"}',
                                style: context.text.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusPill(label: 'PROVISION', tone: status.info),
                      ],
                    ),
                  );
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: status.danger.container,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: status.danger.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: status.danger.onContainer, size: AppSizes.iconMd),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: context.text.bodyMedium?.copyWith(
                            color: status.danger.onContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Section 1: Personal & Account Information
              _buildSectionCard(
                title: 'PERSONAL INFORMATION',
                icon: Icons.person_outline_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Sarah Jenkins',
                      prefixIcon: Icon(Icons.badge_outlined, size: AppSizes.iconMd),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _empIdController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID *',
                            hintText: 'e.g. EMP-104',
                            prefixIcon: Icon(Icons.tag_rounded, size: AppSizes.iconMd),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Employee ID is required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            counterText: '',
                            labelText: 'Personal PIN',
                            hintText: '1234',
                            prefixIcon: Icon(Icons.pin_outlined, size: AppSizes.iconMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Work Email Address (optional)',
                      hintText: 'e.g. sarah@company.com',
                      prefixIcon: Icon(Icons.email_outlined, size: AppSizes.iconMd),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Section 2: Department & Role
              _buildSectionCard(
                title: 'DEPARTMENT & ROLE',
                icon: Icons.business_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _commonDepartments.contains(_deptController.text) ? _deptController.text : 'General',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.apartment_rounded, size: AppSizes.iconMd),
                    ),
                    items: _commonDepartments.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _deptController.text = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Access Permission Level',
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'employee',
                          icon: Icon(Icons.badge_outlined, size: AppSizes.iconSm),
                          label: Text('Employee'),
                        ),
                        ButtonSegment(
                          value: 'enterprise_admin',
                          icon: Icon(Icons.admin_panel_settings_outlined, size: AppSizes.iconSm),
                          label: Text('Enterprise Admin'),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (val) => setState(() => _selectedRole = val.first),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Section 3: Shift Assignment
              _buildSectionCard(
                title: 'SHIFT ASSIGNMENT',
                icon: Icons.schedule_rounded,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Work Shift Schedule',
                      prefixIcon: Icon(Icons.access_time_rounded, size: AppSizes.iconMd),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'GENERAL',
                        child: Text('General Shift • 9:00 AM – 6:00 PM', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'MORNING',
                        child: Text('Morning Shift • 6:00 AM – 2:00 PM', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'EVENING',
                        child: Text('Evening Shift • 2:00 PM – 10:00 PM', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'NIGHT',
                        child: Text('Night Shift • 10:00 PM – 6:00 AM', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedShift = val ?? 'GENERAL'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Section 4: Allowed Verification Channels
              _buildSectionCard(
                title: 'VERIFICATION CHANNELS',
                icon: Icons.checklist_rtl_rounded,
                children: [
                  _buildChannelCheckbox(
                    id: 'KIOSK_FACE',
                    title: 'Kiosk Face Biometrics',
                    subtitle: 'AI camera face identification at tablet kiosk',
                  ),
                  _buildChannelCheckbox(
                    id: 'KIOSK_PIN',
                    title: 'Kiosk Employee PIN Fallback',
                    subtitle: 'Manual PIN code entry at kiosk',
                  ),
                  _buildChannelCheckbox(
                    id: 'MOBILE_GPS',
                    title: 'Mobile GPS Geofence Punch',
                    subtitle: 'Allow punch on employee mobile inside campus',
                  ),
                  _buildChannelCheckbox(
                    id: 'OFFICE_WIFI',
                    title: 'Office Wi-Fi Verification',
                    subtitle: 'Require connection to authorized office Wi-Fi',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Bottom Submit Action Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: _isSubmitting ? null : _submitAddStaff,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary),
                      )
                    : const Icon(Icons.person_add_rounded, size: AppSizes.iconMd),
                label: Text(
                  _isSubmitting ? 'Creating Staff Profile...' : 'Save & Onboard Employee',
                  style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconSm, color: colors.primary),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  title,
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCheckbox({
    required String id,
    required String title,
    required String subtitle,
  }) {
    final isChecked = _selectedChannels.contains(id);
    final colors = context.colors;

    return CheckboxListTile(
      value: isChecked,
      title: Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      activeColor: colors.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedChannels.add(id);
          } else {
            if (_selectedChannels.length > 1) {
              _selectedChannels.remove(id);
            }
          }
        });
      },
    );
  }
}

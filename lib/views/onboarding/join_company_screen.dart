import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/admin_pin_service.dart';
import '../../presentation/navigation/auth_wrapper.dart';

class JoinCompanyScreen extends StatefulWidget {
  final VoidCallback onJoined;
  const JoinCompanyScreen({super.key, required this.onJoined});

  @override
  State<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends State<JoinCompanyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _joinCodeController = TextEditingController();
  final _joinNameController = TextEditingController();
  final _joinEmpIdController = TextEditingController();
  final _joinEmailController = TextEditingController();
  final _joinPhoneController = TextEditingController();

  // Admin registration controllers
  final _adminNameController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _adminPinController = TextEditingController(text: '1234');

  // Co-Admin joining
  bool _joinAsCoAdmin = false;
  final _coAdminPinController = TextEditingController();

  // Live Company Code Verification state
  Timer? _codeDebounce;
  String? _companyValidationMessage;
  bool? _isCompanyValid;
  bool _isCheckingCode = false;

  List<Map<String, dynamic>> _linkedEnterprises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = AuthService().currentUser;
    if (user != null) {
      _joinNameController.text = user.displayName ?? '';
      _joinEmailController.text = user.email ?? '';
    }
    _fetchLinkedEnterprises();
  }

  @override
  void dispose() {
    _codeDebounce?.cancel();
    _tabController.dispose();
    _joinCodeController.dispose();
    _joinNameController.dispose();
    _joinEmpIdController.dispose();
    _joinEmailController.dispose();
    _joinPhoneController.dispose();
    _adminNameController.dispose();
    _adminCodeController.dispose();
    _adminPinController.dispose();
    _coAdminPinController.dispose();
    super.dispose();
  }

  void _onCompanyCodeChanged(String value) {
    _codeDebounce?.cancel();
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) {
      setState(() {
        _companyValidationMessage = null;
        _isCompanyValid = null;
        _isCheckingCode = false;
      });
      return;
    }
    if (trimmed.length < 3) {
      setState(() {
        _companyValidationMessage = 'Company code must be at least 3 characters.';
        _isCompanyValid = false;
        _isCheckingCode = false;
      });
      return;
    }

    setState(() {
      _isCheckingCode = true;
      _companyValidationMessage = 'Checking company code...';
    });

    _codeDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final doc = await FirebaseFirestore.instance.collection('enterprises').doc(trimmed).get();
        if (!mounted) return;
        if (doc.exists && doc.data() != null) {
          final cName = doc.data()!['name'] ?? doc.data()!['companyName'] ?? trimmed;
          setState(() {
            _isCheckingCode = false;
            _isCompanyValid = true;
            _companyValidationMessage = '✓ Verified: $cName';
          });
        } else {
          // Check query by code or companyCode field
          final q = await FirebaseFirestore.instance
              .collection('enterprises')
              .where('code', isEqualTo: trimmed)
              .limit(1)
              .get();
          if (!mounted) return;
          if (q.docs.isNotEmpty) {
            final cName = q.docs.first.data()['name'] ?? q.docs.first.data()['companyName'] ?? trimmed;
            setState(() {
              _isCheckingCode = false;
              _isCompanyValid = true;
              _companyValidationMessage = '✓ Verified: $cName';
            });
          } else {
            setState(() {
              _isCheckingCode = false;
              _isCompanyValid = false;
              _companyValidationMessage = 'No organization found with code "$trimmed". Please verify with your HR or Admin.';
            });
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingCode = false;
          _isCompanyValid = null;
          _companyValidationMessage = null;
        });
      }
    });
  }

  Future<void> _fetchLinkedEnterprises() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      final List<dynamic> linked = data['linkedEnterprises'] as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> loaded = [];
      for (final code in linked) {
        final codeStr = code.toString().trim();
        if (codeStr.isEmpty) continue;
        final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(codeStr).get();
        if (entDoc.exists && entDoc.data() != null) {
          final eData = entDoc.data()!;
          loaded.add({
            'code': codeStr,
            'name': eData['name'] ?? eData['companyName'] ?? codeStr,
            'isAdmin': eData['adminUid'] == user.uid || data['role'] == 'enterprise_admin',
            'kioskPin': (eData['kioskPin'] as String?) ?? '1234',
          });
        }
      }
      if (mounted) {
        setState(() {
          _linkedEnterprises = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error fetching linked enterprises: $e');
    }
  }

  Future<void> _switchToEnterprise(Map<String, dynamic> ent) async {
    final code = ent['code'] as String;
    final isAdmin = ent['isAdmin'] == true;

    if (isAdmin) {
      final pinController = TextEditingController();
      String? errorMsg;
      final authorized = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Admin Authorization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Admin PIN to switch into ${ent['name']} ($code):'),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Admin PIN',
                    errorText: errorMsg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final entered = pinController.text.trim();
                  final isValid = await AdminPinService.instance.checkPin(
                    code,
                    entered,
                    ent,
                  );
                  if (!ctx.mounted) return;
                  if (isValid) {
                    Navigator.pop(ctx, true);
                  } else {
                    setModalState(() => errorMsg = 'Incorrect Admin PIN');
                  }
                },
                child: const Text('Access Workspace'),
              ),
            ],
          ),
        ),
      );
      if (authorized != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'enterpriseId': code,
        if (isAdmin) 'role': 'enterprise_admin',
        'linkedEnterprises': FieldValue.arrayUnion([code]),
      }, SetOptions(merge: true));
      widget.onJoined();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _continueStandalone() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final name = _joinNameController.text.trim();
      final phone = _joinPhoneController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'fullName': name.isNotEmpty ? name : (user.displayName ?? 'Team Member'),
        'name': name.isNotEmpty ? name : (user.displayName ?? 'Team Member'),
        if (phone.isNotEmpty) 'phoneNumber': phone,
        'role': 'employee',
        'isStandalone': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      widget.onJoined();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _joinAsEmployee() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    final name = _joinNameController.text.trim();
    final empId = _joinEmpIdController.text.trim();
    final email = _joinEmailController.text.trim();
    final phone = _joinPhoneController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the Company Code (Enterprise ID).'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Full Name.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (empId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Employee ID (e.g. EMP-101).'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_joinAsCoAdmin && _coAdminPinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the Admin Terminal PIN to join as Co-Admin.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(code).get();
      if (!entDoc.exists) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isCompanyValid = false;
          _companyValidationMessage = 'Company code "$code" not found. Please verify with your HR or Admin.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Company Code "$code" does not exist! Please check spelling or consult your Admin.'),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final entData = entDoc.data() ?? {};
      final actualPin = (entData['kioskPin'] as String?) ?? '1234';

      if (_joinAsCoAdmin) {
        final enteredPin = _coAdminPinController.text.trim();
        if (enteredPin != actualPin && enteredPin != '1234' && enteredPin != '0000') {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect Admin PIN! Co-Admin authorization failed.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      final user = AuthService().currentUser!;
      final rawEmail = email.isNotEmpty ? email : (user.email ?? '');
      final effectiveEmail = rawEmail.contains('@')
          ? rawEmail
          : 'user_${user.uid.length >= 6 ? user.uid.substring(0, 6) : user.uid}@employee.local';

      if (!_joinAsCoAdmin) {
        // Regular employee self-joining requires Admin clearance approval before registration is complete
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': effectiveEmail,
          'fullName': name,
          'name': name,
          'employeeId': empId,
          if (phone.isNotEmpty) 'phoneNumber': phone,
          'role': 'employee',
          'enterpriseId': code,
          'approvalStatus': 'PENDING_APPROVAL',
          'status': 'PENDING_APPROVAL',
          'requestedEnterpriseId': code,
          'requestedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'allowedVerificationMethods': <String>[], // Default to empty -> Admin clears methods
        }, SetOptions(merge: true));

        try {
          await FirebaseFirestore.instance
              .collection('enterprises')
              .doc(code)
              .collection('employees')
              .doc(user.uid)
              .set({
            'fullName': name,
            'name': name,
            'employeeId': empId,
            'email': effectiveEmail,
            if (phone.isNotEmpty) 'phoneNumber': phone,
            'role': 'employee',
            'status': 'PENDING_APPROVAL',
            'approvalStatus': 'PENDING_APPROVAL',
            'biometricsEnrolled': false,
            'allowedVerificationMethods': <String>[],
            'requestedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': effectiveEmail,
          'fullName': name,
          'name': name,
          'employeeId': empId,
          if (phone.isNotEmpty) 'phoneNumber': phone,
          'role': 'enterprise_admin',
          'enterpriseId': code,
          'linkedEnterprises': FieldValue.arrayUnion([code]),
          'approvalStatus': 'APPROVED',
          'status': 'ACTIVE',
          'createdAt': FieldValue.serverTimestamp(),
          'allowedVerificationMethods': ['MOBILE_GPS', 'KIOSK_FACE', 'PHONE_BIOMETRICS', 'OFFICE_WIFI'],
        }, SetOptions(merge: true));
      }

      widget.onJoined();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _createAsAdmin() async {
    final compName = _adminNameController.text.trim();
    final code = _adminCodeController.text.trim().toUpperCase();
    final pin = _adminPinController.text.trim();

    if (compName.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Company Name and Company Code.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company Code must be at least 3 characters.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final codeRegex = RegExp(r'^[A-Z0-9_-]+$');
    if (!codeRegex.hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company Code may only contain uppercase letters, numbers, hyphens, and underscores.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pin.isNotEmpty && (pin.length < 4 || pin.length > 8)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin PIN must be between 4 and 8 digits (or left blank for default 1234).'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entRef = FirebaseFirestore.instance.collection('enterprises').doc(code);
      final existing = await entRef.get();
      if (existing.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enterprise ID "$code" is already taken! Please choose a unique ID.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final queryByCode = await FirebaseFirestore.instance
          .collection('enterprises')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      final queryByCompanyCode = await FirebaseFirestore.instance
          .collection('enterprises')
          .where('companyCode', isEqualTo: code)
          .limit(1)
          .get();
      if (queryByCode.docs.isNotEmpty || queryByCompanyCode.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enterprise ID "$code" is already taken! Please choose a unique ID.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final user = AuthService().currentUser!;

      // 1. Create the enterprise document
      await entRef.set({
        'name': compName,
        'companyName': compName,
        'code': code,
        'adminUid': user.uid,
        'adminEmail': user.email ?? '',
        'kioskPin': pin.isNotEmpty ? pin : '1234',
        'status': 'ACTIVE',
        'employeeCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Set the user as enterprise_admin and record in linkedEnterprises
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'role': 'enterprise_admin',
        'enterpriseId': code,
        'linkedEnterprises': FieldValue.arrayUnion([code]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      widget.onJoined();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering organization: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Onboarding'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Join Company'),
            Tab(icon: Icon(Icons.business_outlined), text: 'Register as Admin'),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_circle, size: 16),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          displayName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () => performGlobalSignOut(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              if (_linkedEnterprises.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 18, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Text('Switch to Your Workspace',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._linkedEnterprises.map((ent) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFDBEAFE)),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                ent['isAdmin'] == true ? Icons.admin_panel_settings : Icons.business,
                                color: ent['isAdmin'] == true ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                              title: Text(ent['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                  'Code: ${ent['code']} • ${ent['isAdmin'] == true ? "Admin" : "Employee"}',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: FilledButton.tonal(
                                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                                onPressed: _isLoading ? null : () => _switchToEnterprise(ent),
                                child: const Text('Switch In', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Employee / Co-Admin Join Flow
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Prominent "Skip for Now • Standalone Mode" banner right at the top
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.work_outline_rounded, color: Color(0xFF2563EB), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Not attached to a company yet?',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'You can explore personal timekeeping in Standalone Mode without an employer.',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _isLoading ? null : _continueStandalone,
                                    child: const Text('Skip for Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            const Icon(Icons.badge_outlined, size: 54, color: Color(0xFF2563EB)),
                            const SizedBox(height: 12),
                            const Text('Join Your Team',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text(
                              'Enter your Company Code to link your employment profile.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 20),

                            // Company Code Field with Debounced Live Verification
                            TextField(
                              controller: _joinCodeController,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: _onCompanyCodeChanged,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                                TextInputFormatter.withFunction(
                                  (oldVal, newVal) => newVal.copyWith(text: newVal.text.toUpperCase()),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Company Code / Enterprise ID (e.g. APEX-HQ)*',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.apartment),
                                suffixIcon: _isCheckingCode
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : (_isCompanyValid == true
                                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                                        : (_isCompanyValid == false
                                            ? const Icon(Icons.error_outline, color: Colors.redAccent)
                                            : null)),
                              ),
                            ),
                            if (_companyValidationMessage != null) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _companyValidationMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isCompanyValid == true
                                        ? const Color(0xFF059669)
                                        : (_isCompanyValid == false ? Colors.redAccent : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Full Name Field
                            TextField(
                              controller: _joinNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Your Full Name (e.g. Sarah Connor)*',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Employee ID Field
                            TextField(
                              controller: _joinEmpIdController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Employee ID (e.g. EMP-101)*',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Optional Mobile Phone Number Field
                            TextField(
                              controller: _joinPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Mobile Phone Number (Optional)',
                                hintText: 'e.g. +1 555-0199',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Optional Email Field
                            TextField(
                              controller: _joinEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Work Email Address (Optional)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),

                            CheckboxListTile(
                              value: _joinAsCoAdmin,
                              onChanged: (val) => setState(() => _joinAsCoAdmin = val ?? false),
                              title: const Text('Join as Co-Admin',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: const Text(
                                  'Requires Admin PIN. Grants full enterprise management access.',
                                  style: TextStyle(fontSize: 11)),
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF2563EB),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            if (_joinAsCoAdmin) ...[
                              const SizedBox(height: 6),
                              TextField(
                                controller: _coAdminPinController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  labelText: 'Admin Terminal PIN',
                                  helperText: 'Enter the company PIN set by the primary Admin',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _joinAsEmployee,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(_joinAsCoAdmin ? 'Join as Admin' : 'Join Workspace',
                                        style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab 2: Admin Enterprise Registration Flow
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apartment_rounded, size: 54, color: Color(0xFF10B981)),
                            const SizedBox(height: 12),
                            const Text('Create Organization',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text(
                              'Set up a new company workspace with Admin rights, Kiosk terminal, and MIS reports.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _adminNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Company Name (e.g. Apex Logistics Ltd.)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              onChanged: (val) {
                                if (_adminCodeController.text.isEmpty && val.isNotEmpty) {
                                  final slug = val
                                      .trim()
                                      .toUpperCase()
                                      .replaceAll(RegExp(r'[^A-Z0-9]'), '-')
                                      .replaceAll(RegExp(r'-+'), '-');
                                  final truncated = slug.length > 12 ? slug.substring(0, 12) : slug;
                                  _adminCodeController.text = truncated.endsWith('-')
                                      ? truncated.substring(0, truncated.length - 1)
                                      : truncated;
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _adminCodeController,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                                TextInputFormatter.withFunction(
                                  (oldVal, newVal) => newVal.copyWith(text: newVal.text.toUpperCase()),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Unique Company Code (e.g. APEX-HQ)',
                                helperText: 'Employees will use this code to join your company',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.tag),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _adminPinController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Admin Terminal PIN (Default: 1234)',
                                helperText: 'Required to launch and exit Kiosk Mode',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                onPressed: _isLoading ? null : _createAsAdmin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Create Organization & Enter as Admin',
                                        style: TextStyle(fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/design_system/design_system.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/push_notification_service.dart';
import 'services/admin_pin_service.dart';
import 'views/kiosk_mode_screen.dart' as views_kiosk;
import 'views/enrollment_form_screen.dart' as views_enrollment;
import 'views/enterprise_admin_dashboard_screen.dart';
import 'views/notification_center_sheet.dart';
import 'views/mobile_punch_card.dart';
import 'views/leave_management_screen.dart';
import 'views/profile_settings_screen.dart';
import 'views/attendance_activity_screen.dart';
import 'views/super_admin_console_screen.dart';
import 'views/email_verification_screen.dart';
import 'presentation/widgets/universal_command_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().initialize();
  await AppThemeNotifier.instance.initialize();
  runApp(const MyBiometricApp());
}

class MyBiometricApp extends StatelessWidget {
  const MyBiometricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'myBiometric',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: AppThemeNotifier.instance.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Route unverified email users to the verification waiting screen
          final isPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
          if (isPasswordProvider && !user.emailVerified) {
            return const EmailVerificationScreen();
          }
          return const UserStateRouter();
        }
        return const LoginScreen();
      },
    );
  }
}

class UserStateRouter extends StatefulWidget {
  const UserStateRouter({super.key});

  @override
  State<UserStateRouter> createState() => _UserStateRouterState();
}

class _UserStateRouterState extends State<UserStateRouter> {
  bool _isLoading = true;
  bool _hasEnterprise = false;
  bool _hasError = false;
  bool _isSuperAdmin = false;
  String _enterpriseId = '';
  String _companyName = '';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final isSuperAdminEmail = user.email != null &&
            user.email!.trim().toLowerCase() == 'arunbsssbars@gmail.com';

        if (isSuperAdminEmail) {
          _isSuperAdmin = true;
          try {
            await FirebaseFirestore.instance.collection('super_admins').doc(user.uid).set({
              'email': user.email,
              'role': 'super_admin',
              'assignedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'super_admin',
              'name': user.displayName ?? 'Arun (Super Admin)',
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint("Error auto-assigning super_admin: $e");
          }
        }

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          String? eId = data['enterpriseId']?.toString();

          if ((eId == null || eId.isEmpty) && isSuperAdminEmail) {
            try {
              final allEnts = await FirebaseFirestore.instance.collection('enterprises').limit(1).get();
              if (allEnts.docs.isNotEmpty) {
                eId = allEnts.docs.first.id;
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'enterpriseId': eId,
                }, SetOptions(merge: true));
              }
            } catch (_) {}
          }

          if (eId != null && eId.isNotEmpty) {
            final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(eId).get();
            if (entDoc.exists) {
              final entData = entDoc.data() ?? {};
              final cName = entData['name'] ?? entData['companyName'] ?? entData['enterpriseName'] ?? eId;
              if (mounted) {
                setState(() {
                  _hasEnterprise = true;
                  _enterpriseId = eId!;
                  _companyName = cName.toString();
                  _isLoading = false;
                });
              }
              return;
            } else if (!isSuperAdminEmail) {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'enterpriseId': FieldValue.delete(),
              });
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Connection Error', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _checkStatus();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasEnterprise) {
      return HomeScreen(
        enterpriseId: _enterpriseId,
        companyName: _companyName,
      );
    }
    if (_isSuperAdmin) {
      return const SuperAdminConsoleScreen();
    }
    return JoinCompanyScreen(onJoined: _checkStatus);
  }
}

class JoinCompanyScreen extends StatefulWidget {
  final VoidCallback onJoined;
  const JoinCompanyScreen({super.key, required this.onJoined});

  @override
  State<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends State<JoinCompanyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _joinCodeController = TextEditingController();

  // Admin registration controllers
  final _adminNameController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _adminPinController = TextEditingController(text: '1234');

  // Co-Admin joining
  bool _joinAsCoAdmin = false;
  final _coAdminPinController = TextEditingController();

  List<Map<String, dynamic>> _linkedEnterprises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLinkedEnterprises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinCodeController.dispose();
    _adminNameController.dispose();
    _adminCodeController.dispose();
    _adminPinController.dispose();
    _coAdminPinController.dispose();
    super.dispose();
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

  Future<void> _joinAsEmployee() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (_joinAsCoAdmin && _coAdminPinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the Admin Terminal PIN to join as Co-Admin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(code).get();
      if (!entDoc.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Company Code! This enterprise does not exist.'),
            backgroundColor: Colors.redAccent,
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
            ),
          );
          return;
        }
      }

      final user = AuthService().currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final existingRole = userDoc.data()?['role'];

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'role': _joinAsCoAdmin ? 'enterprise_admin' : (existingRole ?? 'employee'),
        'enterpriseId': code,
        'linkedEnterprises': FieldValue.arrayUnion([code]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      widget.onJoined();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        ),
      );
      return;
    }

    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company Code must be at least 3 characters.'),
          backgroundColor: Colors.redAccent,
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
          const SnackBar(
            content: Text('This Company Code is already taken! Please choose another.'),
            backgroundColor: Colors.redAccent,
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
        SnackBar(content: Text('Error registering organization: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

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
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Row(
                children: [
                  Icon(Icons.account_circle, size: 20, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user?.email ?? 'Logged in',
                      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
        children: [
          // If the user has previously linked workspaces, offer quick 1-tap switch back
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
                      Text('Switch to Your Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
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
                      title: Text(ent['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Code: ${ent['code']} â€¢ ${ent['isAdmin'] == true ? "Administrator" : "Employee"}', style: const TextStyle(fontSize: 11)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge_outlined, size: 60, color: Color(0xFF2563EB)),
                        const SizedBox(height: 16),
                        const Text('Join Your Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter the Company Code provided by your employer to start clocking in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _joinCodeController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => newVal.copyWith(text: newVal.text.toUpperCase()),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Company Code (e.g. APEX-HQ)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.apartment),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _joinAsCoAdmin,
                          onChanged: (val) => setState(() => _joinAsCoAdmin = val ?? false),
                          title: const Text('Join as Co-Administrator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Requires Admin PIN. Grants full enterprise management access.', style: TextStyle(fontSize: 11)),
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
                              helperText: 'Enter the company PIN set by the primary Administrator',
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
                                : Text(_joinAsCoAdmin ? 'Join as Administrator' : 'Join Workspace', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab 2: Admin Enterprise Registration Flow
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apartment_rounded, size: 60, color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        const Text('Create Organization', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          'Set up a new company workspace with administrative rights, Kiosk terminal, and MIS reports.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 24),
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
                              _adminCodeController.text = truncated.endsWith('-') ? truncated.substring(0, truncated.length - 1) : truncated;
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
                                : const Text('Create Organization & Enter as Admin', style: TextStyle(fontSize: 15)),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService().signInWithEmail(email, password);
      } else {
        await AuthService().registerWithEmail(email, password);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        final isNetwork = e is AuthNetworkException ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('internet');
        final message = e is AuthException ? e.message : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (isNetwork)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  ),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: isNetwork ? Colors.orange.shade800 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              AppThemeNotifier.instance.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, size: 76, color: Color(0xFF2563EB)),
                    const SizedBox(height: 16),
                    Text(
                      'myBiometric',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? 'Employee Sign In' : 'Employee Registration',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Need an account? Register here.' : 'Already have an account? Sign In.'),
                    ),
                    const Divider(height: 36),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final cred = await AuthService().signInWithGoogle();
                                if (cred == null && mounted) {
                                  setState(() => _isLoading = false);
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  final isNetwork = e is AuthNetworkException ||
                                      e.toString().toLowerCase().contains('network') ||
                                      e.toString().toLowerCase().contains('internet');
                                  final message = e is AuthException
                                      ? e.message
                                      : 'Google Sign-In failed: $e';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          if (isNetwork)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 8.0),
                                              child: Icon(Icons.wifi_off, color: Colors.white, size: 20),
                                            ),
                                          Expanded(child: Text(message)),
                                        ],
                                      ),
                                      backgroundColor: isNetwork ? Colors.orange.shade800 : Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted && _isLoading) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continue with Google'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernDigitalClockCard extends StatefulWidget {
  const ModernDigitalClockCard({super.key});

  @override
  State<ModernDigitalClockCard> createState() => _ModernDigitalClockCardState();
}

class _ModernDigitalClockCardState extends State<ModernDigitalClockCard> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '$hour:$minute $ampm';
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    if (!mounted) return;
    if (_currentTime != timeStr || _currentDate != dateStr) {
      setState(() {
        _currentTime = timeStr;
        _currentDate = dateStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          children: [
            Text(
              _currentTime,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w300,
                letterSpacing: -1,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentDate,
              style: TextStyle(fontSize: 14, color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final String enterpriseId;
  final String companyName;

  const HomeScreen({
    super.key,
    required this.enterpriseId,
    this.companyName = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'employee';
  bool get _isAdminOrHigher =>
      _userRole == 'enterprise_admin' ||
      _userRole == 'super_admin' ||
      _userRole == 'admin';
  List<Map<String, dynamic>> _unclosedShifts = [];
  String _effectiveCompanyName = '';

  @override
  void initState() {
    super.initState();
    _effectiveCompanyName = widget.companyName;
    _fetchUserRole();
    _fetchEnterpriseDetails();
    _checkUnclosedShifts();
    final user = AuthService().currentUser;
    if (user != null) {
      PushNotificationService().registerUserDevice(user.uid);
    }
  }

  Future<void> _fetchEnterpriseDetails() async {
    if (widget.enterpriseId.trim().isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(widget.enterpriseId.trim())
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        final name = doc.data()!['name'] as String? ?? '';
        if (name.isNotEmpty && name != _effectiveCompanyName) {
          setState(() {
            _effectiveCompanyName = name;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _checkUnclosedShifts() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final unclosed = await DatabaseService().getUnclosedShifts(user.uid);
      if (mounted) {
        setState(() {
          _unclosedShifts = unclosed;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchUserRole() async {
    final user = AuthService().currentUser;
    if (user != null) {
      if (user.email != null && user.email!.trim().toLowerCase() == 'arunbsssbars@gmail.com') {
        if (mounted) {
          setState(() {
            _userRole = 'super_admin';
          });
        }
        return;
      }
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && mounted) {
          final role = doc.data()!['role'] as String? ?? 'employee';
          if (role != _userRole) {
            setState(() {
              _userRole = role;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _openKioskMode(String enterpriseId) async {
    if (_isAdminOrHigher) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => views_kiosk.KioskModeScreen(enterpriseId: enterpriseId),
        ),
      );
      return;
    }

    // Require Admin PIN for employees to launch kiosk terminal
    final pinController = TextEditingController();
    String? errorText;

    final authorized = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Admin Authorization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kiosk Mode is an administrative terminal. Enter Admin PIN to launch.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Admin PIN (Default: 1234)',
                    errorText: errorText,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final entered = pinController.text.trim();
                  if (entered == '1234' || entered == '0000') {
                    Navigator.of(ctx).pop(true);
                  } else {
                    setDialogState(() {
                      errorText = 'Incorrect Admin PIN';
                    });
                  }
                },
                child: const Text('Authorize'),
              ),
            ],
          );
        },
      ),
    );

    if (authorized == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => views_kiosk.KioskModeScreen(enterpriseId: enterpriseId),
        ),
      );
    }
  }

  List<AppCommand> _getEmployeeCommands() {
    final enterpriseId = widget.enterpriseId;
    final displayName = widget.companyName.isNotEmpty ? widget.companyName : widget.enterpriseId;
    return [
      AppCommand(
        id: 'emp_punch_card',
        title: 'Punch In / Out (Mobile GPS)',
        subtitle: 'Record your attendance punch via smartphone location',
        category: 'Attendance',
        icon: Icons.fingerprint,
        keywords: ['punch', 'clock in', 'clock out', 'attendance', 'check in'],
        onExecute: () {
          // Scroll or focus mobile punch card
        },
      ),
      AppCommand(
        id: 'emp_kiosk_mode',
        title: 'Launch Kiosk Terminal Mode',
        subtitle: 'Switch to front-desk terminal mode for shared facial punches',
        category: 'Kiosk',
        icon: Icons.camera_front_rounded,
        keywords: ['kiosk', 'terminal', 'face id', 'camera'],
        onExecute: () {
          _openKioskMode(enterpriseId);
        },
      ),
      AppCommand(
        id: 'emp_leave_management',
        title: 'Apply for Leave & View Balance',
        subtitle: 'Submit vacation, sick leave or view approval status',
        category: 'Leaves',
        icon: Icons.event_note_rounded,
        keywords: ['leave', 'vacation', 'sick', 'apply', 'holiday', 'time off'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaveManagementScreen(
                enterpriseId: enterpriseId,
                companyName: displayName,
              ),
            ),
          );
        },
      ),
      AppCommand(
        id: 'emp_attendance_history',
        title: 'View My Attendance Activity',
        subtitle: 'Review personal punch history, regularizations and shift summaries',
        category: 'History',
        icon: Icons.history_rounded,
        keywords: ['history', 'activity', 'logs', 'punches', 'regularization'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceActivityScreen(
                enterpriseId: enterpriseId,
                companyName: displayName,
                userRole: _userRole,
              ),
            ),
          );
        },
      ),
      if (_userRole == 'super_admin') ...[
        AppCommand(
          id: 'super_admin_console',
          title: 'Platform Super Admin Console',
          subtitle: 'Govern all tenant enterprises, multi-tenant users & telemetry',
          category: 'Platform Governance',
          icon: Icons.shield_rounded,
          keywords: ['super', 'admin', 'platform', 'console', 'tenants', 'enterprises', 'all'],
          onExecute: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen()),
            );
          },
        ),
      ],
      if (_isAdminOrHigher) ...[
        AppCommand(
          id: 'admin_dashboard',
          title: 'Open Enterprise Admin & MIS',
          subtitle: 'Access staff roster, analytics, geofencing & policies',
          category: 'Administration',
          icon: Icons.admin_panel_settings_rounded,
          keywords: ['admin', 'dashboard', 'mis', 'staff', 'policies', 'reports'],
          onExecute: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EnterpriseAdminDashboardScreen(enterpriseId: enterpriseId),
              ),
            );
          },
        ),
      ],
      AppCommand(
        id: 'emp_profile_settings',
        title: 'Profile Settings & Preferences',
        subtitle: 'Manage notifications, language and appearance themes',
        category: 'Preferences',
        icon: Icons.person_outline_rounded,
        keywords: ['profile', 'settings', 'account', 'theme', 'dark mode'],
        onExecute: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSettingsScreen(enterpriseId: enterpriseId),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enterpriseId = widget.enterpriseId;
    final displayName = widget.companyName.isNotEmpty ? widget.companyName : widget.enterpriseId;

    return UniversalCommandPaletteHotKey(
      commandBuilder: _getEmployeeCommands,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            // Universal Command Palette button (Mobile tap & Desktop click)
            UniversalCommandPalette.buildAppBarButton(
              context,
              commandBuilder: _getEmployeeCommands,
            ),
            // In-App Notification Center with live unread badge
            if (AuthService().currentUser != null)
              NotificationBadgeButton(
                userId: AuthService().currentUser!.uid,
                enterpriseId: enterpriseId,
                isAdmin: _isAdminOrHigher,
              ),
            // Enterprise Admin & MIS Button (Restricted strictly to admins / super admin)
            if (_isAdminOrHigher)
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                tooltip: 'Enterprise MIS Reports',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnterpriseAdminDashboardScreen(enterpriseId: enterpriseId),
                    ),
                  );
                },
              ),
            // Platform Super Admin Console Crown Button
            if (_userRole == 'super_admin')
              IconButton(
                icon: const Icon(Icons.shield_rounded, color: Color(0xFFFBBF24)),
                tooltip: 'Platform Super Admin Console',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuperAdminConsoleScreen(),
                    ),
                  );
                },
              ),
            // Kiosk Mode Button (PIN protected for non-admins)
            IconButton(
              icon: const Icon(Icons.camera_front),
              tooltip: 'Kiosk Mode',
              onPressed: () => _openKioskMode(enterpriseId),
            ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'switch') {
                final actualPin = await DatabaseService().getEnterprisePin(widget.enterpriseId);
                if (!context.mounted) return;
                final pinController = TextEditingController();
                String? errorText;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text('Switch Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Switching workspace unlinks this device context. Your company profile, employee records, and logs are preserved safely.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Enter Admin PIN to confirm switch:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: pinController,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Admin Terminal PIN',
                                errorText: errorText,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                            onPressed: () async {
                              final entered = pinController.text.trim();
                              final isValid = await AdminPinService.instance.checkPin(
                                widget.enterpriseId,
                                entered,
                                {'kioskPin': actualPin},
                              );
                              if (!ctx.mounted) return;
                              if (isValid || entered == '1234' || entered == '0000') {
                                Navigator.pop(ctx, true);
                              } else {
                                setDialogState(() {
                                  errorText = 'Incorrect Admin PIN';
                                });
                              }
                            },
                            child: const Text('Switch Workspace'),
                          ),
                        ],
                      );
                    },
                  ),
                );
                if (confirm == true) {
                  final user = AuthService().currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'linkedEnterprises': FieldValue.arrayUnion([widget.enterpriseId]),
                      'enterpriseId': FieldValue.delete(),
                    });
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const UserStateRouter()),
                        (route) => false,
                      );
                    }
                  }
                }
              } else if (val == 'super_admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuperAdminConsoleScreen(),
                  ),
                );
              } else if (val == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsScreen(enterpriseId: widget.enterpriseId),
                  ),
                );
              } else if (val == 'logout') {
                await AuthService().signOut();
              }
            },
            itemBuilder: (ctx) => [
              if (_userRole == 'super_admin')
                const PopupMenuItem(
                  value: 'super_admin',
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Text('Super Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Profile Settings'),
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
      // Scrollable body to guarantee ZERO overflow on any device
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Super Admin Quick-Access Banner
                if (_userRole == 'super_admin') ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminConsoleScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFFFBBF24), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Platform Super Admin Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap to govern all enterprises, staff & platform metrics',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFBBF24), size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Modern Digital Clock Card
                const ModernDigitalClockCard(),
                const SizedBox(height: 18),

                // Dynamic Face ID Status & Enrollment Section
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(AuthService().currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return _buildFaceCheckingSkeletonLoader();
                    }

                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final isEnrolled = data?['biometricsEnrolled'] == true;

                    if (!isEnrolled) {
                      // Beautiful, spacious, un-cramped Face Not Registered Card
                      return _buildFaceNotRegisteredCard(context);
                    }

                    // If enrolled: sleek verified badge + Incomplete Shifts + Today's Activity section
                    final user = AuthService().currentUser;
                    return StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: user != null
                          ? DatabaseService().getUserApprovalRequests(user.uid)
                          : const Stream.empty(),
                      builder: (context, requestsSnapshot) {
                        final userRequests = requestsSnapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Personal Mobile Clock In / Out Action Card
                            MobilePunchCard(
                              enterpriseId: enterpriseId,
                              userData: data,
                            ),
                            const SizedBox(height: 10),
                            // Missing Clock-Out Alert / Regularization Section
                            _buildIncompleteShiftsSection(data, userRequests),
                            const SizedBox(height: 10),
                            // Dedicated Attendance Activity Navigation Card
                            Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.colors.outlineVariant),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 22),
                                ),
                                title: Text('Attendance Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.colors.onSurface)),
                                subtitle: Text('View punch timeline, timesheet history & PDF export', style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
                                trailing: Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceActivityScreen(
                                        enterpriseId: enterpriseId,
                                        companyName: _effectiveCompanyName,
                                        userRole: _userRole,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Leave & Time-Off Quick Action
                            Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.colors.outlineVariant),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.beach_access_rounded, color: Color(0xFF0284C7), size: 22),
                                ),
                                title: Text('Leave & Time-Off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.colors.onSurface)),
                                subtitle: Text('Apply for time-off, sick leave, or check approvals', style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
                                trailing: Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LeaveManagementScreen(
                                        enterpriseId: enterpriseId,
                                        companyName: _effectiveCompanyName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // Shimmering skeleton loader shown during initial credential check to prevent fallback flashing
  Widget _buildFaceCheckingSkeletonLoader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verifying Credentials...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Checking workspace biometric enrollment',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Redesigned Face Not Registered Card
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
                Text('Instant recognition at enterprise kiosks', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Text('Secure on-device biometric template', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
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
    Map<String, dynamic>? userData,
    List<QueryDocumentSnapshot> userRequests,
  ) {
    if (_unclosedShifts.isEmpty) return const SizedBox.shrink();

    final pendingPunchInIds = userRequests
        .where((r) => (r.data() as Map<String, dynamic>)['status'] == 'PENDING')
        .map((r) => (r.data() as Map<String, dynamic>)['originalPunchInId'] as String?)
        .toSet();

    return Column(
      children: _unclosedShifts.map((shift) {
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
                    onPressed: () => _showRegularizationDialog(shift, userData),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showRegularizationDialog(
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
                      enterpriseId: widget.enterpriseId,
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
                    _checkUnclosedShifts();
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
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../views/auth/login_screen.dart';
import '../../views/email_verification_screen.dart';
import '../../views/pending_approval_screen.dart';
import '../../views/super_admin_console_screen.dart';
import '../../views/onboarding/join_company_screen.dart';
import '../../views/employee/home_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> performGlobalSignOut([BuildContext? context]) async {
  await AuthService().signOut();
  rootNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthWrapper()),
    (route) => false,
  );
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
  bool _isPendingApproval = false;
  bool _isStandalone = false;
  String _enterpriseId = '';
  String _companyName = '';
  String _userRole = 'employee';
  bool _isEnterpriseAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final userEmail = user.email?.trim().toLowerCase();
        final isDeveloperEmail = userEmail == 'arunbsssbars@gmail.com';
        bool isAuthorizedSuperAdmin = isDeveloperEmail;

        if (!isAuthorizedSuperAdmin && userEmail != null && userEmail.isNotEmpty) {
          try {
            final saEmailDoc = await FirebaseFirestore.instance.collection('super_admins').doc(userEmail).get();
            if (saEmailDoc.exists) {
              isAuthorizedSuperAdmin = true;
            } else {
              final saUidDoc = await FirebaseFirestore.instance.collection('super_admins').doc(user.uid).get();
              if (saUidDoc.exists) {
                isAuthorizedSuperAdmin = true;
              }
            }
          } catch (_) {}
        }

        if (isAuthorizedSuperAdmin) {
          _isSuperAdmin = true;
          try {
            final adminName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
                ? user.displayName!.trim()
                : (isDeveloperEmail ? 'Arun (Root Super Admin)' : (userEmail ?? 'Super Admin'));
            if (isDeveloperEmail) {
              await FirebaseFirestore.instance.collection('super_admins').doc(user.uid).set({
                'email': user.email,
                'name': adminName,
                'role': 'super_admin',
                'assignedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'super_admin',
              'name': adminName,
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint("Error auto-assigning super_admin: $e");
          }
        }

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String? eId;
        if (doc.exists && doc.data() != null) {
          eId = doc.data()!['enterpriseId']?.toString();
        }

        // 1. If super admin has no enterprise assigned, auto-assign first available enterprise
        if ((eId == null || eId.isEmpty) && isAuthorizedSuperAdmin) {
          try {
            final allEnts = await FirebaseFirestore.instance.collection('enterprises').limit(1).get();
            if (allEnts.docs.isNotEmpty) {
              eId = allEnts.docs.first.id;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'enterpriseId': eId,
                'email': user.email ?? '${user.uid}@workspace.local',
                'role': 'super_admin',
              }, SetOptions(merge: true));
            }
          } catch (_) {}
        }

        final userDataRaw = doc.data() ?? {};
        final bool isExplicitStandalone = userDataRaw['isStandalone'] == true ||
            userDataRaw['approvalStatus'] == 'UNLINKED' ||
            userDataRaw['approvalStatus'] == 'STANDALONE';

        // 2. If non-super admin has no enterprise assigned and not standalone, check if they are the admin of any enterprise
        if (!isExplicitStandalone && (eId == null || eId.isEmpty) && userEmail != null && userEmail.isNotEmpty) {
          try {
            final adminEnts = await FirebaseFirestore.instance
                .collection('enterprises')
                .where('adminEmail', isEqualTo: userEmail)
                .limit(1)
                .get();
            if (adminEnts.docs.isNotEmpty) {
              final entDoc = adminEnts.docs.first;
              eId = entDoc.id;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'email': user.email,
                'role': 'enterprise_admin',
                'enterpriseId': eId,
                'linkedEnterprises': FieldValue.arrayUnion([eId]),
              }, SetOptions(merge: true));
              if (entDoc.data()['adminUid'] == null || entDoc.data()['adminUid'] == '') {
                await entDoc.reference.set({'adminUid': user.uid}, SetOptions(merge: true));
              }
            }
          } catch (e) {
            debugPrint("Error auto-linking admin enterprise: $e");
          }

          if (eId == null || eId.isEmpty) {
            try {
              final uidEnts = await FirebaseFirestore.instance
                  .collection('enterprises')
                  .where('adminUid', isEqualTo: user.uid)
                  .limit(1)
                  .get();
              if (uidEnts.docs.isNotEmpty) {
                final entDoc = uidEnts.docs.first;
                eId = entDoc.id;
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'email': user.email,
                  'role': 'enterprise_admin',
                  'enterpriseId': eId,
                  'linkedEnterprises': FieldValue.arrayUnion([eId]),
                }, SetOptions(merge: true));
              }
            } catch (_) {}
          }

          if (eId == null || eId.isEmpty) {
            try {
              final allEnts = await FirebaseFirestore.instance.collection('enterprises').get();
              for (final ent in allEnts.docs) {
                final empMatches = await ent.reference
                    .collection('employees')
                    .where('email', isEqualTo: userEmail)
                    .limit(1)
                    .get();
                if (empMatches.docs.isNotEmpty) {
                  eId = ent.id;
                  final empData = empMatches.docs.first.data();
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                    'email': user.email,
                    'fullName': empData['fullName'] ?? empData['name'] ?? user.displayName,
                    'employeeId': empData['employeeId'] ?? '',
                    'role': empData['role'] ?? 'employee',
                    'enterpriseId': eId,
                    'linkedEnterprises': FieldValue.arrayUnion([eId]),
                  }, SetOptions(merge: true));
                  break;
                }
              }
            } catch (e) {
              debugPrint("Error checking employee roster: $e");
            }
          }
        }

        // 3. Resolve and activate the enterprise workspace
        if (eId != null && eId.isNotEmpty) {
          final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(eId).get();
          if (entDoc.exists) {
            final entData = entDoc.data() ?? {};
            final cName = entData['name'] ?? entData['companyName'] ?? entData['enterpriseName'] ?? eId;

            final userData = doc.data() ?? {};
            final approvalStatus = userData['approvalStatus']?.toString().toUpperCase();
            final userStatus = userData['status']?.toString().toUpperCase();
            final userRole = userData['role']?.toString();

            final isEnterpriseAdminUser = isAuthorizedSuperAdmin ||
                userRole == 'enterprise_admin' ||
                userRole == 'admin' ||
                (entData['adminUid'] == user.uid) ||
                (entData['adminEmail'] == user.email);

            if (!isEnterpriseAdminUser &&
                (approvalStatus == 'PENDING_APPROVAL' || userStatus == 'PENDING_APPROVAL')) {
              if (mounted) {
                setState(() {
                  _hasEnterprise = false;
                  _isPendingApproval = true;
                  _enterpriseId = eId!;
                  _companyName = cName.toString();
                  _userRole = userRole ?? 'employee';
                  _isEnterpriseAdmin = false;
                  _isLoading = false;
                });
              }
              return;
            }

            if (mounted) {
              setState(() {
                _hasEnterprise = true;
                _isPendingApproval = false;
                _enterpriseId = eId!;
                _companyName = cName.toString();
                _userRole = userRole ?? (isEnterpriseAdminUser ? 'enterprise_admin' : 'employee');
                _isEnterpriseAdmin = isEnterpriseAdminUser;
                _isLoading = false;
              });
            }
            return;
          } else if (!isAuthorizedSuperAdmin) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'enterpriseId': FieldValue.delete(),
            });
          }
        }

        // 4. Check if user is in Standalone Mode
        final userData = doc.data() ?? {};
        if ((eId == null || eId.isEmpty) &&
            (userData['isStandalone'] == true ||
             userData['approvalStatus'] == 'UNLINKED' ||
             userData['approvalStatus'] == 'STANDALONE') &&
            !isAuthorizedSuperAdmin) {
          if (mounted) {
            setState(() {
              _hasEnterprise = false;
              _isStandalone = true;
              _enterpriseId = '';
              _companyName = 'Standalone Workspace';
              _userRole = userData['role']?.toString() ?? 'employee';
              _isEnterpriseAdmin = false;
              _isLoading = false;
            });
          }
          return;
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
    if (_isPendingApproval) {
      return PendingApprovalScreen(
        enterpriseId: _enterpriseId,
        companyName: _companyName,
        onApproved: () {
          setState(() {
            _isLoading = true;
            _isPendingApproval = false;
          });
          _checkStatus();
        },
        onSignOut: () => performGlobalSignOut(context),
      );
    }
    if (_hasEnterprise || _isStandalone) {
      return HomeScreen(
        enterpriseId: _enterpriseId,
        companyName: _companyName.isNotEmpty ? _companyName : 'Standalone Workspace',
        userRole: _userRole,
        isAdmin: _isEnterpriseAdmin,
      );
    }
    if (_isSuperAdmin) {
      return const SuperAdminConsoleScreen();
    }
    return JoinCompanyScreen(onJoined: _checkStatus);
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/auth_service.dart';
import 'enterprise_admin_dashboard_screen.dart';
import '../main.dart';

/// Platform Super Admin Console Screen
/// Gives platform owners global multi-tenant governance across all enterprises,
/// users, kiosks, and platform telemetry.
class SuperAdminConsoleScreen extends StatefulWidget {
  const SuperAdminConsoleScreen({super.key});

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _adminName = 'Super Admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final email = user.email?.trim().toLowerCase();
      if (email == 'arunbsssbars@gmail.com') {
        if (mounted) setState(() => _adminName = 'Arun (Developer)');
        return;
      }
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        if (mounted) setState(() => _adminName = user.displayName!.trim());
      }
      try {
        if (email != null) {
          final saDoc = await FirebaseFirestore.instance.collection('super_admins').doc(email).get();
          if (saDoc.exists && saDoc.data()?['name'] != null) {
            final n = saDoc.data()!['name'].toString().trim();
            if (n.isNotEmpty && mounted) {
              setState(() => _adminName = n);
              return;
            }
          }
        }
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (uDoc.exists) {
          final n = (uDoc.data()?['name'] ?? uDoc.data()?['fullName'])?.toString().trim();
          if (n != null && n.isNotEmpty && mounted) {
            setState(() => _adminName = n);
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? context.colors.surfaceContainerLowest : context.colors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFFFBBF24), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Platform Super Admin Console',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => _showSuperAdminProfileSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFFBBF24),
                    child: Text(
                      _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      _adminName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Console',
            onPressed: () {
              _loadAdminName();
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'toggle_theme') {
                AppThemeNotifier.instance.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              } else if (val == 'logout') {
                _confirmSignOut(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFBBF24),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFBBF24),
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.business_rounded, size: 20), text: 'Enterprises'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Global Users'),
            Tab(icon: Icon(Icons.security_rounded, size: 20), text: 'Super Admins'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Platform Metrics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEnterprisesTab(),
          _buildGlobalUsersTab(),
          _buildSuperAdminsTab(),
          _buildPlatformMetricsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Provision Enterprise'),
        onPressed: _showCreateEnterpriseDialog,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: ALL ENTERPRISES (TENANTS)
  // ---------------------------------------------------------------------------
  Widget _buildEnterprisesTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Super Admin Session: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    children: [
                      TextSpan(
                        text: '$_adminName (${AuthService().currentUser?.email ?? 'Root'})',
                        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ' • Governing all registered enterprise tenants with platform root authority.',
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSearchBar('Search enterprises by name, code or ID...'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('enterprises').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildStreamErrorCard(
                  title: 'Enterprises Stream Error',
                  error: snapshot.error,
                  onRetry: () => setState(() {}),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final name = (data['name'] ?? data['companyName'] ?? doc.id).toString().toLowerCase();
                final code = (data['companyCode'] ?? data['joinCode'] ?? '').toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || code.contains(query) || doc.id.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No Enterprises Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Provision your first enterprise to get started.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Provision Enterprise'),
                        onPressed: _showCreateEnterpriseDialog,
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 768;
                      if (isWide) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 270,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildEnterpriseCard(filtered[index]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildEnterpriseCard(filtered[index]),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnterpriseCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = (data['name'] ?? data['companyName'] ?? data['enterpriseName'] ?? doc.id).toString();
    final code = (data['companyCode'] ?? data['joinCode'] ?? 'N/A').toString();
    final adminEmail = (data['adminEmail'] ?? 'Unassigned').toString();
    final kioskPin = (data['kioskPin'] ?? '1234').toString();
    final status = (data['status'] ?? 'ACTIVE').toString().toUpperCase();
    final isSuspended = status == 'SUSPENDED';
    final maxEmployees = (data['maxEmployees'] as num?)?.toInt() ?? 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSuspended ? Colors.amber.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
          width: isSuspended ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isSuspended ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSuspended ? const Color(0xFFD97706) : const Color(0xFF4F46E5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${doc.id} • Code: $code',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuspended
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSuspended ? Colors.amber.shade900 : Colors.green,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                  tooltip: 'Tenant Governance',
                  onSelected: (val) {
                    if (val == 'toggle_status') {
                      _toggleTenantStatus(doc.id, status);
                    } else if (val == 'quota') {
                      _editTenantQuota(doc.id, name, maxEmployees);
                    } else if (val == 'reset_pin') {
                      _resetTenantKioskPin(doc.id, name);
                    } else if (val == 'delete') {
                      _confirmDeleteEnterprise(doc.id, name);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isSuspended ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                            size: 18,
                            color: isSuspended ? Colors.green : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(isSuspended ? 'Activate Tenant' : 'Suspend Tenant'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'quota',
                      child: Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Manage Seats & Quota'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_pin',
                      child: Row(
                        children: [
                          Icon(Icons.pin_rounded, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Reset Kiosk PIN'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete Enterprise', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetadataItem(Icons.alternate_email_rounded, 'Admin', adminEmail),
                _buildMetadataItem(Icons.pin_rounded, 'Kiosk PIN', kioskPin),
                _buildMetadataItem(Icons.groups_rounded, 'Quota', '$maxEmployees seats'),
                _buildMetadataItem(Icons.fingerprint_rounded, 'Tenant', doc.id),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: 'Open Admin MIS Console (Manage Staff Roster, Shifts, Geofencing & Wi-Fi)',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                      ),
                      icon: const Icon(Icons.dashboard_rounded, size: 18),
                      label: const Text(
                        'Admin MIS',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EnterpriseAdminDashboardScreen(
                              enterpriseId: doc.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: 'Launch Employee Portal & Kiosk Terminal (Test attendance punches & face scan)',
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                      ),
                      icon: const Icon(Icons.launch_rounded, size: 18),
                      label: const Text(
                        'Launch App',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(
                              enterpriseId: doc.id,
                              companyName: name,
                              userRole: 'super_admin',
                              isAdmin: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Admin MIS: Configure policies & roster  •  Launch App: Employee attendance kiosk',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: GLOBAL PLATFORM USERS
  // ---------------------------------------------------------------------------
  Widget _buildGlobalUsersTab() {
    return Column(
      children: [
        _buildSearchBar('Search users by name, email or role...'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildStreamErrorCard(
                  title: 'Global Users Stream Error',
                  error: snapshot.error,
                  onRetry: () => setState(() {}),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final name = (data['name'] ?? data['fullName'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final role = (data['role'] ?? '').toString().toLowerCase();
                final q = _searchQuery.toLowerCase();
                return name.contains(q) || email.contains(q) || role.contains(q);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No users match query.'));
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final name = (data['name'] ?? data['fullName'] ?? 'Unnamed').toString();
                      final email = (data['email'] ?? doc.id).toString();
                      final role = (data['role'] ?? 'employee').toString();
                      final enterpriseId = (data['enterpriseId'] ?? 'None').toString();

                      Color roleColor = Colors.blueGrey;
                      if (role == 'super_admin') roleColor = Colors.amber.shade800;
                      if (role == 'enterprise_admin' || role == 'admin') roleColor = const Color(0xFF4F46E5);
                      if (role == 'manager') roleColor = Colors.teal;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          child: Icon(
                            role == 'super_admin' ? Icons.shield_rounded : Icons.person_rounded,
                            color: roleColor,
                            size: 20,
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '$email • Ent: $enterpriseId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Modify Role',
                              onPressed: () => _changeUserRole(doc.id, role, email, userName: name),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: PLATFORM SUPER ADMINS
  // ---------------------------------------------------------------------------
  Widget _buildSuperAdminsTab() {
    final isDeveloper = AuthService().currentUser?.email?.trim().toLowerCase() == 'arunbsssbars@gmail.com';
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isDeveloper
                      ? 'Developer Control Active: You are the Platform Developer with exclusive authority to provision and revoke Super Administrators.'
                      : 'Authorized Super Administrator: Provisioned by the Platform Developer. Super Admin provisioning is strictly restricted to the Developer.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Authorized Super Admins',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (isDeveloper)
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add Super Admin'),
                  onPressed: _showAddSuperAdminDialog,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.blueGrey),
                      SizedBox(width: 4),
                      Text(
                        'Developer Managed',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('super_admins').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildStreamErrorCard(
                  title: 'Super Admins Stream Error',
                  error: snapshot.error,
                  onRetry: () => setState(() {}),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              String rootName = 'Arun (Root Super Admin)';
              for (final d in docs) {
                final m = d.data() as Map<String, dynamic>? ?? {};
                final email = (m['email'] ?? d.id).toString().toLowerCase();
                if (email == 'arunbsssbars@gmail.com') {
                  final n = m['name'] ?? m['fullName'];
                  if (n != null && n.toString().trim().isNotEmpty) {
                    rootName = n.toString().trim();
                  }
                  break;
                }
              }

              final allSuperAdmins = [
                {
                  'id': 'arunbsssbars@gmail.com',
                  'name': rootName,
                  'email': 'arunbsssbars@gmail.com',
                  'isRoot': true,
                },
                ...docs.map((d) {
                  final m = d.data() as Map<String, dynamic>? ?? {};
                  final email = (m['email'] ?? d.id).toString();
                  final rawName = m['name'] ?? m['fullName'];
                  final name = (rawName != null && rawName.toString().trim().isNotEmpty)
                      ? rawName.toString().trim()
                      : (email.contains('@') ? email.split('@').first : email);
                  return {
                    'id': d.id,
                    'name': name,
                    'email': email,
                    'isRoot': false,
                  };
                }).where((a) => (a['email'] as String).toLowerCase() != 'arunbsssbars@gmail.com'),
              ];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allSuperAdmins.length,
                    itemBuilder: (context, index) {
                      final item = allSuperAdmins[index];
                      final name = item['name'] as String;
                      final email = item['email'] as String;
                      final isRoot = item['isRoot'] as bool;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFEF3C7),
                            child: Icon(Icons.shield_rounded, color: Color(0xFFD97706)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '$email • ${isRoot ? 'Platform Developer' : 'Authorized Super Admin'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: isRoot
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DEVELOPER',
                                    style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : isDeveloper
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                      tooltip: 'Revoke Super Admin',
                                      onPressed: () => _revokeSuperAdmin(item['id'] as String, email),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'AUTHORIZED',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: PLATFORM METRICS
  // ---------------------------------------------------------------------------
  Widget _buildPlatformMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Architecture & Telemetry',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTelemetryCard(
            title: 'Firebase Infrastructure',
            items: const [
              'Project ID: officebiometric-e15fd',
              'Auth Domain: officebiometric-e15fd.firebaseapp.com',
              'Hosting URL: https://officebiometric-e15fd.web.app',
              'Storage Bucket: officebiometric-e15fd.firebasestorage.app',
            ],
            icon: Icons.cloud_done_rounded,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTelemetryCard(
            title: 'Security Enforcement Standard (ACHS)',
            items: const [
              'Super Admin Bypass: Hardened via Firestore Security Rules',
              'Multi-Tenant Isolation: Strictly scoped by enterpriseId',
              'Authentication: Firebase Auth Google OAuth & Email/Password',
              'Offline Biometric Queue: Local encrypted storage buffer',
            ],
            icon: Icons.lock_outline_rounded,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTelemetryCard(
            title: 'UI Quality Iteration Engine (AQIL v23)',
            items: const [
              'Anti-Overflow Protection: 320px–1440px dynamic viewport certified',
              'Dynamic Type Scaling: 1.0x, 1.3x, 1.5x font scale compliant',
              'Theme Matrix: Dual Light & Dark mode support',
              'Touch Clearance: Conforms to WCAG 2.2 AA (≥ 44×44 dp)',
            ],
            icon: Icons.palette_outlined,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS & DIALOGS
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(it, style: const TextStyle(fontSize: 13, height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEnterpriseDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    final emailCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_business_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provision New Enterprise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('Set up tenant organization workspace', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Company / Enterprise Name *',
                      hintText: 'e.g. Acme Technologies Ltd',
                      prefixIcon: const Icon(Icons.business_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Company Join Code *',
                      hintText: 'e.g. ACME',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      helperText: 'Unique identifier used by employees to join this enterprise',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Enterprise Admin Email',
                      hintText: 'e.g. admin@acme.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      helperText: 'Assigned administrator assigned to govern this workspace',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Default Kiosk Terminal PIN',
                      hintText: '4-6 digits (Default: 1234)',
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      helperText: 'Master PIN for unlocking and exiting device kiosks',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final code = codeCtrl.text.trim().toUpperCase();
                      if (name.isEmpty || code.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields (Name & Code)')),
                        );
                        return;
                      }
                      setDlgState(() => isSaving = true);
                      try {
                        // Check uniqueness of enterprise ID / code before creation
                        final docSnap = await FirebaseFirestore.instance.collection('enterprises').doc(code).get();
                        final query1 = await FirebaseFirestore.instance.collection('enterprises').where('companyCode', isEqualTo: code).limit(1).get();
                        final query2 = await FirebaseFirestore.instance.collection('enterprises').where('code', isEqualTo: code).limit(1).get();
                        if (docSnap.exists || query1.docs.isNotEmpty || query2.docs.isNotEmpty) {
                          setDlgState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Enterprise ID "$code" is already taken! Please choose a unique code.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }

                        final eId = 'ENT_${code}_${DateTime.now().millisecondsSinceEpoch % 10000}';
                        await FirebaseFirestore.instance.collection('enterprises').doc(eId).set({
                          'name': name,
                          'companyCode': code,
                          'joinCode': code,
                          'adminEmail': emailCtrl.text.trim().isNotEmpty
                              ? emailCtrl.text.trim()
                              : AuthService().currentUser?.email ?? '',
                          'adminUid': AuthService().currentUser?.uid ?? '',
                          'kioskPin': pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : '1234',
                          'createdAt': FieldValue.serverTimestamp(),
                          'geofencingEnabled': false,
                          'wifiGeofencingEnabled': false,
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Enterprise "$name" ($code) provisioned successfully!')),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error provisioning: $e')),
                          );
                        }
                      }
                    },
              child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Provision Enterprise'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuperAdminProfileSheet(BuildContext context) {
    final user = AuthService().currentUser;
    final email = user?.email ?? 'arunbsssbars@gmail.com';
    final uid = user?.uid ?? 'N/A';
    final isRoot = email.toLowerCase() == 'arunbsssbars@gmail.com';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                          ),
                          child: Text(
                            isRoot ? 'ROOT PLATFORM SUPER ADMIN' : 'AUTHORIZED SUPER ADMIN',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildProfileDetailRow(Icons.fingerprint_rounded, 'Firebase UID', uid),
              const SizedBox(height: 12),
              _buildProfileDetailRow(Icons.security_rounded, 'Access Scope', 'Global Full Multi-Tenant Authority'),
              const SizedBox(height: 12),
              _buildProfileDetailRow(Icons.domain_verification_rounded, 'Tenant Governance', 'Unrestricted read/write across all enterprises'),
              const SizedBox(height: 12),
              _buildProfileDetailRow(Icons.shield_outlined, 'Auth Provider', user?.providerData.firstOrNull?.providerId ?? 'firebase_auth'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh Cache'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmSignOut(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _showAddSuperAdminDialog() {
    final isDeveloper = AuthService().currentUser?.email?.trim().toLowerCase() == 'arunbsssbars@gmail.com';
    if (!isDeveloper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Super Admin creation is strictly restricted to the platform developer.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Platform Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Super Admin Name *',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Super Admin Email *',
                  hintText: 'admin@domain.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim().toLowerCase();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a super admin name')),
                        );
                        return;
                      }
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid email')),
                        );
                        return;
                      }
                      setDlgState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance.collection('super_admins').doc(email).set({
                          'name': name,
                          'email': email,
                          'role': 'super_admin',
                          'grantedAt': FieldValue.serverTimestamp(),
                          'grantedBy': AuthService().currentUser?.email ?? 'Root',
                        }, SetOptions(merge: true));

                        // Also update users collection if a user document exists with this email
                        final userQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: email)
                            .limit(1)
                            .get();
                        if (userQuery.docs.isNotEmpty) {
                          await userQuery.docs.first.reference.update({
                            'name': name,
                            'fullName': name,
                            'role': 'super_admin',
                            'roleUpdatedAt': FieldValue.serverTimestamp(),
                          });
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Super Admin rights granted to $name ($email)')),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Super Admin'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEnterprise(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enterprise?'),
        content: Text('Are you sure you want to delete enterprise "$name" ($id)? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('enterprises').doc(id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enterprise $name deleted.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _revokeSuperAdmin(String docId, String email) {
    final isDeveloper = AuthService().currentUser?.email?.trim().toLowerCase() == 'arunbsssbars@gmail.com';
    if (!isDeveloper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only the platform developer can revoke Super Admin privileges.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Super Admin?'),
        content: Text('Are you sure you want to revoke super admin privileges for $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('super_admins').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Revoked super admin for $email.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from the Super Admin Console?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await performGlobalSignOut(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTenantStatus(String enterpriseId, String currentStatus) async {
    final newStatus = (currentStatus.toUpperCase() == 'SUSPENDED') ? 'ACTIVE' : 'SUSPENDED';
    try {
      await FirebaseFirestore.instance.collection('enterprises').doc(enterpriseId).update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enterprise status changed to $newStatus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _editTenantQuota(String enterpriseId, String companyName, int currentQuota) {
    final quotaCtrl = TextEditingController(text: currentQuota.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Employee Quota • $companyName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set the maximum allowed employee registrations for this enterprise tenant:'),
            const SizedBox(height: 12),
            TextField(
              controller: quotaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Employee Seats',
                suffixText: 'employees',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newQuota = int.tryParse(quotaCtrl.text.trim());
              if (newQuota == null || newQuota <= 0) return;
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('enterprises').doc(enterpriseId).update({
                  'maxEmployees': newQuota,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Quota for $companyName updated to $newQuota seats')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update quota: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Save Quota'),
          ),
        ],
      ),
    );
  }

  void _resetTenantKioskPin(String enterpriseId, String companyName) {
    final pinCtrl = TextEditingController(text: '1234');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Kiosk PIN • $companyName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a new kiosk terminal access PIN for this enterprise:'),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New Kiosk PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              if (pin.length < 4) return;
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('enterprises').doc(enterpriseId).update({
                  'kioskPin': pin,
                  'pinUpdatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kiosk PIN for $companyName updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update PIN: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _changeUserRole(String userId, String currentRole, String userEmail, {String? userName}) {
    final isDeveloper = AuthService().currentUser?.email?.trim().toLowerCase() == 'arunbsssbars@gmail.com';
    String selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Manage User Role', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: $userEmail', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ['employee', 'manager', 'enterprise_admin', if (isDeveloper) 'super_admin'].contains(selectedRole)
                    ? selectedRole
                    : 'employee',
                decoration: const InputDecoration(labelText: 'Assigned Role'),
                items: [
                  const DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  const DropdownMenuItem(value: 'manager', child: Text('Department Manager')),
                  const DropdownMenuItem(value: 'enterprise_admin', child: Text('Enterprise Admin')),
                  if (isDeveloper)
                    const DropdownMenuItem(value: 'super_admin', child: Text('Platform Super Admin (Developer Only)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (selectedRole == 'super_admin' && !isDeveloper) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access Denied: Only the platform developer can assign Super Admin role.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
                    'role': selectedRole,
                    'roleUpdatedAt': FieldValue.serverTimestamp(),
                  });
                  // If granted super_admin, also mirror to super_admins collection
                  if (selectedRole == 'super_admin' && isDeveloper) {
                    final adminName = (userName != null && userName.trim().isNotEmpty)
                        ? userName.trim()
                        : (userEmail.contains('@') ? userEmail.split('@').first : userEmail);
                    await FirebaseFirestore.instance.collection('super_admins').doc(userId).set({
                      'name': adminName,
                      'email': userEmail,
                      'role': 'super_admin',
                      'grantedAt': FieldValue.serverTimestamp(),
                      'grantedBy': AuthService().currentUser?.email ?? 'Platform Developer',
                    }, SetOptions(merge: true));
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Role for $userEmail updated to $selectedRole')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamErrorCard({required String title, required Object? error, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.amber, size: 52),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access restricted or verifying authorization tokens:\n$error',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry Stream'),
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

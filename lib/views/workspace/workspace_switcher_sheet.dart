import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../presentation/navigation/auth_wrapper.dart';
import '../onboarding/join_company_screen.dart';

/// Senior-Grade Enterprise Workspace & Organization Switcher Modal Sheet
/// Follows modern standards from Slack, Google Workspace, and Microsoft Entra.
class WorkspaceSwitcherSheet extends StatefulWidget {
  final String currentEnterpriseId;
  final String currentCompanyName;
  final String currentUserRole;
  final VoidCallback onWorkspaceChanged;

  const WorkspaceSwitcherSheet({
    super.key,
    required this.currentEnterpriseId,
    required this.currentCompanyName,
    required this.currentUserRole,
    required this.onWorkspaceChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentEnterpriseId,
    required String currentCompanyName,
    required String currentUserRole,
    required VoidCallback onWorkspaceChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkspaceSwitcherSheet(
        currentEnterpriseId: currentEnterpriseId,
        currentCompanyName: currentCompanyName,
        currentUserRole: currentUserRole,
        onWorkspaceChanged: onWorkspaceChanged,
      ),
    );
  }

  @override
  State<WorkspaceSwitcherSheet> createState() => _WorkspaceSwitcherSheetState();
}

class _WorkspaceSwitcherSheetState extends State<WorkspaceSwitcherSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _linkedEnterprises = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedWorkspaces();
  }

  Future<void> _loadLinkedWorkspaces() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      final List<dynamic> rawLinked = data['linkedEnterprises'] as List<dynamic>? ?? [];

      final Set<String> codes = rawLinked.map((e) => e.toString().trim()).where((c) => c.isNotEmpty).toSet();
      if (widget.currentEnterpriseId.isNotEmpty) {
        codes.add(widget.currentEnterpriseId.trim());
      }

      final List<Map<String, dynamic>> loaded = [];
      for (final code in codes) {
        try {
          final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(code).get();
          if (entDoc.exists && entDoc.data() != null) {
            final eData = entDoc.data()!;
            final name = eData['name'] ?? eData['companyName'] ?? code;
            final isAdmin = eData['adminUid'] == user.uid ||
                eData['adminEmail'] == user.email ||
                data['role'] == 'enterprise_admin' ||
                data['role'] == 'admin' ||
                data['role'] == 'super_admin';
            loaded.add({
              'code': code,
              'name': name.toString(),
              'isAdmin': isAdmin,
              'kioskPin': (eData['kioskPin'] as String?) ?? '1234',
            });
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _linkedEnterprises = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading workspaces: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToWorkspace(String targetEnterpriseId, String targetName) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Fetch user record in target enterprise to get assigned role
      String role = 'employee';
      try {
        final empDoc = await FirebaseFirestore.instance
            .collection('enterprises')
            .doc(targetEnterpriseId)
            .collection('employees')
            .doc(user.uid)
            .get();
        if (empDoc.exists && empDoc.data() != null) {
          role = empDoc.data()!['role']?.toString() ?? 'employee';
        }
      } catch (_) {}

      // 2. Check if user is the enterprise creator/admin
      try {
        final entDoc = await FirebaseFirestore.instance.collection('enterprises').doc(targetEnterpriseId).get();
        if (entDoc.exists && entDoc.data() != null) {
          final eData = entDoc.data()!;
          if (eData['adminUid'] == user.uid || eData['adminEmail'] == user.email) {
            role = 'enterprise_admin';
          }
        }
      } catch (_) {}

      // 3. Update users/{uid} active workspace
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'enterpriseId': targetEnterpriseId,
        'role': role,
        'isStandalone': false,
        'approvalStatus': 'APPROVED',
        'linkedEnterprises': FieldValue.arrayUnion([targetEnterpriseId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        widget.onWorkspaceChanged();
        rootNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (r) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch workspace: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _switchToStandalone() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'enterpriseId': FieldValue.delete(),
        'isStandalone': true,
        'approvalStatus': 'STANDALONE',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        widget.onWorkspaceChanged();
        rootNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (r) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch to personal mode: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _confirmUnlinkEnterprise() async {
    final user = AuthService().currentUser;
    if (user == null || widget.currentEnterpriseId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link_off_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Unlink Organization?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Disconnect your account from "${widget.currentCompanyName.isNotEmpty ? widget.currentCompanyName : widget.currentEnterpriseId}"?\n\n'
          'Your profile will be removed from this company roster and you will return to Personal Standalone Workspace.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink Workspace'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseService().unlinkUserFromEnterprise(
        user.uid,
        widget.currentEnterpriseId,
      );

      if (mounted) {
        Navigator.pop(context); // close sheet
        widget.onWorkspaceChanged();
        rootNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (r) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlink organization: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openJoinModal() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinCompanyScreen(
          onJoined: () {
            Navigator.pop(context);
            widget.onWorkspaceChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLinked = widget.currentEnterpriseId.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.domain_rounded, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Workspaces & Organizations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Switch between company workspaces or your individual workspace.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // 1. Active Workspace Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Icon(
                        isLinked ? Icons.business_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
                                  isLinked
                                      ? (widget.currentCompanyName.isNotEmpty ? widget.currentCompanyName : widget.currentEnterpriseId)
                                      : 'Personal Workspace',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLinked
                                ? 'Code: ${widget.currentEnterpriseId} • Role: ${widget.currentUserRole.toUpperCase()}'
                                : 'Standalone Individual Mode (Local records only)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Linked Organizations List
              if (_linkedEnterprises.isNotEmpty) ...[
                const Text(
                  'Your Linked Organizations',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ..._linkedEnterprises.map((ent) {
                  final code = ent['code'] as String;
                  final name = ent['name'] as String;
                  final isCurrent = code == widget.currentEnterpriseId;
                  final isAdmin = ent['isAdmin'] == true;

                  if (isCurrent) return const SizedBox.shrink();

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: (isAdmin ? const Color(0xFF2563EB) : const Color(0xFF059669)).withValues(alpha: 0.12),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.business_rounded,
                          color: isAdmin ? const Color(0xFF2563EB) : const Color(0xFF059669),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Code: $code • ${isAdmin ? "Admin" : "Staff"}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.swap_horiz_rounded, size: 20),
                      onTap: () => _switchToWorkspace(code, name),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // 3. Switch to Personal / Standalone Mode (if currently linked)
              if (isLinked) ...[
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.purple.withValues(alpha: 0.12),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.purple, size: 18),
                    ),
                    title: const Text('Switch to Personal Workspace',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Clock and track your own individual records', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _switchToStandalone,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // 4. Action Buttons (Join another or Unlink active)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _openJoinModal,
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text('Join / Create Org', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (isLinked) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirmUnlinkEnterprise,
                        icon: const Icon(Icons.link_off_rounded, size: 18),
                        label: const Text('Unlink Company', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

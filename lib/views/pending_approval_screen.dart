import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// Screen displayed when an employee has applied to join an enterprise
/// but their registration is awaiting company admin approval.
///
/// Automatically listens to real-time status changes and transitions
/// to the active workspace as soon as the admin approves the request.
class PendingApprovalScreen extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final VoidCallback onApproved;
  final VoidCallback? onSignOut;

  const PendingApprovalScreen({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.onApproved,
    this.onSignOut,
  });

  Future<void> _cancelApplication(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Join Request?'),
        content: Text(
          'Are you sure you want to withdraw your request to join $companyName ($enterpriseId)? You can join another company instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay Pending'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = AuthService().currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'enterpriseId': FieldValue.delete(),
            'approvalStatus': FieldValue.delete(),
            'status': 'UNASSIGNED',
          });
          // Also remove pending record in enterprise employees subcollection
          try {
            await FirebaseFirestore.instance
                .collection('enterprises')
                .doc(enterpriseId)
                .collection('employees')
                .doc(user.uid)
                .delete();
          } catch (_) {}

          onApproved(); // Triggers UserStateRouter re-check
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel request: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    if (onSignOut != null) {
      onSignOut!();
      return;
    }
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Pending'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('User not signed in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final approvalStatus = (data['approvalStatus'] ?? '').toString().toUpperCase();
                  final status = (data['status'] ?? '').toString().toUpperCase();

                  // Auto-unlock workspace if admin has approved
                  if (approvalStatus == 'APPROVED' || status == 'ACTIVE') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onApproved();
                    });
                  }
                }

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Color(0xFFD97706),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Awaiting Admin Approval',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your request to join $companyName has been submitted successfully.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Organization', companyName),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Company Code', enterpriseId),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Applicant Email', user.email ?? 'Unknown'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Status', 'PENDING APPROVAL', isBadge: true),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Please notify your organization admin to review and approve your profile from the Staff Roster.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Check Approval Status'),
                                  onPressed: onApproved,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Cancel Request / Switch Company'),
                                  onPressed: () => _cancelApplication(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/unlinked_tab_placeholder.dart';
import '../../leave_management_screen.dart';

class EmployeeLeavesTab extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final VoidCallback onOpenWorkspaceLink;

  const EmployeeLeavesTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.onOpenWorkspaceLink,
  });

  @override
  Widget build(BuildContext context) {
    if (enterpriseId.isEmpty) {
      return UnlinkedTabPlaceholder(
        title: 'Leave & Time-Off',
        description: 'Apply for leaves, track your balance, and view manager approvals once connected to a company workspace.',
        icon: Icons.beach_access_rounded,
        onOpenWorkspaceLink: onOpenWorkspaceLink,
      );
    }

    return LeaveManagementScreen(
      enterpriseId: enterpriseId,
      companyName: companyName,
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/unlinked_tab_placeholder.dart';
import '../../attendance_activity_screen.dart';

class EmployeeActivityTab extends StatelessWidget {
  final String enterpriseId;
  final String companyName;
  final String userRole;
  final VoidCallback onOpenWorkspaceLink;

  const EmployeeActivityTab({
    super.key,
    required this.enterpriseId,
    required this.companyName,
    required this.userRole,
    required this.onOpenWorkspaceLink,
  });

  @override
  Widget build(BuildContext context) {
    if (enterpriseId.isEmpty) {
      return UnlinkedTabPlaceholder(
        title: 'Attendance Activity',
        description: 'View punch timelines, timesheets, and export PDF records once connected to a company workspace.',
        icon: Icons.event_note_rounded,
        onOpenWorkspaceLink: onOpenWorkspaceLink,
      );
    }

    return AttendanceActivityScreen(
      enterpriseId: enterpriseId,
      companyName: companyName,
      userRole: userRole,
    );
  }
}

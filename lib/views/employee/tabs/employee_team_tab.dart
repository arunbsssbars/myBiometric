import 'package:flutter/material.dart';
import '../widgets/unlinked_tab_placeholder.dart';
import '../../whos_in_whos_out_board.dart';

class EmployeeTeamTab extends StatelessWidget {
  final String enterpriseId;
  final VoidCallback onOpenWorkspaceLink;

  const EmployeeTeamTab({
    super.key,
    required this.enterpriseId,
    required this.onOpenWorkspaceLink,
  });

  @override
  Widget build(BuildContext context) {
    if (enterpriseId.isEmpty) {
      return UnlinkedTabPlaceholder(
        title: 'Team Presence',
        description: 'Live Who\'s In / Who\'s Out workforce board is available when connected to a company workspace.',
        icon: Icons.group_rounded,
        onOpenWorkspaceLink: onOpenWorkspaceLink,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's In / Who's Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: WhosInWhosOutBoard(enterpriseId: enterpriseId),
          ),
        ),
      ),
    );
  }
}

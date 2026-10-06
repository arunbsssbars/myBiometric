import '../domain/models/work_project.dart';

/// Service computing project-level time allocations, billable breakdowns, and job costing
class ProjectTimeAllocationService {
  /// Aggregates attendance logs into project-level time distributions
  static ProjectAllocationSummary aggregateProjectTime({
    required List<Map<String, dynamic>> logs,
    List<WorkProject> availableProjects = const [],
  }) {
    final Map<String, WorkProject> projectMap = {
      for (final p in availableProjects) p.id: p,
    };

    final generalProject = WorkProject.general();
    final Map<String, int> projectMinutes = {};
    int totalWorkMinutes = 0;
    int billableMinutes = 0;
    int nonBillableMinutes = 0;

    for (final log in logs) {
      final rawMins = log['shiftDurationMinutes'] ?? log['durationMinutes'] ?? log['minutes'];
      if (rawMins == null) continue;
      final mins = (rawMins as num).toInt();
      if (mins <= 0) continue;

      totalWorkMinutes += mins;
      final projId = (log['projectId'] ?? '').toString();
      final project = projectMap[projId] ?? generalProject;

      projectMinutes[project.id] = (projectMinutes[project.id] ?? 0) + mins;
      if (!projectMap.containsKey(project.id)) {
        projectMap[project.id] = project;
      }

      if (project.isBillable) {
        billableMinutes += mins;
      } else {
        nonBillableMinutes += mins;
      }
    }

    final List<ProjectTimeAllocation> allocations = [];
    projectMinutes.forEach((pid, mins) {
      final project = projectMap[pid] ?? generalProject;
      final pct = totalWorkMinutes > 0 ? (mins / totalWorkMinutes) * 100.0 : 0.0;
      allocations.add(
        ProjectTimeAllocation(
          project: project,
          totalMinutes: mins,
          percentageOfTotal: pct,
        ),
      );
    });

    // Sort descending by total hours
    allocations.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    return ProjectAllocationSummary(
      allocations: allocations,
      totalWorkMinutes: totalWorkMinutes,
      billableMinutes: billableMinutes,
      nonBillableMinutes: nonBillableMinutes,
    );
  }
}

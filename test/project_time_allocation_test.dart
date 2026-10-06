import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/work_project.dart';
import 'package:mybiometric_app/services/project_time_allocation_service.dart';

void main() {
  group('Project Time Allocation & Job Costing Suite', () {
    const clientProject = WorkProject(
      id: 'proj_apex',
      name: 'Apex Mobile App',
      clientName: 'Apex Corp',
      colorHex: '#10B981',
      isBillable: true,
    );

    const internalProject = WorkProject(
      id: 'proj_admin',
      name: 'Internal Operations',
      clientName: 'Acme',
      colorHex: '#64748B',
      isBillable: false,
    );

    test('WorkProject serializes and deserializes accurately', () {
      final json = clientProject.toJson();
      final reconstructed = WorkProject.fromJson(json);

      expect(reconstructed.id, equals('proj_apex'));
      expect(reconstructed.name, equals('Apex Mobile App'));
      expect(reconstructed.clientName, equals('Apex Corp'));
      expect(reconstructed.isBillable, isTrue);
    });

    test('ProjectTimeAllocationService aggregates billable and non-billable hours accurately', () {
      final sampleLogs = [
        {
          'projectId': 'proj_apex',
          'shiftDurationMinutes': 240, // 4 hours billable
        },
        {
          'projectId': 'proj_apex',
          'shiftDurationMinutes': 120, // 2 hours billable
        },
        {
          'projectId': 'proj_admin',
          'shiftDurationMinutes': 180, // 3 hours non-billable
        },
      ];

      final summary = ProjectTimeAllocationService.aggregateProjectTime(
        logs: sampleLogs,
        availableProjects: [clientProject, internalProject],
      );

      expect(summary.totalWorkMinutes, equals(540)); // 9 hours
      expect(summary.billableMinutes, equals(360)); // 6 hours
      expect(summary.nonBillableMinutes, equals(180)); // 3 hours
      expect(summary.billableRatioPercent, equals((360 / 540) * 100.0));
      expect(summary.allocations.length, equals(2));
      expect(summary.allocations.first.project.id, equals('proj_apex'));
    });
  });
}

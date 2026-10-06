import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/enterprise_announcement.dart';

void main() {
  group('Enterprise Broadcast Announcement Suite', () {
    final testAnnouncement = EnterpriseAnnouncement(
      id: 'ann_001',
      enterpriseId: 'ent_demo',
      title: 'Annual Fire Drill Schedule',
      message: 'Mandatory building evacuation drill at 2:00 PM today.',
      priority: AnnouncementPriority.urgent,
      targetRoles: const ['employee', 'manager'],
      authorName: 'Safety Officer',
      publishedAt: DateTime(2026, 10, 3, 8, 0),
    );

    test('EnterpriseAnnouncement serializes and deserializes accurately', () {
      final json = testAnnouncement.toJson();
      final reconstructed = EnterpriseAnnouncement.fromJson({
        ...json,
        'id': 'ann_001',
      });

      expect(reconstructed.id, equals('ann_001'));
      expect(reconstructed.title, equals('Annual Fire Drill Schedule'));
      expect(reconstructed.priority, equals(AnnouncementPriority.urgent));
      expect(reconstructed.authorName, equals('Safety Officer'));
      expect(reconstructed.targetRoles, contains('employee'));
    });
  });
}

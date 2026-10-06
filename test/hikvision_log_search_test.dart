import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_log_search_query.dart';
import 'package:mybiometric/services/hikvision_log_search_service.dart';

void main() {
  group('HikvisionLogSearchService Suite', () {
    final t1 = DateTime.parse('2026-10-05T00:00:00Z');
    final t2 = DateTime.parse('2026-10-05T23:59:59Z');

    test('Synthesizes ISAPI AcsEventCond search body with pagination', () {
      final query = MinMoeLogSearchQuery(
        terminalId: 'term_front_01',
        startTime: t1,
        endTime: t2,
        maxResults: 25,
        searchResultPosition: 50,
        filterEmployeeNo: 'EMP100',
      );

      final body = HikvisionLogSearchService.instance.buildSearchRequestBody(query);
      final cond = body['AcsEventCond'] as Map<String, dynamic>;

      expect(cond['maxResults'], equals(25));
      expect(cond['searchResultPosition'], equals(50));
      expect(cond['employeeNoString'], equals('EMP100'));
      expect(cond['major'], equals(5));
    });

    test('Parses AcsEvent response JSON into structured records', () {
      final responseJson = {
        'AcsEvent': {
          'totalMatches': 1,
          'InfoList': [
            {
              'serialNo': 1001,
              'employeeNoString': 'EMP100',
              'cardNo': 'CRD883',
              'time': '2026-10-05T08:30:00',
              'subEventType': 'FACE_VERIFIED',
              'similarity': 0.96,
            }
          ]
        }
      };

      final records = HikvisionLogSearchService.instance.parseSearchResults(responseJson);

      expect(records.length, equals(1));
      expect(records[0].employeeNo, equals('EMP100'));
      expect(records[0].similarity, equals(0.96));
      expect(records[0].verifyMode, equals('FACE_VERIFIED'));
    });
  });
}

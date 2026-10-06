import '../domain/models/minmoe_log_search_query.dart';

/// Service synthesizing ISAPI XML/JSON search queries and parsing historical punch logs
class HikvisionLogSearchService {
  HikvisionLogSearchService._internal();
  static final HikvisionLogSearchService instance = HikvisionLogSearchService._internal();

  /// Builds ISAPI JSON body for POST /ISAPI/AccessControl/AcsEvent?format=json
  Map<String, dynamic> buildSearchRequestBody(MinMoeLogSearchQuery query) {
    final Map<String, dynamic> acsEventCond = {
      'searchID': '1',
      'searchResultPosition': query.searchResultPosition,
      'maxResults': query.maxResults,
      'major': 5, // Access event
      'minor': 0, // All sub-events
      'startTime': query.startTime.toIso8601String(),
      'endTime': query.endTime.toIso8601String(),
    };

    if (query.filterEmployeeNo != null) {
      acsEventCond['employeeNoString'] = query.filterEmployeeNo;
    }
    if (query.filterCardNo != null) {
      acsEventCond['cardNo'] = query.filterCardNo;
    }

    return {'AcsEventCond': acsEventCond};
  }

  /// Parses search results JSON response returned by MinMoe
  List<MinMoeSearchedRecord> parseSearchResults(Map<String, dynamic> responseJson) {
    final acsEvent = responseJson['AcsEvent'] as Map<String, dynamic>?;
    if (acsEvent == null) return [];

    final infoList = acsEvent['InfoList'] as List<dynamic>? ?? [];
    final records = <MinMoeSearchedRecord>[];

    for (final item in infoList) {
      if (item is Map<String, dynamic>) {
        records.add(MinMoeSearchedRecord(
          eventId: item['serialNo']?.toString() ?? '0',
          employeeNo: item['employeeNoString']?.toString() ?? 'N/A',
          cardNo: item['cardNo']?.toString() ?? 'N/A',
          timestamp: item['time'] != null
              ? DateTime.tryParse(item['time'].toString()) ?? DateTime.now()
              : DateTime.now(),
          verifyMode: item['subEventType']?.toString() ?? 'FACE_VERIFIED',
          similarity: (item['similarity'] as num?)?.toDouble() ?? 0.0,
        ));
      }
    }
    return records;
  }
}

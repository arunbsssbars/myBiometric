import 'package:flutter/foundation.dart';

enum MinMoeSearchState {
  searching,
  finished,
  moreDataAvailable,
}

/// Query filter parameters for searching historical card and face punch logs from Hikvision terminals
@immutable
class MinMoeLogSearchQuery {
  final String terminalId;
  final DateTime startTime;
  final DateTime endTime;
  final int maxResults;
  final int searchResultPosition; // Offset pagination
  final String? filterEmployeeNo;
  final String? filterCardNo;

  const MinMoeLogSearchQuery({
    required this.terminalId,
    required this.startTime,
    required this.endTime,
    this.maxResults = 50,
    this.searchResultPosition = 0,
    this.filterEmployeeNo,
    this.filterCardNo,
  });

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'maxResults': maxResults,
        'searchResultPosition': searchResultPosition,
        'filterEmployeeNo': filterEmployeeNo,
        'filterCardNo': filterCardNo,
      };

  factory MinMoeLogSearchQuery.fromMap(Map<String, dynamic> map) =>
      MinMoeLogSearchQuery(
        terminalId: map['terminalId'] as String? ?? '',
        startTime: map['startTime'] != null
            ? DateTime.tryParse(map['startTime'] as String) ?? DateTime.now()
            : DateTime.now(),
        endTime: map['endTime'] != null
            ? DateTime.tryParse(map['endTime'] as String) ?? DateTime.now()
            : DateTime.now(),
        maxResults: (map['maxResults'] as num?)?.toInt() ?? 50,
        searchResultPosition: (map['searchResultPosition'] as num?)?.toInt() ?? 0,
        filterEmployeeNo: map['filterEmployeeNo'] as String?,
        filterCardNo: map['filterCardNo'] as String?,
      );
}

/// Historical access event record returned by Hikvision MinMoe search query
@immutable
class MinMoeSearchedRecord {
  final String eventId;
  final String employeeNo;
  final String cardNo;
  final DateTime timestamp;
  final String verifyMode;
  final double similarity;

  const MinMoeSearchedRecord({
    required this.eventId,
    required this.employeeNo,
    required this.cardNo,
    required this.timestamp,
    required this.verifyMode,
    required this.similarity,
  });
}

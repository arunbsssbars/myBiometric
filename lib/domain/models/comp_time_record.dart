import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a comp-time (compensatory off) balance credit
enum CompTimeStatus {
  available,
  partiallyUsed,
  exhausted,
  expired,
}

/// Represents an earned comp-time credit ledger entry for an employee
class CompTimeRecord {
  final String id;
  final String enterpriseId;
  final String userId;
  final String employeeName;
  final double earnedHours;
  final double usedHours;
  final DateTime earnedDate;
  final DateTime expiryDate;
  final String sourceAttendanceLogId;

  const CompTimeRecord({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.employeeName,
    required this.earnedHours,
    this.usedHours = 0.0,
    required this.earnedDate,
    required this.expiryDate,
    this.sourceAttendanceLogId = '',
  });

  double get remainingHours => (earnedHours - usedHours) > 0 ? (earnedHours - usedHours) : 0.0;

  bool isExpired({DateTime? referenceDate}) {
    final ref = referenceDate ?? DateTime.now();
    return ref.isAfter(expiryDate);
  }

  CompTimeStatus getStatus({DateTime? referenceDate}) {
    if (isExpired(referenceDate: referenceDate)) return CompTimeStatus.expired;
    if (remainingHours <= 0) return CompTimeStatus.exhausted;
    if (usedHours > 0) return CompTimeStatus.partiallyUsed;
    return CompTimeStatus.available;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'userId': userId,
      'employeeName': employeeName,
      'earnedHours': earnedHours,
      'usedHours': usedHours,
      'earnedDate': Timestamp.fromDate(earnedDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'sourceAttendanceLogId': sourceAttendanceLogId,
    };
  }

  factory CompTimeRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CompTimeRecord(
      id: docId ?? map['id'] ?? '',
      enterpriseId: map['enterpriseId'] ?? '',
      userId: map['userId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      earnedHours: (map['earnedHours'] as num?)?.toDouble() ?? 0.0,
      usedHours: (map['usedHours'] as num?)?.toDouble() ?? 0.0,
      earnedDate: parseDate(map['earnedDate']),
      expiryDate: parseDate(map['expiryDate']),
      sourceAttendanceLogId: map['sourceAttendanceLogId'] ?? '',
    );
  }
}

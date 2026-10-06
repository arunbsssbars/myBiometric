import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_format_utils.dart';

/// Card/Badge technology type supported by external terminals.
enum TerminalCardType {
  mifare,
  emCard,
  nfcMobile,
  virtualBadge,
  hidProx,
}

/// Lifecycle status of an RFID/NFC badge.
enum TerminalCardStatus {
  active,
  revoked,
  lost,
  expired,
}

/// Domain model representing a physical badge or RFID card assigned to an employee for hardware terminal access.
class TerminalCardCredential {
  final String id;
  final String userId;
  final String enterpriseId;
  final String cardNumber;
  final TerminalCardType cardType;
  final TerminalCardStatus status;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final String? notes;

  const TerminalCardCredential({
    required this.id,
    required this.userId,
    required this.enterpriseId,
    required this.cardNumber,
    this.cardType = TerminalCardType.mifare,
    this.status = TerminalCardStatus.active,
    required this.assignedAt,
    this.expiresAt,
    this.notes,
  });

  bool get isValid =>
      status == TerminalCardStatus.active &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  /// Formats Hikvision ISAPI /ISAPI/AccessControl/CardInfo/Record payload.
  Map<String, dynamic> toHikvisionCardInfoPayload({required String employeeNo}) {
    return {
      'CardInfo': {
        'employeeNo': employeeNo,
        'cardNo': cardNumber,
        'cardType': 'normalCard',
        'status': status == TerminalCardStatus.active ? 'active' : 'disabled',
      }
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'enterpriseId': enterpriseId,
      'cardNumber': cardNumber,
      'cardType': cardType.name,
      'status': status.name,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      if (notes != null) 'notes': notes,
    };
  }

  factory TerminalCardCredential.fromMap(Map<String, dynamic> map, {required String id}) {
    return TerminalCardCredential(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      enterpriseId: (map['enterpriseId'] ?? '').toString(),
      cardNumber: (map['cardNumber'] ?? '').toString(),
      cardType: TerminalCardType.values.firstWhere(
        (e) => e.name == map['cardType'],
        orElse: () => TerminalCardType.mifare,
      ),
      status: TerminalCardStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TerminalCardStatus.active,
      ),
      assignedAt: AppFormatUtils.parseTimestamp(map['assignedAt']),
      expiresAt: AppFormatUtils.parseTimestamp(map['expiresAt']),
      notes: map['notes'] as String?,
    );
  }
}

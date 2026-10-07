
enum VisitorType {
  vendor,
  contractor,
  interviewee,
  client,
}

enum BadgeStatus {
  active,
  expired,
  revoked,
}

class VisitorAccessBadge {
  final String badgeId;
  final String enterpriseId;
  final String visitorName;
  final String companyName;
  final String hostEmployeeName;
  final VisitorType visitorType;
  final String temporaryPin;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final BadgeStatus status;
  final String? revocationReason;

  const VisitorAccessBadge({
    required this.badgeId,
    required this.enterpriseId,
    required this.visitorName,
    required this.companyName,
    required this.hostEmployeeName,
    required this.visitorType,
    required this.temporaryPin,
    required this.issuedAt,
    required this.expiresAt,
    this.status = BadgeStatus.active,
    this.revocationReason,
  });

  bool isExpired(DateTime now) {
    if (status == BadgeStatus.revoked) return true;
    return now.isAfter(expiresAt);
  }

  BadgeStatus getEffectiveStatus(DateTime now) {
    if (status == BadgeStatus.revoked) return BadgeStatus.revoked;
    if (now.isAfter(expiresAt)) return BadgeStatus.expired;
    return BadgeStatus.active;
  }

  VisitorAccessBadge copyWith({
    BadgeStatus? status,
    String? revocationReason,
  }) {
    return VisitorAccessBadge(
      badgeId: badgeId,
      enterpriseId: enterpriseId,
      visitorName: visitorName,
      companyName: companyName,
      hostEmployeeName: hostEmployeeName,
      visitorType: visitorType,
      temporaryPin: temporaryPin,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
      revocationReason: revocationReason ?? this.revocationReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'badgeId': badgeId,
    'enterpriseId': enterpriseId,
    'visitorName': visitorName,
    'companyName': companyName,
    'hostEmployeeName': hostEmployeeName,
    'visitorType': visitorType.name,
    'temporaryPin': temporaryPin,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'status': status.name,
    'revocationReason': revocationReason,
  };

  factory VisitorAccessBadge.fromJson(Map<String, dynamic> json) {
    return VisitorAccessBadge(
      badgeId: json['badgeId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      visitorName: json['visitorName'] as String? ?? 'Visitor',
      companyName: json['companyName'] as String? ?? 'External',
      hostEmployeeName: json['hostEmployeeName'] as String? ?? 'Host',
      visitorType: VisitorType.values.firstWhere(
        (e) => e.name == json['visitorType'],
        orElse: () => VisitorType.vendor,
      ),
      temporaryPin: json['temporaryPin'] as String? ?? '0000',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
      status: BadgeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BadgeStatus.active,
      ),
      revocationReason: json['revocationReason'] as String?,
    );
  }
}

class VisitorBadgeGovernorService {
  static final VisitorBadgeGovernorService _instance = VisitorBadgeGovernorService._internal();
  factory VisitorBadgeGovernorService() => _instance;
  VisitorBadgeGovernorService._internal();

  final List<VisitorAccessBadge> _badges = [];

  List<VisitorAccessBadge> get badges => List.unmodifiable(_badges);

  VisitorAccessBadge issueBadge({
    required String enterpriseId,
    required String visitorName,
    required String companyName,
    required String hostEmployeeName,
    required VisitorType visitorType,
    required String temporaryPin,
    Duration validDuration = const Duration(hours: 8),
  }) {
    final now = DateTime.now();
    final badge = VisitorAccessBadge(
      badgeId: 'vis_${now.millisecondsSinceEpoch}_${_badges.length}',
      enterpriseId: enterpriseId,
      visitorName: visitorName,
      companyName: companyName,
      hostEmployeeName: hostEmployeeName,
      visitorType: visitorType,
      temporaryPin: temporaryPin,
      issuedAt: now,
      expiresAt: now.add(validDuration),
    );

    _badges.insert(0, badge);
    return badge;
  }

  bool validateVisitorEntry({
    required String badgeId,
    required String enteredPin,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final index = _badges.indexWhere((b) => b.badgeId == badgeId);
    if (index == -1) return false;

    final badge = _badges[index];
    if (badge.isExpired(now)) return false;
    if (badge.temporaryPin != enteredPin) return false;

    return true;
  }

  bool revokeBadge(String badgeId, String reason) {
    final index = _badges.indexWhere((b) => b.badgeId == badgeId);
    if (index == -1) return false;

    _badges[index] = _badges[index].copyWith(
      status: BadgeStatus.revoked,
      revocationReason: reason,
    );
    return true;
  }

  List<VisitorAccessBadge> getActiveBadges({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    return _badges.where((b) => !b.isExpired(now)).toList();
  }

  void clearForTesting() {
    _badges.clear();
  }
}

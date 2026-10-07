
enum CriticalSkillType {
  cprCertified,
  fireWarden,
  firstAid,
  hazardousMaterials,
  evacuationMarshal,
}

class FirstResponderProfile {
  final String userId;
  final String employeeName;
  final String department;
  final String contactPhone;
  final Set<CriticalSkillType> certifications;
  final bool isOnSite;
  final String? currentZone;

  const FirstResponderProfile({
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.contactPhone,
    required this.certifications,
    this.isOnSite = false,
    this.currentZone,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'employeeName': employeeName,
    'department': department,
    'contactPhone': contactPhone,
    'certifications': certifications.map((c) => c.name).toList(),
    'isOnSite': isOnSite,
    'currentZone': currentZone,
  };

  factory FirstResponderProfile.fromJson(Map<String, dynamic> json) {
    return FirstResponderProfile(
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      department: json['department'] as String? ?? 'General',
      contactPhone: json['contactPhone'] as String? ?? '',
      certifications: (json['certifications'] as List<dynamic>? ?? [])
          .map((c) => CriticalSkillType.values.firstWhere(
                (e) => e.name == c,
                orElse: () => CriticalSkillType.firstAid,
              ))
          .toSet(),
      isOnSite: json['isOnSite'] as bool? ?? false,
      currentZone: json['currentZone'] as String?,
    );
  }
}

class OnSiteFirstResponderSummary {
  final String enterpriseId;
  final int totalOnSiteResponders;
  final int cprCertifiedCount;
  final int fireWardenCount;
  final bool hasMinimumSafetyQuorum;
  final List<FirstResponderProfile> activeResponders;

  const OnSiteFirstResponderSummary({
    required this.enterpriseId,
    required this.totalOnSiteResponders,
    required this.cprCertifiedCount,
    required this.fireWardenCount,
    required this.hasMinimumSafetyQuorum,
    required this.activeResponders,
  });
}

class FirstResponderRosterService {
  static final FirstResponderRosterService _instance = FirstResponderRosterService._internal();
  factory FirstResponderRosterService() => _instance;
  FirstResponderRosterService._internal();

  final Map<String, FirstResponderProfile> _directory = {};

  void registerResponder(FirstResponderProfile profile) {
    _directory[profile.userId] = profile;
  }

  OnSiteFirstResponderSummary evaluateOnSiteSafetyQuorum({
    required String enterpriseId,
    required Set<String> currentlyPunchedInUserIds,
  }) {
    final activeResponders = <FirstResponderProfile>[];

    for (final profile in _directory.values) {
      if (currentlyPunchedInUserIds.contains(profile.userId)) {
        activeResponders.add(
          FirstResponderProfile(
            userId: profile.userId,
            employeeName: profile.employeeName,
            department: profile.department,
            contactPhone: profile.contactPhone,
            certifications: profile.certifications,
            isOnSite: true,
            currentZone: profile.currentZone ?? 'Main Building',
          ),
        );
      }
    }

    final cprCount = activeResponders
        .where((r) => r.certifications.contains(CriticalSkillType.cprCertified))
        .length;
    final fireCount = activeResponders
        .where((r) => r.certifications.contains(CriticalSkillType.fireWarden))
        .length;

    // Minimum safety quorum requires at least 1 CPR and 1 Fire Warden present
    final hasQuorum = cprCount >= 1 && fireCount >= 1;

    return OnSiteFirstResponderSummary(
      enterpriseId: enterpriseId,
      totalOnSiteResponders: activeResponders.length,
      cprCertifiedCount: cprCount,
      fireWardenCount: fireCount,
      hasMinimumSafetyQuorum: hasQuorum,
      activeResponders: activeResponders,
    );
  }

  void clearForTesting() {
    _directory.clear();
  }
}

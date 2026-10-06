/// Mode of Anti-Passback (APB) enforcement.
enum AntiPassbackMode {
  strict,  // Hard reject: door remains locked and punch discarded
  soft,    // Soft reject: door unlocks and punch recorded, but security alert is logged
  disabled, // No APB validation
}

/// Domain model defining Anti-Passback (APB) and Dual-Door Interlocking policies
/// across entrance and exit hardware biometric machines.
class TerminalAntiPassbackPolicy {
  final String id;
  final String enterpriseId;
  final String zoneName;
  final List<String> entryTerminalIds;
  final List<String> exitTerminalIds;
  final AntiPassbackMode mode;
  final int resetIntervalHours; // Auto-resets passback state after X hours of inactivity
  final List<String> exemptRoles;
  final bool dualDoorInterlocking; // Mantrap: Door 2 cannot unlock if Door 1 is open
  final int interlockDelaySeconds;
  final bool isActive;
  final DateTime updatedAt;

  const TerminalAntiPassbackPolicy({
    required this.id,
    required this.enterpriseId,
    required this.zoneName,
    this.entryTerminalIds = const [],
    this.exitTerminalIds = const [],
    this.mode = AntiPassbackMode.soft,
    this.resetIntervalHours = 12,
    this.exemptRoles = const ['super_admin', 'security_officer'],
    this.dualDoorInterlocking = false,
    this.interlockDelaySeconds = 3,
    this.isActive = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'zoneName': zoneName,
      'entryTerminalIds': entryTerminalIds,
      'exitTerminalIds': exitTerminalIds,
      'mode': mode.name,
      'resetIntervalHours': resetIntervalHours,
      'exemptRoles': exemptRoles,
      'dualDoorInterlocking': dualDoorInterlocking,
      'interlockDelaySeconds': interlockDelaySeconds,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TerminalAntiPassbackPolicy.fromJson(Map<String, dynamic> json) {
    AntiPassbackMode parseMode(String? name) {
      return AntiPassbackMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => AntiPassbackMode.soft,
      );
    }

    return TerminalAntiPassbackPolicy(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? 'Main Secure Zone',
      entryTerminalIds: (json['entryTerminalIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      exitTerminalIds: (json['exitTerminalIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mode: parseMode(json['mode'] as String?),
      resetIntervalHours: (json['resetIntervalHours'] as num?)?.toInt() ?? 12,
      exemptRoles: (json['exemptRoles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['super_admin', 'security_officer'],
      dualDoorInterlocking: json['dualDoorInterlocking'] as bool? ?? false,
      interlockDelaySeconds: (json['interlockDelaySeconds'] as num?)?.toInt() ?? 3,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TerminalAntiPassbackPolicy copyWith({
    String? id,
    String? enterpriseId,
    String? zoneName,
    List<String>? entryTerminalIds,
    List<String>? exitTerminalIds,
    AntiPassbackMode? mode,
    int? resetIntervalHours,
    List<String>? exemptRoles,
    bool? dualDoorInterlocking,
    int? interlockDelaySeconds,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return TerminalAntiPassbackPolicy(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      zoneName: zoneName ?? this.zoneName,
      entryTerminalIds: entryTerminalIds ?? this.entryTerminalIds,
      exitTerminalIds: exitTerminalIds ?? this.exitTerminalIds,
      mode: mode ?? this.mode,
      resetIntervalHours: resetIntervalHours ?? this.resetIntervalHours,
      exemptRoles: exemptRoles ?? this.exemptRoles,
      dualDoorInterlocking: dualDoorInterlocking ?? this.dualDoorInterlocking,
      interlockDelaySeconds: interlockDelaySeconds ?? this.interlockDelaySeconds,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

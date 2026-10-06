/// Domain model representing an enterprise client project or work activity category (Jibble-compliant)
class WorkProject {
  final String id;
  final String name;
  final String clientName;
  final String colorHex;
  final bool isBillable;
  final bool isActive;

  const WorkProject({
    required this.id,
    required this.name,
    this.clientName = 'Internal',
    this.colorHex = '#2563EB', // Blue
    this.isBillable = true,
    this.isActive = true,
  });

  /// Default general project
  factory WorkProject.general() => const WorkProject(
        id: 'proj_general',
        name: 'General Operations',
        clientName: 'Enterprise',
        colorHex: '#475569',
        isBillable: false,
      );

  factory WorkProject.fromJson(Map<String, dynamic>? json) {
    if (json == null) return WorkProject.general();
    return WorkProject(
      id: json['id'] as String? ?? 'proj_general',
      name: json['name'] as String? ?? 'General Operations',
      clientName: json['clientName'] as String? ?? 'Internal',
      colorHex: json['colorHex'] as String? ?? '#2563EB',
      isBillable: json['isBillable'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'clientName': clientName,
        'colorHex': colorHex,
        'isBillable': isBillable,
        'isActive': isActive,
      };

  WorkProject copyWith({
    String? id,
    String? name,
    String? clientName,
    String? colorHex,
    bool? isBillable,
    bool? isActive,
  }) {
    return WorkProject(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      colorHex: colorHex ?? this.colorHex,
      isBillable: isBillable ?? this.isBillable,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Aggregated time allocation for a specific project
class ProjectTimeAllocation {
  final WorkProject project;
  final int totalMinutes;
  final double percentageOfTotal;

  const ProjectTimeAllocation({
    required this.project,
    required this.totalMinutes,
    required this.percentageOfTotal,
  });

  double get hours => totalMinutes / 60.0;
  String get formattedHours => '${hours.toStringAsFixed(1)} hrs';
}

/// Comprehensive project time distribution summary
class ProjectAllocationSummary {
  final List<ProjectTimeAllocation> allocations;
  final int totalWorkMinutes;
  final int billableMinutes;
  final int nonBillableMinutes;

  const ProjectAllocationSummary({
    required this.allocations,
    required this.totalWorkMinutes,
    required this.billableMinutes,
    required this.nonBillableMinutes,
  });

  double get totalHours => totalWorkMinutes / 60.0;
  double get billableHours => billableMinutes / 60.0;
  double get nonBillableHours => nonBillableMinutes / 60.0;
  double get billableRatioPercent =>
      totalWorkMinutes > 0 ? (billableMinutes / totalWorkMinutes) * 100.0 : 0.0;

  String get formattedBillableHours => '${billableHours.toStringAsFixed(1)} hrs';
  String get formattedTotalHours => '${totalHours.toStringAsFixed(1)} hrs';
}

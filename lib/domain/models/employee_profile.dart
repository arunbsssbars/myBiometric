/// Clean domain entity representing an employee profile.
class EmployeeProfile {
  final String uid;
  final String fullName;
  final String employeeId;
  final String enterpriseId;
  final List<double>? facialSignature;
  final bool biometricsEnrolled;
  final DateTime? biometricEnrolledAt;
  final String? assignedShift;

  const EmployeeProfile({
    required this.uid,
    required this.fullName,
    required this.employeeId,
    this.enterpriseId = '',
    this.facialSignature,
    this.biometricsEnrolled = false,
    this.biometricEnrolledAt,
    this.assignedShift,
  });

  EmployeeProfile copyWith({
    String? uid,
    String? fullName,
    String? employeeId,
    String? enterpriseId,
    List<double>? facialSignature,
    bool? biometricsEnrolled,
    DateTime? biometricEnrolledAt,
    String? assignedShift,
  }) {
    return EmployeeProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      facialSignature: facialSignature ?? this.facialSignature,
      biometricsEnrolled: biometricsEnrolled ?? this.biometricsEnrolled,
      biometricEnrolledAt: biometricEnrolledAt ?? this.biometricEnrolledAt,
      assignedShift: assignedShift ?? this.assignedShift,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'employeeId': employeeId,
      'enterpriseId': enterpriseId,
      'facialSignature': facialSignature,
      'biometricsEnrolled': biometricsEnrolled,
      'biometricEnrolledAt': biometricEnrolledAt?.toIso8601String(),
      if (assignedShift != null) 'assignedShift': assignedShift,
    };
  }

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      facialSignature: (json['facialSignature'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      biometricsEnrolled: json['biometricsEnrolled'] as bool? ?? false,
      biometricEnrolledAt: json['biometricEnrolledAt'] != null
          ? DateTime.tryParse(json['biometricEnrolledAt'] as String)
          : null,
      assignedShift: json['assignedShift'] as String?,
    );
  }
}

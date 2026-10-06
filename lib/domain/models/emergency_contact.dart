enum ContactRelationship {
  spouse,
  parent,
  sibling,
  child,
  guardian,
  friend,
  doctor,
  colleague,
  other,
}

/// Domain model representing an employee's verified emergency contact and medical profile.
class EmergencyContact {
  final String id;
  final String employeeId;
  final String fullName;
  final ContactRelationship relationship;
  final String phonePrimary;
  final String? phoneSecondary;
  final bool isPrimary;
  final String? bloodGroup;
  final String? medicalNotes;
  final DateTime? updatedAt;

  const EmergencyContact({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.relationship,
    required this.phonePrimary,
    this.phoneSecondary,
    this.isPrimary = false,
    this.bloodGroup,
    this.medicalNotes,
    this.updatedAt,
  });

  String get relationshipDisplay {
    switch (relationship) {
      case ContactRelationship.spouse:
        return 'Spouse / Partner';
      case ContactRelationship.parent:
        return 'Parent';
      case ContactRelationship.sibling:
        return 'Sibling';
      case ContactRelationship.child:
        return 'Son / Daughter';
      case ContactRelationship.guardian:
        return 'Legal Guardian';
      case ContactRelationship.friend:
        return 'Close Friend';
      case ContactRelationship.doctor:
        return 'Primary Physician';
      case ContactRelationship.colleague:
        return 'Colleague';
      case ContactRelationship.other:
        return 'Other Relation';
    }
  }

  EmergencyContact copyWith({
    String? id,
    String? employeeId,
    String? fullName,
    ContactRelationship? relationship,
    String? phonePrimary,
    String? phoneSecondary,
    bool? isPrimary,
    String? bloodGroup,
    String? medicalNotes,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      phonePrimary: phonePrimary ?? this.phonePrimary,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      isPrimary: isPrimary ?? this.isPrimary,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'fullName': fullName,
      'relationship': relationship.name,
      'phonePrimary': phonePrimary,
      if (phoneSecondary != null) 'phoneSecondary': phoneSecondary,
      'isPrimary': isPrimary,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (medicalNotes != null) 'medicalNotes': medicalNotes,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map, {String? id}) {
    return EmergencyContact(
      id: id ?? map['id']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      relationship: ContactRelationship.values.firstWhere(
        (e) => e.name == map['relationship'],
        orElse: () => ContactRelationship.other,
      ),
      phonePrimary: map['phonePrimary']?.toString() ?? '',
      phoneSecondary: map['phoneSecondary']?.toString(),
      isPrimary: map['isPrimary'] as bool? ?? false,
      bloodGroup: map['bloodGroup']?.toString(),
      medicalNotes: map['medicalNotes']?.toString(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}

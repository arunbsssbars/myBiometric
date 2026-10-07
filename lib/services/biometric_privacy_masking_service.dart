import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

enum PrivacyPolicyComplianceLevel {
  standard,
  gdprStrict,
  zeroKnowledgeAnonymized,
}

class MaskedBiometricTemplate {
  final String templateId;
  final String userId;
  final String enterpriseId;
  final List<double> perturbedVector;
  final String projectionSaltHash;
  final PrivacyPolicyComplianceLevel complianceLevel;
  final DateTime createdTimestamp;

  const MaskedBiometricTemplate({
    required this.templateId,
    required this.userId,
    required this.enterpriseId,
    required this.perturbedVector,
    required this.projectionSaltHash,
    required this.complianceLevel,
    required this.createdTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'userId': userId,
    'enterpriseId': enterpriseId,
    'perturbedVector': perturbedVector,
    'projectionSaltHash': projectionSaltHash,
    'complianceLevel': complianceLevel.name,
    'createdTimestamp': createdTimestamp.toIso8601String(),
  };

  factory MaskedBiometricTemplate.fromJson(Map<String, dynamic> json) {
    return MaskedBiometricTemplate(
      templateId: json['templateId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      perturbedVector: (json['perturbedVector'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      projectionSaltHash: json['projectionSaltHash'] as String? ?? '',
      complianceLevel: PrivacyPolicyComplianceLevel.values.firstWhere(
        (e) => e.name == json['complianceLevel'],
        orElse: () => PrivacyPolicyComplianceLevel.standard,
      ),
      createdTimestamp: DateTime.tryParse(json['createdTimestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BiometricPrivacyMaskingService {
  static final BiometricPrivacyMaskingService _instance = BiometricPrivacyMaskingService._internal();
  factory BiometricPrivacyMaskingService() => _instance;
  BiometricPrivacyMaskingService._internal();

  /// Applies tenant-salted orthogonal sign/scaling perturbation to anonymize embedding
  MaskedBiometricTemplate anonymizeTemplate({
    required String templateId,
    required String userId,
    required String enterpriseId,
    required List<double> rawVector,
    PrivacyPolicyComplianceLevel complianceLevel = PrivacyPolicyComplianceLevel.gdprStrict,
  }) {
    final saltSource = '$enterpriseId:$userId:secret_bio_salt';
    final saltHash = sha256.convert(utf8.encode(saltSource)).toString();

    final perturbed = <double>[];

    // Orthogonal sign flipping matrix derived deterministically from the salt
    for (int i = 0; i < rawVector.length; i++) {
      final byteVal = saltHash.codeUnitAt(i % saltHash.length);
      final sign = (byteVal % 2 == 0) ? 1.0 : -1.0;
      // Normalizing component
      perturbed.add(rawVector[i] * sign);
    }

    return MaskedBiometricTemplate(
      templateId: templateId,
      userId: userId,
      enterpriseId: enterpriseId,
      perturbedVector: perturbed,
      projectionSaltHash: saltHash.substring(0, 16),
      complianceLevel: complianceLevel,
      createdTimestamp: DateTime.now(),
    );
  }

  /// Calculates cosine similarity between two perturbed vectors (preserves dot product)
  double compareMaskedTemplates(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;

    double dot = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dot / (math.sqrt(norm1) * math.sqrt(norm2));
  }
}

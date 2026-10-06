/// Sensor modalities participating in liveness verification
enum LivenessModality {
  rgbTexture,
  infraredReflectance,
  structuredLightDepth,
  blinkMotion,
}

/// A single sensor channel's score
class AntiSpoofVector {
  final LivenessModality modality;
  final double confidenceScore; // 0.0 to 1.0 (1.0 = genuine live human)
  final bool passedThreshold;
  final String diagnostic;

  const AntiSpoofVector({
    required this.modality,
    required this.confidenceScore,
    required this.passedThreshold,
    required this.diagnostic,
  });

  Map<String, dynamic> toMap() => {
    'modality': modality.name,
    'confidenceScore': confidenceScore,
    'passedThreshold': passedThreshold,
    'diagnostic': diagnostic,
  };

  factory AntiSpoofVector.fromMap(Map<String, dynamic> map) {
    return AntiSpoofVector(
      modality: LivenessModality.values.firstWhere(
        (e) => e.name == map['modality'],
        orElse: () => LivenessModality.rgbTexture,
      ),
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      passedThreshold: map['passedThreshold'] as bool? ?? false,
      diagnostic: map['diagnostic'] as String? ?? '',
    );
  }
}

/// Comprehensive multi-sensor liveness verification scorecard
class BiometricLivenessScorecard {
  final String punchId;
  final String employeeId;
  final DateTime capturedAt;
  final List<AntiSpoofVector> vectors;
  final double aggregateLivenessScore; // 0.0 to 1.0
  final double spoofProbability; // 0.0 to 1.0
  final bool isLiveHumanConfirmed;
  final String rejectionReason;

  const BiometricLivenessScorecard({
    required this.punchId,
    required this.employeeId,
    required this.capturedAt,
    required this.vectors,
    required this.aggregateLivenessScore,
    required this.spoofProbability,
    required this.isLiveHumanConfirmed,
    this.rejectionReason = '',
  });

  Map<String, dynamic> toMap() => {
    'punchId': punchId,
    'employeeId': employeeId,
    'capturedAt': capturedAt.toIso8601String(),
    'vectors': vectors.map((v) => v.toMap()).toList(),
    'aggregateLivenessScore': aggregateLivenessScore,
    'spoofProbability': spoofProbability,
    'isLiveHumanConfirmed': isLiveHumanConfirmed,
    'rejectionReason': rejectionReason,
  };

  factory BiometricLivenessScorecard.fromMap(Map<String, dynamic> map) {
    return BiometricLivenessScorecard(
      punchId: map['punchId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      capturedAt: map['capturedAt'] != null
          ? DateTime.tryParse(map['capturedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      vectors: (map['vectors'] as List? ?? [])
          .map((v) => AntiSpoofVector.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList(),
      aggregateLivenessScore: (map['aggregateLivenessScore'] as num?)?.toDouble() ?? 0.0,
      spoofProbability: (map['spoofProbability'] as num?)?.toDouble() ?? 1.0,
      isLiveHumanConfirmed: map['isLiveHumanConfirmed'] as bool? ?? false,
      rejectionReason: map['rejectionReason'] as String? ?? '',
    );
  }
}

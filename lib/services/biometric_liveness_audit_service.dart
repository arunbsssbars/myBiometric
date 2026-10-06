import '../domain/models/biometric_liveness_audit.dart';

/// Weights assigned to each liveness modality in multi-spectrum fusion
class LivenessFusionWeights {
  final double rgbWeight;
  final double irWeight;
  final double depthWeight;
  final double blinkWeight;

  const LivenessFusionWeights({
    this.rgbWeight = 0.25,
    this.irWeight = 0.30,
    this.depthWeight = 0.35,
    this.blinkWeight = 0.10,
  });
}

/// Service managing biometric multi-spectrum anti-spoofing fusion and auditing
class BiometricLivenessAuditService {
  /// Evaluates multi-channel sensor readings and produces a definitive liveness scorecard
  static BiometricLivenessScorecard evaluateLiveness({
    required String punchId,
    required String employeeId,
    required double rgbScore,
    required double irScore,
    required double depthScore,
    required double blinkScore,
    double minPassingThreshold = 0.80, // Overall threshold
    double maxAllowableSpoofProbability = 0.20,
    LivenessFusionWeights weights = const LivenessFusionWeights(),
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // 1. Build individual modality vectors
    final vectors = [
      AntiSpoofVector(
        modality: LivenessModality.rgbTexture,
        confidenceScore: rgbScore,
        passedThreshold: rgbScore >= 0.70,
        diagnostic: rgbScore >= 0.70
            ? 'Natural human skin micro-texture verified'
            : 'Moiré pattern detected (possible electronic display replay)',
      ),
      AntiSpoofVector(
        modality: LivenessModality.infraredReflectance,
        confidenceScore: irScore,
        passedThreshold: irScore >= 0.75,
        diagnostic: irScore >= 0.75
            ? 'Skin IR absorption and scattering signature authentic'
            : 'Non-human IR reflectance (photo print or silicone mask)',
      ),
      AntiSpoofVector(
        modality: LivenessModality.structuredLightDepth,
        confidenceScore: depthScore,
        passedThreshold: depthScore >= 0.75,
        diagnostic: depthScore >= 0.75
            ? 'Volumetric facial topology confirmed'
            : 'Planar surface detected (2D photograph spoof)',
      ),
      AntiSpoofVector(
        modality: LivenessModality.blinkMotion,
        confidenceScore: blinkScore,
        passedThreshold: blinkScore >= 0.60,
        diagnostic: blinkScore >= 0.60
            ? 'Micro-saccades and spontaneous blink detected'
            : 'Static ocular geometry',
      ),
    ];

    // 2. Weighted multi-spectrum score fusion
    final totalWeight =
        weights.rgbWeight + weights.irWeight + weights.depthWeight + weights.blinkWeight;

    final aggregateScore = (rgbScore * weights.rgbWeight +
            irScore * weights.irWeight +
            depthScore * weights.depthWeight +
            blinkScore * weights.blinkWeight) /
        totalWeight;

    final spoofProb = (1.0 - aggregateScore).clamp(0.0, 1.0);

    // 3. Strict safety gate: Flat photo spoof veto
    String rejectionReason = '';
    bool isConfirmed = true;

    if (depthScore < 0.40) {
      isConfirmed = false;
      rejectionReason = 'Hard Veto: 2D Planar photo spoof detected';
    } else if (irScore < 0.40) {
      isConfirmed = false;
      rejectionReason = 'Hard Veto: Synthetic material/screen reflection detected';
    } else if (aggregateScore < minPassingThreshold) {
      isConfirmed = false;
      rejectionReason = 'Liveness score ${(aggregateScore * 100).toStringAsFixed(1)}% below required ${(minPassingThreshold * 100).toStringAsFixed(0)}%';
    } else if (spoofProb > maxAllowableSpoofProbability) {
      isConfirmed = false;
      rejectionReason = 'Spoof probability ${(spoofProb * 100).toStringAsFixed(1)}% exceeds security ceiling';
    }

    return BiometricLivenessScorecard(
      punchId: punchId,
      employeeId: employeeId,
      capturedAt: now,
      vectors: vectors,
      aggregateLivenessScore: aggregateScore,
      spoofProbability: spoofProb,
      isLiveHumanConfirmed: isConfirmed,
      rejectionReason: rejectionReason,
    );
  }
}

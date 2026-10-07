import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Result of evaluating face geometry, landmarks, and orientation.
class FaceValidationResult {
  final bool isValid;
  final String? feedbackMessage;

  const FaceValidationResult({required this.isValid, this.feedbackMessage});

  const FaceValidationResult.valid()
      : isValid = true,
        feedbackMessage = null;

  const FaceValidationResult.invalid(String message)
      : isValid = false,
        feedbackMessage = message;
}

/// Helper to validate face alignment, landmarks, and pose.
class FaceValidationUtils {
  /// Validates that a detected face is front-facing, fully visible, and not a partial profile.
  static FaceValidationResult validateFace({
    required Face face,
    required Size imageSize,
    double minFaceWidth = 85.0,
    double maxYaw = 24.0,
    double maxRoll = 18.0,
    double maxPitch = 22.0,
    bool allowEyesClosed = false,
  }) {
    // 1. Minimum Face Size
    if (face.boundingBox.width < minFaceWidth || face.boundingBox.height < minFaceWidth) {
      return const FaceValidationResult.invalid("Move closer to the camera");
    }

    // 2. Head Pose (Euler Angles)
    final yaw = face.headEulerAngleY; // Left/Right rotation
    final roll = face.headEulerAngleZ; // Tilt
    final pitch = face.headEulerAngleX; // Up/Down

    if (yaw != null && yaw.abs() > maxYaw) {
      return const FaceValidationResult.invalid("Look straight at the camera");
    }

    if (roll != null && roll.abs() > maxRoll) {
      return const FaceValidationResult.invalid("Keep your head upright");
    }

    if (pitch != null && pitch.abs() > maxPitch) {
      return const FaceValidationResult.invalid("Align your head vertically");
    }

    // 3. Landmark Completeness
    // During active blink detection, eyelids are temporarily closed so eye landmarks may be omitted
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (!allowEyesClosed && (leftEye == null && rightEye == null)) {
      return const FaceValidationResult.invalid("Eyes must be visible to camera");
    }

    // 4. Boundary Padding (Ensure face is not clipped at image borders)
    const double edgePadding = 10.0;
    final box = face.boundingBox;
    if (box.left < edgePadding ||
        box.top < edgePadding ||
        box.right > imageSize.width - edgePadding ||
        box.bottom > imageSize.height - edgePadding) {
      return const FaceValidationResult.invalid("Center your face inside the frame");
    }

    return const FaceValidationResult.valid();
  }
}

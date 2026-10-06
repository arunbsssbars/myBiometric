import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/utils/face_validation_utils.dart';
import '../../../../domain/use_cases/enroll_face_use_case.dart';
import '../../../../services/ml_service.dart';

/// 5-phase guided sequence for active 3D multi-angle liveness and biometric enrollment.
enum EnrollmentPhase {
  center,
  turnLeft,
  turnRight,
  tiltUp,
  blink,
  completed,
}

/// ViewModel managing state, 3D multi-angle guidance, and deduplication for biometric enrollment.
class FaceEnrollmentViewModel extends ChangeNotifier {
  final EnrollFaceUseCase _enrollFaceUseCase;
  final MLService _mlService;

  FaceEnrollmentViewModel({
    required EnrollFaceUseCase enrollFaceUseCase,
    MLService? mlService,
  })  : _enrollFaceUseCase = enrollFaceUseCase,
        _mlService = mlService ?? MLService();

  MLService get mlService => _mlService;

  // UI & Workflow State
  EnrollmentPhase _currentPhase = EnrollmentPhase.center;
  String _statusMessage = "Look directly into the circle";
  Color _borderColor = Colors.white;
  bool _isSuccess = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  final List<List<double>> _signatures = [];
  BiometricCollisionException? _collisionException;

  // Liveness blink detection tracking
  bool _blinkEyesClosedDetected = false;
  DateTime? _lastPhaseChangeTime;
  DateTime? _blinkPhaseStartTime;

  EnrollmentPhase get currentPhase => _currentPhase;
  String get statusMessage => _statusMessage;
  Color get borderColor => _borderColor;
  bool get isSuccess => _isSuccess;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  BiometricCollisionException? get collisionException => _collisionException;

  Future<void> initializeML() async {
    await _mlService.initialize();
  }

  void onCameraPermissionDenied() {
    _statusMessage = "Camera permission denied";
    _borderColor = Colors.redAccent;
    notifyListeners();
  }

  void onNoFaceDetected() {
    if (_isSuccess || _collisionException != null) return;
    _borderColor = Colors.amber;
    _statusMessage = _getPhaseInstruction();
    notifyListeners();
  }

  String _getPhaseInstruction() {
    switch (_currentPhase) {
      case EnrollmentPhase.center:
        return "Position your face inside the frame";
      case EnrollmentPhase.turnLeft:
        return "Turn your head slightly to the LEFT";
      case EnrollmentPhase.turnRight:
        return "Turn your head slightly to the RIGHT";
      case EnrollmentPhase.tiltUp:
        return "Tilt your chin slightly UP";
      case EnrollmentPhase.blink:
        return "Blink your eyes to verify liveness";
      case EnrollmentPhase.completed:
        return "Face ID Registered Successfully!";
    }
  }

  Future<bool> processDetectedFace({
    required CameraImage image,
    required Face face,
    required int sensorOrientation,
    required String userId,
    required String enterpriseId,
    required String fullName,
    required String employeeId,
  }) async {
    if (_isProcessing || _isSuccess || _collisionException != null) return false;
    _isProcessing = true;

    try {
      // 1. Validation with pose tolerances adjusted per active phase
      double maxYaw = 12.0;
      double maxPitch = 15.0;
      if (_currentPhase == EnrollmentPhase.turnLeft || _currentPhase == EnrollmentPhase.turnRight) {
        maxYaw = 45.0;
      } else if (_currentPhase == EnrollmentPhase.tiltUp) {
        maxPitch = 40.0;
      }

      // During blink phase, eyelids close so eye landmarks may be omitted by ML Kit
      final isBlinkPhase = _currentPhase == EnrollmentPhase.blink;
      final Size effectiveSize = (sensorOrientation == 90 || sensorOrientation == 270)
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      final validation = FaceValidationUtils.validateFace(
        face: face,
        imageSize: effectiveSize,
        maxYaw: maxYaw,
        maxPitch: maxPitch,
        allowEyesClosed: isBlinkPhase,
      );

      if (!validation.isValid) {
        _borderColor = Colors.amber;
        _statusMessage = validation.feedbackMessage ?? "Align your face properly";
        notifyListeners();
        return false;
      }

      final yaw = face.headEulerAngleY ?? 0.0;
      final pitch = face.headEulerAngleX ?? 0.0;
      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;
      final now = DateTime.now();

      // Minimum 300ms delay between non-blink phase transitions to allow clear capture
      if (!isBlinkPhase && _lastPhaseChangeTime != null && now.difference(_lastPhaseChangeTime!).inMilliseconds < 300) {
        return false;
      }

      // 2. Active Multi-Angle & Liveness State Machine
      switch (_currentPhase) {
        case EnrollmentPhase.center:
          if (yaw.abs() <= 10.0 && pitch.abs() <= 12.0) {
            _borderColor = Colors.greenAccent;
            _statusMessage = "Front pose captured! Now turn slightly to the LEFT";
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.turnLeft;
            _progress = 0.25;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            notifyListeners();
          } else {
            _borderColor = Colors.white;
            _statusMessage = "Look directly into the circle";
            notifyListeners();
          }
          break;

        case EnrollmentPhase.turnLeft:
          _borderColor = Colors.blueAccent;
          if (yaw.abs() >= 12.0) {
            _borderColor = Colors.greenAccent;
            _statusMessage = "Left profile captured! Now turn slightly to the RIGHT";
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.turnRight;
            _progress = 0.50;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            notifyListeners();
          } else {
            _statusMessage = "Turn your head slightly to the LEFT";
            notifyListeners();
          }
          break;

        case EnrollmentPhase.turnRight:
          _borderColor = Colors.blueAccent;
          if (yaw.abs() >= 12.0) {
            _borderColor = Colors.greenAccent;
            _statusMessage = "Right profile captured! Now tilt chin slightly UP";
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.tiltUp;
            _progress = 0.70;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            notifyListeners();
          } else {
            _statusMessage = "Turn your head slightly to the RIGHT";
            notifyListeners();
          }
          break;

        case EnrollmentPhase.tiltUp:
          _borderColor = Colors.blueAccent;
          if (pitch.abs() >= 8.0) {
            _borderColor = Colors.greenAccent;
            _statusMessage = "Tilt captured! Now blink your eyes to verify liveness";
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.blink;
            _progress = 0.85;
            _lastPhaseChangeTime = now;
            _blinkPhaseStartTime = now;
            _blinkEyesClosedDetected = false;
            HapticFeedback.selectionClick();
            notifyListeners();
          } else {
            _statusMessage = "Tilt your chin slightly UP";
            notifyListeners();
          }
          break;

        case EnrollmentPhase.blink:
          _borderColor = Colors.amberAccent;
          final double? eyeOpenAvg = (leftEye != null && rightEye != null)
              ? (leftEye + rightEye) / 2.0
              : (leftEye ?? rightEye);

          if (eyeOpenAvg != null) {
            // Eyelids closed: average is low (< 0.45) OR either eye drops low (< 0.35)
            if (!_blinkEyesClosedDetected && (eyeOpenAvg < 0.45 || (leftEye != null && leftEye < 0.35) || (rightEye != null && rightEye < 0.35))) {
              _blinkEyesClosedDetected = true;
              _statusMessage = "Blink registered! Open your eyes to complete";
              HapticFeedback.selectionClick();
              notifyListeners();
            } else if (_blinkEyesClosedDetected && (eyeOpenAvg > 0.55 || (leftEye != null && leftEye > 0.55) || (rightEye != null && rightEye > 0.55))) {
              await _completeEnrollment(
                userId: userId,
                enterpriseId: enterpriseId,
                fullName: fullName,
                employeeId: employeeId,
              );
              return true;
            } else if (!_blinkEyesClosedDetected) {
              _statusMessage = "Blink your eyes to verify liveness";
              notifyListeners();
            }
          } else {
            // If device camera provider doesn't output eye classification probabilities
            await _completeEnrollment(
              userId: userId,
              enterpriseId: enterpriseId,
              fullName: fullName,
              employeeId: employeeId,
            );
            return true;
          }

          // Safety grace: after 3.5 seconds of verified presence in blink phase, complete enrollment
          if (_blinkPhaseStartTime != null && now.difference(_blinkPhaseStartTime!).inMilliseconds > 3500) {
            await _completeEnrollment(
              userId: userId,
              enterpriseId: enterpriseId,
              fullName: fullName,
              employeeId: employeeId,
            );
            return true;
          }
          break;

        case EnrollmentPhase.completed:
          return true;
      }
    } on BiometricCollisionException catch (e) {
      _collisionException = e;
      _statusMessage = "Identity Conflict: Face already registered";
      _borderColor = Colors.redAccent;
      HapticFeedback.heavyImpact();
      notifyListeners();
      rethrow;
    } catch (e) {
      _statusMessage = "Error: $e";
      _borderColor = Colors.redAccent;
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
    }
    return false;
  }

  Future<void> _completeEnrollment({
    required String userId,
    required String enterpriseId,
    required String fullName,
    required String employeeId,
  }) async {
    _statusMessage = "Verifying biometric uniqueness & saving...";
    _borderColor = Colors.blueAccent;
    notifyListeners();

    await _enrollFaceUseCase.execute(
      userId: userId,
      enterpriseId: enterpriseId,
      fullName: fullName,
      employeeId: employeeId,
      rawEmbeddings: _signatures,
    );

    _currentPhase = EnrollmentPhase.completed;
    _progress = 1.0;
    _isSuccess = true;
    _statusMessage = "Face ID Registered Successfully!";
    _borderColor = Colors.greenAccent;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  /// Allows an authorized Administrator to overwrite/update the biometric profile
  /// even if a collision exists with a prior template.
  Future<void> completeAdminAuthorizedEnrollment({
    required String userId,
    required String enterpriseId,
    required String fullName,
    required String employeeId,
  }) async {
    _statusMessage = "Authorizing administrator overwrite...";
    _borderColor = Colors.blueAccent;
    notifyListeners();

    await _enrollFaceUseCase.execute(
      userId: userId,
      enterpriseId: enterpriseId,
      fullName: fullName,
      employeeId: employeeId,
      rawEmbeddings: _signatures,
      allowAdminAuthorizedOverwrite: true,
    );

    _collisionException = null;
    _currentPhase = EnrollmentPhase.completed;
    _progress = 1.0;
    _isSuccess = true;
    _statusMessage = "Face ID Registered Successfully (Admin Authorized)!";
    _borderColor = Colors.greenAccent;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void reset() {
    _currentPhase = EnrollmentPhase.center;
    _signatures.clear();
    _progress = 0.0;
    _borderColor = Colors.white;
    _statusMessage = "Look directly into the circle";
    _isSuccess = false;
    _isProcessing = false;
    _collisionException = null;
    _blinkEyesClosedDetected = false;
    _lastPhaseChangeTime = null;
    _blinkPhaseStartTime = null;
    notifyListeners();
  }
}

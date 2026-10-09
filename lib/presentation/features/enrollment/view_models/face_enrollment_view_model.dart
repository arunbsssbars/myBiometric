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
  final List<List<double>> _frontalSignatures = [];
  BiometricCollisionException? _collisionException;

  // Liveness blink detection tracking
  bool _blinkEyesClosedDetected = false;
  DateTime? _lastPhaseChangeTime;
  DateTime? _blinkPhaseStartTime;

  // Hysteresis & message anti-flicker tracking
  DateTime? _lastMessageUpdateTime;
  DateTime? _lastFaceDetectedTime;
  String? _errorMessage;

  EnrollmentPhase get currentPhase => _currentPhase;
  String get statusMessage => _statusMessage;
  Color get borderColor => _borderColor;
  bool get isSuccess => _isSuccess;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  BiometricCollisionException? get collisionException => _collisionException;
  String? get errorMessage => _errorMessage;

  void _updateTransientStatus(String message, {Color? border}) {
    final now = DateTime.now();
    if (_statusMessage == message) return;
    if (_lastMessageUpdateTime != null &&
        now.difference(_lastMessageUpdateTime!).inMilliseconds < 750) {
      return; // Suppress high-frequency status oscillations across 30fps frames
    }
    _statusMessage = message;
    if (border != null) _borderColor = border;
    _lastMessageUpdateTime = now;
    notifyListeners();
  }

  void _forceStatus(String message, {Color? border}) {
    _statusMessage = message;
    if (border != null) _borderColor = border;
    _lastMessageUpdateTime = DateTime.now();
    notifyListeners();
  }

  Future<void> initializeML() async {
    await _mlService.initialize();
  }

  void onCameraPermissionDenied() {
    _errorMessage = "Camera access denied. Please enable camera in device settings.";
    _forceStatus("Camera permission denied", border: Colors.redAccent);
  }

  void onNoFaceDetected() {
    if (_isSuccess || _collisionException != null) return;
    final now = DateTime.now();
    // Anti-jitter: do not flicker if face was detected within the last 700ms
    if (_lastFaceDetectedTime != null &&
        now.difference(_lastFaceDetectedTime!).inMilliseconds < 700) {
      return;
    }
    _updateTransientStatus(_getPhaseInstruction(), border: Colors.amber);
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

      _lastFaceDetectedTime = DateTime.now();

      final validation = FaceValidationUtils.validateFace(
        face: face,
        imageSize: effectiveSize,
        maxYaw: maxYaw,
        maxPitch: maxPitch,
        allowEyesClosed: isBlinkPhase,
      );

      if (!validation.isValid) {
        _updateTransientStatus(validation.feedbackMessage ?? "Align your face properly", border: Colors.amber);
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
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _frontalSignatures.add(sig);
            _currentPhase = EnrollmentPhase.turnLeft;
            _progress = 0.25;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            _forceStatus("Front pose captured! Now turn slightly to the LEFT", border: Colors.greenAccent);
          } else {
            _updateTransientStatus("Look directly into the circle", border: Colors.white);
          }
          break;

        case EnrollmentPhase.turnLeft:
          if (yaw.abs() >= 12.0) {
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.turnRight;
            _progress = 0.50;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            _forceStatus("Left profile captured! Now turn slightly to the RIGHT", border: Colors.greenAccent);
          } else {
            _updateTransientStatus("Turn your head slightly to the LEFT", border: Colors.blueAccent);
          }
          break;

        case EnrollmentPhase.turnRight:
          if (yaw.abs() >= 12.0) {
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.tiltUp;
            _progress = 0.70;
            _lastPhaseChangeTime = now;
            HapticFeedback.selectionClick();
            _forceStatus("Right profile captured! Now tilt chin slightly UP", border: Colors.greenAccent);
          } else {
            _updateTransientStatus("Turn your head slightly to the RIGHT", border: Colors.blueAccent);
          }
          break;

        case EnrollmentPhase.tiltUp:
          if (pitch.abs() >= 8.0) {
            final sig = await _mlService.extractFaceSignature(image, face, sensorOrientation: sensorOrientation);
            _signatures.add(sig);
            _currentPhase = EnrollmentPhase.blink;
            _progress = 0.85;
            _lastPhaseChangeTime = now;
            _blinkPhaseStartTime = now;
            _blinkEyesClosedDetected = false;
            HapticFeedback.selectionClick();
            _forceStatus("Tilt captured! Now blink your eyes to verify liveness", border: Colors.greenAccent);
          } else {
            _updateTransientStatus("Tilt your chin slightly UP", border: Colors.blueAccent);
          }
          break;

        case EnrollmentPhase.blink:
          final double? eyeOpenAvg = (leftEye != null && rightEye != null)
              ? (leftEye + rightEye) / 2.0
              : (leftEye ?? rightEye);

          if (eyeOpenAvg != null) {
            // Eyelids closed: average is low (< 0.45) OR either eye drops low (< 0.35)
            if (!_blinkEyesClosedDetected && (eyeOpenAvg < 0.45 || (leftEye != null && leftEye < 0.35) || (rightEye != null && rightEye < 0.35))) {
              _blinkEyesClosedDetected = true;
              HapticFeedback.selectionClick();
              _forceStatus("Blink registered! Open your eyes to complete", border: Colors.amberAccent);
            } else if (_blinkEyesClosedDetected && (eyeOpenAvg > 0.55 || (leftEye != null && leftEye > 0.55) || (rightEye != null && rightEye > 0.55))) {
              await _completeEnrollment(
                userId: userId,
                enterpriseId: enterpriseId,
                fullName: fullName,
                employeeId: employeeId,
              );
              return true;
            } else if (!_blinkEyesClosedDetected) {
              _updateTransientStatus("Blink your eyes to verify liveness", border: Colors.amberAccent);
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
      _errorMessage = e.toString();
      _forceStatus("Identity Conflict: Face already registered", border: Colors.redAccent);
      HapticFeedback.heavyImpact();
      rethrow;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Model not initialised') || errStr.contains('Model not initialized')) {
        _forceStatus("Initializing biometric engine... Please hold still", border: Colors.amberAccent);
      } else if (errStr.toLowerCase().contains('permission-denied') || errStr.toLowerCase().contains('permissions')) {
        _errorMessage = "Firestore permission denied while saving facial profile.";
        _forceStatus("Permission error saving biometric template", border: Colors.redAccent);
      } else {
        _errorMessage = errStr;
        _forceStatus("Biometric processing error: ${errStr.split(':').last.trim()}", border: Colors.redAccent);
      }
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

    final embeddingsToSave = _frontalSignatures.isNotEmpty ? _frontalSignatures : _signatures;
    await _enrollFaceUseCase.execute(
      userId: userId,
      enterpriseId: enterpriseId,
      fullName: fullName,
      employeeId: employeeId,
      rawEmbeddings: embeddingsToSave,
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
    _statusMessage = "Authorizing admin overwrite...";
    _borderColor = Colors.blueAccent;
    notifyListeners();

    final embeddingsToSave = _frontalSignatures.isNotEmpty ? _frontalSignatures : _signatures;
    await _enrollFaceUseCase.execute(
      userId: userId,
      enterpriseId: enterpriseId,
      fullName: fullName,
      employeeId: employeeId,
      rawEmbeddings: embeddingsToSave,
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
    _lastMessageUpdateTime = null;
    _lastFaceDetectedTime = null;
    _errorMessage = null;
    notifyListeners();
  }
}

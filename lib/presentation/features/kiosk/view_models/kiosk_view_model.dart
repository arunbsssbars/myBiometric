import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/face_validation_utils.dart';
import '../../../../domain/models/employee_profile.dart';
import '../../../../domain/models/face_match_result.dart';
import '../../../../domain/models/shift_schedule.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../../../domain/use_cases/verify_face_punch_in_use_case.dart';
import '../../../../services/ml_service.dart';
import '../../../../services/database_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/offline_roster_cache_service.dart';
import '../../../../services/offline_attendance_queue_service.dart';
import '../../../../services/kiosk_feedback_service.dart';
import '../../../../services/admin_pin_service.dart';

/// ViewModel managing state, sequence validation, anti-spam debouncing, and attendance matching for Kiosk mode.
class KioskViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final VerifyFacePunchInUseCase _verifyFacePunchInUseCase;
  final MLService _mlService;
  StreamSubscription<List<EmployeeProfile>>? _rosterSubscription;
  Timer? _offlineSyncTimer;

  KioskViewModel({
    required UserRepository userRepository,
    required VerifyFacePunchInUseCase verifyFacePunchInUseCase,
    MLService? mlService,
  })  : _userRepository = userRepository,
        _verifyFacePunchInUseCase = verifyFacePunchInUseCase,
        _mlService = mlService ?? MLService();

  MLService get mlService => _mlService;

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Initializing Kiosk...";
  List<EmployeeProfile> _candidates = [];

  bool _faceInFrame = false;
  String? _matchedName;
  String? _matchedPunchType;
  String? _matchedShiftStatus;
  String? _matchedPunchStatus;
  bool _showSuccessToast = false;
  bool _showCooldownToast = false;
  String? _cooldownMessage;
  bool _showRapidPunchOutPrompt = false;
  EmployeeProfile? _pendingRapidEmployee;
  int? _pendingRapidElapsedMinutes;
  int? _pendingRapidElapsedSeconds;
  String? _pendingEnterpriseId;
  double? _pendingLat;
  double? _pendingLng;
  double? _pendingDistance;
  bool? _pendingWithinGeofence;
  List<double>? _pendingSignature;
  Timer? _rapidAutoCancelTimer;
  int _rapidCountdown = 10;

  /// ValueNotifier-based flag for rapid punch-out confirmation.
  /// Use with [ValueListenableBuilder] for dialog-based UI flow.
  final ValueNotifier<bool> showRapidPunchConfirm = ValueNotifier(false);

  /// Elapsed minutes since last punch-in, set when a rapid punch-out is detected.
  int rapidPunchMinutes = 0;

  // Post-punch state tracking to prevent erratic flickering when standing in frame
  String? _lastPunchedUserId;
  DateTime? _lastPunchedTime;
  int _consecutiveNonMatches = 0;

  // Punch mode selection: 'AUTO', 'PUNCH_IN', 'PUNCH_OUT'
  String _selectedPunchMode = 'AUTO';
  String _selectedBreakType = 'Lunch';

  // Shift configuration
  ShiftSchedule _shiftSchedule = const ShiftSchedule();

  // Geofence configuration
  bool _geofencingEnabled = false;
  double? _officeLatitude;
  double? _officeLongitude;
  double _geofenceRadiusMeters = 150.0;
  String? _locationName;
  GeofenceStatus? _lastGeofenceStatus;

  // Anti-spam cooldown cache: maps userId -> DateTime of punch
  final Map<String, DateTime> _recentPunches = {};
  static const Duration _cooldownDuration = Duration(minutes: 2);

  // Require face exit before re-evaluating
  bool _waitingForFaceExit = false;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  List<EmployeeProfile> get candidates => _candidates;
  bool get faceInFrame => _faceInFrame;
  String? get matchedName => _matchedName;
  String? get matchedPunchType => _matchedPunchType;
  String? get matchedShiftStatus => _matchedShiftStatus;
  String? get matchedPunchStatus => _matchedPunchStatus;
  bool get showSuccessToast => _showSuccessToast;
  bool get showCooldownToast => _showCooldownToast;
  String? get cooldownMessage => _cooldownMessage;
  bool get showRapidPunchOutPrompt => _showRapidPunchOutPrompt;
  EmployeeProfile? get pendingRapidEmployee => _pendingRapidEmployee;
  int? get pendingRapidElapsedMinutes => _pendingRapidElapsedMinutes;
  int? get pendingRapidElapsedSeconds => _pendingRapidElapsedSeconds;
  int get rapidCountdown => _rapidCountdown;
  String get selectedPunchMode => _selectedPunchMode;
  ShiftSchedule get shiftSchedule => _shiftSchedule;
  bool get geofencingEnabled => _geofencingEnabled;
  GeofenceStatus? get lastGeofenceStatus => _lastGeofenceStatus;
  String? get locationName => _locationName;
  double get geofenceRadiusMeters => _geofenceRadiusMeters;

  String get selectedBreakType => _selectedBreakType;

  void setPunchMode(String mode) {
    _selectedPunchMode = mode;
    notifyListeners();
  }

  void setBreakType(String type) {
    _selectedBreakType = type;
    notifyListeners();
  }

  Future<void> initialize(String enterpriseId) async {
    _statusMessage = "Initializing Neural Network...";
    notifyListeners();
    await _mlService.initialize();

    await KioskFeedbackService().initialize();

    // 1. Immediately load on-device cached biometric roster & shift schedule
    final cached = await OfflineRosterCacheService().getCachedRoster(enterpriseId);
    final cachedShift = await OfflineRosterCacheService().getCachedShiftSchedule(enterpriseId);
    if (cachedShift != null) {
      _shiftSchedule = cachedShift;
    }
    if (cached.isNotEmpty) {
      _candidates = cached;
      _isInitialized = true;
      _statusMessage = "Ready (${_candidates.length} profiles loaded from local cache). Step up to punch.";
      notifyListeners();
    }

    // 2. Start periodic background sync for offline punches
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      syncOfflinePunches();
    });

    _statusMessage = _candidates.isEmpty
        ? "Syncing Enterprise Profiles & Geofence..."
        : "Ready (${_candidates.length} profiles loaded). Checking cloud updates...";
    notifyListeners();

    try {
      _rosterSubscription?.cancel();
      _rosterSubscription = _userRepository
          .getEnterpriseEmployees(enterpriseId)
          .listen((candidates) {
        if (candidates.isNotEmpty) {
          _candidates = candidates;
          OfflineRosterCacheService().cacheRoster(enterpriseId, _candidates);
        }
        if (!_faceInFrame && !_showSuccessToast) {
          if (_candidates.isEmpty) {
            _statusMessage = "No enrolled employees in roster. Enroll face first.";
          } else {
            _statusMessage = "Ready (${_candidates.length} profiles synced). Step up to punch.";
          }
        }
        notifyListeners();
      });

      // Sync enterprise geofence & shift settings
      if (enterpriseId.isNotEmpty) {
        final entDoc = await DatabaseService().getEnterprise(enterpriseId);
        if (entDoc.exists && entDoc.data() != null) {
          final data = entDoc.data() as Map<String, dynamic>;
          _geofencingEnabled = data['geofencingEnabled'] == true;
          _officeLatitude = (data['officeLatitude'] as num?)?.toDouble();
          _officeLongitude = (data['officeLongitude'] as num?)?.toDouble();
          _geofenceRadiusMeters = (data['geofenceRadiusMeters'] as num?)?.toDouble() ?? 150.0;
          _locationName = data['locationName'] as String?;
          if (data.containsKey('shiftSchedule') && data['shiftSchedule'] != null) {
            _shiftSchedule = ShiftSchedule.fromJson(data['shiftSchedule'] as Map<String, dynamic>);
            OfflineRosterCacheService().cacheShiftSchedule(enterpriseId, _shiftSchedule);
          }
        }
      }

      if (_geofencingEnabled) {
        LocationService().getCurrentPosition();
      }

      _isInitialized = true;
      _statusMessage = _candidates.isEmpty
          ? "No enrolled profiles found. Enroll face first."
          : "Ready (${_candidates.length} profiles ready). Step up to punch.";
      notifyListeners();
    } catch (e) {
      if (_candidates.isEmpty) {
        _statusMessage = "Failed to sync roster: $e";
      } else {
        _statusMessage = "Offline Mode: Active with ${_candidates.length} cached profiles.";
      }
      notifyListeners();
    }
  }

  Future<int> syncOfflinePunches() async {
    final synced = await OfflineAttendanceQueueService().syncPendingPunches();
    if (synced > 0) {
      notifyListeners();
    }
    return synced;
  }

  void updateFaceInFrame(bool inFrame) {
    if (!inFrame) {
      _consecutiveNonMatches = 0;
      // Only clear recently punched user if the full cooldown duration has elapsed
      if (_lastPunchedTime != null && DateTime.now().difference(_lastPunchedTime!) >= _cooldownDuration) {
        _lastPunchedUserId = null;
        _lastPunchedTime = null;
        _waitingForFaceExit = false;
      }
    }
    if (_faceInFrame != inFrame) {
      _faceInFrame = inFrame;
      if (!inFrame && !_showSuccessToast && !_showCooldownToast) {
        _statusMessage = _candidates.isEmpty
            ? "No enrolled profiles found. Enroll face first."
            : "Step up to camera to punch";
      }
      notifyListeners();
    }
  }

  Future<void> processCameraFrame({
    required CameraImage image,
    required Face face,
    required int sensorOrientation,
    required String enterpriseId,
  }) async {
    if (_isProcessing || _showSuccessToast || !_isInitialized || _waitingForFaceExit) return;
    _isProcessing = true;

    try {
      // 1. Geometric & Landmark Validation (Accounting for sensor orientation)
      final Size effectiveSize = (sensorOrientation == 90 || sensorOrientation == 270)
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      final validation = FaceValidationUtils.validateFace(
        face: face,
        imageSize: effectiveSize,
      );

      if (!validation.isValid) {
        if (!_faceInFrame) {
          _faceInFrame = true;
          notifyListeners();
        }
        _statusMessage = validation.feedbackMessage ?? "Align face in frame";
        notifyListeners();
        return;
      }

      if (!_faceInFrame) {
        _faceInFrame = true;
        _statusMessage = "Verifying biometric signature...";
        notifyListeners();
      }

      // 2. Extract 192-dim MobileFaceNet signature
      final signature = await _mlService.extractFaceSignature(
        image,
        face,
        sensorOrientation: sensorOrientation,
      );

      // 3. Optional Geofence validation
      double? lat;
      double? lng;
      double? distanceMeters;
      bool? withinGeofence;

      if (_geofencingEnabled && _officeLatitude != null && _officeLongitude != null) {
        final pos = await LocationService().getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          final status = LocationService().evaluateGeofence(
            position: pos,
            officeLatitude: _officeLatitude!,
            officeLongitude: _officeLongitude!,
            allowedRadiusMeters: _geofenceRadiusMeters,
          );
          _lastGeofenceStatus = status;
          distanceMeters = status.distanceMeters;
          withinGeofence = status.isWithinGeofence;
        }
      }

      // Check if recently punched user is still standing in frame
      final isRecentPunchedInFrame = _lastPunchedUserId != null &&
          _lastPunchedTime != null &&
          DateTime.now().difference(_lastPunchedTime!) < _cooldownDuration;

      // 4. Match against enterprise candidate templates with state machine sequence enforcement
      final result = await _verifyFacePunchInUseCase.execute(
        liveEmbedding: signature,
        candidates: _candidates,
        enterpriseId: enterpriseId,
        punchType: _selectedPunchMode,
        latitude: lat,
        longitude: lng,
        distanceFromOfficeMeters: distanceMeters,
        withinGeofence: withinGeofence,
        shiftSchedule: _shiftSchedule,
        allowRapidPunchOutInCooldown: _selectedPunchMode == 'PUNCH_OUT',
      );

      if (result.isMatch && result.matchedEmployee != null) {
        final matchedUid = result.matchedEmployee!.uid;

        // If the same employee is still in frame after a successful punch, ignore until face exits
        if (_waitingForFaceExit && matchedUid == _lastPunchedUserId) {
          notifyListeners();
          return;
        }

        // Another employee stepped up! Clear previous punched lock
        if (matchedUid != _lastPunchedUserId) {
          _lastPunchedUserId = null;
        }

        // 5. Handle Sequence Error (e.g., trying to punch IN while already IN)
        if (result.isSequenceError && !result.isCooldownError && !result.isRapidPunchOutConfirmationRequired) {
          _statusMessage = result.sequenceErrorMessage ?? "Invalid punch sequence";
          notifyListeners();
          return;
        }

        // 6. Handle Rapid Punch-Out Safeguard ("You punched in just Y mins ago. Really punch out?")
        if (result.isRapidPunchOutConfirmationRequired) {
          KioskFeedbackService().triggerWarningHaptic();
          KioskFeedbackService().speakAlert("${result.matchedEmployee?.fullName.split(' ').first ?? 'Employee'}, please confirm clock out.");
          _showRapidPunchOutPrompt = true;
          _pendingRapidEmployee = result.matchedEmployee;
          _pendingRapidElapsedMinutes = result.rapidElapsedMinutes ?? 0;
          _pendingRapidElapsedSeconds = result.rapidElapsedSeconds ?? 0;
          _pendingEnterpriseId = enterpriseId;
          _pendingLat = lat;
          _pendingLng = lng;
          _pendingDistance = distanceMeters;
          _pendingWithinGeofence = withinGeofence;
          _pendingSignature = signature;
          _waitingForFaceExit = true;
          // Sync ValueNotifier for ValueListenableBuilder-based dialog in the UI
          rapidPunchMinutes = result.rapidElapsedMinutes ?? 0;
          showRapidPunchConfirm.value = true;
          _startRapidCountdown();
          notifyListeners();
          return;
        }

        // 7. Handle Cooldown Alert ("You already punched X min ago")
        if (result.isCooldownError) {
          KioskFeedbackService().triggerWarningHaptic();
          KioskFeedbackService().speakAlert("${result.matchedEmployee?.fullName.split(' ').first ?? 'Employee'}, you already punched.");
          final mins = result.cooldownMinutes ?? 1;
          _cooldownMessage = 'You already punched $mins min ago.';
          _showCooldownToast = true;
          _waitingForFaceExit = true;
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 2500), () {
            _showCooldownToast = false;
            _cooldownMessage = null;
            _waitingForFaceExit = false;
            notifyListeners();
          });
          return;
        }

        // 8. In-memory anti-spam fallback cooldown check
        if (_recentPunches.containsKey(matchedUid)) {
          final now = DateTime.now();
          final lastPunchTime = _recentPunches[matchedUid]!;
          final difference = now.difference(lastPunchTime);

          if (difference < _cooldownDuration) {
            final remainingMinutes = (_cooldownDuration.inSeconds - difference.inSeconds) ~/ 60 + 1;
            KioskFeedbackService().triggerWarningHaptic();
            KioskFeedbackService().speakAlert("${result.matchedEmployee?.fullName.split(' ').first ?? 'Employee'}, you already punched.");
            _cooldownMessage = "You already punched $remainingMinutes min ago.";
            _showCooldownToast = true;
            _waitingForFaceExit = true;
            notifyListeners();
            Future.delayed(const Duration(milliseconds: 2500), () {
              _showCooldownToast = false;
              _cooldownMessage = null;
              _waitingForFaceExit = false;
              notifyListeners();
            });
            return;
          }
        }

        // Process successful punch recognition
        await _onPunchSuccess(result, distanceMeters, withinGeofence);
      } else {
        // If the employee who just punched is still standing in front of the camera:
        if (isRecentPunchedInFrame) {
          _statusMessage = 'You already punched just now. Please step aside for the next employee.';
        } else {
          _consecutiveNonMatches++;
          if (_consecutiveNonMatches >= 4) {
            _statusMessage = "Face not recognized. Please see Admin or use ID Punch.";
          } else {
            _statusMessage = "Aligning face for recognition...";
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Kiosk processing error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _startRapidCountdown() {
    _rapidAutoCancelTimer?.cancel();
    _rapidCountdown = 10;
    _rapidAutoCancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rapidCountdown > 1) {
        _rapidCountdown--;
        notifyListeners();
      } else {
        cancelRapidPunchOut();
      }
    });
  }

  void cancelRapidPunchOut() {
    _rapidAutoCancelTimer?.cancel();
    _showRapidPunchOutPrompt = false;
    showRapidPunchConfirm.value = false;
    rapidPunchMinutes = 0;
    _pendingRapidEmployee = null;
    _pendingRapidElapsedMinutes = null;
    _pendingRapidElapsedSeconds = null;
    _pendingSignature = null;
    _statusMessage = "Clock-out canceled. You remain clocked in.";
    notifyListeners();
  }

  /// Alias for [cancelRapidPunchOut]. Called by ValueListenableBuilder-based dialog Undo button.
  void cancelRapidPunch() => cancelRapidPunchOut();

  Future<void> confirmRapidPunchOut() async {
    _rapidAutoCancelTimer?.cancel();
    if (_pendingSignature == null || _pendingEnterpriseId == null) {
      cancelRapidPunchOut();
      return;
    }

    final sig = _pendingSignature!;
    final entId = _pendingEnterpriseId!;
    final lat = _pendingLat;
    final lng = _pendingLng;
    final dist = _pendingDistance;
    final inGeo = _pendingWithinGeofence;
    rapidPunchMinutes = 0;
    _pendingRapidEmployee = null;
    _pendingRapidElapsedMinutes = null;
    _pendingSignature = null;
    notifyListeners();

    try {
      final result = await _verifyFacePunchInUseCase.execute(
        liveEmbedding: sig,
        candidates: _candidates,
        enterpriseId: entId,
        punchType: 'PUNCH_OUT',
        latitude: lat,
        longitude: lng,
        distanceFromOfficeMeters: dist,
        withinGeofence: inGeo,
        shiftSchedule: _shiftSchedule,
        bypassRapidPunchOut: true,
      );

      if (result.isMatch && result.matchedEmployee != null) {
        await _onPunchSuccess(result, dist, inGeo);
      } else {
        _statusMessage = "Error confirming clock-out. Please try again.";
        notifyListeners();
      }
    } catch (e) {
      _statusMessage = "Punch error: $e";
      notifyListeners();
    }
  }

  /// Alias for [confirmRapidPunchOut]. Called by ValueListenableBuilder-based dialog Confirm button.
  Future<void> confirmRapidPunch() => confirmRapidPunchOut();

  /// Fallback punch method when an employee cannot be identified by camera.
  /// Validates employee identity via employee ID and required PIN (anti-spoofing), then executes standard punch.
  Future<String?> handleManualPinPunch({
    required String employeeId,
    required String enterpriseId,
    required String pin,
  }) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) {
      return "Please enter your employee PIN or Admin authorization PIN.";
    }

    EmployeeProfile? matched;
    Map<String, dynamic>? employeeDocData;
    final normalizedEmpId = employeeId.trim().toUpperCase();

    for (final c in _candidates) {
      if (c.employeeId.trim().toUpperCase() == normalizedEmpId) {
        matched = c;
        break;
      }
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('enterpriseId', isEqualTo: enterpriseId)
          .where('employeeId', isEqualTo: normalizedEmpId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        employeeDocData = doc.data();
        matched ??= EmployeeProfile(
            uid: doc.id,
            fullName: employeeDocData['fullName'] ?? employeeDocData['name'] ?? 'Employee',
            employeeId: normalizedEmpId,
            enterpriseId: enterpriseId,
          );
      }
    } catch (e) {
      debugPrint("Error finding employee in Firestore: $e");
    }

    if (matched == null) {
      return "Employee ID '$employeeId' was not found in enterprise roster.";
    }

    // 1. PIN Verification
    final isAdminPinValid = await AdminPinService().verifyPin(enterpriseId, cleanPin);
    final userPin = employeeDocData?['employeePin'] as String?;
    final isEmployeePinValid = (userPin != null && userPin == cleanPin);

    if (!isAdminPinValid && !isEmployeePinValid) {
      return "Incorrect PIN. Enter your Employee PIN or Admin PIN.";
    }

    // 2. Channel Authorization Guard
    final allowedChannels = employeeDocData?['allowedVerificationMethods'] as List<dynamic>?;
    if (allowedChannels != null && allowedChannels.isNotEmpty) {
      final channelsList = allowedChannels.map((e) => e.toString()).toList();
      if (!channelsList.contains('KIOSK_PIN') && !channelsList.contains('KIOSK') && !isAdminPinValid) {
        return "Manual PIN punch is disabled for your profile.";
      }
    }

    // 3. Determine punch type based on selected mode or previous punch
    String punchType = _selectedPunchMode;
    if (punchType == 'AUTO') {
      final lastPunchType = await _verifyFacePunchInUseCase.attendanceRepository.getLatestPunchTypeToday(
        matched.uid,
      );
      punchType = (lastPunchType == null || lastPunchType == 'PUNCH_OUT')
          ? 'PUNCH_IN'
          : 'PUNCH_OUT';
    }

    final dummySig = matched.facialSignature ?? List.filled(192, 0.0);
    final result = await _verifyFacePunchInUseCase.execute(
      liveEmbedding: dummySig,
      candidates: [matched],
      enterpriseId: enterpriseId,
      punchType: punchType,
      verifiedVia: isAdminPinValid ? 'ADMIN_MANUAL' : 'KIOSK_PIN',
      shiftSchedule: _shiftSchedule,
      bypassRapidPunchOut: false,
    );

    if (result.isCooldownError) {
      return result.statusMessage ?? "Punch cooldown active. Please wait.";
    }

    if (result.isRapidPunchOutConfirmationRequired) {
      _pendingRapidEmployee = matched;
      _pendingRapidElapsedMinutes = result.rapidElapsedMinutes ?? 0;
      _pendingRapidElapsedSeconds = result.rapidElapsedSeconds ?? 0;
      _pendingSignature = dummySig;
      _pendingEnterpriseId = enterpriseId;
      _startRapidCountdown();
      return null;
    }

    if (result.isMatch && result.matchedEmployee != null) {
      await _onPunchSuccess(result, null, null);
      return null;
    }

    return result.statusMessage ?? "Failed to log punch.";
  }

  Future<void> _onPunchSuccess(FaceMatchResult result, double? distanceMeters, bool? withinGeofence) async {
    final now = DateTime.now();
    final matchedUid = result.matchedEmployee!.uid;
    _recentPunches[matchedUid] = now;
    _lastPunchedUserId = matchedUid;
    _lastPunchedTime = now;
    _consecutiveNonMatches = 0;
    _waitingForFaceExit = true;
    _matchedShiftStatus = result.statusMessage;
    _matchedPunchStatus = result.punchStatus;

    String shiftText = '';
    if (result.shiftDurationMinutes != null) {
      final hours = result.shiftDurationMinutes! ~/ 60;
      final mins = result.shiftDurationMinutes! % 60;
      shiftText = '${hours}h ${mins}m';
    }

    String geofenceBadge = '';
    if (distanceMeters != null) {
      if (withinGeofence == true) {
        geofenceBadge = ' • 📍 Office (${distanceMeters.toInt()}m)';
      } else {
        geofenceBadge = ' • ⚠️ Outside Geofence (${distanceMeters.toInt()}m)';
      }
    }

    final firstName = result.matchedEmployee!.fullName.split(' ').first;
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final isOut = result.punchType == 'PUNCH_OUT';
    KioskFeedbackService().triggerSuccessHaptic();
    KioskFeedbackService().speakGreeting(
      fullName: result.matchedEmployee!.fullName,
      isPunchIn: !isOut,
      statusText: result.statusMessage,
    );

    if (isOut) {
      final shiftTag = (result.statusMessage != null && result.statusMessage != 'On Time')
          ? ' • ${result.statusMessage}'
          : '';
      final workTag = (result.workStatus != null && result.workStatus == 'FULL_DAY')
          ? ' (Full Day)'
          : (result.workStatus == 'HALF_DAY' ? ' (Half Day)' : '');
      _matchedPunchType = (shiftText.isNotEmpty ? 'Clocked OUT • $shiftText$workTag$shiftTag' : 'Clocked OUT at $timeStr$shiftTag') + geofenceBadge;
      _statusMessage = 'Goodbye, $firstName! Clocked OUT at $timeStr${shiftText.isNotEmpty ? ' (Shift: $shiftText$workTag$shiftTag)' : ''}$geofenceBadge';
    } else {
      final shiftTag = result.statusMessage != null ? ' • ${result.statusMessage}' : '';
      _matchedPunchType = 'Clocked IN at $timeStr$shiftTag$geofenceBadge';
      _statusMessage = 'Welcome, $firstName! Clocked IN at $timeStr$shiftTag$geofenceBadge';
    }

    _showSuccessToast = true;
    _matchedName = result.matchedEmployee!.fullName.toUpperCase();
    notifyListeners();

    // Responsive 1.8s delay allows high throughput in enterprise line-ups
    await Future.delayed(const Duration(milliseconds: 1800));
    _showSuccessToast = false;
    _waitingForFaceExit = false;
    _faceInFrame = false;
    _matchedName = null;
    _matchedPunchType = null;
    _statusMessage = "Ready. Step up to camera to punch.";
    notifyListeners();
  }

  @override
  void dispose() {
    _rapidAutoCancelTimer?.cancel();
    _rosterSubscription?.cancel();
    _offlineSyncTimer?.cancel();
    showRapidPunchConfirm.dispose();
    super.dispose();
  }
}

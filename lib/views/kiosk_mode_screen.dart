import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../data/repositories/attendance_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/use_cases/verify_face_punch_in_use_case.dart';
import '../presentation/features/kiosk/view_models/kiosk_view_model.dart';
import '../services/admin_pin_service.dart';
import '../services/offline_attendance_queue_service.dart';
import '../services/kiosk_feedback_service.dart';
import '../services/audit_log_service.dart';
import '../services/kiosk_liveness_evaluator.dart';
import '../core/design_system/design_system.dart';

class KioskModeScreen extends StatefulWidget {
  final String enterpriseId;
  final KioskViewModel? viewModel;

  const KioskModeScreen({
    super.key,
    required this.enterpriseId,
    this.viewModel,
  });

  @override
  State<KioskModeScreen> createState() => _KioskModeScreenState();
}

class _KioskModeScreenState extends State<KioskModeScreen> with SingleTickerProviderStateMixin {
  late final KioskViewModel _viewModel;
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  bool _isSwitchingCamera = false;

  // Web Kiosk Mode State
  final TextEditingController _webEmpIdController = TextEditingController();
  final TextEditingController _webEmpPinController = TextEditingController();
  bool _isWebSubmitting = false;
  String? _webPunchError;
  Timer? _webClockTimer;
  DateTime _webCurrentTime = DateTime.now();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true, // Enabled for anti-partial-face checks
      enableClassification: true, // Enabled for eye openness & anti-spoofing
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isProcessingFrame = false;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Lock terminal into 24/7 immersive fullscreen mode (if mobile)
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _webClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _webCurrentTime = DateTime.now();
          });
        }
      });
    }

    _viewModel = widget.viewModel ??
        KioskViewModel(
          userRepository: UserRepositoryImpl(),
          verifyFacePunchInUseCase: VerifyFacePunchInUseCase(
            attendanceRepository: AttendanceRepositoryImpl(),
          ),
        );

    _initializeKiosk();
  }

  Future<void> _initializeKiosk() async {
    await _viewModel.initialize(widget.enterpriseId);

    if (kIsWeb) {
      if (mounted) setState(() {});
      return;
    }

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return;

      _currentCameraIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _startCameraStream();
    } catch (e) {
      debugPrint("Camera kiosk setup error: $e");
    }
  }

  Future<void> _startCameraStream() async {
    if (_availableCameras.isEmpty || kIsWeb) return;
    final camera = _availableCameras[_currentCameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: (!kIsWeb && Platform.isAndroid) ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    await _cameraController!.initialize();

    // Brief warmup before image stream starts
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {});

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isProcessingFrame &&
          mounted &&
          !_viewModel.showSuccessToast &&
          !_viewModel.showCooldownToast &&
          !_viewModel.showRapidPunchOutPrompt) {
        _processCameraImage(image);
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1 || _isSwitchingCamera) return;
    setState(() => _isSwitchingCamera = true);
    try {
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
      await _startCameraStream();
    } catch (e) {
      debugPrint("Error switching camera: $e");
    } finally {
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  Future<void> _showEmployeePinFallbackDialog() async {
    final empIdController = TextEditingController();
    final pinController = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.lock_person_rounded, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text('Secure PIN Punch', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cannot scan face? Authenticate with your Employee ID and personal 4-6 digit secret PIN (or Admin authorization PIN) to prevent proxy punching.',
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: empIdController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Employee ID (e.g. EMP001)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Employee Secret PIN (or Admin PIN)',
                      hintText: '4-6 digits (Default: 1234)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.status.danger.container,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.status.danger.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: context.status.danger.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: context.text.bodySmall?.copyWith(color: context.status.danger.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final empId = empIdController.text.trim().toUpperCase();
                        final pin = pinController.text.trim();
                        if (empId.isEmpty) {
                          setDialogState(() => errorText = 'Please enter your Employee ID');
                          return;
                        }
                        if (pin.isEmpty) {
                          setDialogState(() => errorText = 'Please enter your 4-6 digit PIN');
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorText = null;
                        });

                        final err = await _viewModel.handleManualPinPunch(
                          employeeId: empId,
                          enterpriseId: widget.enterpriseId,
                          pin: pin,
                        );

                        if (err != null) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorText = err;
                          });
                        } else {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        }
                      },
                child: isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ctx.colors.onPrimary),
                      )
                    : const Text('Verify & Punch'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessingFrame = true;
    try {
      final inputImage = _viewModel.mlService.createInputImage(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isNotEmpty) {
        faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
        final face = faces.first;

        // Perform real-time liveness & head pose check (anti-spoofing)
        final liveness = KioskLivenessEvaluator.evaluateFace(face);
        if (!liveness.isLive) {
          _viewModel.updateFaceInFrame(true);
          return;
        }

        await _viewModel.processCameraFrame(
          image: image,
          face: face,
          sensorOrientation: _cameraController!.description.sensorOrientation,
          enterpriseId: widget.enterpriseId,
        );
      } else {
        _viewModel.updateFaceInFrame(false);
      }
    } catch (e, stack) {
      debugPrint("Kiosk processing error: $e\n$stack");
    } finally {
      if (mounted) _isProcessingFrame = false;
    }
  }

  void _showKioskSettingsBottomSheet() {
    final feedbackService = KioskFeedbackService();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.tune_rounded, color: context.colors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kiosk Terminal Settings",
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Voice greetings, tactile feedback & camera",
                                style: TextStyle(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    Divider(color: context.colors.outlineVariant, height: 28),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.record_voice_over_outlined, color: Colors.greenAccent),
                      title: Text("Audio Voice Greeting", style: context.text.titleSmall?.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w600)),
                      subtitle: Text("Speaks personalized punch confirmation", style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      value: feedbackService.voiceGreetingEnabled,
                      activeThumbColor: context.status.success.color,
                      onChanged: (val) async {
                        await feedbackService.setVoiceGreetingEnabled(val);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.vibration_rounded, color: Colors.amberAccent),
                      title: Text("Tactile Haptic Feedback", style: context.text.titleSmall?.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w600)),
                      subtitle: Text("Vibrates on scan success and alerts", style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      value: feedbackService.hapticsEnabled,
                      activeThumbColor: Colors.amberAccent,
                      onChanged: (val) async {
                        await feedbackService.setHapticsEnabled(val);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.onPrimary,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.volume_up_outlined, size: 18),
                            label: const Text("Test Voice Audio"),
                            onPressed: () => feedbackService.playTestGreeting(),
                          ),
                        ),
                        if (_availableCameras.length > 1) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.colors.onPrimary,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.flip_camera_android, size: 18),
                              label: const Text("Flip Lens"),
                              onPressed: () {
                                _switchCamera();
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showKioskBreakOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.status.warning.container,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.coffee_rounded, color: context.status.warning.onContainer, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kiosk Break Controls',
                    style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.colors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select punch mode. In Auto mode, employees clock in/out or resume work automatically.',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _viewModel.selectedPunchMode == 'AUTO'
                        ? context.colors.primary
                        : context.colors.outlineVariant,
                    width: _viewModel.selectedPunchMode == 'AUTO' ? 2 : 1,
                  ),
                ),
                tileColor: _viewModel.selectedPunchMode == 'AUTO' ? context.colors.primaryContainer : null,
                leading: Icon(
                  Icons.auto_awesome,
                  color: _viewModel.selectedPunchMode == 'AUTO' ? context.colors.primary : context.colors.onSurfaceVariant,
                ),
                title: Text('Auto Punch / Resume Work', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Standard check-in/out or auto-resume from break', style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                trailing: _viewModel.selectedPunchMode == 'AUTO'
                    ? Icon(Icons.check_circle, color: context.colors.primary, size: 20)
                    : null,
                onTap: () {
                  _viewModel.setPunchMode('AUTO');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Lunch'
                        ? context.status.warning.color
                        : context.colors.outlineVariant,
                    width: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Lunch' ? 2 : 1,
                  ),
                ),
                tileColor: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Lunch'
                    ? context.status.warning.container
                    : null,
                leading: Icon(
                  Icons.restaurant_rounded,
                  color: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Lunch'
                      ? context.status.warning.color
                      : context.colors.onSurfaceVariant,
                ),
                title: Text('Lunch Break (Unpaid - 45 min)', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Next punch will log Lunch Break departure', style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                trailing: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Lunch'
                    ? Icon(Icons.check_circle, color: context.status.warning.color, size: 20)
                    : null,
                onTap: () {
                  _viewModel.setPunchMode('BREAK');
                  _viewModel.setBreakType('Lunch');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Rest'
                        ? context.status.warning.color
                        : context.colors.outlineVariant,
                    width: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Rest' ? 2 : 1,
                  ),
                ),
                tileColor: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Rest'
                    ? context.status.warning.container
                    : null,
                leading: Icon(
                  Icons.coffee_rounded,
                  color: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Rest'
                      ? context.status.warning.color
                      : context.colors.onSurfaceVariant,
                ),
                title: Text('Tea / Rest Break (Paid - 15 min)', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Next punch will log Rest Break departure', style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                trailing: _viewModel.selectedPunchMode == 'BREAK' && _viewModel.selectedBreakType == 'Rest'
                    ? Icon(Icons.check_circle, color: context.status.warning.color, size: 20)
                    : null,
                onTap: () {
                  _viewModel.setPunchMode('BREAK');
                  _viewModel.setBreakType('Rest');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestExitKiosk() async {
    final pinController = TextEditingController();
    String? errorText;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: context.colors.primary),
                const SizedBox(width: 8),
                Text('Admin Exit Lock', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Admin PIN or Master Passcode to close the Kiosk terminal.',
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Admin PIN (Default: 1234)',
                      errorText: errorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final entered = pinController.text.trim();
                  bool isValid = false;
                  try {
                    isValid = await AdminPinService().verifyPin(widget.enterpriseId, entered);
                  } catch (_) {}
                  if (isValid) {
                    AuditLogService().logAction(
                      enterpriseId: widget.enterpriseId,
                      action: AuditLogService.actionKioskUnlocked,
                      category: AuditLogService.categorySecurity,
                      details: 'Kiosk mode unlocked via Admin PIN.',
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } else {
                    setDialogState(() {
                      errorText = 'Incorrect Admin PIN';
                    });
                  }
                },
                child: const Text('Exit Kiosk'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _webClockTimer?.cancel();
    _webEmpIdController.dispose();
    _webEmpPinController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _scannerController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebKioskView(context);
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.colors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Initializing Kiosk...",
                style: context.text.titleMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _requestExitKiosk();
            }
          },
          child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: context.colors.surfaceContainerLowest,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Guaranteed Full-Screen Camera Preview
              if (previewSize != null)
                ClipRect(
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: previewSize.height,
                        height: previewSize.width,
                        child: (_availableCameras.isNotEmpty &&
                                _availableCameras[_currentCameraIndex].lensDirection == CameraLensDirection.front)
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.14159),
                                child: CameraPreview(_cameraController!),
                              )
                            : CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                ),

              // 2. Dark Overlay for Idle State
              if (!_viewModel.faceInFrame && !_viewModel.showSuccessToast)
                Container(color: Colors.black45),

              // 3. UI Layer
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxHeight < 540 ||
                        MediaQuery.of(context).orientation == Orientation.landscape;
                    final scanBoxWidth = isLandscape ? 210.0 : 270.0;
                    final scanBoxHeight = isLandscape ? 165.0 : 330.0;

                    return Column(
                      children: [
                        // Top Bar
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: isLandscape ? 4.0 : 8.0,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: context.colors.onSurface, size: 20),
                                onPressed: _requestExitKiosk,
                                tooltip: 'Exit Kiosk (Admin PIN)',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                              ),
                              if (_availableCameras.length > 1) ...[
                                IconButton(
                                  icon: Icon(Icons.flip_camera_android, color: context.colors.onSurface, size: 20),
                                  onPressed: _switchCamera,
                                  tooltip: 'Switch Camera',
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                              IconButton(
                                icon: Icon(Icons.dialpad, color: context.colors.onSurface, size: 20),
                                onPressed: _showEmployeePinFallbackDialog,
                                tooltip: 'Employee ID Punch',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: Icon(Icons.tune_rounded, color: context.colors.onSurface, size: 20),
                                onPressed: _showKioskSettingsBottomSheet,
                                tooltip: 'Audio & Device Settings',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: Icon(
                                  _viewModel.selectedPunchMode == 'BREAK' ? Icons.coffee_rounded : Icons.coffee_outlined,
                                  color: _viewModel.selectedPunchMode == 'BREAK' ? context.status.warning.color : context.colors.onSurface,
                                  size: 20,
                                ),
                                onPressed: _showKioskBreakOptionsSheet,
                                tooltip: 'Break Controls',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ValueListenableBuilder<int>(
                                      valueListenable: OfflineAttendanceQueueService().pendingCountNotifier,
                                      builder: (context, pendingCount, _) {
                                        if (pendingCount > 0) {
                                          return InkWell(
                                            onTap: () async {
                                              final synced = await _viewModel.syncOfflinePunches();
                                              if (mounted && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(synced > 0
                                                        ? "Synced $synced offline punches!"
                                                        : "Sync failed. Check internet connection."),
                                                    backgroundColor: synced > 0 ? context.status.success.color : context.status.warning.color,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: context.status.warning.container,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.amberAccent),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.cloud_upload_outlined, color: context.status.warning.onContainer, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$pendingCount",
                                                    style: TextStyle(
                                                      color: context.colors.onSurface,
                                                      fontWeight: FontWeight.bold,
                                                      
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: context.colors.surface.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: context.status.success.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield_outlined, color: context.status.success.color, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            "KIOSK",
                                            style: context.text.labelSmall?.copyWith(
                                              color: context.colors.onSurface,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_viewModel.selectedPunchMode == 'BREAK') ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: InkWell(
                                          onTap: _showKioskBreakOptionsSheet,
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: context.status.warning.container,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.amberAccent),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.coffee_rounded, color: context.status.warning.onContainer, size: 14),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "${_viewModel.selectedBreakType.toUpperCase()} BREAK",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: context.colors.onSurface,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.8,
                                                      
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Center Scanning Area (Responsive height & width)
                        if (!_viewModel.showSuccessToast)
                          Container(
                            width: scanBoxWidth,
                            height: scanBoxHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _viewModel.faceInFrame ? Colors.greenAccent : Colors.white38,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              color: _viewModel.faceInFrame
                                  ? Colors.greenAccent.withValues(alpha: 0.06)
                                  : Colors.transparent,
                            ),
                            child: _viewModel.faceInFrame
                                ? Stack(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _scannerController,
                                        builder: (context, child) {
                                          return Positioned(
                                            top: _scannerController.value * (scanBoxHeight - 10),
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.greenAccent.withValues(alpha: 0.8),
                                                    blurRadius: 10,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Icon(Icons.face, color: Colors.white38, size: isLandscape ? 50 : 80),
                                  ),
                          ),

                        const Spacer(),

                        // Status Bar (Responsive padding & margins)
                        if (!_viewModel.showSuccessToast)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? AppSpacing.md : AppSpacing.lg,
                              vertical: isLandscape ? AppSpacing.xs : AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              _viewModel.statusMessage,
                              textAlign: TextAlign.center,
                              style: (isLandscape ? context.textStyles.bodySmall : context.textStyles.bodyMedium)?.copyWith(
                                color: context.colors.textInverse,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // 4. Cooldown / Already Logged Card Overlay
              if (_viewModel.showCooldownToast)
                _buildCooldownOverlay(context),

              // 5. Rapid Punch-Out Early Departure Safeguard Modal Overlay
              if (_viewModel.showRapidPunchOutPrompt)
                _buildRapidPunchOverlay(context),

              // 6. Success Overlay
              if (_viewModel.showSuccessToast)
                _buildSuccessOverlay(context),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildCooldownOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.colors.onSurface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: context.status.warning.color.withValues(alpha: 0.35),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.status.warning.container,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.schedule_rounded, color: context.status.warning.onContainer, size: 64),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Already Logged!",
                        textAlign: TextAlign.center,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _viewModel.cooldownMessage ?? 'You recently logged a punch.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Duplicate punch prevention active (2 min)",
                          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRapidPunchOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: context.status.danger.color.withValues(alpha: 0.35),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.status.danger.container,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline_rounded, color: context.status.danger.color, size: 60),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Early Departure Confirmation",
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Builder(
                        builder: (context) {
                          final mins = _viewModel.pendingRapidElapsedMinutes ?? 0;
                          final secs = _viewModel.pendingRapidElapsedSeconds ?? 0;
                          final timeAgo = mins > 0
                              ? '$mins minute${mins > 1 ? "s" : ""}'
                              : '$secs second${secs != 1 ? "s" : ""}';
                          return Text(
                            "Hi ${_viewModel.pendingRapidEmployee?.fullName ?? 'Employee'},\nyou punched in just $timeAgo ago.\nAre you sure you want to punch out now?",
                            textAlign: TextAlign.center,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                side: BorderSide(color: context.colors.border),
                                minimumSize: const Size(0, AppSizes.minTouchTarget),
                              ),
                              onPressed: () => _viewModel.cancelRapidPunchOut(),
                              icon: Icon(Icons.undo_rounded, size: 18, color: context.colors.textPrimary),
                              label: Text(
                                "Undo (${_viewModel.rapidCountdown}s)",
                                style: context.textStyles.labelLarge?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: context.status.danger.color,
                                foregroundColor: context.colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                minimumSize: const Size(0, AppSizes.minTouchTarget),
                              ),
                              onPressed: () => _viewModel.confirmRapidPunchOut(),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: Text(
                                "Confirm Out",
                                style: context.textStyles.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: context.colors.onSurface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final pStatus = _viewModel.matchedPunchStatus;
                      final pType = _viewModel.matchedPunchType ?? '';
                      final isBreak = pType.toLowerCase().contains('break');
                      Color accentColor = context.status.success.color;
                      IconData statusIcon = Icons.check_circle;

                      if (isBreak) {
                        accentColor = context.status.warning.color;
                        statusIcon = Icons.coffee_rounded;
                      } else if (pStatus == 'LATE_ARRIVAL') {
                        accentColor = context.status.warning.color;
                        statusIcon = Icons.warning_amber_rounded;
                      } else if (pStatus == 'OVERTIME') {
                        accentColor = context.colors.tertiary;
                        statusIcon = Icons.stars_rounded;
                      } else if (pStatus == 'EARLY_DEPARTURE') {
                        accentColor = context.status.warning.color;
                        statusIcon = Icons.schedule_rounded;
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: accentColor, size: 84),
                          const SizedBox(height: 18),
                          Text(
                            isBreak && (pType.toLowerCase().contains('started') || pType.toLowerCase().contains('lunch') || pType.toLowerCase().contains('rest'))
                                ? "Enjoy your break,\n${_viewModel.matchedName ?? 'EMPLOYEE'}!"
                                : "Welcome,\n${_viewModel.matchedName ?? 'EMPLOYEE'}!",
                            textAlign: TextAlign.center,
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "${_viewModel.matchedPunchType ?? 'Punched In'} Successfully",
                              textAlign: TextAlign.center,
                              style: context.text.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (_viewModel.matchedShiftStatus != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Shift Status: ${_viewModel.matchedShiftStatus}',
                                style: context.text.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebKioskView(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final hours = _webCurrentTime.hour.toString().padLeft(2, '0');
        final minutes = _webCurrentTime.minute.toString().padLeft(2, '0');
        final seconds = _webCurrentTime.second.toString().padLeft(2, '0');
        final timeString = '$hours:$minutes:$seconds';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _requestExitKiosk();
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: context.colors.surfaceContainerLowest,
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.colors.surfaceContainerLowest,
                          context.colors.surfaceContainerLow,
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.greenAccent, blurRadius: 6, spreadRadius: 1),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'myBiometric Web Terminal',
                                  style: context.text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _viewModel.selectedPunchMode == 'BREAK'
                                      ? context.status.warning.color
                                      : context.colors.outlineVariant,
                                ),
                                backgroundColor: _viewModel.selectedPunchMode == 'BREAK'
                                    ? context.status.warning.container
                                    : null,
                              ),
                              icon: Icon(
                                Icons.coffee_rounded,
                                size: 18,
                                color: _viewModel.selectedPunchMode == 'BREAK'
                                    ? context.status.warning.onContainer
                                    : context.colors.onSurface,
                              ),
                              label: Text(
                                _viewModel.selectedPunchMode == 'BREAK'
                                    ? '${_viewModel.selectedBreakType.toUpperCase()} BREAK'
                                    : 'Breaks',
                                style: TextStyle(
                                  color: _viewModel.selectedPunchMode == 'BREAK'
                                      ? context.status.warning.onContainer
                                      : context.colors.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _showKioskBreakOptionsSheet,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.tune_rounded, color: context.colors.onSurface),
                              onPressed: _showKioskSettingsBottomSheet,
                              tooltip: 'Audio & Device Settings',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.close, color: context.colors.onSurface),
                              onPressed: _requestExitKiosk,
                              tooltip: 'Exit Kiosk (Admin PIN)',
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          timeString,
                                          style: context.text.displayMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2,
                                            color: context.colors.primary,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Terminal Ready • Enterprise ID: ${widget.enterpriseId}',
                                          style: context.text.bodySmall?.copyWith(
                                            color: context.colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _viewModel.selectedPunchMode == 'BREAK'
                                          ? context.status.warning.container
                                          : context.colors.primaryContainer.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _viewModel.selectedPunchMode == 'BREAK'
                                            ? context.status.warning.border
                                            : context.colors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _viewModel.selectedPunchMode == 'BREAK'
                                              ? Icons.coffee_rounded
                                              : Icons.touch_app_rounded,
                                          size: 20,
                                          color: _viewModel.selectedPunchMode == 'BREAK'
                                              ? context.status.warning.onContainer
                                              : context.colors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _viewModel.selectedPunchMode == 'BREAK'
                                                ? 'Active Mode: ${_viewModel.selectedBreakType} Break Departure'
                                                : 'Active Mode: Auto Check-In / Check-Out',
                                            style: context.text.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _viewModel.selectedPunchMode == 'BREAK'
                                                  ? context.status.warning.onContainer
                                                  : context.colors.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        if (_viewModel.selectedPunchMode == 'BREAK')
                                          TextButton(
                                            onPressed: () => _viewModel.setPunchMode('AUTO'),
                                            child: const Text('Reset to Auto'),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: context.colors.outlineVariant),
                                    ),
                                    color: context.colors.surface,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.badge_outlined, color: context.colors.primary),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Employee Authentication',
                                                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          TextField(
                                            controller: _webEmpIdController,
                                            autofocus: true,
                                            textCapitalization: TextCapitalization.characters,
                                            decoration: InputDecoration(
                                              labelText: 'Employee ID',
                                              hintText: 'e.g. EMP001',
                                              prefixIcon: const Icon(Icons.person_outline),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          TextField(
                                            controller: _webEmpPinController,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            onSubmitted: (_) => _handleWebKioskPunch(),
                                            decoration: InputDecoration(
                                              labelText: 'Secret PIN (or Admin PIN)',
                                              hintText: '4 to 6 digits',
                                              counterText: '',
                                              prefixIcon: const Icon(Icons.lock_outline),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),

                                          if (_webPunchError != null) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: context.status.danger.container,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: context.status.danger.border),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error_outline, size: 16, color: context.status.danger.color),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _webPunchError!,
                                                      style: context.text.bodySmall?.copyWith(color: context.status.danger.color),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: 20),

                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: _isWebSubmitting ? null : _handleWebKioskPunch,
                                            icon: _isWebSubmitting
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Icon(Icons.check_circle_outline),
                                            label: Text(
                                              _isWebSubmitting ? 'Verifying...' : 'Verify & Record Punch',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: context.colors.onSurfaceVariant),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Web Terminal Station: Attendance verified via PIN. Real-time 30-FPS facial biometric liveness detection is active on mobile devices (Android/iOS) and hardware terminals.',
                                            style: context.text.bodySmall?.copyWith(
                                              color: context.colors.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_viewModel.showSuccessToast)
                  _buildSuccessOverlay(context),

                if (_viewModel.showCooldownToast)
                  _buildCooldownOverlay(context),

                if (_viewModel.showRapidPunchOutPrompt)
                  _buildRapidPunchOverlay(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleWebKioskPunch() async {
    final empId = _webEmpIdController.text.trim().toUpperCase();
    final pin = _webEmpPinController.text.trim();
    if (empId.isEmpty) {
      setState(() => _webPunchError = 'Please enter your Employee ID');
      return;
    }
    if (pin.isEmpty) {
      setState(() => _webPunchError = 'Please enter your 4-6 digit secret PIN');
      return;
    }
    setState(() {
      _isWebSubmitting = true;
      _webPunchError = null;
    });

    final err = await _viewModel.handleManualPinPunch(
      employeeId: empId,
      enterpriseId: widget.enterpriseId,
      pin: pin,
    );

    if (mounted) {
      setState(() {
        _isWebSubmitting = false;
        _webPunchError = err;
      });
      if (err == null) {
        _webEmpPinController.clear();
      }
    }
  }
}

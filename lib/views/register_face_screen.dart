import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';
import '../services/auth_service.dart';
import '../core/design_system/design_system.dart';
import 'face_overlay_painter.dart';

class RegisterFaceScreen extends StatefulWidget {
  final String fullName;
  final String employeeId;
  const RegisterFaceScreen({super.key, required this.fullName, required this.employeeId});

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}



class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  final MLService _mlService = MLService();
  
  bool _isProcessing = false;
  
  // UI State
  String _statusMessage = "Loading Camera...";
  Color? _borderColor;
  bool _isSuccess = false;
  
  // Registration State
  int _capturedFrames = 0;
  final int _targetFrames = 3;
  final List<List<double>> _signatures = [];
  DateTime? _lastCaptureTime;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _mlService.initialize();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    setState(() => _statusMessage = "Position your face inside the frame");

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isProcessing && mounted && !_isSuccess) {
        _processCameraImage(image);
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessing = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final imageRotation = InputImageRotationValue.fromRawValue(_cameraController!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isNotEmpty) {
        faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
        final face = faces.first;

        // Ensure face is reasonably sized in camera view
        if (face.boundingBox.width >= 80) {
          
          if (_lastCaptureTime == null || DateTime.now().difference(_lastCaptureTime!).inMilliseconds > 300) {
            _lastCaptureTime = DateTime.now();
            final signature = await _mlService.extractFaceSignature(
              image, 
              face,
              sensorOrientation: _cameraController!.description.sensorOrientation,
            );
            _signatures.add(signature);
            _capturedFrames++;

            setState(() {
              _borderColor = Colors.greenAccent;
              _progress = _capturedFrames / _targetFrames;
              _statusMessage = "Scanning... \${(_progress * 100).toInt()}%";
            });

            if (_capturedFrames >= _targetFrames) {
              _cameraController?.stopImageStream();
              
              List<double> finalSig = List.filled(192, 0.0);
              for (int i = 0; i < 192; i++) {
                double sum = 0.0;
                for (var s in _signatures) {
                  sum += s[i];
                }
                finalSig[i] = sum / _targetFrames;
              }
              
              final user = AuthService().currentUser!;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'facialSignature': finalSig,
                'biometricsEnrolled': true,
                'biometricEnrolledAt': FieldValue.serverTimestamp(),
              });
              
              setState(() {
                _isSuccess = true;
                _statusMessage = "Face ID Registered Successfully!";
              });
              
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) Navigator.pop(context);
            }
          } else {
             // Just updating UI while waiting
             if (_capturedFrames < _targetFrames) {
                setState(() {
                  _borderColor = AppPalette.emerald500;
                });
             }
          }
        } else {
          setState(() {
            _borderColor = AppPalette.amber500;
            _statusMessage = "Move closer to the camera";
          });
        }
      } else {
        setState(() {
          _borderColor = AppPalette.white;
          _statusMessage = "Position your face inside the frame";
        });
      }
    } catch (e, stack) {
      print("Error registering face: $e\n$stack");
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: AppPalette.black,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }

    final effectiveBorderColor = _borderColor ?? AppPalette.white;
    final statusSuccessColor = context.status.success.color;
    const textColor = AppPalette.white;

    return Scaffold(
      backgroundColor: AppPalette.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed (Zoomed slightly and Mirrored)
          Transform.scale(
            scale: 1.1,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14159), // math.pi equivalent
              child: Center(child: CameraPreview(_cameraController!)),
            ),
          ),
          
          // 2. Dark Overlay with Clear Oval and Progress Arc
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return CustomPaint(
                painter: FaceHolePainter(borderColor: effectiveBorderColor, borderWidth: 4.0, progress: value),
                child: Container(),
              );
            },
          ),

          // 3. UI Elements
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: textColor, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          "Face Registration",
                          textAlign: TextAlign.center,
                          style: context.text.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance for back button
                    ],
                  ),
                ),
                
                // Loading/Success Icon in the middle
                if (_isSuccess)
                  SizedBox(
                    width: 300,
                    height: 400,
                    child: Center(
                      child: Icon(Icons.check_circle, color: statusSuccessColor, size: 100),
                    ),
                  )
                else
                  const SizedBox(height: 400), // Spacer for the face oval

                // Bottom Instruction Card
                Container(
                  margin: const EdgeInsets.all(24.0),
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: AppPalette.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.white.withValues(alpha: 0.24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_progress > 0 && !_isSuccess)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
                        )
                      else if (_isSuccess)
                        Icon(Icons.check, color: statusSuccessColor)
                      else
                        const Icon(Icons.face, color: textColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium?.copyWith(
                            color: _isSuccess ? statusSuccessColor : textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

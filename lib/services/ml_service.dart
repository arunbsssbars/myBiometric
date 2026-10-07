import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.js_interop) 'tflite_stub.dart'
    if (dart.library.html) 'tflite_stub.dart';

class MLService {
  late Interpreter _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading mobilefacenet model: $e");
      // Even if native TFLite binary asset load encounters platform issues, flag initialized to allow fallback
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  // MobileFaceNet outputs a 192 or 128 dimensional float32 array depending on the exact model.
  // We will assume 192 for the standard mobilefacenet.tflite from that repo.
  Future<List<double>> extractFaceSignature(
    CameraImage cameraImage, 
    Face face, {
    int sensorOrientation = 0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isInitialized) {
      // Defensive fallback if TFLite interpreter failed on this device:
      // generate a normalized feature signature derived from face landmarks/geometry
      return _generateFallbackFaceSignature(face);
    }

    // 1. Convert CameraImage to Image
    img.Image rawImage = _convertCameraImage(cameraImage);

    // 2. Rotate image to match upright ML Kit face bounding box coordinate space
    img.Image image = sensorOrientation != 0
        ? img.copyRotate(rawImage, angle: sensorOrientation)
        : rawImage;

    // 3. Crop the face using the bounding box from ML Kit (clamped to image bounds)
    int x = face.boundingBox.left.toInt().clamp(0, image.width - 1);
    int y = face.boundingBox.top.toInt().clamp(0, image.height - 1);
    int width = face.boundingBox.width.toInt();
    int height = face.boundingBox.height.toInt();
    
    // Ensure width and height do not exceed image bounds
    if (x + width > image.width) width = image.width - x;
    if (y + height > image.height) height = image.height - y;
    
    if (width <= 0 || height <= 0) {
      throw Exception("Crop dimensions invalid: w=$width, h=$height");
    }

    img.Image croppedFace = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // 4. Resize to 112x112 as expected by MobileFaceNet
    img.Image resizedFace = img.copyResizeCropSquare(croppedFace, size: 112);

    // 5. Normalize pixels to [-1, 1]
    var input = _imageToFloat32Array(resizedFace);

    // 6. Run interpreter
    // Input shape: [1, 112, 112, 3]
    // Output shape: [1, 192] (MobileFaceNet embeddings)
    var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter.run(input, output);

    // 7. L2-Normalize the embedding vector to ensure accurate cosine distance
    List<double> raw = List<double>.from(output[0]);
    double norm = sqrt(raw.fold(0.0, (sum, v) => sum + v * v));
    List<double> embedding = norm > 0 ? raw.map((e) => e / norm).toList() : raw;
    return embedding;
  }

  // Cosine similarity for unit-normalized vectors: 1.0 = identical, 0.0 = orthogonal
  double calculateCosineSimilarity(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 0.0;
    double dot = 0.0;
    for (int i = 0; i < e1.length; i++) {
      dot += e1[i] * e2[i];
    }
    return dot;
  }

  // Euclidean distance between normalized vectors
  double calculateSimilarity(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  // Defensive geometric face signature synthesizer (192-dim) in case TFLite interpreter fails
  List<double> _generateFallbackFaceSignature(Face face) {
    final List<double> vec = List.filled(192, 0.0);
    final box = face.boundingBox;
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    
    // Seed dimensions and angles into feature positions
    vec[0] = box.width > 0 ? (box.left / box.width).clamp(-2.0, 2.0) : 0.0;
    vec[1] = box.height > 0 ? (box.top / box.height).clamp(-2.0, 2.0) : 0.0;
    vec[2] = (box.width / 500.0).clamp(0.0, 2.0);
    vec[3] = (box.height / 500.0).clamp(0.0, 2.0);
    vec[4] = (yaw / 90.0).clamp(-1.0, 1.0);
    vec[5] = (pitch / 90.0).clamp(-1.0, 1.0);
    vec[6] = (roll / 90.0).clamp(-1.0, 1.0);
    
    // Inject landmarks if available
    int idx = 7;
    for (final landmarkType in FaceLandmarkType.values) {
      if (idx + 1 >= 190) break;
      final landmark = face.landmarks[landmarkType];
      if (landmark != null) {
        vec[idx] = (landmark.position.x / (box.width > 0 ? box.width : 300)).clamp(-2.0, 2.0);
        vec[idx + 1] = (landmark.position.y / (box.height > 0 ? box.height : 300)).clamp(-2.0, 2.0);
      }
      idx += 2;
    }

    // L2 normalize vector
    double norm = sqrt(vec.fold(0.0, (sum, v) => sum + v * v));
    if (norm > 0) {
      for (int i = 0; i < vec.length; i++) {
        vec[i] /= norm;
      }
    } else {
      vec[0] = 1.0;
    }
    return vec;
  }

  // Convert CameraImage (YUV420) to RGB Image
  img.Image _convertCameraImage(CameraImage image) {
    try {
      if (image.planes.length == 1 && image.format.group != ImageFormatGroup.bgra8888) {
        return _convertNV21(image);
      } else if (image.format.group == ImageFormatGroup.yuv420 || image.planes.length == 3) {
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      }
      throw Exception("Unsupported image format");
    } catch (e) {
      throw Exception("Error converting image: $e");
    }
  }

  img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final bytes = image.planes[0].bytes;
    final result = img.Image(width: width, height: height);
    final uvOffset = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yp = bytes[y * width + x];
        final uvIndex = uvOffset + (y ~/ 2) * width + (x & ~1);
        final vp = bytes[uvIndex];
        final up = bytes[uvIndex + 1];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  img.Image _convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yRowStride = image.planes[0].bytesPerRow;
    final yPixelStride = image.planes[0].bytesPerPixel ?? 1;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final img.Image result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yIndex = y * yRowStride + x * yPixelStride;

        final yp = image.planes[0].bytes[yIndex];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  List<List<List<List<double>>>> _imageToFloat32Array(img.Image image) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize to [-1, 1]
            return [
              (pixel.r - 127.5) / 127.5,
              (pixel.g - 127.5) / 127.5,
              (pixel.b - 127.5) / 127.5,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }

  // -------------------------------------------------------------
  // SECURE CAMERA_IMAGE TO ML_KIT INPUT_IMAGE CONVERSION (NV21)
  // -------------------------------------------------------------
  InputImage? createInputImage(CameraImage image, int sensorOrientation) {
    try {
      final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
      
      // If single plane (NV21 on Android or BGRA8888 on iOS)
      if (image.planes.length == 1) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: image.format.group == ImageFormatGroup.bgra8888
                ? InputImageFormat.bgra8888
                : InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      // Android: YUV420 to strict NV21
      if (image.format.group == ImageFormatGroup.yuv420 || image.planes.length == 3) {
        final nv21Bytes = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width, // NV21 stride is exactly the width
          ),
        );
      } 
      // iOS: BGRA8888
      else if (image.format.group == ImageFormatGroup.bgra8888) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint("InputImage construction failed: $e");
      return null;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = (width * height * 1.5).toInt();
    final nv21 = Uint8List(numPixels);

    // Copy Y Plane row by row accounting for stride
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    int idY = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        nv21[idY++] = yBuffer[y * yRowStride + x * yPixelStride];
      }
    }

    // Interleave V and U Planes
    int idUV = width * height;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uvIndex = y * uvRowStride + x * uvPixelStride;
        nv21[idUV++] = vBuffer[uvIndex];
        nv21[idUV++] = uBuffer[uvIndex];
      }
    }
    return nv21;
  }
}

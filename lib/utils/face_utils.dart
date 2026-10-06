import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
/// Crops the face region from a `CameraImage` using the bounding box
/// and resizes it to [size] × [size] (default 112).
/// Returns a Uint8List of normalized float32 RGB data ready for the
/// MobileFaceNet model.
Uint8List cropAndResize(CameraImage cameraImage, Face face, {int size = 112}) {
  // Convert YUV420 to RGB image via helper (same as MLService._convertCameraImage).
  // For brevity we reuse the conversion logic here.
  img.Image rgb = _convertCameraImage(cameraImage);

  // Clamp bounding box to image bounds.
  int x = face.boundingBox.left.toInt().clamp(0, rgb.width - 1);
  int y = face.boundingBox.top.toInt().clamp(0, rgb.height - 1);
  int w = face.boundingBox.width.toInt();
  int h = face.boundingBox.height.toInt();
  if (x + w > rgb.width) w = rgb.width - x;
  if (y + h > rgb.height) h = rgb.height - y;

  img.Image cropped = img.copyCrop(rgb, x: x, y: y, width: w, height: h);
  img.Image resized = img.copyResizeCropSquare(cropped, size: size);

  // Normalize to [-1, 1] and flatten to Float32 Uint8List.
  final Float32List buffer = Float32List(size * size * 3);
  int i = 0;
  for (int py = 0; py < size; py++) {
  for (int px = 0; px < size; px++) {
    final pixel = resized.getPixel(px, py);
    buffer[i++] = (pixel.r - 127.5) / 127.5;
    buffer[i++] = (pixel.g - 127.5) / 127.5;
    buffer[i++] = (pixel.b - 127.5) / 127.5;
  }
}
  return buffer.buffer.asUint8List();
}

// Helper to convert YUV420 CameraImage to an RGB Image (same logic as MLService).
img.Image _convertCameraImage(CameraImage image) {
  if (image.format.group == ImageFormatGroup.yuv420) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
    final result = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  } else if (image.format.group == ImageFormatGroup.bgra8888) {
    return img.Image.fromBytes(width: image.width, height: image.height, bytes: image.planes[0].bytes.buffer, order: img.ChannelOrder.bgra);
  }
  throw Exception('Unsupported image format');
}

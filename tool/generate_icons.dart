import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final masterFile = File('test_flutter_fingerprint_512.png');
  if (!masterFile.existsSync()) {
    print('Master icon not found: ${masterFile.path}');
    exit(1);
  }

  final bytes = masterFile.readAsBytesSync();
  final masterImage = img.decodeImage(bytes);
  if (masterImage == null) {
    print('Failed to decode master image');
    exit(1);
  }

  print('Loaded master image: ${masterImage.width}x${masterImage.height}');

  void saveResized(String outPath, int width, int height) {
    final resized = img.copyResize(
      masterImage,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated: $outPath (${width}x$height)');
  }

  // 1. Android Mipmap Icons
  final androidMipmaps = {
    'android/app/src/main/res/mipmap-mdpi': 48,
    'android/app/src/main/res/mipmap-hdpi': 72,
    'android/app/src/main/res/mipmap-xhdpi': 96,
    'android/app/src/main/res/mipmap-xxhdpi': 144,
    'android/app/src/main/res/mipmap-xxxhdpi': 192,
  };

  for (final entry in androidMipmaps.entries) {
    saveResized('${entry.key}/ic_launcher.png', entry.value, entry.value);
    saveResized('${entry.key}/ic_launcher_round.png', entry.value, entry.value);
  }

  // 2. iOS AppIcon set
  final iosPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final iosIcons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in iosIcons.entries) {
    saveResized('$iosPath/${entry.key}', entry.value, entry.value);
  }

  // 3. Web Icons & Favicon
  saveResized('web/favicon.png', 48, 48);
  saveResized('web/icons/Icon-192.png', 192, 192);
  saveResized('web/icons/Icon-512.png', 512, 512);
  saveResized('web/icons/Icon-maskable-192.png', 192, 192);
  saveResized('web/icons/Icon-maskable-512.png', 512, 512);

  print('All Android, iOS, and Web launcher icons successfully generated!');
}

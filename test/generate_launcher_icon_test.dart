import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate official fingerprint launcher icon', (WidgetTester tester) async {
    final fontFile = File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
    if (fontFile.existsSync()) {
      final fontBytes = fontFile.readAsBytesSync();
      final fontLoader = FontLoader('MaterialIcons');
      fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      await fontLoader.load();
    }

    final repaintKey = GlobalKey();
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: repaintKey,
            child: Container(
              width: 512,
              height: 512,
              color: Colors.white,
              child: const Center(
                child: Icon(
                  Icons.fingerprint,
                  size: 380,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    File('test_flutter_fingerprint_512.png').writeAsBytesSync(byteData!.buffer.asUint8List());
  }, skip: true);
}

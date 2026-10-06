import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/views/face_overlay_painter.dart';

void main() {
  testWidgets('FaceHolePainter renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            painter: FaceHolePainter(
              borderColor: Colors.greenAccent,
              borderWidth: 4.0,
              progress: 0.5,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter is FaceHolePainter),
      findsOneWidget,
    );
  });
}

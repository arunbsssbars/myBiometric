import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/ui_test_helper.dart';

void main() {
  group('Kiosk Top Bar Responsive & Anti-Overflow Suite', () {
    Widget buildKioskTopBar({
      bool isBreakMode = false,
      String breakType = 'LUNCH',
      int pendingSyncCount = 0,
    }) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 400;

          return SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8.0 : 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // 1. Flexible scrollable action strip
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {},
                            tooltip: 'Exit Kiosk (Admin PIN)',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_camera_android, size: 20),
                            onPressed: () {},
                            tooltip: 'Switch Camera',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                            onPressed: () {},
                            tooltip: 'Selfie Mirror Active',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.dialpad, size: 20),
                            onPressed: () {},
                            tooltip: 'Employee ID Punch',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 20),
                            onPressed: () {},
                            tooltip: 'Audio & Device Settings',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: Icon(
                              isBreakMode ? Icons.coffee_rounded : Icons.coffee_outlined,
                              size: 20,
                            ),
                            onPressed: () {},
                            tooltip: 'Break Controls',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 2. Right Status Area: flex-safe chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pendingSyncCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amberAccent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "$pendingSyncCount",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.green, size: 14),
                            if (!isCompact) ...[
                              const SizedBox(width: 4),
                              const Text(
                                "KIOSK",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isBreakMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amberAccent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.coffee_rounded, size: 14),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: isCompact ? 50 : 80),
                                child: Text(
                                  isCompact ? "BREAK" : "${breakType.toUpperCase()} BREAK",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
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
    }

    testWidgets('renders across all form factors and font scales without RenderFlex overflow (Standard Kiosk Mode)',
        (WidgetTester tester) async {
      await UiQualityTester.testResponsiveLayout(
        tester,
        child: buildKioskTopBar(
          isBreakMode: false,
          pendingSyncCount: 3,
        ),
        devices: UiTestDevice.all,
        fontScales: [UiFontScale.standard, UiFontScale.large, UiFontScale.extraLarge],
      );
    });

    testWidgets('renders across all form factors and font scales without RenderFlex overflow (Break Mode Active)',
        (WidgetTester tester) async {
      await UiQualityTester.testResponsiveLayout(
        tester,
        child: buildKioskTopBar(
          isBreakMode: true,
          breakType: 'AFTERNOON TEA',
          pendingSyncCount: 5,
        ),
        devices: UiTestDevice.all,
        fontScales: [UiFontScale.standard, UiFontScale.large, UiFontScale.extraLarge],
      );
    });
  });
}

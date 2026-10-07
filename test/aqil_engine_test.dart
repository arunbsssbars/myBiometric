import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/core/design_system/design_system.dart';
import 'helpers/ui_test_helper.dart';

void main() {
  group('AQIL v3 Universal Engine Suite', () {
    testWidgets('auditAccessibility passes for compliant M3 interactive button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
                onPressed: () {},
                child: const Text('Compliant Button'),
              ),
            ),
          ),
        ),
      );

      await UiQualityTester.auditAccessibility(tester);
    });

    testWidgets('testStrictResponsiveLayout executes without overflow across small and large phones',
        (WidgetTester tester) async {
      await UiQualityTester.testStrictResponsiveLayout(
        tester,
        devices: [UiTestDevice.smallPhone, UiTestDevice.standardPhone],
        fontScales: [UiFontScale.standard],
        child: Container(
          color: Colors.blue,
          height: 100,
          child: const Center(child: Text('Strict Header', overflow: TextOverflow.ellipsis)),
        ),
      );
    });

    testWidgets('testThemeMatrix executes builder cleanly under both Light and Dark themes',
        (WidgetTester tester) async {
      await UiQualityTester.testThemeMatrix(
        tester,
        lightTheme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        builder: (context) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: context.colors.surface,
          child: Text(
            'Theme Matrix Content',
            style: context.text.titleSmall?.copyWith(color: context.colors.onSurface),
          ),
        ),
      );
    });

    testWidgets('detectTextCollision detects zero collisions when text items are spaced cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('First Non-Colliding Item'),
                SizedBox(height: 20),
                Text('Second Non-Colliding Item'),
              ],
            ),
          ),
        ),
      );

      final collisions = UiQualityTester.detectTextCollision(tester);
      expect(collisions, isEmpty);
    });

    testWidgets('auditAdaptiveWindowSize tests compact, medium, and expanded sizes without crash',
        (WidgetTester tester) async {
      await UiQualityTester.auditAdaptiveWindowSize(
        tester,
        theme: AppTheme.light(),
        builder: (context) {
          final window = context.windowSize;
          return Center(
            child: Text('Window: ${window.name}', overflow: TextOverflow.ellipsis),
          );
        },
      );
    });

    testWidgets('auditReducedMotion settles cleanly when animations are disabled',
        (WidgetTester tester) async {
      await UiQualityTester.auditReducedMotion(
        tester,
        theme: AppTheme.light(),
        builder: (context) => const AppCardSkeleton(),
      );
    });

    testWidgets('auditVisualSnapshot asserts target RenderBox geometry and bounds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                key: ValueKey('test_card'),
                width: 200,
                height: 100,
                child: Card(child: Text('Card Content')),
              ),
            ),
          ),
        ),
      );

      await UiQualityTester.auditVisualSnapshot(
        tester,
        targetFinder: find.byKey(const ValueKey('test_card')),
      );
    });

    testWidgets('auditDesignTokens produces clean report when single-line texts have ellipsis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              'Safeguarded Text',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditDesignTokens(tester);
      expect(report.isClean, isTrue);
      expect(report.totalScannedWidgets, greaterThan(0));
    });

    testWidgets('auditRtlBiDirectionality renders layout seamlessly in RTL text direction',
        (WidgetTester tester) async {
      await UiQualityTester.auditRtlBiDirectionality(
        tester,
        child: Row(
          children: [
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('النص التجريبي', overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.blue,
              child: const Text('شارة'),
            ),
          ],
        ),
      );
    });

    testWidgets('auditFocusTraversal advances keyboard focus through focusable nodes',
        (WidgetTester tester) async {
      final f1 = FocusNode(debugLabel: 'Input1');
      final f2 = FocusNode(debugLabel: 'Input2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: f1),
                TextField(focusNode: f2),
              ],
            ),
          ),
        ),
      );

      f1.requestFocus();
      await tester.pumpAndSettle();

      final report = await UiQualityTester.auditFocusTraversal(tester, maxSteps: 5);
      expect(report.visitedCount, greaterThan(0));
      expect(report.isTrapped, isFalse);

      f1.dispose();
      f2.dispose();
    });

    testWidgets('detectTouchTargetClustering identifies safe spacing vs clustered targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
              ],
            ),
          ),
        ),
      );

      final cleanReport = UiQualityTester.detectTouchTargetClustering(tester, minSeparationDp: 8.0);
      expect(cleanReport.isClean, isTrue);
      expect(cleanReport.scannedTargets, greaterThanOrEqualTo(2));
    });

    testWidgets('calculateContrastRatio and auditContrast accurately calculate WCAG compliance',
        (WidgetTester tester) async {
      final highContrast = UiQualityTester.auditContrast(
        foreground: Colors.black,
        background: Colors.white,
      );
      expect(highContrast.ratio, greaterThan(15.0));
      expect(highContrast.meetsAa, isTrue);
      expect(highContrast.meetsAaa, isTrue);

      final lowContrast = UiQualityTester.auditContrast(
        foreground: const Color(0xFFD0D0D0),
        background: Colors.white,
      );
      expect(lowContrast.ratio, lessThan(3.0));
      expect(lowContrast.meetsAa, isFalse);
      expect(lowContrast.meetsAaa, isFalse);
    });

    testWidgets('auditRebuildBudget asserts interaction remains within rebuild budget',
        (WidgetTester tester) async {
      int count = 0;
      final report = await UiQualityTester.auditRebuildBudget(
        tester,
        builder: (context, trigger) => Center(
          child: ElevatedButton(
            onPressed: () {
              count++;
              trigger();
            },
            child: Text('Count: $count'),
          ),
        ),
        interaction: (t) async {
          await t.tap(find.byType(ElevatedButton));
        },
        maxAllowedRebuilds: 3,
      );

      expect(report.isWithinBudget, isTrue);
      expect(report.interactionBuilds, lessThanOrEqualTo(3));
    });

    testWidgets('testNetworkStateMatrix verifies all 4 SaaS lifecycle degradation states',
        (WidgetTester tester) async {
      await UiQualityTester.testNetworkStateMatrix(
        tester,
        builder: (context, state) {
          switch (state) {
            case NetworkMatrixState.onlineLoaded:
              return const Text('Online Data');
            case NetworkMatrixState.offlineCached:
              return const Column(
                children: [
                  Text('Offline Cached Data'),
                  Text('Last synced: 2m ago'),
                ],
              );
            case NetworkMatrixState.degradedLatency:
              return const CircularProgressIndicator();
            case NetworkMatrixState.offlineError:
              return const Column(
                children: [
                  Text('Network Connection Error'),
                  Text('Tap to retry'),
                ],
              );
          }
        },
      );
    });

    testWidgets('auditSemanticsAnnouncements verifies live region tags and labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          showSemanticsDebugger: false,
          home: Scaffold(
            body: Semantics(
              liveRegion: true,
              label: 'Attendance Sync Complete',
              child: const Text('Sync Finished'),
            ),
          ),
        ),
      );

      final report = await UiQualityTester.auditSemanticsAnnouncements(tester);
      expect(report.totalLabeledNodes, greaterThan(0));
    });

    testWidgets('testHighContrastMode renders without layout exceptions under high-contrast theme',
        (WidgetTester tester) async {
      await UiQualityTester.testHighContrastMode(
        tester,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('High Contrast Action'),
          ),
        ),
      );
    });

    test('AqilQualityScorecard computes grade, compliance score, and markdown report', () {
      final scorecard = AqilQualityScorecard(
        targetName: 'KioskScreen',
        passedPillars: [
          'Design Tokens (0 debt)',
          'Strict Responsive Layout (5 viewports)',
          'Dual Theme Matrix (Light + Dark)',
          'Accessibility WCAG 2.2 AA (4.5:1 contrast, 48dp targets)',
          'Touch Proximity (> 8dp separation)',
          'Network State Degradation (4 states)',
        ],
        warnings: [
          'Reduced motion duration fallback recommended',
        ],
      );

      expect(scorecard.complianceScore, greaterThan(90.0));
      expect(scorecard.letterGrade, isIn(['A', 'A+']));

      final md = scorecard.toMarkdownReport();
      expect(md, contains('AQIL v3.5 Enterprise UI Quality Scorecard: KioskScreen'));
      expect(md, contains('[x] Design Tokens'));

      final json = scorecard.toJson();
      expect(json['targetName'], equals('KioskScreen'));
      expect(json['complianceScore'], equals(scorecard.complianceScore));
    });

    testWidgets('auditFormValidationStates verifies all 5 lifecycle validation states',
        (WidgetTester tester) async {
      await UiQualityTester.auditFormValidationStates(
        tester,
        builder: (context, state) {
          switch (state) {
            case FormValidationState.pristineEmpty:
              return const TextField(decoration: InputDecoration(hintText: 'Enter name'));
            case FormValidationState.activeFocused:
              return const TextField(autofocus: true);
            case FormValidationState.validationError:
              return const TextField(
                decoration: InputDecoration(
                  errorText: 'Name is required and cannot be empty.',
                ),
              );
            case FormValidationState.disabledState:
              return const TextField(enabled: false);
            case FormValidationState.validSuccessState:
              return const TextField(
                decoration: InputDecoration(
                  helperText: 'Verified valid user',
                  suffixIcon: Icon(Icons.check_circle, color: Colors.green),
                ),
              );
          }
        },
      );
    });

    testWidgets('auditSafeAreaInsets handles extreme notch and gesture bar insets',
        (WidgetTester tester) async {
      await UiQualityTester.auditSafeAreaInsets(
        tester,
        insets: const EdgeInsets.only(top: 59, bottom: 34),
        builder: (context) => SafeArea(
          child: Column(
            children: [
              Container(height: 50, color: Colors.blue, child: const Text('Top Header')),
              const Spacer(),
              ElevatedButton(onPressed: () {}, child: const Text('Bottom Action')),
            ],
          ),
        ),
      );
    });

    testWidgets('auditTextTruncation identifies single-line text ellipsis safeguards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              'Ellipsis protected string',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditTextTruncation(tester);
      expect(report.isClean, isTrue);
      expect(report.totalTextsScanned, greaterThan(0));
    });

    testWidgets('auditTapTargetHitSlop scans interactive element sizes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                iconSize: 24,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {},
                icon: const Icon(Icons.settings),
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditTapTargetHitSlop(tester, minTouchSize: 44.0);
      expect(report.scannedTargets, greaterThan(0));
    });

    testWidgets('testLocaleExpansionMatrix tests 1.0x, 1.35x, and 1.6x pseudo-localization growth',
        (WidgetTester tester) async {
      await UiQualityTester.testLocaleExpansionMatrix(
        tester,
        builder: (context, factor) => Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Localized Action' * (factor > 1.3 ? 2 : 1),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });

    testWidgets('auditDarkSurfaceTonalElevation inspects Material 3 dark surface hierarchy',
        (WidgetTester tester) async {
      final darkTheme = AppTheme.dark();
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text('Tonal Card Content'),
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditDarkSurfaceTonalElevation(
        tester,
        darkTheme: darkTheme,
      );
      expect(report.hasM3TonalHierarchy, isTrue);
    });

    testWidgets('testKeyboardOverlapResilience verifies UI adapts under 336dp soft keyboard inset',
        (WidgetTester tester) async {
      await UiQualityTester.testKeyboardOverlapResilience(
        tester,
        builder: (context) => ListView(
          children: [
            const TextField(),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('Submit Form')),
          ],
        ),
      );
    });

    testWidgets('auditHapticFeedbackInteractions dispatches interaction cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Haptic Button'),
              ),
            ),
          ),
        ),
      );

      final report = await UiQualityTester.auditHapticFeedbackInteractions(
        tester,
        actionFinder: find.byType(FilledButton),
      );
      expect(report.isClean, isTrue);
    });

    testWidgets('runFullAqilSuite orchestrates comprehensive quality checks and produces scorecard',
        (WidgetTester tester) async {
      final scorecard = await UiQualityTester.runFullAqilSuite(
        tester,
        componentName: 'StandardButton',
        lightTheme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        builder: (context) => Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
            ),
            onPressed: () {},
            child: const Text('Compliant Button', overflow: TextOverflow.ellipsis),
          ),
        ),
      );

      expect(scorecard.complianceScore, greaterThanOrEqualTo(80.0));
      expect(scorecard.passedPillars, isNotEmpty);
      expect(scorecard.targetName, equals('StandardButton'));
    });

    testWidgets('auditHeadingHierarchy discovers semantic headings in the widget tree',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Semantics(
                  header: true,
                  child: const Text('Main Dashboard Header'),
                ),
                const Text('Regular body paragraph text'),
              ],
            ),
          ),
        ),
      );

      final report = await UiQualityTester.auditHeadingHierarchy(tester);
      expect(report.hasHeadings, isTrue);
      expect(report.totalHeadings, greaterThan(0));
      expect(report.headingLabels, contains('Main Dashboard Header'));
    });

    test('simulateCvdColor transforms colors across protanopia, deuteranopia, tritanopia, and achromatopsia', () {
      const redColor = Color(0xFFFF0000);
      final simProtanopia = UiQualityTester.simulateCvdColor(redColor, CvdMode.protanopia);
      final simAchromatopsia = UiQualityTester.simulateCvdColor(redColor, CvdMode.achromatopsia);

      expect(simProtanopia, isNot(equals(redColor)));
      expect((simAchromatopsia.r - simAchromatopsia.g).abs(), lessThan(0.01));
      expect((simAchromatopsia.g - simAchromatopsia.b).abs(), lessThan(0.01));

      final cvdReport = UiQualityTester.auditCvdContrast(
        foreground: Colors.black,
        background: Colors.white,
      );
      expect(cvdReport.allModesCompliant, isTrue);
      expect(cvdReport.simulatedRatios.length, equals(4));
    });

    testWidgets('auditFormErrorSemantics detects error text on form input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                errorText: 'Invalid employee ID number',
              ),
            ),
          ),
        ),
      );

      final report = await UiQualityTester.auditFormErrorSemantics(
        tester,
        fieldFinder: find.byType(TextField),
      );
      expect(report.hasSemanticError, isTrue);
    });

    testWidgets('auditExtremeFontScaling scales cleanly at 2.0x, 2.5x, and 3.0x',
        (WidgetTester tester) async {
      await UiQualityTester.auditExtremeFontScaling(
        tester,
        scales: [2.0, 2.5, 3.0],
        builder: (context, scale) => Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Large Print Accessibility Text (${scale}x)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });

    testWidgets('auditAccessibleNames scans and validates interactive element accessible labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Save Changes'),
              ),
            ),
          ),
        ),
      );

      final report = await UiQualityTester.auditAccessibleNames(tester);
      expect(report.totalInteractiveScanned, greaterThan(0));
      expect(report.unlabeledElements, isEmpty);
    });

    test('auditFlashingContentRisk identifies seizure-safe vs hazardous animation frequencies', () {
      final safeAnimation = UiQualityTester.auditFlashingContentRisk(
        cycleDuration: const Duration(milliseconds: 500), // 2.0 Hz
        luminanceDelta: 0.2,
      );
      expect(safeAnimation.isSeizureSafe, isTrue);

      final hazardousAnimation = UiQualityTester.auditFlashingContentRisk(
        cycleDuration: const Duration(milliseconds: 200), // 5.0 Hz
        luminanceDelta: 0.3,
      );
      expect(hazardousAnimation.isSeizureSafe, isFalse);
    });

    testWidgets('auditAnimationFrameBudget measures frame duration during animated transitions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      final report = await UiQualityTester.auditAnimationFrameBudget(
        tester,
        triggerAction: (t) async {},
        expectedFrameCount: 5,
      );
      expect(report.isPerformant, isTrue);
      expect(report.framesPumped, equals(5));
    });

    testWidgets('auditGestureConflicts checks component edge margin for OS navigation swipe conflicts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: SizedBox(
                key: ValueKey('safe_card'),
                width: 200,
                height: 100,
                child: Card(child: Text('Safe Carousel Card')),
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditGestureConflicts(
        tester,
        swipeableFinder: find.byKey(const ValueKey('safe_card')),
        systemEdgeMarginDp: 24.0,
      );
      expect(report.hasEdgeGestureConflict, isFalse);
    });

    test('auditFocusIndicatorVisibility evaluates WCAG 2.2 focus ring appearance', () {
      final compliantRing = UiQualityTester.auditFocusIndicatorVisibility(
        focusRingColor: Colors.black,
        surfaceColor: Colors.white,
        strokeWidthDp: 2.0,
      );
      expect(compliantRing.meetsAaAppearance, isTrue);

      final undersizedRing = UiQualityTester.auditFocusIndicatorVisibility(
        focusRingColor: Colors.black,
        surfaceColor: Colors.white,
        strokeWidthDp: 1.0,
      );
      expect(undersizedRing.meetsAaAppearance, isFalse);
    });

    testWidgets('auditVirtualizedListIntegrity verifies sliver viewport virtualization',
        (WidgetTester tester) async {
      final report = await UiQualityTester.auditVirtualizedListIntegrity(
        tester,
        totalItemCount: 1000,
        itemBuilder: (context, index) => SizedBox(
          height: 60,
          child: Text('Item #$index'),
        ),
      );
      expect(report.isProperlyVirtualized, isTrue);
      expect(report.activeRenderedItems, lessThan(100));
    });

    testWidgets('auditFoldableHingeInsets tests layout under foldable dual-screen geometry',
        (WidgetTester tester) async {
      final report = await UiQualityTester.auditFoldableHingeInsets(
        tester,
        builder: (context, hinge) => Row(
          children: [
            Expanded(child: Container(color: Colors.blue, child: const Text('Left Screen'))),
            SizedBox(width: hinge.width),
            Expanded(child: Container(color: Colors.green, child: const Text('Right Screen'))),
          ],
        ),
      );
      expect(report.isClean, isTrue);
    });

    testWidgets('testMultiWindowMatrix tests responsiveness across 320px, 500px, and 700px split ratios',
        (WidgetTester tester) async {
      await UiQualityTester.testMultiWindowMatrix(
        tester,
        splitWidths: [320.0, 500.0, 700.0],
        builder: (context, splitWidth) => Center(
          child: Text('Width: ${splitWidth.toInt()}px', overflow: TextOverflow.ellipsis),
        ),
      );
    });

    testWidgets('auditModalDismissibility asserts barrier tap dismissal of modal dialog',
        (WidgetTester tester) async {
      final report = await UiQualityTester.auditModalDismissibility(
        tester,
        showModalAction: (context) => showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => const AlertDialog(title: Text('Test Dialog')),
        ),
      );
      expect(report.isClean, isTrue);
    });

    testWidgets('auditPinnedHeaderBehavior asserts scroll stability with pinned sliver header',
        (WidgetTester tester) async {
      final report = await UiQualityTester.auditPinnedHeaderBehavior(
        tester,
        sliverHeaderBuilder: (context) => const SliverAppBar(
          pinned: true,
          title: Text('Pinned Header'),
        ),
      );
      expect(report.isStable, isTrue);
    });

    testWidgets('auditFabSafeAreaClearance detects whether FAB avoids bottom navigation bar collision',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(onPressed: () {}),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditFabSafeAreaClearance(tester);
      expect(report.hasFab, isTrue);
    });

    testWidgets('testPaginationStateMatrix verifies initial shimmer, loaded, next page, and error states',
        (WidgetTester tester) async {
      await UiQualityTester.testPaginationStateMatrix(
        tester,
        builder: (context, state) {
          switch (state) {
            case PaginationState.initialShimmer:
              return const Text('Loading Skeleton Shimmer');
            case PaginationState.firstPageLoaded:
              return const Text('Page 1 Loaded');
            case PaginationState.loadingNextPage:
              return const Text('Loading Page 2...');
            case PaginationState.paginationError:
              return const Text('Pagination Error - Tap to Retry');
          }
        },
      );
    });

    testWidgets('auditEmptyStateActionability asserts zero-data state has message and actionable CTA',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No records found'),
                  ElevatedButton(onPressed: () {}, child: const Text('Add Record')),
                ],
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditEmptyStateActionability(tester);
      expect(report.isCompliant, isTrue);
    });

    testWidgets('testOptimisticUpdateRollback tests rollback resilience upon server rejection',
        (WidgetTester tester) async {
      await UiQualityTester.testOptimisticUpdateRollback(
        tester,
        builder: (context, isChecked) => Center(
          child: Switch(value: isChecked, onChanged: (_) {}),
        ),
        userAction: (t) async {
          await t.tap(find.byType(Switch));
        },
      );
    });

    testWidgets('auditOfflineSyncIndicator detects presence of offline sync badge or chip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Chip(
                avatar: Icon(Icons.cloud_off, size: 16),
                label: Text('3 Pending Sync'),
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditOfflineSyncIndicator(tester);
      expect(report.hasSyncIndicators, isTrue);
      expect(report.totalIndicators, greaterThan(0));
    });

    testWidgets('auditPullToRefreshIntegrity verifies RefreshIndicator execution',
        (WidgetTester tester) async {
      final report = await UiQualityTester.auditPullToRefreshIntegrity(
        tester,
        builder: (context, refresh) => RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            children: const [
              SizedBox(height: 300, child: Text('Row 1')),
              SizedBox(height: 300, child: Text('Row 2')),
            ],
          ),
        ),
      );
      expect(report.hasRefreshIndicator, isTrue);
    });

    test('auditWcagAaaStrict evaluates 7:1 contrast and 44dp touch target standards', () {
      final report = UiQualityTester.auditWcagAaaStrict(
        foreground: Colors.black,
        background: Colors.white,
        touchTargetSizeDp: 48.0,
      );
      expect(report.isFullyCompliant, isTrue);
      expect(report.meetsAaaContrast, isTrue);
      expect(report.meetsAaaTouchTarget, isTrue);
    });

    testWidgets('auditGeometryDrift asserts RenderBox dimensions against design token tolerances',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: ValueKey('token_box'),
                width: 120,
                height: 48,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      final report = UiQualityTester.auditGeometryDrift(
        tester,
        targetFinder: find.byKey(const ValueKey('token_box')),
        expectedSize: const Size(120, 48),
        tolerancePx: 0.5,
      );
      expect(report.isStable, isTrue);
      expect(report.widthVariance, lessThanOrEqualTo(0.5));
    });

    test('exportSarifQualityReport formats scorecard into valid OASIS SARIF v2.1.0 JSON', () {
      final scorecard = AqilQualityScorecard(
        targetName: 'lib/views/kiosk_screen.dart',
        passedPillars: ['Responsive Layout', 'Theme Matrix'],
        violations: ['Strict Responsive Layout: RenderFlex overflowed by 12px'],
      );

      final sarif = UiQualityTester.exportSarifQualityReport(scorecard);
      expect(sarif['version'], equals('2.1.0'));
      expect(sarif[r'$schema'], contains('sarif-2.1.0.json'));
      expect((sarif['runs'] as List).isNotEmpty, isTrue);
    });

    testWidgets('runEnterpriseQualityBenchmark executes multi-component catalog benchmark',
        (WidgetTester tester) async {
      final results = await UiQualityTester.runEnterpriseQualityBenchmark(
        tester,
        components: {
          'ButtonA': (context) => FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
                onPressed: () {},
                child: const Text('Button A', overflow: TextOverflow.ellipsis),
              ),
          'ButtonB': (context) => OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
                onPressed: () {},
                child: const Text('Button B', overflow: TextOverflow.ellipsis),
              ),
        },
      );

      expect(results.length, equals(2));
      expect(results.containsKey('ButtonA'), isTrue);
      expect(results.containsKey('ButtonB'), isTrue);
      expect(results['ButtonA']!.complianceScore, greaterThan(0));
    });

    group('Frontier 1: AqilSelfHealer Autonomous AST Remediator', () {
      test('healTextEllipsis generates patch adding maxLines and ellipsis', () {
        const source = '''
Widget build(BuildContext context) {
  return Text("Unsafe Title");
}
''';
        final patch = AqilSelfHealer.healTextEllipsis(
          source,
          textSnippet: 'Text("Unsafe Title")',
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.textEllipsisSafeguard));
        expect(
          patch.replacementSnippet,
          equals('Text("Unsafe Title", maxLines: 1, overflow: TextOverflow.ellipsis)'),
        );
      });

      test('healTextEllipsis skips Text widget that already has overflow safeguard', () {
        const source = 'Text("Safe", overflow: TextOverflow.ellipsis)';
        final patch = AqilSelfHealer.healTextEllipsis(
          source,
          textSnippet: 'Text("Safe", overflow: TextOverflow.ellipsis)',
        );
        expect(patch, isNull);
      });

      test('healRowFlexOverflow generates patch wrapping child in Expanded or Flexible', () {
        const source = 'Row(children: [Text("Long Title"), Icon(Icons.star)])';
        final patchExpanded = AqilSelfHealer.healRowFlexOverflow(
          source,
          childSnippet: 'Text("Long Title")',
        );

        expect(patchExpanded, isNotNull);
        expect(patchExpanded!.rule, equals(RemediationRule.rowFlexOverflowWrap));
        expect(patchExpanded.replacementSnippet, equals('Expanded(child: Text("Long Title"))'));

        final patchFlexible = AqilSelfHealer.healRowFlexOverflow(
          source,
          childSnippet: 'Text("Long Title")',
          useFlexible: true,
        );
        expect(patchFlexible!.replacementSnippet, equals('Flexible(child: Text("Long Title"))'));
      });

      test('healColumnOverflow wraps overflowing Column in SingleChildScrollView', () {
        const source = 'Column(children: [WidgetA(), WidgetB()])';
        final patch = AqilSelfHealer.healColumnOverflow(
          source,
          columnSnippet: 'Column(children: [WidgetA(), WidgetB()])',
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.columnScrollableWrap));
        expect(
          patch.replacementSnippet,
          equals('SingleChildScrollView(child: Column(children: [WidgetA(), WidgetB()]))'),
        );
      });

      test('healTouchTargetSize generates minimum touch target patch', () {
        const source = 'IconButton(icon: Icon(Icons.add), onPressed: () {})';
        final patch = AqilSelfHealer.healTouchTargetSize(
          source,
          buttonSnippet: 'IconButton(icon: Icon(Icons.add), onPressed: () {})',
          minSize: 48.0,
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.minTouchTargetPadding));
        expect(patch.replacementSnippet, contains('constraints: const BoxConstraints(minWidth: 48, minHeight: 48)'));
      });

      test('healUnlabeledIconButton adds accessible tooltip label', () {
        const source = 'IconButton(icon: Icon(Icons.close), onPressed: () {})';
        final patch = AqilSelfHealer.healUnlabeledIconButton(
          source,
          iconButtonSnippet: 'IconButton(icon: Icon(Icons.close), onPressed: () {})',
          semanticTooltip: 'Close Dialog',
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.accessibleTooltip));
        expect(patch.replacementSnippet, contains("tooltip: 'Close Dialog'"));
      });

      test('healMetadataRow transforms separated metadata into joined single text', () {
        const source = 'Row(children: [Text(name), Text(date)])';
        final patch = AqilSelfHealer.healMetadataRow(
          source,
          rowSnippet: 'Row(children: [Text(name), Text(date)])',
          metadataVariables: ['name', 'date', 'status'],
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.metadataJoin));
        expect(
          patch.replacementSnippet,
          equals("Text([name, date, status].join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis)"),
        );
      });

      test('healHardcodedColor replaces raw hex literals with design token', () {
        const source = 'Container(color: Color(0xFF1E88E5))';
        final patch = AqilSelfHealer.healHardcodedColor(
          source,
          hardcodedLiteral: 'Color(0xFF1E88E5)',
          tokenReplacement: 'context.colors.primary',
        );

        expect(patch, isNotNull);
        expect(patch!.rule, equals(RemediationRule.colorTokenization));
        expect(patch.replacementSnippet, equals('context.colors.primary'));
      });

      test('scanAndHeal applies complete multi-rule remediation atomically', () {
        const inputSource = '''
Widget build(BuildContext context) {
  return Column(
    children: [
      Text("Unsafe Subtitle"),
      IconButton(icon: Icon(Icons.delete), onPressed: () {}),
      Container(color: Color(0xFF00FF00)),
    ],
  );
}
''';
        final result = AqilSelfHealer.scanAndHeal(
          inputSource,
          unSafeguardedTexts: ['Text("Unsafe Subtitle")'],
          undersizedButtons: ['IconButton(icon: Icon(Icons.delete), onPressed: () {})'],
          unlabeledIconButtons: {
            'IconButton(icon: Icon(Icons.delete), onPressed: () {})': 'Delete item'
          },
          hardcodedColors: {'Color(0xFF00FF00)': 'context.colors.success'},
        );

        expect(result.success, isTrue);
        expect(result.hasModifications, isTrue);
        expect(result.patchCount, greaterThanOrEqualTo(3));
        expect(result.healedSource, contains('overflow: TextOverflow.ellipsis'));
        expect(result.healedSource, contains('context.colors.success'));
        expect(result.healedSource, contains("tooltip: 'Delete item'"));
      });
    });

    group('Frontier 2: AqilPerceptualVisualEngine Pixel-Level Perceptual Regression', () {
      test('colorDistance calculates normalized Euclidean distance accurately', () {
        const white = 0xFFFFFFFF;
        const black = 0xFF000000;
        const red = 0xFFFF0000;

        expect(AqilPerceptualVisualEngine.colorDistance(white, white), equals(0.0));
        expect(AqilPerceptualVisualEngine.colorDistance(white, black), closeTo(1.0, 0.001));
        expect(AqilPerceptualVisualEngine.colorDistance(black, red), greaterThan(0.0));
        expect(AqilPerceptualVisualEngine.colorDistance(black, red), lessThan(1.0));
      });

      test('PixelFrame initialization and pixel manipulation functions correctly', () {
        final frame = PixelFrame.filled(width: 20, height: 20, color: 0xFF000000);
        expect(frame.getPixel(0, 0), equals(0xFF000000));
        expect(frame.getPixel(19, 19), equals(0xFF000000));

        frame.setPixel(5, 5, 0xFFFF0000);
        expect(frame.getPixel(5, 5), equals(0xFFFF0000));

        frame.fillRect(const Rect.fromLTWH(10, 10, 5, 5), 0xFF0000FF);
        expect(frame.getPixel(10, 10), equals(0xFF0000FF));
        expect(frame.getPixel(14, 14), equals(0xFF0000FF));
        expect(frame.getPixel(15, 15), equals(0xFF000000));
      });

      test('compareFrames evaluates identical frames as 100% visual match', () {
        final baseline = PixelFrame.filled(width: 50, height: 50, color: 0xFF123456);
        final current = PixelFrame.filled(width: 50, height: 50, color: 0xFF123456);

        final result = AqilPerceptualVisualEngine.compareFrames(baseline, current);
        expect(result.isMatch, isTrue);
        expect(result.diffRatio, equals(0.0));
        expect(result.differingPixels, equals(0));
        expect(result.discrepancyBoundingBoxes, isEmpty);
      });

      test('compareFrames with dynamic masking excludes volatile changes from diff ratio', () {
        final baseline = PixelFrame.filled(width: 100, height: 100, color: 0xFFFFFFFF);
        final current = PixelFrame.filled(width: 100, height: 100, color: 0xFFFFFFFF);

        // Simulate volatile timestamp region changed in current frame (10x10 = 100 differing pixels)
        current.fillRect(const Rect.fromLTWH(10, 10, 10, 10), 0xFF000000);

        // Without mask, this represents 100 / 10000 = 1.0% diff
        final unmaskedResult = AqilPerceptualVisualEngine.compareFrames(
          baseline,
          current,
          toleranceThreshold: 0.005, // 0.5% threshold
        );
        expect(unmaskedResult.isMatch, isFalse);
        expect(unmaskedResult.differingPixels, equals(100));

        // With dynamic mask covering the volatile timestamp region
        final maskedResult = AqilPerceptualVisualEngine.compareFrames(
          baseline,
          current,
          masks: [
            const VisualMaskRegion(
              rect: Rect.fromLTWH(10, 10, 10, 10),
              label: 'Volatile Timestamp',
            ),
          ],
          toleranceThreshold: 0.005,
        );

        expect(maskedResult.isMatch, isTrue);
        expect(maskedResult.differingPixels, equals(0));
        expect(maskedResult.maskedPixels, equals(100));
        expect(maskedResult.diffRatio, equals(0.0));
      });

      test('renderAsciiDiffHeatmap formats readable visual regression matrix', () {
        final baseline = PixelFrame.filled(width: 40, height: 20, color: 0xFFFFFFFF);
        final current = PixelFrame.filled(width: 40, height: 20, color: 0xFFFFFFFF);
        current.fillRect(const Rect.fromLTWH(5, 5, 10, 5), 0xFFFF0000);

        final result = AqilPerceptualVisualEngine.compareFrames(
          baseline,
          current,
          masks: [const VisualMaskRegion(rect: Rect.fromLTWH(0, 0, 5, 5), label: 'Avatar')],
        );

        final heatmap = result.renderAsciiDiffHeatmap(cols: 10, rows: 5);
        expect(heatmap, contains('=== AQIL Perceptual Visual Diff Heatmap'));
        expect(heatmap, contains('M ')); // Masked region symbol
        expect(heatmap, contains('* ')); // Discrepancy symbol
        expect(heatmap, contains('. ')); // Match symbol
      });

      testWidgets('auditPerceptualVisualRegression integrates with widget tree and extracts masks',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Static Header Title'),
                  Container(
                    key: const ValueKey('volatile_clock'),
                    width: 80,
                    height: 30,
                    color: Colors.grey,
                    child: const Text('10:45:22 AM'),
                  ),
                ],
              ),
            ),
          ),
        );

        final baseline = PixelFrame.filled(width: 200, height: 200, color: 0xFFFFFFFF);
        final current = PixelFrame.filled(width: 200, height: 200, color: 0xFFFFFFFF);

        final diff = UiQualityTester.auditPerceptualVisualRegression(
          tester,
          baselineFrame: baseline,
          currentFrame: current,
          dynamicMaskFinders: [find.byKey(const ValueKey('volatile_clock'))],
          volatileTextPatterns: ['AM'],
        );

        expect(diff.appliedMasks.isNotEmpty, isTrue);
        expect(diff.isMatch, isTrue);
      });
    });

    group('Frontier 3: AqilComponentCatalog & Storybook Auto-Generator', () {
      late AqilComponentCatalog catalog;

      setUp(() {
        catalog = UiQualityTester.createComponentCatalog();
        catalog.register(
          CatalogComponent(
            id: 'primary_button',
            name: 'Primary Button',
            category: 'Actions',
            description: 'Main CTA button with filled styling',
            variants: const [
              ComponentVariant(id: 'standard', name: 'Standard'),
              ComponentVariant(id: 'disabled', name: 'Disabled'),
            ],
            builder: (context, variant) => FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              ),
              onPressed: variant.id == 'disabled' ? null : () {},
              child: Text('Button: ${variant.name}', overflow: TextOverflow.ellipsis),
            ),
          ),
        );
        catalog.register(
          CatalogComponent(
            id: 'status_chip',
            name: 'Status Chip',
            category: 'Indicators',
            description: 'Colored chip displaying entity status',
            variants: const [
              ComponentVariant(id: 'active', name: 'Active'),
              ComponentVariant(id: 'offline', name: 'Offline'),
            ],
            builder: (context, variant) => Chip(
              label: Text(variant.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        );
      });

      test('catalog accurately indexes components, categories, and variants', () {
        expect(catalog.componentCount, equals(2));
        expect(catalog.totalVariantCount, equals(4));

        final grouped = catalog.groupByCategory();
        expect(grouped.containsKey('Actions'), isTrue);
        expect(grouped.containsKey('Indicators'), isTrue);
        expect(grouped['Actions']!.first.id, equals('primary_button'));
      });

      test('exportMarkdownDocumentation formats valid markdown report table', () {
        final docs = catalog.exportMarkdownDocumentation();
        expect(docs, contains('# Design System Component Catalog & Storybook'));
        expect(docs, contains('## Category: ACTIONS'));
        expect(docs, contains('`Standard`, `Disabled`'));
        expect(docs, contains('## Category: INDICATORS'));
      });

      testWidgets('buildStorybookViewer renders gallery and handles theme/font interactions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          catalog.buildStorybookViewer(),
        );
        await tester.pumpAndSettle();

        expect(find.text('AQIL Component Storybook'), findsOneWidget);
        expect(find.byKey(const ValueKey('storybook_search_field')), findsOneWidget);
        expect(find.byKey(const ValueKey('catalog_item_primary_button')), findsOneWidget);

        // Toggle theme brightness
        await tester.tap(find.byKey(const ValueKey('storybook_theme_toggle')));
        await tester.pumpAndSettle();

        // Scale font
        await tester.tap(find.byKey(const ValueKey('storybook_font_scale_toggle')));
        await tester.pumpAndSettle();

        // Search filter
        await tester.enterText(
          find.byKey(const ValueKey('storybook_search_field')),
          'Status',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('catalog_item_status_chip')), findsOneWidget);
      });

      testWidgets('auditCatalogMatrix executes automated theme and font compliance across variants',
          (WidgetTester tester) async {
        final auditResults = await catalog.auditCatalogMatrix(
          tester,
          lightTheme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
        );

        expect(auditResults.length, equals(2));
        expect(auditResults['primary_button']!.isCompliant, isTrue);
        expect(auditResults['status_chip']!.isCompliant, isTrue);
        expect(auditResults['primary_button']!.variantsAudited, equals(2));
      });
    });

    group('Frontier 4: AqilCiCdBot Headless CI/CD PR Bot & Annotations', () {
      test('evaluateCiExitCode passes for compliant scorecards and fails on overflow', () {
        final passingCard = AqilQualityScorecard(
          targetName: 'lib/views/compliant_screen.dart',
          passedPillars: ['Responsive Layout', 'Theme Matrix', 'Accessibility AA'],
        );
        expect(UiQualityTester.evaluateCiExitCode(scorecard: passingCard), isTrue);

        final failingCard = AqilQualityScorecard(
          targetName: 'lib/views/broken_screen.dart',
          passedPillars: ['Responsive Layout'],
          violations: ['RenderFlex overflowed by 24 pixels'],
        );
        expect(UiQualityTester.evaluateCiExitCode(scorecard: failingCard), isFalse);
      });

      test('formatPullRequestComment formats comprehensive GitHub PR review summary', () {
        final card = AqilQualityScorecard(
          targetName: 'lib/views/kiosk_screen.dart',
          passedPillars: ['Theme Matrix', 'WCAG 2.2 AA Contrast'],
          violations: ['Tap target 36x36dp smaller than min standard 48x48dp'],
        );

        const patch = RemediationPatch(
          rule: RemediationRule.minTouchTargetPadding,
          description: 'Enforce minimum accessible touch target size (≥ 48dp)',
          originalSnippet: 'IconButton(icon: Icon(Icons.close), onPressed: () {})',
          replacementSnippet: 'IconButton(icon: Icon(Icons.close), onPressed: () {}, constraints: const BoxConstraints(minWidth: 48, minHeight: 48))',
        );

        final comment = UiQualityTester.generateCiPullRequestComment(
          scorecard: card,
          commitSha: 'a1b2c3d4e5f6',
          branchName: 'feature/kiosk-upgrade',
          recommendedPatches: [patch],
        );

        expect(comment, contains('## 🤖 AQIL Autonomous UI Quality Bot'));
        expect(comment, contains('feature/kiosk-upgrade'));
        expect(comment, contains('a1b2c3d'));
        expect(comment, contains('Suggested Autonomous AST Fixes (1)'));
        expect(comment, contains('```diff'));
        expect(comment, contains('+ IconButton'));
      });

      test('generateAnnotations produces GitHub workflow commands and check run JSON', () {
        final card = AqilQualityScorecard(
          targetName: 'lib/views/kiosk_screen.dart',
          violations: [
            'RenderFlex overflowed by 18 pixels on the right',
            'Contrast ratio 3.2:1 fails minimum 4.5:1 requirement',
          ],
        );

        final annotations = AqilCiCdBot.generateAnnotations(
          scorecard: card,
          filePath: 'lib/views/kiosk_screen.dart',
        );

        expect(annotations.length, equals(2));
        expect(annotations.first.level, equals(CiAnnotationLevel.failure));
        expect(annotations.first.toGithubWorkflowCommand(), contains('::error file=lib/views/kiosk_screen.dart'));

        final jsonCheck = annotations.first.toGithubCheckRunJson();
        expect(jsonCheck['annotation_level'], equals('failure'));
        expect(jsonCheck['path'], equals('lib/views/kiosk_screen.dart'));
      });

      test('exportGitlabCodeQualityReport produces valid JSON schema for GitLab MRs', () {
        final card = AqilQualityScorecard(
          targetName: 'lib/views/profile_screen.dart',
          violations: ['Single-line text unconstrained and un-safeguarded'],
        );
        final annotations = AqilCiCdBot.generateAnnotations(
          scorecard: card,
          filePath: 'lib/views/profile_screen.dart',
        );

        final report = AqilCiCdBot.exportGitlabCodeQualityReport(annotations);
        expect(report, contains('aqil_ui_quality'));
        expect(report, contains('lib/views/profile_screen.dart'));
      });
    });

    group('Frontier 5: AqilChaosMonkey Interactive Chaos & State-Machine Fuzzing', () {
      test('ChaosMonkeyReport properties and reproduction script format accurately', () {
        const report = ChaosMonkeyReport(
          seed: 999,
          totalActionsAttempted: 10,
          successfulActions: 10,
          hasCrashes: false,
          capturedExceptions: [],
          eventLog: [
            MonkeyEvent(
              step: 1,
              type: MonkeyActionType.tap,
              targetDescription: 'Submit Button',
              details: 'Single tap executed',
              timestamp: Duration(milliseconds: 15),
            ),
          ],
          duration: Duration(milliseconds: 150),
        );

        expect(report.isResilient, isTrue);
        final script = report.generateReproductionScript();
        expect(script, contains('Seed: 999'));
        expect(script, contains('RESILIENT (PASS)'));
        expect(script, contains('Step 1 [tap] on "Submit Button"'));
      });

      testWidgets('runChaosMonkeyFuzzing stress-tests complex interactive screen without crashes',
          (WidgetTester tester) async {
        int tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  const Text('Form Title', overflow: TextOverflow.ellipsis),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  FilledButton(
                    onPressed: () {
                      tapCount++;
                    },
                    child: const Text('Action Button 1', overflow: TextOverflow.ellipsis),
                  ),
                  FilledButton(
                    onPressed: () {
                      tapCount++;
                    },
                    child: const Text('Action Button 2', overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final report = await UiQualityTester.runChaosMonkeyFuzzing(
          tester,
          seed: 42,
          actionCount: 12,
          stepInterval: const Duration(milliseconds: 10),
        );

        expect(report.isResilient, isTrue);
        expect(report.successfulActions, greaterThan(0));
        expect(report.eventLog.isNotEmpty, isTrue);
        expect(tapCount, greaterThanOrEqualTo(0));
      });
    });

    group('Frontier 6: AqilRumSynthesizer Production RUM Feedback Loop & Test Case Synthesizer', () {
      test('RumTelemetryIncident serializes and deserializes cleanly with all properties', () {
        final incident = RumTelemetryIncident(
          incidentId: 'INC-2026-99',
          category: RumErrorCategory.renderFlexOverflow,
          screenRoute: '/enterprise_admin',
          viewportSize: const Size(360, 800),
          devicePixelRatio: 2.625,
          textScaleFactor: 1.35,
          errorMessage: 'A RenderFlex overflowed by 28.5 pixels on the bottom.',
          overflowPixels: 28.5,
          failingWidgetType: 'AdminMetricCard',
          timestamp: DateTime(2026, 10, 4, 12, 0, 0),
        );

        final json = incident.toJson();
        expect(json['incidentId'], equals('INC-2026-99'));
        expect(json['category'], equals('renderFlexOverflow'));
        expect(json['overflowPixels'], equals(28.5));

        final restored = RumTelemetryIncident.fromJson(json);
        expect(restored.incidentId, equals(incident.incidentId));
        expect(restored.category, equals(incident.category));
        expect(restored.overflowPixels, equals(28.5));
        expect(restored.viewportSize.width, equals(360.0));
      });

      test('parseFlutterErrorLog extracts error category, overflow pixels, and widget name', () {
        const rawCrashLog = '''
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 42.0 pixels on the right.
The relevant error-causing widget was:
  EmployeePresenceTile in test_screen.dart:45
════════════════════════════════════════════════════════════════════════════════════════════════════
''';

        final incident = UiQualityTester.parseRumErrorLog(
          rawCrashLog,
          incidentId: 'INC-CRASH-042',
          screenRoute: '/presence',
        );

        expect(incident.category, equals(RumErrorCategory.renderFlexOverflow));
        expect(incident.overflowPixels, equals(42.0));
        expect(incident.incidentId, equals('INC-CRASH-042'));
        expect(incident.screenRoute, equals('/presence'));
      });

      test('synthesizeTestFromRumIncident produces valid executable Dart test script', () {
        final incident = RumTelemetryIncident(
          incidentId: 'INC-404-OVF',
          category: RumErrorCategory.renderFlexOverflow,
          screenRoute: '/kiosk_mode',
          viewportSize: const Size(320, 568),
          devicePixelRatio: 2.0,
          textScaleFactor: 1.5,
          errorMessage: 'RenderFlex overflowed by 15px',
          overflowPixels: 15.0,
          timestamp: DateTime.now(),
        );

        final testScript = UiQualityTester.synthesizeTestFromRumIncident(
          incident,
          testGroupName: 'Kiosk Mode Production Incident Reproduction',
          widgetConstructor: 'const Text("Replay Kiosk")',
        );

        expect(testScript, contains("group('Kiosk Mode Production Incident Reproduction'"));
        expect(testScript, contains('tester.view.physicalSize = const Size(320.0, 568.0) * 2.0;'));
        expect(testScript, contains('textScaler: TextScaler.linear(1.5),'));
        expect(testScript, contains('expect(tester.takeException(), isNull);'));
      });

      test('generateRumSlaTriageReport aggregates metrics and computes SLA risk score', () {
        final incidents = [
          RumTelemetryIncident(
            incidentId: 'INC-1',
            category: RumErrorCategory.renderFlexOverflow,
            screenRoute: '/screenA',
            viewportSize: const Size(360, 640),
            errorMessage: 'Overflow',
            overflowPixels: 16.0,
            timestamp: DateTime.now(),
          ),
          RumTelemetryIncident(
            incidentId: 'INC-2',
            category: RumErrorCategory.renderFlexOverflow,
            screenRoute: '/screenB',
            viewportSize: const Size(360, 640),
            errorMessage: 'Overflow',
            overflowPixels: 32.0,
            timestamp: DateTime.now(),
          ),
          RumTelemetryIncident(
            incidentId: 'INC-3',
            category: RumErrorCategory.viewportUnboundedHeight,
            screenRoute: '/screenC',
            viewportSize: const Size(360, 640),
            errorMessage: 'Unbounded height',
            timestamp: DateTime.now(),
          ),
        ];

        final triage = UiQualityTester.generateRumSlaTriageReport(incidents);
        expect(triage['totalIncidents'], equals(3));
        expect(triage['overflowCount'], equals(2));
        expect(triage['unboundedHeightCount'], equals(1));
        expect(triage['maxOverflowPixels'], equals(32.0));
        expect(triage['criticalityScore'], greaterThan(0));
      });
    });

    group('Frontier 1 (AQIL v7): AqilFrameProfiler Frame Budget & Animation Jank Profiler', () {
      test('evaluateFrameMetrics confirms SLA compliance on smooth 120Hz frames', () {
        final frames = [4.2, 5.1, 4.8, 6.0, 5.5, 4.9, 7.2, 6.1, 5.8, 5.2];
        final report = AqilFrameProfiler.evaluateFrameMetrics(
          frames,
          target: RefreshRateTarget.fps120,
        );

        expect(report.isSlaCompliant, isTrue);
        expect(report.totalFrames, equals(10));
        expect(report.jankFrames, equals(0));
        expect(report.jankRatio, equals(0.0));
        expect(report.budgetMs, closeTo(8.33, 0.01));
        expect(report.p95FrameMs, lessThanOrEqualTo(8.33));
        expect(report.averageFrameMs, closeTo(5.48, 0.1));
      });

      test('evaluateFrameMetrics flags jank spikes and SLA breach on dropped frames', () {
        final frames = [5.0, 6.0, 18.5, 22.0, 6.5, 5.5, 19.0, 5.2, 6.1, 5.4];
        final report = AqilFrameProfiler.evaluateFrameMetrics(
          frames,
          target: RefreshRateTarget.fps120,
        );

        expect(report.isSlaCompliant, isFalse);
        expect(report.jankFrames, equals(3));
        expect(report.jankRatio, equals(0.30));
        expect(report.maxFrameMs, equals(22.0));
        expect(report.optimizationTips.isNotEmpty, isTrue);
        expect(report.toMarkdownSummary(), contains('SLA BREACH'));
      });

      testWidgets('profileAnimationFrames measures animation loop within frame budget',
          (WidgetTester tester) async {
        double position = 0.0;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: RepaintBoundary(
                    key: const ValueKey('animated_box'),
                    child: Transform.translate(
                      offset: Offset(position, 0),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        final report = await UiQualityTester.profileAnimationFrames(
          tester,
          target: RefreshRateTarget.fps60,
          steps: 5,
          stepDuration: const Duration(milliseconds: 16),
          animationDriver: (t) async {
            position += 10.0;
            await t.pump();
          },
        );

        expect(report.totalFrames, equals(5));
        expect(report.targetRate, equals(RefreshRateTarget.fps60));
      });

      testWidgets('auditRepaintIsolation detects direct and missing RepaintBoundaries',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RepaintBoundary(
                    key: ValueKey('isolated_widget'),
                    child: Text('Isolated', overflow: TextOverflow.ellipsis),
                  ),
                  Text('Non-isolated', key: ValueKey('unisolated_widget')),
                ],
              ),
            ),
          ),
        );

        final isolatedReport = UiQualityTester.auditRepaintIsolation(
          tester,
          targetFinder: find.byKey(const ValueKey('isolated_widget')),
        );
        expect(isolatedReport.isIsolated, isTrue);
        expect(isolatedReport.hasRepaintBoundary, isTrue);

        final unisolatedReport = UiQualityTester.auditRepaintIsolation(
          tester,
          targetFinder: find.byKey(const ValueKey('unisolated_widget')),
        );
        expect(unisolatedReport.hasRepaintBoundary, isFalse);
      });
    });

    group('Frontier 2 (AQIL v7): AqilAccessibilityTree Screen Reader & Focus Trap Engine', () {
      testWidgets('verifyLiveRegion detects live region semantics on status alerts',
          (WidgetTester tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Semantics(
                      key: const ValueKey('live_badge'),
                      liveRegion: true,
                      child: const Text('Syncing data in background...'),
                    ),
                    const Text('Normal static text', key: ValueKey('static_text')),
                  ],
                ),
              ),
            ),
          );

          expect(
            UiQualityTester.verifyLiveRegion(
              tester,
              targetFinder: find.byKey(const ValueKey('live_badge')),
            ),
            isTrue,
          );

          expect(
            UiQualityTester.verifyLiveRegion(
              tester,
              targetFinder: find.byKey(const ValueKey('static_text')),
            ),
            isFalse,
          );
        } finally {
          semanticsHandle.dispose();
        }
      });

      testWidgets('auditCustomActions discovers available interactive semantics actions',
          (WidgetTester tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Semantics(
                    key: const ValueKey('actionable_card'),
                    onTap: () {},
                    onLongPress: () {},
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.amber,
                      child: const Text('Interactive Card'),
                    ),
                  ),
                ),
              ),
            ),
          );

          final report = UiQualityTester.auditCustomActions(
            tester,
            targetFinder: find.byKey(const ValueKey('actionable_card')),
            requiredActions: ['tap', 'longPress'],
          );

          expect(report.hasRequiredActions, isTrue);
          expect(report.availableActions.contains('tap'), isTrue);
          expect(report.availableActions.contains('longPress'), isTrue);
          expect(report.missingActions, isEmpty);
        } finally {
          semanticsHandle.dispose();
        }
      });

      testWidgets('auditModalFocusTrap evaluates background accessibility isolation during dialog presentation',
          (WidgetTester tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => FilledButton(
                      key: const ValueKey('open_dialog_button'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            key: const ValueKey('active_dialog'),
                            title: const Text('Dialog Title'),
                            content: const Text('Modal Content'),
                            actions: [
                              TextButton(
                                key: const ValueKey('dialog_close_button'),
                                onPressed: () => Navigator.of(c).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Open Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.byKey(const ValueKey('open_dialog_button')));
          await tester.pumpAndSettle();

          final report = UiQualityTester.auditModalFocusTrap(
            tester,
            modalFinder: find.byKey(const ValueKey('active_dialog')),
            backgroundInteractiveFinder: find.byKey(const ValueKey('open_dialog_button')),
          );

          expect(report.isTrapEnforced, isTrue);
          expect(report.diagnostic, contains('strictly enforced'));
        } finally {
          semanticsHandle.dispose();
        }
      });
    });

    group('Frontier 3 (AQIL v7): AqilComplexScriptEngine Complex Script & Non-Latin Typography Stress Engine', () {
      testWidgets('auditScriptMatrix renders non-Latin scripts (Devanagari, Arabic, CJK, Thai) cleanly',
          (WidgetTester tester) async {
        final reports = await UiQualityTester.auditScriptMatrix(
          tester,
          builder: (context, text, direction) => Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );

        expect(reports.length, equals(4));
        expect(reports[ScriptLanguage.devanagari]!.isSuccessful, isTrue);
        expect(reports[ScriptLanguage.arabic]!.isSuccessful, isTrue);
        expect(reports[ScriptLanguage.cjk]!.isSuccessful, isTrue);
        expect(reports[ScriptLanguage.thai]!.isSuccessful, isTrue);
        expect(reports[ScriptLanguage.devanagari]!.measuredTextHeight, greaterThan(0));
      });

      testWidgets('auditBidiIconMirroring detects directional vs non-directional navigation icons',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Icon(Icons.arrow_back),
                  Icon(Icons.star), // Non-directional icon
                ],
              ),
            ),
          ),
        );

        final report = UiQualityTester.auditBidiIconMirroring(
          tester,
          targetFinder: find.byType(Icon),
        );

        expect(report.directionalIconsScanned, equals(1));
        expect(report.properlyMirroredCount, equals(1));
        expect(report.isCompliant, isTrue);
      });
    });

    group('Frontier 4 (AQIL v7): AqilLifecycleSentinel Memory Leak & Widget Ticker Lifecycle Sentinel', () {
      testWidgets('auditUnmountDisposal confirms clean controller and ticker unmounting',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditUnmountDisposal(
          tester,
          builder: (context) => const _TestDisposableWidget(),
        );

        expect(report.isClean, isTrue);
        expect(report.activeTickerCount, equals(0));
        expect(report.detectedLeaks, isEmpty);
        expect(report.diagnostic, contains('Widget unmounted cleanly'));
      });

      testWidgets('verifyBackgroundTickerPause verifies clean execution when covered by modal barrier',
          (WidgetTester tester) async {
        final success = await UiQualityTester.verifyBackgroundTickerPause(
          tester,
          backgroundBuilder: (context) => Container(
            color: Colors.blue,
            child: const Center(child: Text('Background View')),
          ),
          modalBuilder: (context) => const AlertDialog(
            title: Text('Foreground Modal'),
          ),
        );

        expect(success, isTrue);
      });
    });

    group('Frontier 5 (AQIL v7): AqilFigmaTokenSentinel Figma Two-Way Design Token Drift Sentinel', () {
      test('parseW3cTokens parses standard W3C DTCG design tokens JSON correctly', () {
        final figmaJson = {
          'color': {
            'brand': {
              'primary': {
                r'$value': '#1E88E5',
                r'$type': 'color',
                r'$description': 'Main brand primary color',
              },
            },
          },
          'spacing': {
            'md': {
              r'$value': 16,
              r'$type': 'dimension',
            },
          },
          'motion': {
            'durationFast': {
              r'$value': '150ms',
              r'$type': 'duration',
            },
          },
        };

        final parsed = AqilFigmaTokenSentinel.parseW3cTokens(figmaJson);
        expect(parsed.length, equals(3));
        expect(parsed['color.brand.primary']?.type, equals(W3cTokenType.color));
        expect(parsed['color.brand.primary']?.colorArgbValue, equals(0xFF1E88E5));
        expect(parsed['spacing.md']?.dimensionValue, equals(16.0));
        expect(parsed['motion.durationFast']?.durationMsValue, equals(150));
      });

      test('auditFigmaTokenDrift identifies 100% synchronized tokens without drift', () {
        final figmaJson = {
          'spacing': {
            'sm': {r'$value': 8, r'$type': 'dimension'},
            'md': {r'$value': 16, r'$type': 'dimension'},
          },
          'color': {
            'primary': {r'$value': '#007AFF', r'$type': 'color'},
          },
        };

        final flutterTokens = {
          'spacing.sm': 8.0,
          'spacing.md': 16.0,
          'color.primary': const Color(0xFF007AFF),
        };

        final report = UiQualityTester.auditFigmaTokenDrift(
          figmaTokensJson: figmaJson,
          flutterTokens: flutterTokens,
        );

        expect(report.isCompliant, isTrue);
        expect(report.hasDrift, isFalse);
        expect(report.syncScore, equals(100.0));
        expect(report.drifts, isEmpty);
        expect(report.toMarkdownReport(), contains('100% IN SYNC'));
      });

      test('auditFigmaTokenDrift detects missing in Flutter, dimension drift, and generates patches', () {
        final figmaJson = {
          'spacing': {
            'sm': {r'$value': 8, r'$type': 'dimension'},
            'md': {r'$value': 24, r'$type': 'dimension'}, // Figma has 24
            'lg': {r'$value': 32, r'$type': 'dimension'}, // Missing in flutter
          },
          'color': {
            'primary': {r'$value': '#007AFF', r'$type': 'color'},
          },
        };

        final flutterTokens = {
          'spacing.sm': 8.0,
          'spacing.md': 16.0, // Diverges by 8dp (> 0.5dp tolerance)
          'color.primary': const Color(0xFF007AFF),
          'spacing.orphan': 4.0, // Missing in Figma
        };

        final report = UiQualityTester.auditFigmaTokenDrift(
          figmaTokensJson: figmaJson,
          flutterTokens: flutterTokens,
          dimensionTolerancePx: 1.0,
        );

        expect(report.isCompliant, isFalse);
        expect(report.hasDrift, isTrue);
        expect(report.drifts.length, equals(3));

        // Check drift types
        final valueDrifts = report.drifts.where((d) => d.driftType == TokenDriftType.valueDrift);
        final missingInFlutter = report.drifts.where((d) => d.driftType == TokenDriftType.missingInFlutter);
        final missingInFigma = report.drifts.where((d) => d.driftType == TokenDriftType.missingInFigma);

        expect(valueDrifts.length, equals(1));
        expect(valueDrifts.first.tokenPath, equals('spacing.md'));
        expect(missingInFlutter.length, equals(1));
        expect(missingInFlutter.first.tokenPath, equals('spacing.lg'));
        expect(missingInFigma.length, equals(1));
        expect(missingInFigma.first.tokenPath, equals('spacing.orphan'));

        // Generate patch checks
        final flutterPatch = report.generateFlutterSyncPatch();
        expect(flutterPatch, contains('static const double md = 24.0;'));
        expect(flutterPatch, contains('static const double lg = 32.0;'));

        final figmaPatch = report.generateFigmaTokensPatch();
        expect(figmaPatch.containsKey('spacing'), isTrue);
      });

      test('exportW3cJson exports Flutter tokens map into valid W3C DTCG JSON', () {
        final flutterTokens = {
          'spacing.xs': 4.0,
          'spacing.sm': 8.0,
          'color.surface': const Color(0xFFFFFFFF),
          'motion.fade': const Duration(milliseconds: 200),
        };

        final jsonString = AqilFigmaTokenSentinel.exportW3cJson(flutterTokens);
        expect(jsonString, contains(r'"$value": 4.0'));
        expect(jsonString, contains(r'"$type": "dimension"'));
        expect(jsonString, contains(r'"$value": "#FFFFFFFF"'));
        expect(jsonString, contains(r'"$type": "color"'));
        expect(jsonString, contains(r'"$value": "200ms"'));
        expect(jsonString, contains(r'"$type": "duration"'));
      });
    });

    group('Frontier 6 (AQIL v7): AqilSpatialTensionAuditor Multimodal Visual Layout & Spatial Tension Auditor', () {
      testWidgets('auditSpatialTension confirms high harmony on 8pt grid compliant layouts',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harmonious Heading',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Balanced body copy text with clean typography contrast.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16.0),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text('Card Content', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final report = UiQualityTester.auditSpatialTension(tester);

        expect(report.isHarmonious, isTrue);
        expect(report.tensionScore, greaterThanOrEqualTo(85.0));
        expect(report.gridHarmonyRatio, greaterThan(0.8));
        expect(report.density, equals(SpatialDensity.balanced));
        expect(report.criticalViolationsCount, equals(0));
        expect(report.toMarkdownReport(), contains('HARMONIOUS & BALANCED'));
      });

      testWidgets('auditSpatialTension flags asymmetric padding, cramped borders, and muddy typography',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Asymmetric horizontal padding: left 24 vs right 4 (20dp skew)
                  Padding(
                    padding: EdgeInsets.only(left: 24.0, right: 4.0),
                    child: Text('Asymmetric content', style: TextStyle(fontSize: 16)),
                  ),
                  // Muddy typography step: 16sp vs 15sp (1.06x ratio)
                  Text('Subtitle nearly same as body', style: TextStyle(fontSize: 15)),
                  // Cramped sub-4dp padding
                  Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Text('Cramped', style: TextStyle(fontSize: 12)),
                  ),
                  // Excessive dead void space (> 80dp)
                  SizedBox(height: 100.0),
                ],
              ),
            ),
          ),
        );

        final report = UiQualityTester.auditSpatialTension(tester);

        expect(report.isHarmonious, isFalse);
        expect(report.violations.isNotEmpty, isTrue);
        expect(
          report.violations.any((v) => v.type == SpatialTensionType.asymmetricPadding),
          isTrue,
        );
        expect(
          report.violations.any((v) => v.type == SpatialTensionType.muddyTypographyScale),
          isTrue,
        );
        expect(
          report.violations.any((v) => v.type == SpatialTensionType.crampedCardPadding),
          isTrue,
        );
        expect(
          report.violations.any((v) => v.type == SpatialTensionType.excessiveDeadSpace),
          isTrue,
        );
      });
    });

    group('Frontier 1 (AQIL v8): AqilHardwareSensorMesh Hardware Sensor Mocking Mesh', () {
      testWidgets('auditHardwareFaultResilience detects fault injection and graceful recovery',
          (WidgetTester tester) async {
        final faults = [
          const HardwareFaultInjection(
            peripheral: HardwarePeripheralType.cameraSensor,
            targetStatus: PeripheralStatus.disconnected,
            simulatedErrorMessage: 'Camera USB port disconnected',
          ),
        ];

        final report = await UiQualityTester.auditHardwareFaultResilience(
          tester,
          builder: (context, broker) => StreamBuilder<PeripheralStateEvent>(
            stream: broker.stream,
            initialData: PeripheralStateEvent(
              peripheral: HardwarePeripheralType.cameraSensor,
              status: PeripheralStatus.operational,
            ),
            builder: (context, snapshot) {
              final isDisconnected = snapshot.data?.status == PeripheralStatus.disconnected;
              return Column(
                children: [
                  const Text('Kiosk Face Capture'),
                  if (isDisconnected)
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        Text('Camera disconnected - retrying...'),
                      ],
                    ),
                ],
              );
            },
          ),
          faults: faults,
        );

        expect(report.isResilient, isTrue);
        expect(report.displayedFallbackUi, isTrue);
        expect(report.handledWithoutCrash, isTrue);
        expect(report.recoveredFaults, equals(1));
        expect(report.toMarkdownReport(), contains('RESILIENT & ROBUST'));
      });
    });

    group('Frontier 2 (AQIL v8): AqilGesturePhysicsAuditor Fluid Physics Spring Gesture Auditor', () {
      testWidgets('auditFlingGesture evaluates smooth drag settling dynamics',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        );

        final report = await UiQualityTester.auditFlingGesture(
          tester,
          targetFinder: find.byType(ListView),
          dragDelta: const Offset(0, -100),
          velocity: 600.0,
        );

        expect(report.isFluidAndNatural, isTrue);
        expect(report.hadVisualPopping, isFalse);
        expect(report.profile, isNot(equals(SpringMotionProfile.abruptSnap)));
        expect(report.toMarkdownReport(), contains('FLUID & NATURAL'));
      });
    });

    group('Frontier 3 (AQIL v8): AqilVisualSaliencyAuditor Cognitive Saliency & Visual Flow Auditor', () {
      testWidgets('auditVisualFlow confirms dominance of primary CTA over secondary buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('Confirm Punch In', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final report = UiQualityTester.auditVisualFlow(
          tester,
          primaryCtaFinder: find.byType(FilledButton),
          competingFinders: [find.byType(TextButton)],
        );

        expect(report.isClean, isTrue);
        expect(report.primaryHasDominance, isTrue);
        expect(report.visualCompetitionRatio, lessThan(0.85));
        expect(report.dominantElement?.isMarkedAsPrimary, isTrue);
        expect(report.toMarkdownReport(), contains('CLEAR COGNITIVE HIERARCHY'));
      });
    });

    group('Frontier 4 (AQIL v8): AqilOledPowerAuditor OLED Power & Dark Mode Black-Smear Sentinel', () {
      testWidgets('auditOledDarkProfile calculates APL and verifies M3 dark tonal surfaces',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212), // M3 dark surface container
            ),
            home: Scaffold(
              body: ListView(
                children: const [
                  ListTile(title: Text('Attendance Log 1')),
                  ListTile(title: Text('Attendance Log 2')),
                ],
              ),
            ),
          ),
        );

        final report = UiQualityTester.auditOledDarkProfile(tester);

        expect(report.isDarkTheme, isTrue);
        expect(report.hasPureBlackSmearRisk, isFalse);
        expect(report.isCompliant, isTrue);
        expect(report.powerEfficiencyScore, greaterThanOrEqualTo(80.0));
        expect(report.toMarkdownReport(), contains('OLED COMPLIANT'));
      });
    });

    group('Frontier 5 (AQIL v8): AqilPseudoLocEngine Pseudo-Localization & Reflow Simulator', () {
      test('pseudoLocalize generates accented expansion strings with delimiters', () {
        final transformed = AqilPseudoLocEngine.pseudoLocalize('Submit');
        expect(transformed, startsWith('[!!! '));
        expect(transformed, endsWith(' !!!]'));
        expect(transformed, contains('Š'));
        expect(transformed.length, greaterThan('Submit'.length + 8));
      });

      testWidgets('auditPseudoLocalization confirms layout resilience under +40% string expansion',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditPseudoLocalization(
          tester,
          builder: (context, l10n) => SingleChildScrollView(
            child: Column(
              children: [
                Text(l10n('Regularization Request Form')),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(l10n('Approve All Overtime Requests')),
                ),
              ],
            ),
          ),
        );

        expect(report.isReflowResilient, isTrue);
        expect(report.detectedOverflows, equals(0));
        expect(report.stringsTransformed, greaterThanOrEqualTo(2));
        expect(report.toMarkdownReport(), contains('REFLOW RESILIENT'));
      });
    });

    group('Frontier 6 (AQIL v8): AqilMutationResilienceEngine Adversarial Mutation Resilience', () {
      testWidgets('auditMutationResilience verifies crash-proof index against super-strings and emojis',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditMutationResilience(
          tester,
          builder: (context, mutatedVal) => Center(
            child: SizedBox(
              width: 300,
              child: Text(
                '$mutatedVal',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );

        expect(report.isCrashProof, isTrue);
        expect(report.crashResistanceIndex, equals(100.0));
        expect(report.survivedTrials, equals(report.totalTrials));
        expect(report.toMarkdownReport(), contains('CRASH-PROOF'));
      });
    });

    group('Frontier 1 (AQIL v9): AqilProjectCrawler Zero-Config Project Crawler', () {
      test('parseDartSource extracts discovered Widget classes and generates test suites', () {
        const dummySource = '''
class AttendanceHomeScreen extends StatelessWidget {
  const AttendanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}
''';

        final screens = UiQualityTester.parseDartSource(dummySource, filePath: 'lib/views/home.dart');
        expect(screens.length, equals(2));

        final home = screens.firstWhere((s) => s.screenName == 'AttendanceHomeScreen');
        expect(home.hasConstConstructor, isTrue);
        expect(home.isInstantiableWithoutMocks, isTrue);

        final detail = screens.firstWhere((s) => s.screenName == 'UserDetailScreen');
        expect(detail.hasRequiredParams, isTrue);
        expect(detail.requiredParams, contains('userId'));

        final testCode = AqilProjectCrawler.generateTestSuiteForScreen(home);
        expect(testCode, contains("group('AQIL v9 Fleet Suite — AttendanceHomeScreen'"));
        expect(testCode, contains('UiQualityTester.runFullAqilSuite'));
      });
    });

    group('Frontier 2 (AQIL v9): AqilMediaAssetAuditor Media Asset & Shimmer Skeleton Auditor', () {
      testWidgets('auditMediaAssets flags unbounded images lacking explicit dimensions',
          (WidgetTester tester) async {
        final transparentPng = Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82,
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Image.memory(transparentPng),
            ),
          ),
        );

        final report = UiQualityTester.auditMediaAssets(tester);
        expect(report.isCompliant, isFalse);
        expect(report.hasUnboundedImages, isTrue);
        expect(report.violations.any((v) => v.type == MediaDefectType.unboundedDimensions), isTrue);
        expect(report.toMarkdownReport(), contains('MEDIA DEFECTS DETECTED'));
      });

      testWidgets('verifyShimmerLayoutMatch confirms dimension parity between skeleton and loaded',
          (WidgetTester tester) async {
        final matches = await AqilMediaAssetAuditor.verifyShimmerLayoutMatch(
          tester,
          shimmerBuilder: (context) => Container(width: 200, height: 100, color: Colors.grey.shade300),
          loadedBuilder: (context) => Container(width: 200, height: 100, color: Colors.blue),
        );
        expect(matches, isTrue);
      });
    });

    group('Frontier 3 (AQIL v9): AqilScrollProfiler 1,000-Item Virtualized Scroll Performance', () {
      testWidgets('auditVirtualizedScrollPerformance evaluates recycling across 1,000 items',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 1000,
                itemBuilder: (context, index) => ListTile(title: Text('Record #$index')),
              ),
            ),
          ),
        );

        final report = await UiQualityTester.auditVirtualizedScrollPerformance(
          tester,
          scrollableFinder: find.byType(ListView),
          totalItems: 1000,
          flingVelocity: 2500.0,
        );

        expect(report.isPerformant, isTrue);
        expect(report.isProperlyVirtualized, isTrue);
        expect(report.activeElementsInTree, lessThan(100)); // recycling works!
        expect(report.toMarkdownReport(), contains('HIGH PERFORMANCE & VIRTUALIZED'));
      });
    });

    group('Frontier 4 (AQIL v9): AqilPaletteInvariantAuditor OS High-Contrast & Accent Checker', () {
      testWidgets('auditHighContrastInvariance asserts AAA contrast under OS High Contrast mode',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditHighContrastInvariance(
          tester,
          builder: (context) => const Center(
            child: Text(
              'High Contrast Critical Status',
              style: TextStyle(color: Colors.black),
            ),
          ),
        );

        expect(report.isCompliant, isTrue);
        expect(report.meetsAaaHighContrast, isTrue);
        expect(report.measuredContrastRatio, greaterThanOrEqualTo(7.0));
        expect(report.toMarkdownReport(), contains('HIGH-CONTRAST COMPLIANT'));
      });
    });

    group('Frontier 5 (AQIL v9): AqilStateRestorationAuditor Process Death & State Restoration', () {
      testWidgets('auditFormStateRestoration asserts input preservation across simulated unmount',
          (WidgetTester tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        final report = await UiQualityTester.auditFormStateRestoration(
          tester,
          builder: (context) => TextField(
            controller: controller,
          ),
          inputFinder: find.byType(TextField),
          testInputText: 'Preserved Draft Value',
        );

        expect(report.isZeroDataLoss, isTrue);
        expect(report.formInputsRestored, equals(1));
        expect(report.toMarkdownReport(), contains('ZERO DATA LOSS'));
      });
    });

    group('Frontier 6 (AQIL v9): AqilUnifiedDashboard Cross-Project Unified Quality Dashboard & Badges', () {
      test('buildAntigravityFleetReport aggregates health and emits HTML & SVG badges', () {
        final report = UiQualityTester.buildAntigravityFleetReport();

        expect(report.projects.length, equals(5));
        expect(report.projects.any((p) => p.projectName == 'myBiometric'), isTrue);
        expect(report.fleetAverageScore, greaterThan(90.0));
        expect(report.fleetGrade, equals('A+'));

        final html = report.generateHtmlDashboard();
        expect(html, contains('AQIL v9 Cross-Project Quality Fleet'));
        expect(html, contains('myBiometric'));
        expect(html, contains('PowerNewsApp'));

        final svg = FleetDashboardReport.generateSvgBadge(
          label: 'AQIL Fleet',
          value: 'Grade A+ (99%)',
          color: '#10b981',
        );
        expect(svg, startsWith('<svg'));
        expect(svg, endsWith('</svg>'));
        expect(svg, contains('Grade A+ (99%)'));
      });
    });

    group('Frontier 1 (AQIL v10): AqilNetworkChaosEngine Network Chaos & Jitter Engine', () {
      testWidgets('auditNetworkChaosResilience verifies timeout and retry UI rendering',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditNetworkChaosResilience(
          tester,
          builder: (context, hasError) => Column(
            children: [
              if (hasError)
                const Row(
                  children: [
                    Icon(Icons.wifi_off),
                    Text('Network error: connection timed out. Tap retry.'),
                  ],
                ),
            ],
          ),
          profile: NetworkChaosProfile.cellular2gEdge,
        );

        expect(report.isResilient, isTrue);
        expect(report.displayedErrorOrRetry, isTrue);
        expect(report.handledWithoutUncaughtException, isTrue);
        expect(report.toMarkdownReport(), contains('RESILIENT UNDER CHAOS'));
      });
    });

    group('Frontier 2 (AQIL v10): AqilBiometricSpoofSentinel Biometric Spoof & Liveness Sentinel', () {
      testWidgets('auditAntiSpoofResilience detects attack rejection and supervisor override option',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditAntiSpoofResilience(
          tester,
          builder: (context, attack) => const Column(
            children: [
              Text('Biometric Verification Failed: spoof attack rejected.'),
              Text('Enter Supervisor PIN to override.'),
            ],
          ),
          vectors: const [BiometricSpoofType.printedPhoto2D, BiometricSpoofType.digitalScreenReplay],
        );

        expect(report.isSecure, isTrue);
        expect(report.attacksSafelyRejected, equals(2));
        expect(report.displayedSecurityWarning, isTrue);
        expect(report.triggeredLockoutOrOverride, isTrue);
        expect(report.toMarkdownReport(), contains('SECURE & PAD COMPLIANT'));
      });
    });

    group('Frontier 3 (AQIL v10): AqilGcThrashSentinel Memory Footprint & Allocation Stability', () {
      testWidgets('auditAllocationStability verifies bounded imageCache during rapid rebuilds',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditAllocationStability(
          tester,
          builder: (context, cycle) => Container(
            key: ValueKey('cycle-$cycle'),
            child: Text('Frame #$cycle'),
          ),
          cycles: 20,
        );

        expect(report.isMemoryStable, isTrue);
        expect(report.cyclesExecuted, equals(20));
        expect(report.toMarkdownReport(), contains('MEMORY STABLE'));
      });
    });

    group('Frontier 4 (AQIL v10): AqilFoldableAngleAuditor Foldable Posture Continuity', () {
      testWidgets('auditFoldablePostureMatrix verifies responsive continuity across postures',
          (WidgetTester tester) async {
        final report = await UiQualityTester.auditFoldablePostureMatrix(
          tester,
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) => Container(
              color: Colors.blue,
              child: Center(
                child: Text('Width: ${constraints.maxWidth.toStringAsFixed(0)}'),
              ),
            ),
          ),
        );

        expect(report.isPostureResilient, isTrue);
        expect(report.hadOverflows, isFalse);
        expect(report.posturesTested.length, equals(3));
        expect(report.toMarkdownReport(), contains('RESILIENT ACROSS POSTURES'));
      });
    });

    group('Frontier 5 (AQIL v10): AqilHashChainSentinel Cryptographic Integrity & Offline Hash-Chain', () {
      test('verifyChainIntegrity detects intact chain and flags tampered blocks', () {
        final now = DateTime(2026, 10, 4, 12, 0, 0);

        final b0 = AqilHashChainSentinel.createBlock(
          index: 0,
          employeeId: 'EMP-001',
          timestamp: now,
          punchType: 'PUNCH_IN',
          previousHash: 'GENESIS_BLOCK_ROOT',
        );

        final b1 = AqilHashChainSentinel.createBlock(
          index: 1,
          employeeId: 'EMP-002',
          timestamp: now.add(const Duration(minutes: 5)),
          punchType: 'PUNCH_IN',
          previousHash: b0.blockHash,
        );

        final b2 = AqilHashChainSentinel.createBlock(
          index: 2,
          employeeId: 'EMP-001',
          timestamp: now.add(const Duration(hours: 4)),
          punchType: 'START_BREAK',
          previousHash: b1.blockHash,
        );

        // 1. Verify intact chain
        final intactReport = UiQualityTester.verifyHashChainIntegrity([b0, b1, b2]);
        expect(intactReport.isChainIntact, isTrue);
        expect(intactReport.corruptedIndices, isEmpty);
        expect(intactReport.toMarkdownReport(), contains('CRYPTOGRAPHICALLY SECURE'));

        // 2. Tamper with b1 blockHash
        final tamperedB1 = OfflinePunchBlock(
          index: b1.index,
          employeeId: b1.employeeId,
          timestamp: b1.timestamp,
          punchType: b1.punchType,
          previousHash: b1.previousHash,
          blockHash: 'FORGED_INVALID_HASH_VALUE',
        );

        final tamperedReport = UiQualityTester.verifyHashChainIntegrity([b0, tamperedB1, b2]);
        expect(tamperedReport.isChainIntact, isFalse);
        expect(tamperedReport.corruptedIndices, contains(1));
        expect(tamperedReport.toMarkdownReport(), contains('CHAIN TAMPERING DETECTED'));
      });
    });

    group('Frontier 6 (AQIL v10): AqilA11yGoldenBaseline Semantics Tree Golden Baseline Audit', () {
      test('compareSemanticsBaseline verifies clean match and catches dropped labels', () {
        final baseline = [
          'Submit Attendance [BUTTON]',
          'Employee Dashboard [HEADER]',
          'Scan QR Code [BUTTON]',
        ];

        final matching = [
          'Submit Attendance [BUTTON]',
          'Employee Dashboard [HEADER]',
          'Scan QR Code [BUTTON]',
        ];

        final matchReport = UiQualityTester.compareSemanticsBaseline(
          baseline: baseline,
          current: matching,
        );
        expect(matchReport.isMatchingBaseline, isTrue);
        expect(matchReport.semanticDiffs, isEmpty);
        expect(matchReport.toMarkdownReport(), contains('ZERO REGRESSION'));

        // Regressed current state missing header
        final regressed = [
          'Submit Attendance [BUTTON]',
          'Scan QR Code [BUTTON]',
        ];

        final regressedReport = UiQualityTester.compareSemanticsBaseline(
          baseline: baseline,
          current: regressed,
        );
        expect(regressedReport.isMatchingBaseline, isFalse);
        expect(regressedReport.semanticDiffs.any((d) => d.contains('Missing baseline semantic element')), isTrue);
        expect(regressedReport.toMarkdownReport(), contains('ACCESSIBILITY REGRESSION DETECTED'));
      });
    });

    group('AQIL v11 Big Tech Design System Twin Suite', () {
      testWidgets('Frontier 1: AqilSurfaceOpticsAuditor validates Microsoft Fluent & Google M3E surfaces',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: Builder(
                builder: (context) => Container(
                  decoration: AqilSurfaceOpticsAuditor.buildBigTechCardDecoration(
                    context: context,
                    material: AqilSurfaceMaterial.acrylicGlass,
                  ),
                  child: const Text('Fluent Acrylic Card'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final report = await AqilSurfaceOpticsAuditor.auditSurfaceMaterials(tester);
        expect(report.totalAuditedSurfaces, greaterThanOrEqualTo(1));
        expect(report.hasSubtleBorders, isTrue);
        expect(report.isBigTechCompliant, isTrue);
      });

      testWidgets('Frontier 2: AqilMotionChoreographyAuditor asserts natural spring damping settling budget',
          (WidgetTester tester) async {
        final report = await AqilMotionChoreographyAuditor.auditMotionDynamics(
          tester,
          triggerAnimation: (t) async {
            await t.pumpWidget(
              const MaterialApp(
                home: Scaffold(
                  body: AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 200),
                    curve: AqilMotionSpec.emphasizedDecelerate,
                    child: Text('Staggered Card'),
                  ),
                ),
              ),
            );
          },
        );

        expect(report.hasSpringDamping, isTrue);
        expect(report.hasStaggeredEntry, isTrue);
        expect(report.isBigTechCompliant, isTrue);
      });

      testWidgets('Frontier 3: AqilInformationDensityAuditor verifies Compact, Comfortable, Spacious density adaptation',
          (WidgetTester tester) async {
        final report = await AqilInformationDensityAuditor.auditDensityModes(
          tester,
          widgetBuilder: (context, mode) {
            final tokens = AqilDensityTokens.forMode(mode);
            return Container(
              height: tokens.rowHeight,
              padding: tokens.padding,
              child: Text('Item', style: TextStyle(fontSize: tokens.bodyFontSize)),
            );
          },
        );

        expect(report.hasZeroOverflowAcrossModes, isTrue);
        expect(report.isBigTechCompliant, isTrue);
        expect(report.modeSupported.length, equals(3));
      });

      testWidgets('Frontier 4: AqilHapticSensoryAuditor confirms platform haptic feedback invocation',
          (WidgetTester tester) async {
        final report = await AqilHapticSensoryAuditor.auditHapticTrigger(
          tester,
          userAction: (t) async {
            await AqilHapticSensoryAuditor.triggerHaptic(AqilHapticPattern.lightClick);
          },
          expectedPattern: AqilHapticPattern.lightClick,
        );

        expect(report.hasHapticTriggered, isTrue);
        expect(report.isAccessibleWithoutSound, isTrue);
        expect(report.isBigTechCompliant, isTrue);
      });

      testWidgets('Frontier 5: AqilShimmerClsAuditor detects zero Cumulative Layout Shift (CLS) on shimmer swap',
          (WidgetTester tester) async {
        const skeleton = SizedBox(
          width: 300,
          height: 80,
          child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
        );

        const loaded = SizedBox(
          width: 300,
          height: 80,
          child: Card(child: Center(child: Text('Loaded Data'))),
        );

        final report = await AqilShimmerClsAuditor.auditShimmerParity(
          tester,
          skeletonWidget: skeleton,
          loadedWidget: loaded,
        );

        expect(report.isClsZero, isTrue);
        expect(report.cumulativeLayoutShift, lessThanOrEqualTo(0.02));
        expect(report.isBigTechCompliant, isTrue);
      });

      testWidgets('Frontier 6: AqilCommandPaletteAuditor validates universal Ctrl+K command execution',
          (WidgetTester tester) async {
        final commands = [
          AqilCommandItem(
            id: 'punch_in',
            title: 'Punch In',
            category: 'Attendance',
            icon: Icons.fingerprint,
            onSelect: () {},
          ),
          AqilCommandItem(
            id: 'settings',
            title: 'Settings',
            category: 'Preferences',
            icon: Icons.settings,
            onSelect: () {},
          ),
        ];

        final hostApp = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AqilCommandPaletteAuditor.buildCommandPaletteDialog(
                context: context,
                commands: commands,
                onCommandExecuted: (cmd) {},
              ),
            ),
          ),
        );

        final report = await AqilCommandPaletteAuditor.auditCommandPaletteTrigger(
          tester,
          hostApp: hostApp,
        );

        expect(report.isTriggerableViaShortcut, isTrue);
        expect(report.isBigTechCompliant, isTrue);
      });
    });
  });
}

class _TestDisposableWidget extends StatefulWidget {
  const _TestDisposableWidget();

  @override
  State<_TestDisposableWidget> createState() => _TestDisposableWidgetState();
}

class _TestDisposableWidgetState extends State<_TestDisposableWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'Initial Text');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
    );
  }
}

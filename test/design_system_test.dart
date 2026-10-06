import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/core/design_system/design_system.dart';

/// AQIL v2 matrix: 5 viewports × 4 font scales × light/dark, plus WCAG checks.
const _viewports = [
  Size(320, 568),
  Size(393, 852),
  Size(412, 915),
  Size(800, 1280),
  Size(1280, 800),
];
const _scales = [1.0, 1.3, 1.5, 2.0];

Widget _host(ThemeData theme, Size size, double scale, Widget child) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _runMatrix(WidgetTester tester, Widget Function(BuildContext) builder) async {
  for (final theme in [AppTheme.light(), AppTheme.dark()]) {
    for (final size in _viewports) {
      for (final scale in _scales) {
        if (size.width >= 800 && scale > 1.5) continue;
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        await tester.pumpWidget(_host(theme, size, scale, Builder(builder: builder)));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow at $size @ ${scale}x (${theme.brightness.name})',
        );
      }
    }
  }
  addTearDown(tester.view.reset);
}

Widget _kpiRow(BuildContext context) {
  final s = context.status;
  return Row(
    children: [
      Expanded(child: KpiTile(label: 'Working', count: 128, tone: s.success, icon: Icons.work_outline_rounded)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: KpiTile(
          label: 'On break',
          count: 12,
          tone: s.warning,
          icon: Icons.coffee_rounded,
          note: '3 over limit',
        ),
      ),
    ],
  );
}

void main() {
  group('Design tokens', () {
    test('window size classes follow Material 3 breakpoints', () {
      expect(AppBreakpoints.of(320), WindowSizeClass.compact);
      expect(AppBreakpoints.of(599), WindowSizeClass.compact);
      expect(AppBreakpoints.of(600), WindowSizeClass.medium);
      expect(AppBreakpoints.of(840), WindowSizeClass.expanded);
      expect(AppBreakpoints.of(1280), WindowSizeClass.large);
    });

    test('both themes register AppStatusColors extension', () {
      expect(AppTheme.light().extension<AppStatusColors>(), isNotNull);
      expect(AppTheme.dark().extension<AppStatusColors>(), isNotNull);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('status tones meet WCAG AA (4.5:1) for text on container', () {
      double contrast(Color a, Color b) {
        final la = a.computeLuminance();
        final lb = b.computeLuminance();
        final hi = la > lb ? la : lb;
        final lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final palette in [AppStatusColors.light, AppStatusColors.dark]) {
        for (final tone in [palette.success, palette.warning, palette.danger, palette.info, palette.neutral]) {
          expect(contrast(tone.onContainer, tone.container), greaterThanOrEqualTo(4.5));
        }
      }
    });

    testWidgets('AppMotion collapses durations when reduce-motion is on', (tester) async {
      late Duration resolved;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          resolved = AppMotion.of(context, AppMotion.medium);
          return const SizedBox();
        }),
      ));
      expect(resolved, Duration.zero);
    });
  });

  group('Design system components — AQIL v2 matrix', () {
    testWidgets('SectionHeader + StatusPill', (tester) async {
      await _runMatrix(
        tester,
        (context) => SectionHeader(
          icon: Icons.people_alt_rounded,
          title: "Who's In / Who's Out — Headquarters North Campus",
          subtitle: 'Live real-time workforce presence across all departments',
          trailing: StatusPill(label: 'LIVE', tone: context.status.success, icon: Icons.fiber_manual_record),
        ),
      );
    });

    testWidgets('KpiTile row', (tester) async {
      await _runMatrix(tester, _kpiRow);
    });

    testWidgets('EmptyStateView and ErrorStateView', (tester) async {
      await _runMatrix(
        tester,
        (context) => Column(
          children: [
            EmptyStateView(
              icon: Icons.person_search_rounded,
              title: 'No employees match your filters',
              message: 'Try a different status, department or search term.',
              actionLabel: 'Clear filters',
              onAction: () {},
            ),
            ErrorStateView(
              message: 'Unable to load live workforce presence. Check your connection and try again.',
              onRetry: () {},
            ),
          ],
        ),
      );
    });

    testWidgets('Punch Card Action Row (Take Break + Clock Out)', (tester) async {
      await _runMatrix(
        tester,
        (context) => Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.status.warning.onContainer,
                  side: BorderSide(color: context.status.warning.border),
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                ),
                onPressed: () {},
                icon: const Icon(Icons.coffee_rounded, size: 17),
                label: Text(
                  'Take Break',
                  style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                ),
                onPressed: () {},
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: Text(
                  'Clock Out',
                  style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    });

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      testWidgets('WCAG guidelines pass (${theme.brightness.name})', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(
          theme,
          const Size(393, 852),
          1.0,
          Builder(
            builder: (context) => Column(
              children: [
                SectionHeader(
                  icon: Icons.people_alt_rounded,
                  title: "Who's In / Who's Out",
                  subtitle: 'Live presence',
                  trailing: StatusPill(label: 'LIVE', tone: context.status.success),
                ),
                const SizedBox(height: AppSpacing.lg),
                _kpiRow(context),
                ErrorStateView(message: 'Unable to load data.', onRetry: () {}),
              ],
            ),
          ),
        ));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('AppThemeNotifier persistence & transitions', () {
    test('Defaults to system theme and notifies on state change', () async {
      final notifier = AppThemeNotifier.instance;
      notifier.resetForTesting(ThemeMode.system);
      expect(notifier.themeMode, ThemeMode.system);

      var notified = false;
      notifier.addListener(() {
        notified = true;
      });

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.themeMode, ThemeMode.dark);
      expect(notified, isTrue);

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.themeMode, ThemeMode.light);

      // Clean up
      notifier.resetForTesting(ThemeMode.system);
    });
  });

  group('AppSkeleton & Shimmer components — AQIL v2', () {
    testWidgets('AppListSkeleton and AppCardSkeleton render smoothly with zero errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppCardSkeleton(),
                  SizedBox(height: 16),
                  AppListSkeleton(itemCount: 3),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify presence of shimmer animations
      expect(find.byType(AppCardSkeleton), findsOneWidget);
      expect(find.byType(AppListSkeleton), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);

      // Advance frames to verify animation ticks without exception
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });
  });

  group('AdaptiveWindowLayout & AdaptiveContentContainer — AQIL v2', () {
    testWidgets('AdaptiveWindowLayout renders compact, medium, and expanded branches dynamically',
        (WidgetTester tester) async {
      addTearDown(tester.view.reset);

      Future<void> pumpAtSize(Size size) async {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: Scaffold(
                body: SizedBox.expand(
                  child: AdaptiveWindowLayout(
                    compact: (context) => const Text('COMPACT_VIEW'),
                    medium: (context) => const Text('MEDIUM_VIEW'),
                    expanded: (context) => const Text('EXPANDED_VIEW'),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // 1. Compact (360x640)
      await pumpAtSize(const Size(360, 640));
      expect(find.text('COMPACT_VIEW'), findsOneWidget);
      expect(find.text('MEDIUM_VIEW'), findsNothing);

      // 2. Medium (720x1024)
      await pumpAtSize(const Size(720, 1024));
      expect(find.text('MEDIUM_VIEW'), findsOneWidget);
      expect(find.text('COMPACT_VIEW'), findsNothing);

      // 3. Expanded (1024x768)
      await pumpAtSize(const Size(1024, 768));
      expect(find.text('EXPANDED_VIEW'), findsOneWidget);
      expect(find.text('MEDIUM_VIEW'), findsNothing);
    });

    testWidgets('AdaptiveContentContainer constrains max width on large desktop viewports',
        (WidgetTester tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1920, 1080) * tester.view.devicePixelRatio;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(size: Size(1920, 1080)),
            child: Scaffold(
              body: AdaptiveContentContainer(
                maxWidth: 1200,
                child: Text('CONSTRAINED_CONTENT'),
              ),
            ),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(AdaptiveContentContainer),
        matching: find.byType(ConstrainedBox),
      );
      final widget = tester.widget<ConstrainedBox>(finder);
      expect(widget.constraints.maxWidth, 1200);
      final box = tester.renderObject<RenderBox>(finder);
      expect(box.size.width <= 1200, isTrue);
      expect(find.text('CONSTRAINED_CONTENT'), findsOneWidget);
    });
  });

  group('AppFeedback haptic & sensory tokens — AQIL v2', () {
    test('AppFeedback triggers sensory methods safely without exception', () async {
      await expectLater(AppFeedback.lightImpact(), completes);
      await expectLater(AppFeedback.mediumImpact(), completes);
      await expectLater(AppFeedback.heavyImpact(), completes);
      await expectLater(AppFeedback.errorAlert(), completes);
    });
  });
}

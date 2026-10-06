import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 4-pt spacing grid.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const gapXs = SizedBox(width: xs, height: xs);
  static const gapSm = SizedBox(width: sm, height: sm);
  static const gapMd = SizedBox(width: md, height: md);
  static const gapLg = SizedBox(width: lg, height: lg);
  static const gapXl = SizedBox(width: xl, height: xl);
}

/// Corner radius scale.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
  static const double full = pill;

  static final brXs = BorderRadius.circular(xs);
  static final brSm = BorderRadius.circular(sm);
  static final brMd = BorderRadius.circular(md);
  static final brLg = BorderRadius.circular(lg);
  static final brXl = BorderRadius.circular(xl);
  static final brPill = BorderRadius.circular(pill);

  static BorderRadius get cardCircular => brLg;
  static BorderRadius get buttonCircular => brSm;
  static BorderRadius get badgeCircular => brSm;
  static const Radius modal = Radius.circular(xl);
}

/// Minimum interactive sizes per platform guidelines.
abstract final class AppSizes {
  /// Material minimum touch target.
  static const double minTouchTarget = 48;

  /// Kiosk / shared-terminal primary action minimum.
  static const double kioskTouchTarget = 64;

  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  /// Max readable content width on large screens.
  static const double maxContentWidth = 1200;
}

/// Motion tokens (Material 3 durations & easing) honoring reduce-motion.
abstract final class AppMotion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);

  static const Curve standard = Easing.standard;
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;

  /// Returns [Duration.zero] when the platform requests reduced motion.
  static Duration of(BuildContext context, Duration base) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : base;
}

/// Standardized sensory & haptic feedback for user interactions (AQIL v2 Pillar 5).
abstract final class AppFeedback {
  /// Subtle feedback on tap/selection.
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium feedback on action completion (punch recorded, regularization submitted).
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy feedback on critical actions (punch-out, admin override).
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Warning / error pattern on validation failure or geofence breach.
  static Future<void> errorAlert() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}

/// Material 3 window size classes.
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large;

  bool get isCompact => this == WindowSizeClass.compact;
  bool get isAtLeastMedium => index >= WindowSizeClass.medium.index;
  bool get isAtLeastExpanded => index >= WindowSizeClass.expanded.index;
}

abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  static WindowSizeClass of(double width) {
    if (width >= large) return WindowSizeClass.large;
    if (width >= expanded) return WindowSizeClass.expanded;
    if (width >= medium) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }
}

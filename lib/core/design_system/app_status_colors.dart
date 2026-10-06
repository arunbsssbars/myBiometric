import 'package:flutter/material.dart';

import 'app_palette.dart';

/// A semantic color role: [color] for icons/fills, [onContainer] for text
/// on [container], and [border] for outlines. All pairs meet WCAG AA.
@immutable
class StatusTone {
  final Color color;
  final Color container;
  final Color onContainer;
  final Color border;

  const StatusTone({
    required this.color,
    required this.container,
    required this.onContainer,
    required this.border,
  });

  static StatusTone lerp(StatusTone a, StatusTone b, double t) => StatusTone(
        color: Color.lerp(a.color, b.color, t)!,
        container: Color.lerp(a.container, b.container, t)!,
        onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
        border: Color.lerp(a.border, b.border, t)!,
      );
}

/// Semantic status colors for attendance states, exposed as a [ThemeExtension]
/// so they adapt to light/dark themes. Access via `context.status`.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final StatusTone success;
  final StatusTone warning;
  final StatusTone danger;
  final StatusTone info;
  final StatusTone neutral;

  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutral,
  });

  static const light = AppStatusColors(
    success: StatusTone(
      color: AppPalette.emerald500,
      container: AppPalette.emerald50,
      onContainer: AppPalette.emerald700,
      border: AppPalette.emerald200,
    ),
    warning: StatusTone(
      color: AppPalette.amber500,
      container: AppPalette.amber50,
      onContainer: AppPalette.amber700,
      border: AppPalette.amber200,
    ),
    danger: StatusTone(
      color: AppPalette.red500,
      container: AppPalette.red50,
      onContainer: AppPalette.red700,
      border: AppPalette.red200,
    ),
    info: StatusTone(
      color: AppPalette.blue600,
      container: AppPalette.blue50,
      onContainer: AppPalette.blue800,
      border: AppPalette.blue200,
    ),
    neutral: StatusTone(
      color: AppPalette.slate400,
      container: AppPalette.slate100,
      onContainer: AppPalette.slate600,
      border: AppPalette.slate200,
    ),
  );

  static const dark = AppStatusColors(
    success: StatusTone(
      color: AppPalette.emerald500,
      container: AppPalette.emerald950,
      onContainer: AppPalette.emerald300,
      border: AppPalette.emerald900,
    ),
    warning: StatusTone(
      color: AppPalette.amber500,
      container: AppPalette.amber950,
      onContainer: AppPalette.amber300,
      border: AppPalette.amber900,
    ),
    danger: StatusTone(
      color: AppPalette.red500,
      container: AppPalette.red950,
      onContainer: AppPalette.red300,
      border: AppPalette.red900,
    ),
    info: StatusTone(
      color: AppPalette.blue400,
      container: AppPalette.blue950,
      onContainer: AppPalette.blue300,
      border: AppPalette.blue900,
    ),
    neutral: StatusTone(
      color: AppPalette.slate500,
      container: AppPalette.slate800,
      onContainer: AppPalette.slate300,
      border: AppPalette.slate700,
    ),
  );

  @override
  AppStatusColors copyWith({
    StatusTone? success,
    StatusTone? warning,
    StatusTone? danger,
    StatusTone? info,
    StatusTone? neutral,
  }) =>
      AppStatusColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        neutral: neutral ?? this.neutral,
      );

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: StatusTone.lerp(success, other.success, t),
      warning: StatusTone.lerp(warning, other.warning, t),
      danger: StatusTone.lerp(danger, other.danger, t),
      info: StatusTone.lerp(info, other.info, t),
      neutral: StatusTone.lerp(neutral, other.neutral, t),
    );
  }
}

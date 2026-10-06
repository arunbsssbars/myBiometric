import 'package:flutter/material.dart';

import 'app_status_colors.dart';
import 'app_tokens.dart';

export 'app_palette.dart';
export 'app_status_colors.dart';
export 'app_theme.dart';
export 'app_tokens.dart';
export 'components/ds_components.dart';
export 'theme_notifier.dart';

/// Ergonomic accessors for design tokens.
extension DesignSystemContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppStatusColors get status =>
      Theme.of(this).extension<AppStatusColors>() ??
      (Theme.of(this).brightness == Brightness.dark ? AppStatusColors.dark : AppStatusColors.light);
  WindowSizeClass get windowSize => AppBreakpoints.of(MediaQuery.sizeOf(this).width);
}

extension ColorSchemeDesignTokens on ColorScheme {
  Color get border => outlineVariant;
  Color get borderSubtle => outlineVariant;
  Color get textPrimary => onSurface;
  Color get textSecondary => onSurfaceVariant;
  Color get textInverse => onInverseSurface;
}


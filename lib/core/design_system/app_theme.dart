import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_status_colors.dart';
import 'app_tokens.dart';

/// Builds the light and dark [ThemeData] for myBiometric.
///
/// Surface roles used across the app:
/// * `scaffoldBackgroundColor` — page background.
/// * `colorScheme.surface` — cards, sheets, dialogs.
/// * `colorScheme.surfaceContainerLow` — inset panels inside cards, input fills.
/// * `colorScheme.surfaceContainer` — unselected chips, subtle tracks.
/// * `colorScheme.outlineVariant` — card / panel borders and dividers.
abstract final class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppPalette.blue600,
          onPrimary: Colors.white,
          primaryContainer: AppPalette.blue50,
          onPrimaryContainer: AppPalette.blue800,
          secondary: AppPalette.slate600,
          onSecondary: Colors.white,
          secondaryContainer: AppPalette.slate100,
          onSecondaryContainer: AppPalette.slate800,
          tertiary: AppPalette.indigo500,
          onTertiary: Colors.white,
          error: AppPalette.red600,
          onError: Colors.white,
          errorContainer: AppPalette.red50,
          onErrorContainer: AppPalette.red700,
          surface: Colors.white,
          onSurface: AppPalette.slate900,
          onSurfaceVariant: AppPalette.slate500,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: AppPalette.slate50,
          surfaceContainer: AppPalette.slate100,
          surfaceContainerHigh: AppPalette.slate200,
          surfaceContainerHighest: AppPalette.slate300,
          outline: AppPalette.slate400,
          outlineVariant: AppPalette.slate200,
          inverseSurface: AppPalette.slate800,
          onInverseSurface: AppPalette.slate50,
          inversePrimary: AppPalette.blue300,
          shadow: Colors.black,
          scrim: Colors.black,
        ),
        scaffold: AppPalette.slate50,
        status: AppStatusColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppPalette.blue400,
          onPrimary: AppPalette.slate950,
          primaryContainer: AppPalette.blue900,
          onPrimaryContainer: AppPalette.blue100,
          secondary: AppPalette.slate300,
          onSecondary: AppPalette.slate900,
          secondaryContainer: AppPalette.slate700,
          onSecondaryContainer: AppPalette.slate100,
          tertiary: AppPalette.indigo500,
          onTertiary: Colors.white,
          error: AppPalette.red300,
          onError: AppPalette.red950,
          errorContainer: AppPalette.red900,
          onErrorContainer: AppPalette.red200,
          surface: AppPalette.slate900,
          onSurface: AppPalette.slate50,
          onSurfaceVariant: AppPalette.slate400,
          surfaceContainerLowest: AppPalette.slate950,
          surfaceContainerLow: AppPalette.slate800,
          surfaceContainer: AppPalette.slate800,
          surfaceContainerHigh: AppPalette.slate700,
          surfaceContainerHighest: AppPalette.slate600,
          outline: AppPalette.slate500,
          outlineVariant: AppPalette.slate700,
          inverseSurface: AppPalette.slate100,
          onInverseSurface: AppPalette.slate900,
          inversePrimary: AppPalette.blue600,
          shadow: Colors.black,
          scrim: Colors.black,
        ),
        scaffold: AppPalette.slate950,
        status: AppStatusColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required AppStatusColors status,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.brMd);
    const buttonMinSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonMinSize,
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonMinSize,
          elevation: 0,
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonMinSize,
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape, minimumSize: buttonMinSize),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(scheme.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary,
        labelStyle: base.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }
}

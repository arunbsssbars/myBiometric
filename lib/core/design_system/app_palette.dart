import 'package:flutter/material.dart';

/// Raw color ramps for the myBiometric brand.
///
/// These values are the ONLY place hex literals are allowed. Widgets must
/// never reference [AppPalette] directly — use `Theme.of(context).colorScheme`
/// or [AppStatusColors] via `context.colors` / `context.status` instead.
abstract final class AppPalette {
  // Brand (blue)
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue300 = Color(0xFF93C5FD);
  static const blue400 = Color(0xFF60A5FA);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue800 = Color(0xFF1E40AF);
  static const blue900 = Color(0xFF1E3A8A);
  static const blue950 = Color(0xFF172554);

  // Neutral (slate)
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  // Absolute Neutrals
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // Success (emerald)
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald500 = Color(0xFF10B981);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);
  static const emerald950 = Color(0xFF022C22);

  // Warning (amber)
  static const amber50 = Color(0xFFFFFBEB);
  static const amber200 = Color(0xFFFDE68A);
  static const amber300 = Color(0xFFFCD34D);
  static const amber500 = Color(0xFFF59E0B);
  static const amber700 = Color(0xFFB45309);
  static const amber900 = Color(0xFF78350F);
  static const amber950 = Color(0xFF451A03);

  // Danger (red)
  static const red50 = Color(0xFFFEF2F2);
  static const red200 = Color(0xFFFECACA);
  static const red300 = Color(0xFFFCA5A5);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red900 = Color(0xFF7F1D1D);
  static const red950 = Color(0xFF450A0A);

  // Info (sky)
  static const sky50 = Color(0xFFF0F9FF);
  static const sky200 = Color(0xFFBAE6FD);
  static const sky300 = Color(0xFF7DD3FC);
  static const sky700 = Color(0xFF0369A1);
  static const sky900 = Color(0xFF0C4A6E);
  static const sky950 = Color(0xFF082F49);

  // Accent (indigo)
  static const indigo500 = Color(0xFF6366F1);
}

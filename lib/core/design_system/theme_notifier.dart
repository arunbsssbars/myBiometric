import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the application's [ThemeMode] preference.
class AppThemeNotifier extends ChangeNotifier {
  AppThemeNotifier._();
  static final AppThemeNotifier instance = AppThemeNotifier._();

  static const String _prefKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Loads the persisted theme mode from [SharedPreferences].
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (_) {
      // Fallback to system default if SharedPreferences is unavailable (e.g. tests)
      _themeMode = ThemeMode.system;
    }
  }

  /// Updates and persists the current [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'system';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {
      // Best-effort persistence
    }
  }

  /// Resets to default system mode in tests.
  @visibleForTesting
  void resetForTesting([ThemeMode mode = ThemeMode.system]) {
    _themeMode = mode;
    notifyListeners();
  }
}

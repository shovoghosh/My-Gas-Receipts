import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Three-way theme mode: light, dark, or follow-system.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  ThemeProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    _mode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
    notifyListeners();
  }

  /// Backwards-compat helper used by the original Dark Mode switch.
  Future<void> toggleTheme() async {
    await setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

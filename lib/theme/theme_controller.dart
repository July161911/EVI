import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'dark_mode';

  bool _isDark = false;
  bool _isLoaded = false;

  bool get isDark => _isDark;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  /// Updates UI immediately; persistence runs in the background.
  void setDarkMode(bool value) {
    if (_isDark == value) {
      return;
    }
    _isDark = value;
    notifyListeners();
    unawaited(_persist(value));
  }

  void toggle() => setDarkMode(!_isDark);

  Future<void> _persist(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}

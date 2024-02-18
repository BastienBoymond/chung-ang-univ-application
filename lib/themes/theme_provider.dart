import 'package:cau_app_dev/themes/light_theme.dart';
import 'package:cau_app_dev/themes/dark_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = lightTheme;
  static const _themeKey = 'selectedTheme';

  ThemeData get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> reloadTheme() async {
    await _loadTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'Light';
    if (themeName == 'Dark') {
      _currentTheme = darkTheme;
    } else {
      _currentTheme = lightTheme;
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeData theme) async {
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (theme == lightTheme) {
      await prefs.setString(_themeKey, 'Light');
    } else {
      await prefs.setString(_themeKey, 'Dark');
    }
  }
}

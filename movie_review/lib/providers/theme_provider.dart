import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  Color _themeColor = const Color(0xFFFFD700);
  Color _backgroundColor = const Color(0xFF050714);

  Color get themeColor => _themeColor;
  Color get backgroundColor => _backgroundColor;

  void toggleThemeMode() {
    if (_backgroundColor == const Color(0xFF050714)) {
      _backgroundColor = const Color(0xFFF0F0F0);
      _themeColor = const Color(0xFF0056D2);
    } else {
      _backgroundColor = const Color(0xFF050714);
      _themeColor = const Color(0xFFFFD700);
    }
    notifyListeners();
  }
}

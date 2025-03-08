import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode
      ? ThemeData.dark().copyWith(
          primaryColor: Color(0xFF0D47A1),
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF1E88E5),
            secondary: Color(0xFF00ACC1),
          ),
        )
      : ThemeData.light().copyWith(
          primaryColor: Colors.blue[700],
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            secondary: Colors.lightBlue,
          ),
        );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
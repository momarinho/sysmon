import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, system }

class AppThemeNotifier extends ChangeNotifier {
  late ThemeData _themeData;
  AppTheme _currentTheme = AppTheme.dark;
  bool _isSystemTheme = true;

  AppThemeNotifier() {
    _themeData = _getThemeData(AppTheme.dark);
  }

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme => _currentTheme;
  bool get isSystemTheme => _isSystemTheme;

  void setTheme(AppTheme theme) {
    _currentTheme = theme;

    if (_isSystemTheme) {
      _themeData = _getThemeData(theme);
    } else {
      _themeData = _getThemeData(AppTheme.dark);
    }

    notifyListeners();
  }

  void setSystemTheme(bool value) {
    _isSystemTheme = value;

    if (_isSystemTheme) {
      // Get system theme
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final effectiveTheme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
      _themeData = _getThemeData(effectiveTheme);
      _currentTheme = effectiveTheme;
    } else {
      _themeData = _getThemeData(_currentTheme);
    }

    notifyListeners();
  }

  ThemeData _getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return _lightTheme();
      case AppTheme.dark:
      default:
        return _darkTheme();
    }
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00D4AA),
        secondary: const Color(0xFF00D4AA),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF0A0A0A),
        error: const Color(0xFFEF4444),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black..withValues(alpha:0.3),
      ),
      dividerColor: Colors.grey..withValues(alpha:0.3),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
        bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
        titleLarge: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
        labelLarge: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00D4AA),
          side: const BorderSide(color: Color(0xFF00D4AA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        hintStyle: TextStyle(color: Colors.white38, fontFamily: 'Roboto'),
        labelStyle: TextStyle(color: Colors.white54, fontFamily: 'Roboto'),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF00D4AA);
          }
          return Colors.white54;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF00D4AA)..withValues(alpha:0.3);
          }
          return Colors.white24;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return Colors.white24;
        }),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF00D4AA),
        secondary: const Color(0xFF00D4AA),
        surface: const Color(0xFFFFFFFF),
        background: const Color(0xFFF5F5F5),
        error: const Color(0xFFEF4444),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black..withValues(alpha:0.1),
      ),
      dividerColor: Colors.grey..withValues(alpha:0.3),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.black87, fontFamily: 'Roboto'),
        bodyLarge: TextStyle(color: Colors.black87, fontFamily: 'Roboto'),
        titleLarge: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
        labelLarge: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actionsIconTheme: const IconThemeData(color: Colors.black54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00D4AA),
          side: const BorderSide(color: Color(0xFF00D4AA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black38),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        hintStyle: TextStyle(color: Colors.black45, fontFamily: 'Roboto'),
        labelStyle: TextStyle(color: Colors.black54, fontFamily: 'Roboto'),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF00D4AA);
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF00D4AA)..withValues(alpha:0.3);
          }
          return Colors.black38;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return Colors.black38;
        }),
      ),
    );
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('app_theme') ?? 2; // 2 = system theme
    final systemTheme = prefs.getBool('system_theme') ?? true;

    _isSystemTheme = systemTheme;
    _currentTheme = AppTheme.values[themeIndex];

    if (systemTheme) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _currentTheme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    }

    _themeData = _getThemeData(_currentTheme);
    notifyListeners();
  }

  Future<void> saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', AppTheme.values.indexOf(_currentTheme));
    await prefs.setBool('system_theme', _isSystemTheme);
  }

  Future<void> toggleTheme() async {
    if (_isSystemTheme) {
      // Cycle: system -> light -> dark -> system
      if (_currentTheme == AppTheme.light) {
        setTheme(AppTheme.dark);
      } else if (_currentTheme == AppTheme.dark) {
        setTheme(AppTheme.light);
      } else {
        setSystemTheme(false);
        setTheme(AppTheme.light);
      }
    } else {
      // Cycle: light -> dark -> light
      if (_currentTheme == AppTheme.light) {
        setTheme(AppTheme.dark);
      } else {
        setTheme(AppTheme.light);
      }
    }
    await saveTheme();
  }
}
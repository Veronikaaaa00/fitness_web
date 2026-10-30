import 'package:flutter/material.dart';

/// Спокойная серая тема: сланец + почти-белый фон.
abstract final class AppTheme {
  static const slate50 = Color(0xFFF4F5F7);
  static const slate100 = Color(0xFFE8EAEE);
  static const slate200 = Color(0xFFD1D5DB);
  static const slate400 = Color(0xFF9CA3AF);
  static const slate600 = Color(0xFF4B5563);
  static const slate800 = Color(0xFF1F2937);
  static const slate900 = Color(0xFF111827);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: slate800,
      onPrimary: Colors.white,
      primaryContainer: slate200,
      onPrimaryContainer: slate900,
      secondary: slate600,
      onSecondary: Colors.white,
      secondaryContainer: slate100,
      onSecondaryContainer: slate800,
      tertiary: slate600,
      onTertiary: Colors.white,
      error: Color(0xFFB42318),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE4E2),
      onErrorContainer: Color(0xFF7A271A),
      surface: slate50,
      onSurface: slate900,
      surfaceContainerHighest: slate100,
      onSurfaceVariant: slate600,
      outline: slate400,
      outlineVariant: slate200,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: slate800,
      onInverseSurface: slate50,
      inversePrimary: slate200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: slate50,
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: slate200,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? slate900 : slate600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? slate900 : slate600,
            size: 22,
          );
        }),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        indicatorColor: slate100,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: slate200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: slate800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: slate800,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: slate200, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slate800, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: slate600,
        textColor: slate900,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: slate800,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}

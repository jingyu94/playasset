import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4C8DFF),
      onPrimary: Colors.white,
      secondary: Color(0xFF4C8DFF),
      onSecondary: Colors.white,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: Color(0xFF111A2B),
      onSurface: Color(0xFFF8FAFF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF090F1A),
      brightness: Brightness.dark,
      fontFamily: 'NotoSansKR',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFFF3F6FF),
        displayColor: const Color(0xFFF3F6FF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111A2B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1E2A43)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D1524),
        indicatorColor: const Color(0x264C8DFF),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? const Color(0xFFDDE8FF) : const Color(0xFF7F8CA5),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF141F33),
        hintStyle: const TextStyle(color: Color(0xFF7F8CA5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF243450)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF243450)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4C8DFF), width: 1.3),
        ),
      ),
      dividerColor: const Color(0xFF243450),
    );
  }
}

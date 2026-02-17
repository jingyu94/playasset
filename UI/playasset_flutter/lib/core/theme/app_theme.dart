import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF4E7FA3),
      onPrimary: Colors.white,
      secondary: Color(0xFF4FAE9A),
      onSecondary: Colors.white,
      error: Color(0xFFD92D50),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF132231),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4FAF8),
      brightness: Brightness.light,
      fontFamily: 'NotoSansKR',
    );

    final readableTextTheme = base.textTheme
        .apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
          fontSizeFactor: 1.03,
        )
        .copyWith(
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
            height: 1.34,
            fontSize: 17,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
            height: 1.32,
            fontSize: 15,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
            height: 1.28,
            fontSize: 13,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.03,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.03,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.02,
            fontSize: 17,
          ),
        );

    return base.copyWith(
      textTheme: readableTextTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFFFCFFFE),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFD7E9E3)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF8FCFB),
        indicatorColor: const Color(0x264FAE9A),
        height: 60,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? const Color(0xFF2D637E) : const Color(0xFF627985),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 13,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F9F6),
        hintStyle: const TextStyle(color: Color(0xFF69817E)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7E9E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7E9E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4E7FA3), width: 1.3),
        ),
      ),
      dividerColor: const Color(0xFFD7E9E3),
    );
  }

  static ThemeData darkTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5D86D9),
      onPrimary: Colors.white,
      secondary: Color(0xFF6AA0D8),
      onSecondary: Colors.white,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: Color(0xFF111A2B),
      onSurface: Color(0xFFF8FAFF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF050B14),
      brightness: Brightness.dark,
      fontFamily: 'NotoSansKR',
    );

    final readableTextTheme = base.textTheme
        .apply(
          bodyColor: const Color(0xFFF2F6FF),
          displayColor: const Color(0xFFF2F6FF),
          fontSizeFactor: 1.03,
        )
        .copyWith(
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
            height: 1.34,
            fontSize: 17,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
            height: 1.32,
            fontSize: 15,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
            height: 1.28,
            fontSize: 13,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.03,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.03,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.02,
            fontSize: 17,
          ),
        );

    return base.copyWith(
      textTheme: readableTextTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF0D1626),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFF22314B)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A1322),
        indicatorColor: const Color(0x2A5D86D9),
        height: 60,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? const Color(0xFFE4EDFF) : const Color(0xFF9AA8C2),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 13,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1A2E),
        hintStyle: const TextStyle(color: Color(0xFF93A2BF)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3B59)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3B59)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5D86D9), width: 1.3),
        ),
      ),
      dividerColor: const Color(0xFF2A3B59),
    );
  }
}

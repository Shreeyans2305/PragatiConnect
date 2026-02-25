import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData lightTheme([bool isHindi = false]) {
    final base = ThemeData.light();
    final textTheme = isHindi
        ? GoogleFonts.notoSansDevanagariTextTheme(base.textTheme)
        : GoogleFonts.dmSansTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: Colors.white,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
        outline: Colors.grey.shade300,
      ),
      textTheme: _buildTextTheme(textTheme, isDark: false),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle:
            (isHindi ? GoogleFonts.notoSansDevanagari() : GoogleFonts.dmSans())
                .copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPadding.cardRadius),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData darkTheme([bool isHindi = false]) {
    final base = ThemeData.dark();
    final textTheme = isHindi
        ? GoogleFonts.notoSansDevanagariTextTheme(base.textTheme)
        : GoogleFonts.dmSansTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF6AAFD4),
        secondary: const Color(0xFF8EC5E0),
        tertiary: const Color(0xFF9CD5FF),
        surface: const Color(0xFF1C1C1E),
        onSurface: Colors.white,
        onPrimary: Colors.white,
        outline: Colors.white.withValues(alpha: 0.12),
      ),
      textTheme: _buildTextTheme(textTheme, isDark: true),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        titleTextStyle:
            (isHindi ? GoogleFonts.notoSansDevanagari() : GoogleFonts.dmSans())
                .copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPadding.cardRadius),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          borderSide: const BorderSide(color: Color(0xFF6AAFD4), width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6AAFD4),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ─── Shared text theme builder ────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base, {required bool isDark}) {
    final primary = isDark ? Colors.white : AppColors.textPrimary;
    final secondary = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.textSecondary;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        color: primary,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: primary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        color: secondary,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        color: secondary,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, color: secondary),
    );
  }
}

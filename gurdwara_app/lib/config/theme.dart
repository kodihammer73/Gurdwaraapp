import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _blue = Color(0xFF1E5AA8);
const Color _blueLight = Color(0xFF6EA3F1);
const Color _green = Color(0xFF2E8B57);
const Color _greenLight = Color(0xFF7BCB8A);
const Color _red = Color(0xFFC94B4B);
const Color _cream = Color(0xFFFBF8F1);
const Color _creamAlt = Color(0xFFF0E7D6);
const Color _charcoal = Color(0xFF1D1A17);
const Color _charcoalLight = Color(0xFF2C2824);
const Color _stone = Color(0xFFD4C8B8);
const Color _white = Color(0xFFFFFFFF);

class AppTheme {
  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scheme: ColorScheme.light(
      primary: _blue,
      onPrimary: _white,
      primaryContainer: const Color(0xFFD9E7FB),
      onPrimaryContainer: _blue,
      secondary: _green,
      onSecondary: _white,
      secondaryContainer: const Color(0xFFD8F0DF),
      onSecondaryContainer: _green,
      tertiary: _red,
      onTertiary: _white,
      tertiaryContainer: const Color(0xFFF7DADA),
      onTertiaryContainer: _red,
      error: const Color(0xFFC62828),
      onError: _white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410E0B),
      surface: _white,
      onSurface: _charcoal,
      surfaceContainerHighest: _creamAlt,
      outline: _stone,
      outlineVariant: const Color(0xFFB9AA95),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _charcoal,
      onInverseSurface: _cream,
      inversePrimary: _blueLight,
    ),
    scaffoldBackgroundColor: _cream,
    appBarBackgroundColor: _cream,
    cardColor: _white,
    cardBorderColor: _stone,
    navSelectedColor: _blue,
    navUnselectedColor: const Color(0xFF66707A),
    navBackgroundColor: _white,
    navIndicatorColor: const Color(0xFFD9E7FB),
  );

  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scheme: ColorScheme.dark(
      primary: _blueLight,
      onPrimary: _charcoal,
      primaryContainer: const Color(0xFF183D6E),
      onPrimaryContainer: const Color(0xFFD9E7FB),
      secondary: _greenLight,
      onSecondary: _charcoal,
      secondaryContainer: const Color(0xFF214F37),
      onSecondaryContainer: const Color(0xFFD8F0DF),
      tertiary: const Color(0xFFF08C8C),
      onTertiary: _charcoal,
      tertiaryContainer: const Color(0xFF6A2525),
      onTertiaryContainer: const Color(0xFFF7DADA),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: _charcoal,
      onSurface: _cream,
      surfaceContainerHighest: _charcoalLight,
      outline: const Color(0xFF7A6F62),
      outlineVariant: const Color(0xFF5D5449),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _cream,
      onInverseSurface: _charcoal,
      inversePrimary: _blue,
    ),
    scaffoldBackgroundColor: _charcoal,
    appBarBackgroundColor: _charcoalLight,
    cardColor: _charcoalLight,
    cardBorderColor: const Color(0xFF665A4C),
    navSelectedColor: _blueLight,
    navUnselectedColor: const Color(0xFFC8BFB2),
    navBackgroundColor: _charcoalLight,
    navIndicatorColor: const Color(0xFF183D6E),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBackgroundColor,
    required Color appBarBackgroundColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color navSelectedColor,
    required Color navUnselectedColor,
    required Color navBackgroundColor,
    required Color navIndicatorColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: appBarBackgroundColor,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackgroundColor,
        indicatorColor: navIndicatorColor,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => GoogleFonts.inter(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? navSelectedColor
                : navUnselectedColor,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? navSelectedColor
                : navUnselectedColor,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 1 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderColor),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _charcoalLight : _white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: GoogleFonts.inter(
          color: scheme.onSurface.withValues(alpha: 0.65),
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.inter(
          color: scheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.2,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.2,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
          height: 1.6,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface.withValues(alpha: 0.75),
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0.3,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 16,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _charcoalLight : _creamAlt,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        selectedColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? _charcoalLight : _white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
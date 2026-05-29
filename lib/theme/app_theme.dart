import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  // =========================
  // NOTHING STYLE COLORS
  // =========================

  static const Color primary = Color(0xFF0A0A0A);
  static const Color primaryDark = Color(0xFFFFFFFF);

  // Accent
  static const Color accent = Color(0xFFFF3B0A);

  // Status Colors
  static const Color warningAmber = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF453A);
  static const Color successGreen = Color(0xFF30D158);

  // Light Theme
  static const Color border = Color(0xFFE5E5E5);
  static const Color muted = Color(0xFFF5F5F5);

  // Dark Theme
  static const Color darkBorder = Color(0xFF1F1F1F);
  static const Color darkMuted = Color(0xFF111111);

  // Extra Colors
  static const Color cardDark = Color(0xFF151515);
  static const Color backgroundDark = Color(0xFF050505);
  static const Color softWhite = Color(0xFFF8F8F8);

  // =========================
  // SHADCN LIGHT
  // =========================

  static ShadThemeData shadLightTheme() {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadZincColorScheme.light(
        primary: primary,
        background: Colors.white,
        foreground: Color(0xFF09090B),
      ),
    );
  }

  // =========================
  // SHADCN DARK
  // =========================

  static ShadThemeData shadDarkTheme() {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadZincColorScheme.dark(
        primary: primaryDark,
        background: backgroundDark,
        foreground: softWhite,
      ),
    );
  }

  // =========================
  // LIGHT THEME
  // =========================

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      error: errorRed,
      surface: Colors.white,
    );

    return _materialTheme(
      colorScheme: colorScheme,
      scaffold: const Color(0xFFF8F8F8),
      surface: Colors.white,
      borderColor: border,
      mutedColor: muted,
      foreground: const Color(0xFF09090B),
      subtleForeground: const Color(0xFF71717A),
      selectedNavigation: accent.withOpacity(0.12),
      brightness: Brightness.light,
    );
  }

  // =========================
  // DARK THEME
  // =========================

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accent,
      secondary: accent,
      error: errorRed,
      surface: cardDark,
    );

    return _materialTheme(
      colorScheme: colorScheme,
      scaffold: backgroundDark,
      surface: cardDark,
      borderColor: darkBorder,
      mutedColor: darkMuted,
      foreground: softWhite,
      subtleForeground: const Color(0xFFA1A1AA),
      selectedNavigation: accent.withOpacity(0.15),
      brightness: Brightness.dark,
    );
  }

  // =========================
  // MAIN MATERIAL THEME
  // =========================

  static ThemeData _materialTheme({
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color surface,
    required Color borderColor,
    required Color mutedColor,
    required Color foreground,
    required Color subtleForeground,
    required Color selectedNavigation,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // GLOBAL FONT
      fontFamily: GoogleFonts.inter().fontFamily,

      scaffoldBackgroundColor: scaffold,

      // =========================
      // APP BAR
      // =========================
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: foreground,
        ),
      ),

      // =========================
      // CARD
      // =========================
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // =========================
      // INPUT
      // =========================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(borderColor),
        enabledBorder: _inputBorder(borderColor),
        focusedBorder: _inputBorder(accent, width: 1.5),
        errorBorder: _inputBorder(errorRed),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: subtleForeground),
      ),

      // =========================
      // ELEVATED BUTTON
      // =========================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
        ),
      ),

      // =========================
      // OUTLINED BUTTON
      // =========================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // =========================
      // TEXT BUTTON
      // =========================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // =========================
      // CHIP
      // =========================
      chipTheme: ChipThemeData(
        backgroundColor: mutedColor,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),

      // =========================
      // FAB
      // =========================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // =========================
      // NAVIGATION BAR
      // =========================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: selectedNavigation,
        elevation: 0,
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,

        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent, size: 24);
          }

          return IconThemeData(color: subtleForeground, size: 22);
        }),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: accent);
          }

          return GoogleFonts.inter(fontSize: 11, color: subtleForeground);
        }),
      ),

      // =========================
      // DIVIDER
      // =========================
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),

      // =========================
      // LIST TILE
      // =========================
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6)),

      // =========================
      // SWITCH
      // =========================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : null),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent.withOpacity(0.3) : null,
        ),
      ),

      // =========================
      // SNACKBAR
      // =========================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: foreground,
        contentTextStyle: GoogleFonts.inter(color: scaffold, fontSize: 14),
      ),

      // =========================
      // TEXT THEME
      // =========================
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: foreground,
        ),

        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: foreground,
        ),

        headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: foreground),

        titleLarge: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: foreground),

        titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),

        titleSmall: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: foreground),

        bodyLarge: GoogleFonts.spaceGrotesk(fontSize: 16, height: 1.5, color: foreground),

        bodyMedium: GoogleFonts.spaceGrotesk(fontSize: 14, height: 1.4, color: foreground),

        bodySmall: GoogleFonts.spaceGrotesk(fontSize: 12, height: 1.4, color: subtleForeground),

        labelLarge: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: foreground),

        labelMedium: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: foreground),

        labelSmall: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: subtleForeground),
      ),
    );
  }

  // =========================
  // INPUT BORDER
  // =========================

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

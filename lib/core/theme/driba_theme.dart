import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'driba_colors.dart';

/// Driba OS Theme
/// Premium Glass OS Design System
class DribaTheme {
  DribaTheme._();

  /// Main dark theme for Driba OS
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colors
      scaffoldBackgroundColor: DribaColors.background,
      primaryColor: DribaColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: DribaColors.primary,
        secondary: DribaColors.secondary,
        tertiary: DribaColors.tertiary,
        surface: DribaColors.surface,
        background: DribaColors.background,
        error: DribaColors.error,
        onPrimary: DribaColors.textInverse,
        onSecondary: DribaColors.textInverse,
        onSurface: DribaColors.textPrimary,
        onBackground: DribaColors.textPrimary,
        onError: DribaColors.textPrimary,
      ),
      
      // Typography
      textTheme: _textTheme,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DribaColors.textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: DribaColors.textPrimary,
          size: 24,
        ),
      ),
      
      // Bottom Navigation (though we use custom dock)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: DribaColors.primary,
        unselectedItemColor: DribaColors.textTertiary,
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: DribaColors.glassFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          side: const BorderSide(
            color: DribaColors.glassBorder,
            width: 1,
          ),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DribaColors.primary,
          foregroundColor: DribaColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DribaColors.primary,
          side: const BorderSide(color: DribaColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DribaColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DribaColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          borderSide: const BorderSide(color: DribaColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          borderSide: const BorderSide(color: DribaColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          borderSide: const BorderSide(color: DribaColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          borderSide: const BorderSide(color: DribaColors.error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: DribaColors.textTertiary,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: DribaColors.textSecondary,
          fontSize: 14,
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: DribaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
          side: const BorderSide(color: DribaColors.glassBorder),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DribaColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 16,
          color: DribaColors.textSecondary,
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DribaBorderRadius.xxl),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DribaColors.surface,
        contentTextStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: DribaColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          side: const BorderSide(color: DribaColors.glassBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: DribaColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      
      // Icon
      iconTheme: const IconThemeData(
        color: DribaColors.textPrimary,
        size: 24,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: DribaColors.primary,
        inactiveTrackColor: DribaColors.glassFillActive,
        thumbColor: DribaColors.primary,
        overlayColor: DribaColors.primary20,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return DribaColors.primary;
          }
          return DribaColors.textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return DribaColors.primary40;
          }
          return DribaColors.glassFillActive;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return DribaColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(DribaColors.textInverse),
        side: const BorderSide(color: DribaColors.glassBorderHighlight, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DribaColors.primary,
        linearTrackColor: DribaColors.glassFillActive,
        circularTrackColor: DribaColors.glassFillActive,
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Text theme with Space Grotesk
  static TextTheme get _textTheme {
    return const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: DribaColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: DribaColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: DribaColors.textPrimary,
      ),
      
      // Headlines
      headlineLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: DribaColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: DribaColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: DribaColors.textPrimary,
      ),
      
      // Titles
      titleLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: DribaColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: DribaColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: DribaColors.textPrimary,
      ),
      
      // Body
      bodyLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: DribaColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: DribaColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: DribaColors.textSecondary,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DribaColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DribaColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DribaColors.textSecondary,
      ),
    );
  }

  /// Get text theme directly
  static TextTheme get textTheme => _textTheme;
}

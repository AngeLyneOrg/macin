import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

abstract class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        outline: AppColors.border,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      // Injecte Plus Jakarta Sans dans tout le TextTheme Material
      textTheme: GoogleFonts.ubuntuTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.ubuntu(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8),
        displayMedium: GoogleFonts.ubuntu(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: GoogleFonts.ubuntu(fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.ubuntu(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.ubuntu(fontSize: 11, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.ubuntu(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        centerTitle: false,
        toolbarHeight: AppDimensions.appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: AppDimensions.iconLg),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.ubuntu(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.ubuntu(fontSize: 10, fontWeight: FontWeight.w400),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.ubuntu(fontSize: 14, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.ubuntu(fontSize: 14, color: AppColors.textTertiary),
        errorStyle: GoogleFonts.ubuntu(fontSize: 12, color: AppColors.error),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primarySurface,
        labelStyle: GoogleFonts.ubuntu(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.ubuntu(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        linearMinHeight: AppDimensions.xpBarHeight,
      ),
    );
  }

  static ThemeData dark() {
    return light().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles typographiques MACIN — Police : Ubuntu
///
/// Ubuntu est une police humaniste sans-serif, très lisible sur mobile,
/// avec un caractère chaleureux et moderne qui correspond à
/// l'identité "tech accessible" de MACIN.
///
/// Usage : AppTextStyles.heading1 dans n'importe quel widget.
/// Jamais de TextStyle inline dans les widgets.
abstract class AppTextStyles {
  // ── Display (hero, splash) ────────────────────────────────
  static TextStyle get display1 => GoogleFonts.ubuntu(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      );

  static TextStyle get display2 => GoogleFonts.ubuntu(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  // ── Headings ─────────────────────────────────────────────
  static TextStyle get heading1 => GoogleFonts.ubuntu(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ── Body ─────────────────────────────────────────────────
  static TextStyle get body1 => GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get body2 => GoogleFonts.ubuntu(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.textSecondary,
      );

  static TextStyle get body1Medium => GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  // ── Labels ────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.ubuntu(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.ubuntu(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.ubuntu(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.3,
      );

  // ── Captions ─────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.ubuntu(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  static TextStyle get captionMedium => GoogleFonts.ubuntu(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ── Boutons ──────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      );

  static TextStyle get buttonSmall => GoogleFonts.ubuntu(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  // ── Code (éditeur de code) ────────────────────────────────
  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  // ── Numéro de niveau / XP (gamification) ─────────────────
  static TextStyle get xpNumber => GoogleFonts.ubuntu(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: AppColors.accent,
        letterSpacing: -0.5,
      );
}

import 'package:flutter/material.dart';

/// Palette de couleurs officielle de MACIN.
///
/// Toute l'application référence ces constantes — jamais de
/// couleur codée en dur dans les widgets.
abstract class AppColors {
  // ── Primaire (Bleu MACIN) ─────────────────────────────────
  static const Color primary = Color(0xFF013BFF);
  static const Color primaryLight = Color(0xFF547BFF);
  static const Color primaryDark = Color(0xFF0029B3);
  static const Color primarySurface = Color(0xFFE6ECFF);

  // ── Secondaire (Violet — gamification / badges) ──────────
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondarySurface = Color(0xFFF3EEFF);

  // ── Accent (Orange — XP / récompenses) ───────────────────
  static const Color accent = Color(0xFFFF7B00);
  static const Color accentLight = Color(0xFFFFB259);
  static const Color accentSurface = Color(0xFFFFF3E5);

  // ── Succès ────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successSurface = Color(0xFFE8F9EF);

  // ── Erreur ────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorSurface = Color(0xFFFFECEC);

  // ── Avertissement ────────────────────────────────────────
  static const Color warning = Color(0xFFD97706);
  static const Color warningSurface = Color(0xFFFFFBEB);

  // ── Information (bleu cyan — explications, notes) ────────
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSurface = Color(0xFFE0F5FF);

  // ── IA / Tutorat ─────────────────────────────────────────
  static const Color aiPrimary = Color(0xFF0EA5E9);
  static const Color aiSurface = Color(0xFFE0F5FF);

  // ── Code (blocs code leçon / exercice) ───────────────────
  /// Fond sombre des blocs de code (inspiré Catppuccin Mocha).
  static const Color codeBackground = Color(0xFF1E1E2E);

  /// Bordure des blocs de code.
  static const Color codeBorder = Color(0xFF313244);

  /// Couleur du texte dans les blocs de code.
  static const Color codeText = Color(0xFFCDD6F4);

  // ── Neutres (Light mode) ─────────────────────────────────
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F7);

  // ── Textes ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Raretés des badges ───────────────────────────────────
  static const Color rarityCommon = Color(0xFF64748B);
  static const Color rarityRare = Color(0xFF2563EB);
  static const Color rarityEpic = Color(0xFF7C3AED);
  static const Color rarityLegendary = Color(0xFFD97706);

  // ── Dark mode ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);
}
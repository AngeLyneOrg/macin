import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extensions
// ─────────────────────────────────────────────────────────────────────────────

extension ContextX on BuildContext {
  // Thème
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Taille d'écran
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  bool get isSmallScreen => screenWidth < 360;

  // Navigation
  // void pop<T>([T? result]) => Navigator.of(this).pop(result);

  // SnackBar helpers
  void showSuccessSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.successLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textInverse)),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textInverse)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void showInfoSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message,
            style:
                AppTextStyles.body2.copyWith(color: AppColors.textInverse)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// String extensions
// ─────────────────────────────────────────────────────────────────────────────

extension StringX on String {
  /// Capitalise la première lettre uniquement.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Tronque à [maxLength] caractères et ajoute '…'.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  /// Vérifie si c'est une adresse email valide.
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Vérifie si c'est un mot de passe assez fort (6+ caractères).
  bool get isValidPassword => length >= 6;

  /// Retourne les initiales (ex: "Jean Dupont" → "JD").
  String get initials {
    final parts = trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// DateTime extensions
// ─────────────────────────────────────────────────────────────────────────────

extension DateTimeX on DateTime {
  /// Retourne "il y a 3 jours", "il y a 2 heures", etc.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
    return 'il y a ${(diff.inDays / 365).floor()} an(s)';
  }

  /// Format court : "16 juin 2025"
  String get formatted {
    const months = [
      '', 'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '$day ${months[month]} $year';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// int extensions
// ─────────────────────────────────────────────────────────────────────────────

extension IntX on int {
  /// Formate les durées en minutes : 90 → "1h 30min", 45 → "45min"
  String get asDuration {
    if (this < 60) return '${this}min';
    final h = this ~/ 60;
    final m = this % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  /// Formate les montants FCFA : 15000 → "15 000 FCFA"
  String get asFcfa {
    final formatted = toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$formatted FCFA';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// double extensions
// ─────────────────────────────────────────────────────────────────────────────

extension DoubleX on double {
  /// Calcule le niveau XP depuis le score brut (0.0 à 1.0 → 0% à 100%)
  String get asPercent => '${(this * 100).round()}%';

  /// Formate un montant double en FCFA
  String get asFcfa => toInt().asFcfa;
}

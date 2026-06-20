

import 'package:macin/core/constants/app_constants.dart' show AppConstants;

/// Utilitaires pour le système de progression XP / niveaux de MACIN.
///
/// Utilisé par les widgets [XpProgressBar] et [ProfilePage],
/// et par les Cloud Functions pour calculer les badges.
abstract class XpUtils {
  /// Calcule le niveau actuel depuis l'XP total.
  /// Niveau 1 = 0 à 199 XP, Niveau 2 = 200 à 399 XP, etc.
  static int levelFromXp(int xp) {
    return (xp / AppConstants.xpPerLevel).floor() + 1;
  }

  /// XP total requis pour atteindre le [level].
  static int xpRequiredForLevel(int level) {
    return (level - 1) * AppConstants.xpPerLevel;
  }

  /// XP total requis pour atteindre le niveau suivant depuis [currentXp].
  static int xpForNextLevel(int currentXp) {
    final currentLevel = levelFromXp(currentXp);
    return xpRequiredForLevel(currentLevel + 1);
  }

  /// XP déjà accumulé dans le niveau actuel (pour la barre de progression).
  ///
  /// Exemple : 250 XP total → niveau 2, 50 XP dans ce niveau.
  static int xpInCurrentLevel(int xp) {
    final level = levelFromXp(xp);
    return xp - xpRequiredForLevel(level);
  }

  /// Progression dans le niveau actuel entre 0.0 et 1.0.
  ///
  /// Utilisé directement par [LinearProgressIndicator].
  static double progressInCurrentLevel(int xp) {
    final inLevel = xpInCurrentLevel(xp).toDouble();
    return inLevel / AppConstants.xpPerLevel;
  }

  /// XP restant pour passer au niveau suivant.
  static int xpToNextLevel(int xp) {
    return AppConstants.xpPerLevel - xpInCurrentLevel(xp);
  }

  /// Nom du niveau sous forme de titre (gamification).
  static String levelTitle(int level) {
    return switch (level) {
      1 => 'Débutant',
      2 => 'Apprenti',
      3 => 'Développeur',
      4 => 'Confirmé',
      5 => 'Expert',
      6 => 'Senior',
      7 => 'Architecte',
      8 => 'Lead Dev',
      9 => 'Principal',
      _ => level >= 10 ? 'Maître MACIN' : 'Débutant',
    };
  }

  /// Emoji associé au niveau (affiché dans le leaderboard).
  static String levelEmoji(int level) {
    return switch (level) {
      1 => '🌱',
      2 => '🔥',
      3 => '⚡',
      4 => '🚀',
      5 => '💡',
      6 => '🏆',
      7 => '🎯',
      8 => '💎',
      9 => '👑',
      _ => level >= 10 ? '🌟' : '🌱',
    };
  }
}

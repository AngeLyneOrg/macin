import 'dart:math';

/// Utilitaires pour le système de parrainage de MACIN.
abstract class ReferralUtils {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  // Exclut les caractères ambigus : I, O, 0, 1

  /// Génère un code de parrainage unique de 8 caractères.
  ///
  /// Format : XXXX-XXXX (lisible, facile à partager).
  /// Exemple : "MAC4-K9RZ"
  ///
  /// Note : l'unicité finale est vérifiée côté Firestore au moment
  /// de la création du compte (Issue #17).
  static String generateCode() {
    final rng = Random.secure();
    final part1 = List.generate(4, (_) => _chars[rng.nextInt(_chars.length)]).join();
    final part2 = List.generate(4, (_) => _chars[rng.nextInt(_chars.length)]).join();
    return '$part1-$part2';
  }

  /// Normalise un code saisi par l'utilisateur (majuscules, trim).
  static String normalizeCode(String input) {
    return input.trim().toUpperCase().replaceAll(' ', '');
  }

  /// Valide le format d'un code (8 caractères alphanumériques + tiret).
  static bool isValidFormat(String code) {
    return RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code);
  }

  /// Calcule la commission d'un parrain en FCFA.
  static double calculateCommission(double coursePrice, double rate) {
    return coursePrice * rate;
  }

  /// Message de partage du code de parrainage.
  static String shareMessage(String code, String userName) {
    return '''
👋 Salut ! Je t'invite sur MACIN, la plateforme pour apprendre le développement logiciel.

Utilise mon code de parrainage pour t'inscrire et on gagnera tous les deux des avantages :

🎯 Mon code : $code

📱 Télécharge MACIN et commence à coder dès aujourd'hui !
''';
  }
}

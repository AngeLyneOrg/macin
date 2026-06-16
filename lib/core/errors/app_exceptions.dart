/// Exceptions typées de MACIN.
///
/// Chaque repository et service doit catcher les exceptions Firebase
/// et les re-lancer sous forme d'[AppException] pour que les widgets
/// puissent afficher des messages clairs à l'utilisateur.

/// Exception de base de l'application.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException[$code]: $message';
}

/// Erreurs liées à l'authentification Firebase.
class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  factory AuthException.fromFirebase(String code) {
    return switch (code) {
      'user-not-found' =>
        const AuthException(message: 'Aucun compte avec cet email.', code: 'user-not-found'),
      'wrong-password' =>
        const AuthException(message: 'Mot de passe incorrect.', code: 'wrong-password'),
      'email-already-in-use' =>
        const AuthException(message: 'Cet email est déjà utilisé.', code: 'email-already-in-use'),
      'weak-password' =>
        const AuthException(message: 'Mot de passe trop faible (6 caractères minimum).', code: 'weak-password'),
      'invalid-email' =>
        const AuthException(message: 'Adresse email invalide.', code: 'invalid-email'),
      'network-request-failed' =>
        const AuthException(message: 'Pas de connexion internet.', code: 'network-request-failed'),
      'too-many-requests' =>
        const AuthException(message: 'Trop de tentatives. Réessayez plus tard.', code: 'too-many-requests'),
      _ =>
        AuthException(message: 'Erreur d\'authentification : $code', code: code),
    };
  }
}

/// Erreurs liées à Firestore (lecture / écriture).
class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.code});
}

/// Erreurs liées au stockage (Cloudflare R2 / Firebase Storage).
class StorageException extends AppException {
  const StorageException({required super.message, super.code});
}

/// Erreurs liées au réseau / API FastAPI.
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

/// Ressource introuvable dans Firestore.
class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.code});
}

/// L'utilisateur n'a pas les droits pour effectuer cette action.
class PermissionException extends AppException {
  const PermissionException({
    super.message = 'Vous n\'avez pas les droits pour effectuer cette action.',
    super.code = 'permission-denied',
  });
}

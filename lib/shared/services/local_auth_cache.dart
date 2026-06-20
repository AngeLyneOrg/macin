import 'package:hive_flutter/hive_flutter.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/shared/models/user_model.dart';


/// Cache local du profil utilisateur connecté (étudiant ou formateur).
///
/// Pourquoi : Firebase Auth garde déjà la session entre les lancements
/// de l'app (token persistant), mais le **profil Firestore** (rôle, XP,
/// badges, cours inscrits) doit être re-téléchargé à chaque démarrage —
/// ce qui échoue si le réseau est mauvais ou Firestore indisponible.
///
/// [LocalAuthCache] garde une copie du dernier [UserModel] connu dans
/// une box Hive locale. La [SplashPage] et le [AppRouter] peuvent donc
/// décider de l'écran à afficher même hors-ligne, et l'UI peut afficher
/// les données en cache immédiatement pendant que le [StreamBuilder]
/// Firestore se resynchronise en arrière-plan.
///
/// Ce n'est PAS un système d'auth — Firebase Auth reste la seule source
/// de vérité pour "qui est connecté". C'est un cache de confort pour
/// le profil métier (rôle, XP, etc.).
class LocalAuthCache {
  static const String _boxName = AppConstants.hiveBoxSettings;
  static const String _keyUserData = 'cached_user_profile';
  static const String _keyUid = 'cached_uid';
  static const String _keyRole = 'cached_role';

  static Box? _box;

  /// À appeler une fois dans `main()`, après `Hive.initFlutter()`.
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'LocalAuthCache.init() doit être appelé avant toute utilisation.',
      );
    }
    return _box!;
  }

  /// Sauvegarde le profil utilisateur après une connexion réussie
  /// ou une mise à jour Firestore.
  static Future<void> saveUser(UserModel user) async {
    await _safeBox.put(_keyUid, user.uid);
    await _safeBox.put(_keyRole, user.role);
    await _safeBox.put(_keyUserData, user.toMap());
  }

  /// Récupère le dernier profil connu en local (peut être null si
  /// jamais connecté ou cache vidé).
  static UserModel? getCachedUser() {
    final uid = _safeBox.get(_keyUid) as String?;
    final data = _safeBox.get(_keyUserData) as Map?;
    if (uid == null || data == null) return null;

    try {
      return UserModel.fromCachedMap(uid, Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// Rôle en cache, accessible sans désérialiser tout le profil.
  /// Utile dans le routeur pour une redirection rapide.
  static String? getCachedRole() => _safeBox.get(_keyRole) as String?;

  static String? getCachedUid() => _safeBox.get(_keyUid) as String?;

  /// Efface le cache — appelé à la déconnexion.
  static Future<void> clear() async {
    await _safeBox.delete(_keyUid);
    await _safeBox.delete(_keyRole);
    await _safeBox.delete(_keyUserData);
  }

  static bool get hasCachedSession => getCachedUid() != null;
}

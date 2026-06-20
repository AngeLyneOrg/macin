import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/models/user_model.dart';


/// Repository des utilisateurs.
///
/// Toutes les interactions Firestore liées à la collection `users`
/// passent par ici. Les widgets ne touchent jamais Firestore directement.
///
/// Principe :
///   - Les méthodes [watch*] retournent des [Stream] → utilisés dans [StreamBuilder]
///   - Les méthodes [get*] retournent des [Future] → utilisés dans [FutureBuilder]
///   - Les méthodes [update*] / [create*] retournent [Future<void>]
class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConstants.colUsers);

  // ── Streams (pour StreamBuilder) ──────────────────────────

  /// Écoute en temps réel le profil d'un utilisateur.
  ///
  /// Utilisé dans : [ProfilePage], [MainScaffold] (badge wallet),
  /// [WalletPage] (solde), [BadgeGrid].
  ///
  /// Toute modification Firestore (XP gagné, badge octroyé, solde crédité)
  /// se propage automatiquement sans rechargement manuel.
  Stream<UserModel> watchUser(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) throw NotFoundException(message: 'Utilisateur introuvable');
      return UserModel.fromFirestore(doc);
    });
  }

  /// Écoute les transactions du wallet en temps réel.
  ///
  /// Utilisé dans : [WalletPage] section historique.
  Stream<List<TransactionModel>> watchTransactions(String uid) {
    return _col
        .doc(uid)
        .collection(AppConstants.subColTransactions)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.notificationsPageSize)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
  }

  /// Écoute les notifications non lues en temps réel.
  ///
  /// Utilisé dans : [NotificationCenter] et badge sur cloche dans AppBar.
  Stream<List<Map<String, dynamic>>> watchUnreadNotifications(String uid) {
    return _col
        .doc(uid)
        .collection(AppConstants.subColNotifications)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()..['id'] = d.id).toList());
  }

  // ── Futures (pour FutureBuilder / appels ponctuels) ───────

  /// Récupère le profil une seule fois (pas de mise à jour temps réel).
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture profil : $e');
    }
  }

  /// Vérifie si un code de parrainage existe dans Firestore.
  ///
  /// Utilisé dans [RegisterPage] pour valider le code en temps réel.
  Future<String?> getReferrerIdByCode(String referralCode) async {
    try {
      final query = await _col
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first.id; // retourne l'UID du parrain
    } catch (e) {
      throw DatabaseException(message: 'Erreur vérification code parrainage : $e');
    }
  }

  // ── Mutations ─────────────────────────────────────────────

  /// Crée le profil utilisateur lors de l'inscription.
  Future<void> createUser({
    required String uid,
    required String displayName,
    required String email,
    required String referralCode,
    String? photoUrl,
    String? referredBy,
  }) async {
    try {
      await _col.doc(uid).set(UserModel.initialData(
            uid: uid,
            displayName: displayName,
            email: email,
            referralCode: referralCode,
            photoUrl: photoUrl,
            referredBy: referredBy,
          ));
    } catch (e) {
      throw DatabaseException(message: 'Erreur création profil : $e');
    }
  }

  /// Met à jour les champs modifiables du profil.
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (data.isEmpty) return;
      await _col.doc(uid).update(data);
    } catch (e) {
      throw DatabaseException(message: 'Erreur mise à jour profil : $e');
    }
  }

  /// Ajoute un cours à la liste des cours inscrits.
  /// Appelé après un achat validé.
  Future<void> enrollInCourse(String uid, String courseId) async {
    try {
      await _col.doc(uid).update({
        'enrolledCourseIds': FieldValue.arrayUnion([courseId]),
      });
    } catch (e) {
      throw DatabaseException(message: 'Erreur inscription cours : $e');
    }
  }

  /// Ajoute un badge (appelé par Cloud Function, mais disponible ici aussi).
  Future<void> addBadge(String uid, String badgeId) async {
    try {
      await _col.doc(uid).update({
        'badgeIds': FieldValue.arrayUnion([badgeId]),
      });
    } catch (e) {
      throw DatabaseException(message: 'Erreur ajout badge : $e');
    }
  }

  /// Met à jour le score de risque IA (appelé après réception de FastAPI).
  Future<void> updateAiRiskScore(
      String uid, String courseId, double score) async {
    try {
      final progressId = UserProgressModel.buildId(uid, courseId);
      await _db
          .collection(AppConstants.colUserProgress)
          .doc(progressId)
          .update({'aiRiskScore': score});
    } catch (e) {
      throw DatabaseException(message: 'Erreur mise à jour score IA : $e');
    }
  }

  /// Marque toutes les notifications comme lues.
  Future<void> markAllNotificationsRead(String uid) async {
    try {
      final batch = _db.batch();
      final snap = await _col
          .doc(uid)
          .collection(AppConstants.subColNotifications)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw DatabaseException(message: 'Erreur marquage notifications : $e');
    }
  }
}

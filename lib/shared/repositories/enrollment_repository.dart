import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EnrollmentRepository
//
// Centralise toute la logique d'inscription d'un étudiant à un cours.
//
// Une inscription implique 3 opérations atomiques (batch Firestore) :
//   1. Ajouter courseId dans users/{uid}.enrolledCourseIds
//   2. Créer le document user_progress/{uid}_{courseId}
//   3. Enregistrer la transaction dans users/{uid}/transactions/{txId}
//
// L'attribution de l'XP de bienvenue et la notification sont gérées
// par la Cloud Function `onEnrollmentCreated` côté backend.
// ─────────────────────────────────────────────────────────────────────────────

class EnrollmentRepository {
  final FirebaseFirestore _db;

  EnrollmentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Vérifications ─────────────────────────────────────────

  /// Vérifie si un utilisateur est déjà inscrit à un cours.
  ///
  /// Utilisé dans [CourseDetailPage] pour afficher le bon CTA
  /// ("S'inscrire" vs "Continuer").
  Future<bool> isEnrolled(String userId, String courseId) async {
    try {
      final doc =
          await _db.collection(AppConstants.colUsers).doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      final enrolled = List<String>.from(data['enrolledCourseIds'] as List? ?? []);
      return enrolled.contains(courseId);
    } catch (e) {
      throw DatabaseException(message: 'Erreur vérification inscription : $e');
    }
  }

  // ── Inscription ───────────────────────────────────────────

  /// Inscrit un utilisateur à un cours gratuit.
  ///
  /// Pour les cours payants, l'inscription se fait après validation
  /// du paiement (côté Cloud Function) — ce méthode ne gère que le
  /// cas gratuit (price == 0).
  ///
  /// [courseTitle] est utilisé pour la description de la transaction.
  Future<void> enrollFree({
    required String userId,
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      final batch = _db.batch();
      final progressId = '${userId}_$courseId';

      // 1. Ajouter le cours dans enrolledCourseIds
      batch.update(
        _db.collection(AppConstants.colUsers).doc(userId),
        {
          'enrolledCourseIds': FieldValue.arrayUnion([courseId]),
        },
      );

      // 2. Créer le document de progression (seulement s'il n'existe pas)
      batch.set(
        _db.collection(AppConstants.colUserProgress).doc(progressId),
        {
          'userId': userId,
          'courseId': courseId,
          'completedLessonIds': [],
          'completedExerciseIds': [],
          'exerciseScores': {},
          'progressPercent': 0.0,
          'lastAccessedAt': FieldValue.serverTimestamp(),
          'certificateEarned': false,
          'certificateUrl': null,
          'aiRiskScore': null,
        },
        SetOptions(merge: true),
      );

      // 3. Enregistrer la transaction (montant 0 pour les cours gratuits)
      final txRef = _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.subColTransactions)
          .doc();
      batch.set(txRef, {
        'type': 'debit',
        'amount': 0.0,
        'description': 'Inscription : $courseTitle',
        'reference': courseId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw DatabaseException(message: 'Erreur inscription cours gratuit : $e');
    }
  }

  /// Inscrit un utilisateur à un cours payant après validation du paiement.
  ///
  /// [transactionReference] : ID de la transaction de paiement externe
  ///                          (Orange Money, MTN MoMo, etc.)
  Future<void> enrollPaid({
    required String userId,
    required String courseId,
    required String courseTitle,
    required double amount,
    required String transactionReference,
  }) async {
    try {
      final batch = _db.batch();
      final progressId = '${userId}_$courseId';

      // 1. Ajouter le cours + déduire du wallet
      batch.update(
        _db.collection(AppConstants.colUsers).doc(userId),
        {
          'enrolledCourseIds': FieldValue.arrayUnion([courseId]),
          'walletBalance': FieldValue.increment(-amount),
        },
      );

      // 2. Créer le document de progression
      batch.set(
        _db.collection(AppConstants.colUserProgress).doc(progressId),
        {
          'userId': userId,
          'courseId': courseId,
          'completedLessonIds': [],
          'completedExerciseIds': [],
          'exerciseScores': {},
          'progressPercent': 0.0,
          'lastAccessedAt': FieldValue.serverTimestamp(),
          'certificateEarned': false,
          'certificateUrl': null,
          'aiRiskScore': null,
        },
        SetOptions(merge: true),
      );

      // 3. Enregistrer la transaction avec référence de paiement
      final txRef = _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.subColTransactions)
          .doc();
      batch.set(txRef, {
        'type': 'debit',
        'amount': amount,
        'description': 'Achat : $courseTitle',
        'reference': transactionReference,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw DatabaseException(message: 'Erreur inscription cours payant : $e');
    }
  }

  // ── Désinscription ────────────────────────────────────────

  /// Récupère tous les courseIds auxquels un utilisateur est inscrit.
  ///
  /// Utilisé dans [MyCoursesPage] pour charger les cours inscrits
  /// avec leur progression respective.
  Future<List<String>> getEnrolledCourseIds(String userId) async {
    try {
      final doc =
          await _db.collection(AppConstants.colUsers).doc(userId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['enrolledCourseIds'] as List? ?? []);
    } catch (e) {
      throw DatabaseException(
          message: 'Erreur lecture cours inscrits : $e');
    }
  }
}

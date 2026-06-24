import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/exercise_attempt_model.dart';
import 'package:macin/shared/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProgressRepository  ← VERSION ENRICHIE
//
// Ajouts par rapport à la version précédente :
//   • saveAttempt()   : crée un document dans la sous-collection attempts/
//   • watchAttempts() : écoute l'historique des tentatives d'un exercice
//   • getBestScore()  : récupère le meilleur score historique
// ─────────────────────────────────────────────────────────────────────────────

class ProgressRepository {
  final FirebaseFirestore _db;

  ProgressRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _progress =>
      _db.collection(AppConstants.colUserProgress);

  // ── Streams ───────────────────────────────────────────────

  /// Écoute la progression d'un étudiant sur un cours.
  ///
  /// C'est le stream le plus important de l'app :
  /// [CourseDetailPage], [LessonProgressTracker], [AiRiskBanner]
  /// et le bouton "Continuer" l'écoutent tous en temps réel.
  Stream<UserProgressModel?> watchProgress(String userId, String courseId) {
    final progressId = UserProgressModel.buildId(userId, courseId);
    return _progress.doc(progressId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProgressModel.fromFirestore(doc);
    });
  }

  /// Écoute toutes les progressions d'un étudiant.
  ///
  /// Utilisé dans : [HomePage] section "Mes cours en cours".
  Stream<List<UserProgressModel>> watchAllProgress(String userId) {
    return _progress
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserProgressModel.fromFirestore(d)).toList());
  }

  /// Écoute l'historique des tentatives d'un exercice pour un étudiant.
  ///
  /// Sous-collection : user_progress/{progressId}/attempts/
  /// Utilisé dans [ExerciseResultPage] pour afficher l'historique.
  Stream<List<ExerciseAttemptModel>> watchAttempts({
    required String userId,
    required String courseId,
    required String exerciseId,
  }) {
    final progressId = UserProgressModel.buildId(userId, courseId);
    return _progress
        .doc(progressId)
        .collection(AppConstants.subColAttempts)
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExerciseAttemptModel.fromFirestore(d))
            .toList());
  }

  // ── Futures / Mutations ───────────────────────────────────

  /// Initialise la progression lors de l'inscription à un cours.
  Future<void> initProgress(String userId, String courseId) async {
    try {
      final progressId = UserProgressModel.buildId(userId, courseId);
      final doc = await _progress.doc(progressId).get();
      if (!doc.exists) {
        await _progress
            .doc(progressId)
            .set(UserProgressModel.initialData(userId, courseId));
      }
    } catch (e) {
      throw DatabaseException(
          message: 'Erreur initialisation progression : $e');
    }
  }

  /// Marque une leçon comme terminée et met à jour la progression %.
  ///
  /// Utilise [FieldValue.arrayUnion] pour éviter les doublons.
  Future<void> completeLesson({
    required String userId,
    required String courseId,
    required String lessonId,
    required int totalLessons,
    required int xpReward,
  }) async {
    try {
      final progressId = UserProgressModel.buildId(userId, courseId);
      final doc = await _progress.doc(progressId).get();
      final current =
          doc.exists ? UserProgressModel.fromFirestore(doc) : null;

      final completed = {
        ...?current?.completedLessonIds,
        lessonId,
      }.toList();

      final percent =
          totalLessons > 0 ? (completed.length / totalLessons) * 100 : 0.0;

      await _progress.doc(progressId).set({
        'userId': userId,
        'courseId': courseId,
        'completedLessonIds': FieldValue.arrayUnion([lessonId]),
        'progressPercent': percent,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // La Cloud Function onProgressWrite attribue l'XP et les badges.
    } catch (e) {
      throw DatabaseException(message: 'Erreur complétion leçon : $e');
    }
  }

  /// Enregistre le score d'un exercice et marque comme complété si réussi.
  ///
  /// Crée aussi un document dans la sous-collection [attempts/] pour
  /// l'historique et l'analyse IA.
  Future<void> submitExercise({
    required String userId,
    required String courseId,
    required String exerciseId,
    required String exerciseType,
    required int score,
    required int passingScore,
    required Map<String, String> answers,
    required int durationSeconds,
  }) async {
    try {
      final progressId = UserProgressModel.buildId(userId, courseId);
      final passed = score >= passingScore;

      final batch = _db.batch();

      // 1. Mettre à jour le document de progression principal
      final progressUpdates = <String, dynamic>{
        'exerciseScores.$exerciseId': score,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      };
      if (passed) {
        progressUpdates['completedExerciseIds'] =
            FieldValue.arrayUnion([exerciseId]);
      }
      batch.set(
        _progress.doc(progressId),
        progressUpdates,
        SetOptions(merge: true),
      );

      // 2. Créer le document de tentative dans la sous-collection
      final attemptRef = _progress
          .doc(progressId)
          .collection(AppConstants.subColAttempts)
          .doc();
      batch.set(attemptRef, {
        'userId': userId,
        'courseId': courseId,
        'exerciseId': exerciseId,
        'exerciseType': exerciseType,
        'answers': answers,
        'score': score,
        'passingScore': passingScore,
        'passed': passed,
        'durationSeconds': durationSeconds,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw DatabaseException(
          message: 'Erreur soumission exercice : $e');
    }
  }

  /// Récupère le meilleur score enregistré pour un exercice.
  ///
  /// Utilisé dans [ExerciseRunner] pour afficher le badge "Meilleur score"
  /// et bloquer une nouvelle tentative si déjà certifié.
  Future<int?> getBestScore({
    required String userId,
    required String courseId,
    required String exerciseId,
  }) async {
    try {
      final progressId = UserProgressModel.buildId(userId, courseId);
      final snap = await _progress
          .doc(progressId)
          .collection(AppConstants.subColAttempts)
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('score', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['score'] as int?;
    } catch (e) {
      return null;
    }
  }
}

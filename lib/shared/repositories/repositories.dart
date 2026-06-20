import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/course_model.dart';
import 'package:macin/shared/models/exercise_model.dart';
import 'package:macin/shared/models/lesson_model.dart';
import 'package:macin/shared/models/models.dart';



// ─────────────────────────────────────────────────────────────────────────────
// CourseRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Repository des cours, modules, leçons et exercices.
class CourseRepository {
  final FirebaseFirestore _db;

  CourseRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _courses => _db.collection(AppConstants.colCourses);

  // ── Streams ───────────────────────────────────────────────

  /// Écoute tous les cours publiés en temps réel.
  ///
  /// Utilisé dans : [CourseCatalogPage] — l'AnimatedList se met à jour
  /// automatiquement quand un cours est ajouté ou modifié par un formateur.
  Stream<List<CourseModel>> watchPublishedCourses({
    String? levelFilter,
    String? tagFilter,
  }) {
    Query query = _courses.where('isPublished', isEqualTo: true);
    if (levelFilter != null) query = query.where('level', isEqualTo: levelFilter);
    if (tagFilter != null) query = query.where('tags', arrayContains: tagFilter);
    query = query.orderBy('createdAt', descending: true)
        .limit(AppConstants.coursesPageSize);

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => CourseModel.fromFirestore(d)).toList(),
    );
  }

  /// Écoute les cours d'un formateur spécifique.
  ///
  /// Utilisé dans : [InstructorDashboard].
  Stream<List<CourseModel>> watchInstructorCourses(String instructorId) {
    return _courses
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  /// Écoute les modules d'un cours en temps réel.
  ///
  /// Utilisé dans : [CourseDetailPage] — les ExpansionTiles se mettent à jour
  /// si le formateur ajoute un module pendant qu'un étudiant visite la page.
  Stream<List<ModuleModel>> watchModules(String courseId) {
    return _courses
        .doc(courseId)
        .collection(AppConstants.colModules)
        .orderBy('order')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => ModuleModel.fromFirestore(d)).toList());
  }

  /// Écoute les leçons d'un module.
  Stream<List<LessonModel>> watchLessons(String courseId, String moduleId) {
    return _courses
        .doc(courseId)
        .collection(AppConstants.colModules)
        .doc(moduleId)
        .collection(AppConstants.colLessons)
        .orderBy('order')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => LessonModel.fromFirestore(d)).toList());
  }

  /// Écoute un cours spécifique en temps réel.
  ///
  /// Utilisé dans : [CourseDetailPage] — un changement de prix, de
  /// nombre de leçons, etc. fait par le formateur se reflète aussitôt,
  /// sans pull-to-refresh.
  Stream<CourseModel?> watchCourse(String courseId) {
    return _courses.doc(courseId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CourseModel.fromFirestore(doc);
    });
  }

  // ── Futures ───────────────────────────────────────────────

  /// Récupère un cours par son ID (lecture unique).
  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final doc = await _courses.doc(courseId).get();
      if (!doc.exists) return null;
      return CourseModel.fromFirestore(doc);
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture cours : $e');
    }
  }

  /// Recherche de cours par titre (recherche simple).
  ///
  /// Note : Firestore ne supporte pas le full-text search natif.
  /// Pour une v2, utiliser Algolia ou Firebase Extensions Search.
  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      final queryLower = query.toLowerCase();
      // Firestore trick : range query sur le titre pour simuler un "startsWith"
      final snap = await _courses
          .where('isPublished', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();
      return snap.docs
          .map((d) => CourseModel.fromFirestore(d))
          .where((c) => c.title.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      throw DatabaseException(message: 'Erreur recherche cours : $e');
    }
  }

  /// Récupère les leçons d'un module (lecture unique, ex: vérification offline).
  Future<List<LessonModel>> getLessons(
      String courseId, String moduleId) async {
    try {
      final snap = await _courses
          .doc(courseId)
          .collection(AppConstants.colModules)
          .doc(moduleId)
          .collection(AppConstants.colLessons)
          .orderBy('order')
          .get();
      return snap.docs.map((d) => LessonModel.fromFirestore(d)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture leçons : $e');
    }
  }

  /// Récupère les exercices d'un module.
  Future<List<ExerciseModel>> getExercises(
      String courseId, String moduleId) async {
    try {
      final snap = await _courses
          .doc(courseId)
          .collection(AppConstants.colModules)
          .doc(moduleId)
          .collection(AppConstants.colExercises)
          .orderBy('order')
          .get();
      return snap.docs.map((d) => ExerciseModel.fromFirestore(d)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture exercices : $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProgressRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Repository de la progression des étudiants.
///
/// La collection [user_progress] est centrale :
///   - Les widgets la lisent via Stream pour des mises à jour temps réel
///   - FastAPI y écrit [aiRiskScore] après analyse
///   - Les Cloud Functions y déclenchent les badges et certificats
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
  /// Utilisé dans : [HomePage] section "Mes cours en cours",
  /// et dans le dashboard formateur pour la vue globale.
  Stream<List<UserProgressModel>> watchAllProgress(String userId) {
    return _progress
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserProgressModel.fromFirestore(d)).toList());
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
      throw DatabaseException(message: 'Erreur initialisation progression : $e');
    }
  }

  /// Marque une leçon comme terminée et met à jour la progression %.
  ///
  /// Utilise [FieldValue.arrayUnion] pour éviter les doublons.
  /// Calcul du % basé sur [totalLessons] passé en paramètre.
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
      final current = doc.exists ? UserProgressModel.fromFirestore(doc) : null;

      final completed = {
        ...?current?.completedLessonIds,
        lessonId,
      }.toList();

      final percent = totalLessons > 0
          ? (completed.length / totalLessons) * 100
          : 0.0;

      await _progress.doc(progressId).set({
        'userId': userId,
        'courseId': courseId,
        'completedLessonIds': FieldValue.arrayUnion([lessonId]),
        'progressPercent': percent,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // La Cloud Function onProgressWrite se chargera d'attribuer l'XP et les badges.
    } catch (e) {
      throw DatabaseException(message: 'Erreur complétion leçon : $e');
    }
  }

  /// Enregistre le score d'un exercice et marque comme complété si réussi.
  Future<void> submitExercise({
    required String userId,
    required String courseId,
    required String exerciseId,
    required int score,
    required int passingScore,
  }) async {
    try {
      final progressId = UserProgressModel.buildId(userId, courseId);
      final passed = score >= passingScore;

      final updates = <String, dynamic>{
        'exerciseScores.$exerciseId': score,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      };

      if (passed) {
        updates['completedExerciseIds'] =
            FieldValue.arrayUnion([exerciseId]);
      }

      await _progress.doc(progressId).set(updates, SetOptions(merge: true));
    } catch (e) {
      throw DatabaseException(message: 'Erreur soumission exercice : $e');
    }
  }
}

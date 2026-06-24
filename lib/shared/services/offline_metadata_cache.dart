import 'package:hive_flutter/hive_flutter.dart';
import 'package:macin/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OfflineMetadataCache
//
// Petite couche Hive qui retient, PAR APPAREIL, quels fichiers (vidéos,
// PDFs, miniatures de cours) ont été téléchargés en local et où ils se
// trouvent sur le disque.
//
// Pourquoi pas dans Firestore (LessonModel.localPath) ?
// Le chemin local n'a aucun sens partagé entre appareils — un même compte
// peut être connecté sur deux téléphones, chacun avec son propre stockage.
// Ce cache est donc strictement local, dans la box Hive `downloads`
// (voir [AppConstants.hiveBoxDownloads]), ouverte une fois au démarrage.
// ─────────────────────────────────────────────────────────────────────────────
class OfflineMetadataCache {
  static const String _boxName = AppConstants.hiveBoxDownloads;
  static Box? _box;

  /// À appeler une fois dans `main()`, après `Hive.initFlutter()`.
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'OfflineMetadataCache.init() doit être appelé avant toute utilisation.',
      );
    }
    return _box!;
  }

  // ── Clés ──────────────────────────────────────────────────

  static String _lessonKey(String courseId, String lessonId) =>
      'lesson_${courseId}_$lessonId';

  static String _courseLessonsKey(String courseId) => 'course_lessons_$courseId';

  static String _thumbKey(String courseId) => 'thumb_$courseId';

  // ── Leçons téléchargées ───────────────────────────────────

  /// Enregistre le chemin local d'une leçon téléchargée (vidéo, PDF, article).
  static Future<void> setLessonLocalPath(
      String courseId, String lessonId, String localPath) async {
    await _safeBox.put(_lessonKey(courseId, lessonId), localPath);

    final key = _courseLessonsKey(courseId);
    final current = (_safeBox.get(key) as List?)?.cast<String>() ?? <String>[];
    if (!current.contains(lessonId)) {
      await _safeBox.put(key, [...current, lessonId]);
    }
  }

  /// Retourne le chemin local d'une leçon si elle a déjà été téléchargée
  /// sur CET appareil, sinon `null`.
  static String? getLessonLocalPath(String courseId, String lessonId) {
    return _safeBox.get(_lessonKey(courseId, lessonId)) as String?;
  }

  /// Supprime l'entrée locale d'une leçon (après suppression du fichier).
  static Future<void> removeLessonLocalPath(
      String courseId, String lessonId) async {
    await _safeBox.delete(_lessonKey(courseId, lessonId));

    final key = _courseLessonsKey(courseId);
    final current = (_safeBox.get(key) as List?)?.cast<String>() ?? <String>[];
    current.remove(lessonId);
    await _safeBox.put(key, current);
  }

  /// Liste des `lessonId` téléchargés pour un cours donné, sur cet appareil.
  static List<String> getDownloadedLessonIds(String courseId) {
    return (_safeBox.get(_courseLessonsKey(courseId)) as List?)
            ?.cast<String>() ??
        <String>[];
  }

  /// Vide toutes les entrées (leçons + miniature) d'un cours.
  static Future<void> clearCourse(String courseId) async {
    for (final lessonId in getDownloadedLessonIds(courseId)) {
      await _safeBox.delete(_lessonKey(courseId, lessonId));
    }
    await _safeBox.delete(_courseLessonsKey(courseId));
    await _safeBox.delete(_thumbKey(courseId));
  }

  // ── Miniature de cours (souscription / accès hors-ligne) ─

  static Future<void> setCourseThumbnailPath(
      String courseId, String localPath) async {
    await _safeBox.put(_thumbKey(courseId), localPath);
  }

  static String? getCourseThumbnailPath(String courseId) {
    return _safeBox.get(_thumbKey(courseId)) as String?;
  }
}

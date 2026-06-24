import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // ValueChanged
import 'package:path_provider/path_provider.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/lesson_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OfflineService
//
// Gère le téléchargement et la gestion locale des leçons PDF téléchargeables
// (LessonModel.isDownloadable == true).
//
// Les vidéos (MP4) ne sont PAS téléchargées ici — elles sont streamées
// directement depuis Cloudflare R2 via le lecteur vidéo.
// Seuls les PDFs (type == 'pdf') et les articles (type == 'article')
// peuvent être mis en cache local.
//
// Stockage local :
//   {appDocDir}/macin_offline/{courseId}/{lessonId}.pdf
//
// Usage :
//   final service = OfflineService();
//
//   // Télécharger un PDF
//   final path = await service.downloadLesson(
//     lesson: lesson,
//     onProgress: (percent) => setState(() => _progress = percent),
//   );
//
//   // Vérifier si disponible offline
//   final available = await service.isAvailableOffline(lesson);
//
//   // Supprimer du stockage local
//   await service.deleteLocal(lesson);
// ─────────────────────────────────────────────────────────────────────────────

class OfflineService {
  final Dio _dio;

  OfflineService({Dio? dio})
      : _dio = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));

  // ── Chemins ───────────────────────────────────────────────

  Future<Directory> _offlineDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/macin_offline');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _localPath(LessonModel lesson) async {
    final dir = await _offlineDir();
    final ext = lesson.isPdf ? 'pdf' : 'md';
    return '${dir.path}/${lesson.courseId}_${lesson.lessonId}.$ext';
  }

  // ── Téléchargement ────────────────────────────────────────

  /// Télécharge une leçon PDF et retourne son chemin local.
  ///
  /// [onProgress] : callback de progression (0.0 à 1.0)
  /// Retourne le [localPath] à sauvegarder dans [LessonModel.localPath]
  /// via [ProgressRepository] ou [LessonModel.copyWith].
  Future<String> downloadLesson({
    required LessonModel lesson,
    ValueChanged<double>? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!lesson.isDownloadable) {
      throw OfflineException(
          message: 'Cette leçon ne peut pas être téléchargée.');
    }
    if (lesson.contentUrl.isEmpty) {
      throw OfflineException(message: 'URL de la leçon introuvable.');
    }

    final path = await _localPath(lesson);

    try {
      await _dio.download(
        lesson.contentUrl,
        path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );
      return path;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Nettoyage si annulé
        final file = File(path);
        if (await file.exists()) await file.delete();
        throw OfflineException(message: 'Téléchargement annulé.');
      }
      throw OfflineException(
          message: 'Erreur téléchargement : ${e.message}');
    } catch (e) {
      throw OfflineException(message: 'Erreur inattendue : $e');
    }
  }

  /// Sauvegarde le contenu Markdown d'un article en local.
  ///
  /// Utilisé pour les leçons type 'article' — le contenu est déjà
  /// dans [LessonModel.articleContent], pas besoin de HTTP.
  Future<String> saveArticleLocally(LessonModel lesson) async {
    if (!lesson.isArticle) {
      throw OfflineException(message: 'Non applicable aux non-articles.');
    }
    final path = await _localPath(lesson);
    final file = File(path);
    await file.writeAsString(lesson.articleContent);
    return path;
  }

  // ── Vérifications ─────────────────────────────────────────

  /// Vérifie si une leçon est disponible localement.
  Future<bool> isAvailableOffline(LessonModel lesson) async {
    if (lesson.localPath == null) return false;
    final file = File(lesson.localPath!);
    return file.exists();
  }

  /// Retourne la taille du fichier local en octets (0 si inexistant).
  Future<int> localFileSizeBytes(LessonModel lesson) async {
    if (lesson.localPath == null) return 0;
    final file = File(lesson.localPath!);
    if (!await file.exists()) return 0;
    return file.lengthSync();
  }

  // ── Suppression ───────────────────────────────────────────

  /// Supprime le fichier local d'une leçon.
  ///
  /// Penser à appeler [LessonModel.copyWith(localPath: null)]
  /// pour mettre à jour le modèle après suppression.
  Future<void> deleteLocal(LessonModel lesson) async {
    if (lesson.localPath == null) return;
    final file = File(lesson.localPath!);
    if (await file.exists()) await file.delete();
  }

  /// Supprime tous les fichiers offline d'un cours.
  ///
  /// Utilisé lors de la désinscription ou du nettoyage du cache.
  Future<void> deleteCourseCache(String courseId) async {
    final dir = await _offlineDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains(courseId));
    for (final file in files) {
      await file.delete();
    }
  }

  /// Calcule la taille totale du cache offline en octets.
  Future<int> totalCacheSizeBytes() async {
    final dir = await _offlineDir();
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Vide tout le cache offline.
  Future<void> clearAllCache() async {
    final dir = await _offlineDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  void dispose() {
    _dio.close();
  }
}
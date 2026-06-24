import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/lesson_model.dart';
import 'package:macin/shared/services/offline_metadata_cache.dart';

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

  // ── Lecture du cache Hive ─────────────────────────────────

  /// Retourne le localPath persisté dans Hive si le fichier existe encore
  /// sur le disque, sinon nettoie l'entrée Hive et retourne null.
  Future<String?> resolveLocalPath(LessonModel lesson) async {
    final cached = OfflineMetadataCache.getLessonLocalPath(
        lesson.courseId, lesson.lessonId);
    if (cached == null) return null;

    final file = File(cached);
    if (await file.exists()) return cached;

    // Le fichier a été supprimé manuellement ou par le système → nettoyer Hive
    await OfflineMetadataCache.removeLessonLocalPath(
        lesson.courseId, lesson.lessonId);
    return null;
  }

  // ── Téléchargement ────────────────────────────────────────

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

      // ✅ Persister dans Hive — c'est ce qui manquait
      await OfflineMetadataCache.setLessonLocalPath(
          lesson.courseId, lesson.lessonId, path);

      return path;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
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

  Future<String> saveArticleLocally(LessonModel lesson) async {
    if (!lesson.isArticle) {
      throw OfflineException(message: 'Non applicable aux non-articles.');
    }
    final path = await _localPath(lesson);
    final file = File(path);
    await file.writeAsString(lesson.articleContent);

    // ✅ Persister dans Hive
    await OfflineMetadataCache.setLessonLocalPath(
        lesson.courseId, lesson.lessonId, path);

    return path;
  }

  // ── Vérifications ─────────────────────────────────────────

  Future<bool> isAvailableOffline(LessonModel lesson) async {
    final path = await resolveLocalPath(lesson);
    return path != null;
  }

  Future<int> localFileSizeBytes(LessonModel lesson) async {
    final path = await resolveLocalPath(lesson);
    if (path == null) return 0;
    return File(path).lengthSync();
  }

  // ── Suppression ───────────────────────────────────────────

  Future<void> deleteLocal(LessonModel lesson) async {
    final path =
        lesson.localPath ?? OfflineMetadataCache.getLessonLocalPath(
            lesson.courseId, lesson.lessonId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    // ✅ Nettoyer Hive
    await OfflineMetadataCache.removeLessonLocalPath(
        lesson.courseId, lesson.lessonId);
  }

  Future<void> deleteCourseCache(String courseId) async {
    final dir = await _offlineDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains(courseId));
    for (final file in files) {
      await file.delete();
    }
    await OfflineMetadataCache.clearCourse(courseId);
  }

  Future<int> totalCacheSizeBytes() async {
    final dir = await _offlineDir();
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clearAllCache() async {
    final dir = await _offlineDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  void dispose() {
    _dio.close();
  }
}
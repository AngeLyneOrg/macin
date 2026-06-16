import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ModuleModel
// Collection : courses/{courseId}/modules/{moduleId}
// ─────────────────────────────────────────────────────────────────────────────

class ModuleModel extends Equatable {
  final String moduleId;
  final String courseId;
  final String title;
  final int order;
  final int totalLessons;
  final int totalDurationMin;

  const ModuleModel({
    required this.moduleId,
    required this.courseId,
    required this.title,
    required this.order,
    required this.totalLessons,
    required this.totalDurationMin,
  });

  factory ModuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModuleModel(
      moduleId: doc.id,
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      totalLessons: data['totalLessons'] as int? ?? 0,
      totalDurationMin: data['totalDurationMin'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'title': title,
        'order': order,
        'totalLessons': totalLessons,
        'totalDurationMin': totalDurationMin,
      };

  @override
  List<Object?> get props =>
      [moduleId, courseId, title, order, totalLessons];
}

// ─────────────────────────────────────────────────────────────────────────────
// LessonModel
// Collection : courses/{courseId}/modules/{moduleId}/lessons/{lessonId}
// ─────────────────────────────────────────────────────────────────────────────

class LessonModel extends Equatable {
  final String lessonId;
  final String moduleId;
  final String courseId;
  final String title;

  /// 'video' | 'article' | 'pdf' | 'code_demo'
  final String type;

  /// URL Cloudflare R2 (pre-signed, générée par Cloud Function).
  /// Pour les types 'article', c'est le contenu Markdown directement.
  final String contentUrl;

  /// Chemin local si la leçon a été téléchargée pour l'offline.
  /// null si pas encore téléchargé.
  final String? localPath;

  final int durationMin;
  final bool isDownloadable;
  final bool isPreview; // accessible sans être inscrit (teaser)
  final int order;
  final int xpReward;

  const LessonModel({
    required this.lessonId,
    required this.moduleId,
    required this.courseId,
    required this.title,
    required this.type,
    required this.contentUrl,
    this.localPath,
    required this.durationMin,
    required this.isDownloadable,
    required this.isPreview,
    required this.order,
    required this.xpReward,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      lessonId: doc.id,
      moduleId: data['moduleId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? 'video',
      contentUrl: data['contentUrl'] as String? ?? '',
      localPath: data['localPath'] as String?,
      durationMin: data['durationMin'] as int? ?? 0,
      isDownloadable: data['isDownloadable'] as bool? ?? false,
      isPreview: data['isPreview'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
      xpReward: data['xpReward'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'moduleId': moduleId,
        'courseId': courseId,
        'title': title,
        'type': type,
        'contentUrl': contentUrl,
        'localPath': localPath,
        'durationMin': durationMin,
        'isDownloadable': isDownloadable,
        'isPreview': isPreview,
        'order': order,
        'xpReward': xpReward,
      };

  bool get isVideo => type == 'video';
  bool get isArticle => type == 'article';
  bool get isPdf => type == 'pdf';
  bool get isAvailableOffline => localPath != null;

  LessonModel copyWith({String? localPath}) {
    return LessonModel(
      lessonId: lessonId,
      moduleId: moduleId,
      courseId: courseId,
      title: title,
      type: type,
      contentUrl: contentUrl,
      localPath: localPath ?? this.localPath,
      durationMin: durationMin,
      isDownloadable: isDownloadable,
      isPreview: isPreview,
      order: order,
      xpReward: xpReward,
    );
  }

  @override
  List<Object?> get props =>
      [lessonId, moduleId, type, order, localPath, xpReward];
}

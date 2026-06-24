import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:macin/shared/models/block_model.dart';

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
// LessonModel  ← VERSION ENRICHIE
// Collection : courses/{courseId}/modules/{moduleId}/lessons/{lessonId}
//
// Champs ajoutés par rapport à la version précédente :
//   • articleContent : texte Markdown saisi dans l'admin (onglet "Contenu texte")
//   • blocks         : liste de BlockModel parsés depuis le JSON admin
//                      (onglet "Contenu enrichi avancé")
// ─────────────────────────────────────────────────────────────────────────────

class LessonModel extends Equatable {
  final String lessonId;
  final String moduleId;
  final String courseId;
  final String title;

  /// 'video' | 'article' | 'pdf' | 'code_demo'
  final String type;

  /// URL Cloudflare R2 pour les vidéos/PDFs.
  /// Vide pour les leçons de type 'article' (contenu dans [articleContent]).
  final String contentUrl;

  /// Chemin local si téléchargé en offline (null = pas encore téléchargé).
  final String? localPath;

  /// Contenu Markdown de la leçon — saisi via l'onglet "Contenu texte" de
  /// l'admin. Utilisé pour les articles et comme complément pédagogique des
  /// vidéos (notes de cours, transcription enrichie).
  final String articleContent;

  /// Blocs de contenu enrichi (heading, text, code, tip, warning, divider,
  /// image) — saisis via l'onglet "Contenu enrichi avancé" de l'admin.
  /// Flutter les rend via [LessonContentRenderer].
  final List<BlockModel> blocks;

  final int durationMin;
  final bool isDownloadable;
  final bool isPreview;
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
    this.articleContent = '',
    this.blocks = const [],
    required this.durationMin,
    required this.isDownloadable,
    required this.isPreview,
    required this.order,
    required this.xpReward,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Désérialisation sécurisée des blocks JSON
    final rawBlocks = data['blocks'] as List? ?? [];
    final parsedBlocks = rawBlocks
        .whereType<Map<String, dynamic>>()
        .map((b) => BlockModel.fromMap(b))
        .where((b) => b.type != BlockType.unknown)
        .toList();

    return LessonModel(
      lessonId: doc.id,
      moduleId: data['moduleId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? 'video',
      contentUrl: data['contentUrl'] as String? ?? '',
      localPath: data['localPath'] as String?,
      articleContent: data['articleContent'] as String? ?? '',
      blocks: parsedBlocks,
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
        'articleContent': articleContent,
        'blocks': blocks.map((b) => b.toMap()).toList(),
        'durationMin': durationMin,
        'isDownloadable': isDownloadable,
        'isPreview': isPreview,
        'order': order,
        'xpReward': xpReward,
      };

  // ── Helpers ───────────────────────────────────────────────

  bool get isVideo => type == 'video';
  bool get isArticle => type == 'article';
  bool get isPdf => type == 'pdf';
  bool get isCodeDemo => type == 'code_demo';
  bool get isAvailableOffline => localPath != null;

  /// Vrai si la leçon a du contenu enrichi à afficher dans Flutter
  bool get hasBlocks => blocks.isNotEmpty;

  /// Vrai si la leçon a du texte Markdown à afficher
  bool get hasArticleContent => articleContent.isNotEmpty;

  LessonModel copyWith({
    String? localPath,
    String? articleContent,
    List<BlockModel>? blocks,
  }) {
    return LessonModel(
      lessonId: lessonId,
      moduleId: moduleId,
      courseId: courseId,
      title: title,
      type: type,
      contentUrl: contentUrl,
      localPath: localPath ?? this.localPath,
      articleContent: articleContent ?? this.articleContent,
      blocks: blocks ?? this.blocks,
      durationMin: durationMin,
      isDownloadable: isDownloadable,
      isPreview: isPreview,
      order: order,
      xpReward: xpReward,
    );
  }

  @override
  List<Object?> get props =>
      [lessonId, moduleId, type, order, localPath, xpReward, blocks.length];
}

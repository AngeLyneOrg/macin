import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/lesson_model.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/repositories/repositories.dart';
import 'package:macin/shared/services/offline_service.dart';
import 'package:macin/shared/widgets/buttons/macin_primary_button.dart';
import 'package:macin/shared/widgets/lesson/lesson_content_renderer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LessonPlayerPage  ← VERSION ENRICHIE
//
// Intègre :
//   • LessonContentRenderer pour les blocs enrichis (heading/text/code/tip…)
//   • OfflineService pour télécharger PDF et articles hors-ligne
//   • Indicateur de progression de téléchargement
//   • Badge "Disponible hors-ligne" si localPath présent
//   • Passage vers les exercices du module via le bouton "Exercices"
//
// Supporte 4 types de contenu :
//   video      → lecteur vidéo (placeholder, TODO: video_player / better_player)
//   article    → LessonContentRenderer si blocks présents, sinon Markdown brut
//   pdf        → visionneuse PDF (placeholder, TODO: pdfx / syncfusion)
//   code_demo  → snippet de code lecture seule
// ─────────────────────────────────────────────────────────────────────────────

class LessonPlayerPage extends StatefulWidget {
  final String lessonId;
  final String courseId;

  const LessonPlayerPage({
    super.key,
    required this.lessonId,
    required this.courseId,
  });

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  final _courseRepo = CourseRepository();
  final _progressRepo = ProgressRepository();
  final _offlineService = OfflineService();

  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _isMarkingDone = false;
  bool _hasReachedEnd = false;

  // Téléchargement offline
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  late final Future<_LessonData> _lessonDataFuture = _loadLessonData();

  // Leçon courante (mutable pour mettre à jour localPath après téléchargement)
  LessonModel? _currentLesson;

  Future<_LessonData> _loadLessonData() async {
    final modules = await _courseRepo.watchModules(widget.courseId).first;
    for (final module in modules) {
      final lessons =
      await _courseRepo.getLessons(widget.courseId, module.moduleId);
      final idx = lessons.indexWhere((l) => l.lessonId == widget.lessonId);
      if (idx != -1) {
        var lesson = lessons[idx];

        // ✅ Restaurer le localPath depuis Hive (persisté entre sessions)
        final cachedPath = await _offlineService.resolveLocalPath(lesson);
        if (cachedPath != null && lesson.localPath == null) {
          lesson = lesson.copyWith(localPath: cachedPath);
        }

        final data = _LessonData(
          lesson: lesson,
          module: module,
          allLessons: lessons,
          currentIndex: idx,
        );
        setState(() => _currentLesson = lesson);
        return data;
      }
    }
    throw Exception('Leçon introuvable');
  }

  @override
  void dispose() {
    _offlineService.dispose();
    super.dispose();
  }

  // ── Téléchargement offline ────────────────────────────────

  Future<void> _downloadLesson(LessonModel lesson) async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final String path;
      if (lesson.isArticle) {
        path = await _offlineService.saveArticleLocally(lesson);
      } else {
        path = await _offlineService.downloadLesson(
          lesson: lesson,
          onProgress: (p) => setState(() => _downloadProgress = p),
        );
      }
      setState(() => _currentLesson = lesson.copyWith(localPath: path));
      if (mounted) {
        context.showSuccessSnack('Leçon disponible hors-ligne ✓');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnack('Erreur téléchargement : $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _deleteLocal(LessonModel lesson) async {
    try {
      await _offlineService.deleteLocal(lesson);
      setState(() => _currentLesson = lesson.copyWith(localPath: null));
      if (mounted) context.showSuccessSnack('Contenu hors-ligne supprimé.');
    } catch (e) {
      if (mounted) context.showErrorSnack('Erreur suppression : $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_LessonData>(
        future: _lessonDataFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snap.hasError || !snap.hasData) {
            return _buildError();
          }
          final data = snap.data!;
          // Utilise la leçon mise à jour (localPath) si disponible
          final enrichedData = _currentLesson != null
              ? data.withLesson(_currentLesson!)
              : data;
          return _buildLoaded(enrichedData);
        },
      ),
    );
  }

  // ── États ─────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _buildTopBar(null, null),
        const Expanded(
          child:
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildTopBar(null, null),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: AppDimensions.iconXxl, color: AppColors.error),
                const SizedBox(height: AppDimensions.base),
                Text('Leçon introuvable', style: AppTextStyles.heading2),
                const SizedBox(height: AppDimensions.sm),
                TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaded(_LessonData data) {
    final lesson = data.lesson;

    return StreamBuilder<UserProgressModel?>(
      stream: _uid != null
          ? _progressRepo.watchProgress(_uid!, widget.courseId)
          : const Stream.empty(),
      builder: (context, progressSnap) {
        final progress = progressSnap.data;
        final isCompleted =
            progress?.isLessonCompleted(lesson.lessonId) ?? false;

        return Column(
          children: [
            _buildTopBar(lesson, data),
            if (progress != null) _buildCourseProgressBar(progress),
            // Barre de téléchargement si en cours
            if (_isDownloading) _buildDownloadBar(),
            Expanded(child: _buildContent(lesson)),
            _buildBottomBar(context, data, lesson, isCompleted),
          ],
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  Widget _buildTopBar(LessonModel? lesson, _LessonData? data) {
    return SafeArea(
      child: Container(
        height: AppDimensions.appBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border:
          Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data != null)
                    Text(data.module.title,
                        style: AppTextStyles.captionMedium,
                        overflow: TextOverflow.ellipsis),
                  Text(
                    lesson?.title ?? 'Chargement...',
                    style: AppTextStyles.body1Medium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge offline
            if (lesson != null && lesson.isAvailableOffline)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.xs),
                child: Tooltip(
                  message: 'Disponible hors-ligne',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: const Icon(Icons.offline_bolt_rounded,
                        size: 14, color: AppColors.success),
                  ),
                ),
              ),
            if (data != null)
              Text(
                '${data.currentIndex + 1}/${data.allLessons.length}',
                style: AppTextStyles.captionMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseProgressBar(UserProgressModel progress) {
    return Container(
      height: 4,
      color: AppColors.border,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (progress.progressPercent / 100).clamp(0.0, 1.0),
        child: Container(color: AppColors.primary),
      ),
    );
  }

  Widget _buildDownloadBar() {
    return Container(
      color: AppColors.primarySurface,
      padding:
      const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              const Icon(Icons.download_rounded,
                  size: AppDimensions.iconSm, color: AppColors.primary),
              const SizedBox(width: AppDimensions.xs),
              Text(
                'Téléchargement… ${(_downloadProgress * 100).toStringAsFixed(0)} %',
                style: AppTextStyles.captionMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 3,
            borderRadius:
            BorderRadius.circular(AppDimensions.radiusRound),
          ),
          const SizedBox(height: AppDimensions.xs),
        ],
      ),
    );
  }

  // ── Contenu selon le type ─────────────────────────────────

  Widget _buildContent(LessonModel lesson) {
    return switch (lesson.type) {
      'video' => _VideoContent(
        lesson: lesson,
        onEnd: () => setState(() => _hasReachedEnd = true),
        onDownload: lesson.isDownloadable && !lesson.isAvailableOffline
            ? () => _downloadLesson(lesson)
            : null,
        onDeleteLocal: lesson.isAvailableOffline
            ? () => _deleteLocal(lesson)
            : null,
      ),
      'article' => _ArticleContent(
        lesson: lesson,
        onEnd: () => setState(() => _hasReachedEnd = true),
        onDownload: lesson.isDownloadable && !lesson.isAvailableOffline
            ? () => _downloadLesson(lesson)
            : null,
        onDeleteLocal: lesson.isAvailableOffline
            ? () => _deleteLocal(lesson)
            : null,
      ),
      'pdf' => _PdfContent(
        lesson: lesson,
        onEnd: () => setState(() => _hasReachedEnd = true),
        onDownload: lesson.isDownloadable && !lesson.isAvailableOffline
            ? () => _downloadLesson(lesson)
            : null,
        onDeleteLocal: lesson.isAvailableOffline
            ? () => _deleteLocal(lesson)
            : null,
      ),
      'code_demo' => _CodeDemoContent(
        lesson: lesson,
        onEnd: () => setState(() => _hasReachedEnd = true),
      ),
      _ => Center(child: Text('Type inconnu : ${lesson.type}')),
    };
  }

  // ── Barre du bas ─────────────────────────────────────────

  Widget _buildBottomBar(
      BuildContext context,
      _LessonData data,
      LessonModel lesson,
      bool isCompleted,
      ) {
    final hasPrev = data.currentIndex > 0;
    final hasNext = data.currentIndex < data.allLessons.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.md,
        AppDimensions.pagePaddingH,
        AppDimensions.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XP reward
          if (!isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.accent, size: AppDimensions.iconMd),
                  const SizedBox(width: 4),
                  Text(
                    '+${lesson.xpReward} XP en terminant cette leçon',
                    style: AppTextStyles.captionMedium
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              if (hasPrev)
                IconButton(
                  onPressed: () => _navigateToLesson(
                      context, data.allLessons[data.currentIndex - 1]),
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Leçon précédente',
                ),
              Expanded(
                child: isCompleted
                    ? _buildCompletedButton(context, data, hasNext)
                    : MacinPrimaryButton(
                  label: 'Marquer comme terminé',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isMarkingDone,
                  onPressed: () => _markDone(lesson, data),
                ),
              ),
              if (hasNext)
                IconButton(
                  onPressed: () => _navigateToLesson(
                      context, data.allLessons[data.currentIndex + 1]),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Leçon suivante',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedButton(
      BuildContext context, _LessonData data, bool hasNext) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: AppDimensions.iconMd),
        const SizedBox(width: AppDimensions.xs),
        Text('Terminé',
            style:
            AppTextStyles.body1Medium.copyWith(color: AppColors.success)),
        const Spacer(),
        // Bouton raccourci vers les exercices du module
        TextButton.icon(
          onPressed: () => context.goNamed(
            AppRoutes.exercisePage,
            pathParameters: {
              'id': widget.courseId,
              'moduleId': data.module.moduleId,
            },
          ),
          icon: const Icon(Icons.quiz_outlined, size: AppDimensions.iconSm),
          label: const Text('Exercices'),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        ),
        if (hasNext)
          TextButton(
            onPressed: () => _navigateToLesson(
                context, data.allLessons[data.currentIndex + 1]),
            child: const Text('Suivant →'),
          ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _markDone(LessonModel lesson, _LessonData data) async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _isMarkingDone = true);
    try {
      await _progressRepo.completeLesson(
        userId: uid,
        courseId: widget.courseId,
        lessonId: lesson.lessonId,
        totalLessons: data.allLessons.length,
        xpReward: lesson.xpReward,
      );
      if (mounted) {
        context.showSuccessSnack('+${lesson.xpReward} XP gagnés !');
      }
    } catch (e) {
      if (mounted) context.showErrorSnack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isMarkingDone = false);
    }
  }

  void _navigateToLesson(BuildContext context, LessonModel lesson) {
    context.goNamed(
      AppRoutes.lessonPlayer,
      pathParameters: {
        'id': widget.courseId,
        'lessonId': lesson.lessonId,
      },
    );
  }
}

// ── Data class interne ────────────────────────────────────────

class _LessonData {
  final LessonModel lesson;
  final ModuleModel module;
  final List<LessonModel> allLessons;
  final int currentIndex;

  const _LessonData({
    required this.lesson,
    required this.module,
    required this.allLessons,
    required this.currentIndex,
  });

  _LessonData withLesson(LessonModel updated) => _LessonData(
    lesson: updated,
    module: module,
    allLessons: allLessons,
    currentIndex: currentIndex,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets de contenu
// ═══════════════════════════════════════════════════════════════════════════════

// ── Vidéo ─────────────────────────────────────────────────────────────────────

class _VideoContent extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteLocal;

  const _VideoContent({
    required this.lesson,
    required this.onEnd,
    this.onDownload,
    this.onDeleteLocal,
  });

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (_isInitializing || _controller != null) return;
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final VideoPlayerController ctrl;

      // Priorité au fichier local (offline), sinon stream R2
      if (widget.lesson.localPath != null) {
        final file = File(widget.lesson.localPath!);
        if (await file.exists()) {
          ctrl = VideoPlayerController.file(file);
        } else {
          // Fichier local introuvable → fallback URL
          ctrl = _controllerFromUrl();
        }
      } else {
        ctrl = _controllerFromUrl();
      }

      await ctrl.initialize();
      ctrl.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() {
          _controller = ctrl;
          _isInitializing = false;
        });
        await ctrl.play();
      } else {
        ctrl.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  VideoPlayerController _controllerFromUrl() {
    final url = widget.lesson.contentUrl;
    if (url.isEmpty) throw Exception('URL vidéo manquante dans Firestore.');
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final ctrl = _controller;
    if (ctrl == null) return;

    // Déclencher onEnd quand la vidéo se termine
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inSeconds > 0 && pos >= dur - const Duration(seconds: 1)) {
      widget.onEnd();
    }
    setState(() {});
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    // Afficher les contrôles brièvement à chaque interaction
    setState(() => _showControls = true);
  }

  void _retry() {
    _controller?.dispose();
    setState(() {
      _controller = null;
      _hasError = false;
    });
    _initializePlayer();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    return Column(
      children: [
        // ── Zone vidéo 16:9 ──────────────────────────────────
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: _buildVideoArea(ctrl),
          ),
        ),

        // ── Métadonnées + notes de cours ─────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
            children: [
              Row(children: [
                _LessonTypeBadge(type: widget.lesson.type),
                const SizedBox(width: AppDimensions.sm),
                // Badge "hors-ligne" si lecture locale
                if (widget.lesson.localPath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.offline_bolt_rounded, size: 12, color: AppColors.success),
                        const SizedBox(width: 3),
                        Text('Hors-ligne', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                      ]),
                    ),
                  ),
                Text('${widget.lesson.durationMin} min',
                    style: AppTextStyles.captionMedium),
              ]),
              const SizedBox(height: AppDimensions.md),
              Text(widget.lesson.title, style: AppTextStyles.heading2),
              const SizedBox(height: AppDimensions.sm),
              _OfflineActionButton(
                lesson: widget.lesson,
                onDownload: widget.onDownload,
                onDeleteLocal: widget.onDeleteLocal,
              ),
              if (widget.lesson.hasBlocks) ...[
                const SizedBox(height: AppDimensions.xl),
                Text('Notes de cours', style: AppTextStyles.heading3),
                const SizedBox(height: AppDimensions.sm),
                LessonContentRenderer(
                  blocks: widget.lesson.blocks,
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoArea(VideoPlayerController? ctrl) {
    // ── Erreur ───────────────────────────────────────────
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text('Impossible de lire la vidéo',
                  style: AppTextStyles.body1Medium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(_errorMessage ?? '',
                  style: AppTextStyles.caption.copyWith(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // ── Initialisation ───────────────────────────────────
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('Chargement…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    // ── Écran de lancement (avant le premier tap) ────────
    if (ctrl == null) {
      return GestureDetector(
        onTap: _initializePlayer,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: const Color(0xFF0b0f2e)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.lesson.localPath != null
                      ? 'Lecture hors-ligne'
                      : 'Appuie pour lancer la vidéo',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── Player actif ─────────────────────────────────────
    final value = ctrl.value;
    final position = value.position;
    final duration = value.duration;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Vidéo centrée
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(ctrl),
            ),
          ),

          // Overlay play/pause au centre
          if (!value.isPlaying)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Icon(Icons.play_circle_outline_rounded,
                    size: 64, color: Colors.white),
              ),
            ),

          // Barre de contrôles bas
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de progression scrubable
                VideoProgressIndicator(
                  ctrl,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    Text(
                      '${_fmt(position)} / ${_fmt(duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    // Icône indiquant la source (local ou réseau)
                    Icon(
                      widget.lesson.localPath != null
                          ? Icons.offline_bolt_rounded
                          : Icons.wifi_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Article ───────────────────────────────────────────────────────────────────

class _ArticleContent extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteLocal;

  const _ArticleContent({
    required this.lesson,
    required this.onEnd,
    this.onDownload,
    this.onDeleteLocal,
  });

  @override
  State<_ArticleContent> createState() => _ArticleContentState();
}

class _ArticleContentState extends State<_ArticleContent> {
  final _scrollController = ScrollController();
  bool _endCalled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_endCalled) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      _endCalled = true;
      widget.onEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return ListView(
      controller: _scrollController,
      padding:
      const EdgeInsets.all(AppDimensions.pagePaddingH),
      children: [
        // Méta
        Row(children: [
          _LessonTypeBadge(type: lesson.type),
          const SizedBox(width: AppDimensions.sm),
          Text('${lesson.durationMin} min de lecture',
              style: AppTextStyles.captionMedium),
          const Spacer(),
          _OfflineActionButton(
            lesson: lesson,
            onDownload: widget.onDownload,
            onDeleteLocal: widget.onDeleteLocal,
            compact: true,
          ),
        ]),
        const SizedBox(height: AppDimensions.base),
        Text(lesson.title, style: AppTextStyles.heading1),
        const SizedBox(height: AppDimensions.xl),
        const Divider(color: AppColors.divider),
        const SizedBox(height: AppDimensions.xl),

        // Contenu enrichi (blocs admin) ou texte Markdown brut
        if (lesson.hasBlocks)
          LessonContentRenderer(
            blocks: lesson.blocks,
            padding: EdgeInsets.zero,
          )
        else if (lesson.hasArticleContent)
        // TODO: remplacer par MarkdownBody(data: lesson.articleContent)
        // via le package flutter_markdown
          Text(lesson.articleContent,
              style: AppTextStyles.body1.copyWith(height: 1.7))
        else
          Text(
            lesson.contentUrl.startsWith('http')
                ? '(Contenu chargé depuis : ${lesson.contentUrl})'
                : lesson.contentUrl,
            style: AppTextStyles.body1.copyWith(height: 1.7),
          ),

        const SizedBox(height: AppDimensions.xxxl),

        // Marqueur de fin
        Container(
          padding: const EdgeInsets.all(AppDimensions.base),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: AppDimensions.iconMd),
              const SizedBox(width: AppDimensions.sm),
              Text('Fin de l\'article',
                  style:
                  AppTextStyles.body2.copyWith(color: AppColors.success)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── PDF ───────────────────────────────────────────────────────────────────────

class _PdfContent extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteLocal;

  const _PdfContent({
    required this.lesson,
    required this.onEnd,
    this.onDownload,
    this.onDeleteLocal,
  });

  @override
  Widget build(BuildContext context) {
    // Si localPath disponible, on pourrait ouvrir le fichier local
    // TODO: intégrer pdfx ou syncfusion_flutter_pdfviewer
    final hasLocal = lesson.localPath != null &&
        File(lesson.localPath!).existsSync();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.xl),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius:
                  BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.error, size: AppDimensions.iconXxl),
              ),
              const SizedBox(height: AppDimensions.base),
              Text(lesson.title,
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.sm),
              Text(
                hasLocal
                    ? 'PDF disponible hors-ligne'
                    : 'Visionneuse PDF (pdfx à intégrer)',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xl),
              OutlinedButton.icon(
                onPressed: onEnd,
                icon: const Icon(Icons.open_in_new_rounded,
                    size: AppDimensions.iconMd),
                label: const Text('Ouvrir le PDF'),
              ),
              const SizedBox(height: AppDimensions.md),
              _OfflineActionButton(
                lesson: lesson,
                onDownload: onDownload,
                onDeleteLocal: onDeleteLocal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Code Demo ─────────────────────────────────────────────────────────────────

class _CodeDemoContent extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;

  const _CodeDemoContent({required this.lesson, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      children: [
        Row(children: [
          _LessonTypeBadge(type: lesson.type),
          const SizedBox(width: AppDimensions.sm),
          Text('${lesson.durationMin} min',
              style: AppTextStyles.captionMedium),
        ]),
        const SizedBox(height: AppDimensions.base),
        Text(lesson.title, style: AppTextStyles.heading2),
        const SizedBox(height: AppDimensions.xl),
        // Blocs enrichis si présents (explications avant le code)
        if (lesson.hasBlocks) ...[
          LessonContentRenderer(blocks: lesson.blocks, padding: EdgeInsets.zero),
          const SizedBox(height: AppDimensions.base),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.base),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: SelectableText(
            lesson.contentUrl.startsWith('http')
                ? '// Code chargé depuis : ${lesson.contentUrl}'
                : lesson.contentUrl,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFCDD6F4),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets utilitaires partagés dans ce fichier
// ═══════════════════════════════════════════════════════════════════════════════

/// Bouton de téléchargement / suppression du contenu offline.
class _OfflineActionButton extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteLocal;

  /// Si [compact] = true, affiche une IconButton au lieu d'un OutlinedButton.
  final bool compact;

  const _OfflineActionButton({
    required this.lesson,
    this.onDownload,
    this.onDeleteLocal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!lesson.isDownloadable) return const SizedBox.shrink();

    if (lesson.isAvailableOffline) {
      // Leçon déjà en local → proposer la suppression
      if (compact) {
        return IconButton(
          icon: const Icon(Icons.offline_bolt_rounded),
          color: AppColors.success,
          tooltip: 'Disponible hors-ligne — Toucher pour supprimer',
          onPressed: onDeleteLocal,
        );
      }
      return OutlinedButton.icon(
        onPressed: onDeleteLocal,
        icon: const Icon(Icons.delete_outline_rounded,
            size: AppDimensions.iconMd, color: AppColors.error),
        label: const Text('Supprimer du stockage local'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
      );
    }

    // Pas encore téléchargé
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.download_outlined),
        color: AppColors.primary,
        tooltip: 'Télécharger pour lire hors-ligne',
        onPressed: onDownload,
      );
    }
    return OutlinedButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_outlined, size: AppDimensions.iconMd),
      label: const Text('Télécharger pour lire hors-ligne'),
    );
  }
}

/// Badge visuel indiquant le type de la leçon.
class _LessonTypeBadge extends StatelessWidget {
  final String type;
  const _LessonTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (type) {
      'video' => (
      Icons.play_circle_outline_rounded,
      'Vidéo',
      AppColors.primary
      ),
      'article' => (Icons.article_outlined, 'Article', AppColors.secondary),
      'pdf' => (Icons.picture_as_pdf_outlined, 'PDF', AppColors.error),
      'code_demo' => (Icons.code_rounded, 'Code', AppColors.success),
      _ => (Icons.book_outlined, type, AppColors.textTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
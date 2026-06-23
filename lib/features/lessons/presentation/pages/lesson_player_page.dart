import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/lesson_model.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/repositories/repositories.dart';
import 'package:macin/shared/widgets/buttons/macin_primary_button.dart';

/// Page de lecture d'une leçon MACIN.
///
/// Supporte 4 types de contenu :
///   - `video`     : lecteur vidéo (placeholder WebView / video_player)
///   - `article`   : rendu Markdown avec scroll
///   - `pdf`       : visionneuse PDF (placeholder)
///   - `code_demo` : éditeur de code lecture seule
///
/// Logique de progression :
///   - Un bouton "Marquer comme terminé" écrit dans [ProgressRepository]
///   - Un StreamBuilder sur `user_progress` écoute le statut en temps réel
///   - La liste des leçons du module est chargée pour la navigation
///     Précédent / Suivant
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

  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _isMarkingDone = false;
  bool _hasReachedEnd = false; // simulé : l'utilisateur a scrollé jusqu'en bas

  // Future pour charger la leçon + son module (pour Prev/Next)
  late final Future<_LessonData> _lessonDataFuture = _loadLessonData();

  Future<_LessonData> _loadLessonData() async {
    // Recherche le module contenant cette leçon via tous les modules du cours
    final modules = await _courseRepo.watchModules(widget.courseId).first;
    for (final module in modules) {
      final lessons = await _courseRepo.getLessons(widget.courseId, module.moduleId);
      final idx = lessons.indexWhere((l) => l.lessonId == widget.lessonId);
      if (idx != -1) {
        return _LessonData(
          lesson: lessons[idx],
          module: module,
          allLessons: lessons,
          currentIndex: idx,
        );
      }
    }
    throw Exception('Leçon introuvable');
  }

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
          return _buildLoaded(data);
        },
      ),
    );
  }

  // ── États ──────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _buildTopBar(null, null),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
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
                  child: const Text('Retour'),
                ),
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
        final isCompleted = progress?.isLessonCompleted(lesson.lessonId) ?? false;

        return Column(
          children: [
            // ── AppBar ─────────────────────────────────────
            _buildTopBar(lesson, data),

            // ── Barre de progression du cours ───────────────
            if (progress != null) _buildCourseProgressBar(progress),

            // ── Contenu ────────────────────────────────────
            Expanded(
              child: _buildContent(lesson),
            ),

            // ── Navigation Prev/Next + CTA ──────────────────
            _buildBottomBar(context, data, lesson, isCompleted),
          ],
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  Widget _buildTopBar(LessonModel? lesson, _LessonData? data) {
    return SafeArea(
      child: Container(
        height: AppDimensions.appBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
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
                    Text(
                      data.module.title,
                      style: AppTextStyles.captionMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    lesson?.title ?? 'Chargement...',
                    style: AppTextStyles.body1Medium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
        widthFactor: progress.progressPercent / 100,
        child: Container(color: AppColors.primary),
      ),
    );
  }

  // ── Contenu selon le type ─────────────────────────────────

  Widget _buildContent(LessonModel lesson) {
    return switch (lesson.type) {
      'video' => _VideoContent(lesson: lesson, onEnd: () {
        setState(() => _hasReachedEnd = true);
      }),
      'article' => _ArticleContent(lesson: lesson, onEnd: () {
        setState(() => _hasReachedEnd = true);
      }),
      'pdf' => _PdfContent(lesson: lesson, onEnd: () {
        setState(() => _hasReachedEnd = true);
      }),
      'code_demo' => _CodeDemoContent(lesson: lesson, onEnd: () {
        setState(() => _hasReachedEnd = true);
      }),
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
          // ── Récompense XP ────────────────────────────────
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

          // ── CTA + Navigation ────────────────────────────
          Row(
            children: [
              if (hasPrev)
                IconButton(
                  onPressed: () => _navigateToLesson(context,
                      data.allLessons[data.currentIndex - 1]),
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
                  onPressed: () => _navigateToLesson(context,
                      data.allLessons[data.currentIndex + 1]),
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
        Text('Terminé', style: AppTextStyles.body1Medium
            .copyWith(color: AppColors.success)),
        const Spacer(),
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
      if (mounted) {
        context.showErrorSnack('Erreur : $e');
      }
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
}

// ═══════════════════════════════════════════════════════════════
// Widgets de contenu selon le type de leçon
// ═══════════════════════════════════════════════════════════════

/// Contenu vidéo.
///
/// TODO: intégrer `video_player` ou `better_player` pour les vraies
/// vidéos Cloudflare R2. La clé `onEnd` déclenche le bouton "Terminer".
class _VideoContent extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  const _VideoContent({required this.lesson, required this.onEnd});

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Zone vidéo (placeholder) ──────────────────────
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_isPlaying)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _isPlaying = true);
                          // TODO: initialiser le vrai lecteur vidéo ici
                          // Simule la fin après 3s pour le dev
                          Future.delayed(const Duration(seconds: 3), widget.onEnd);
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Appuie pour lancer la vidéo',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Chargement de la vidéo...',
                        style: AppTextStyles.body2
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // ── Informations leçon ────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
            children: [
              Row(
                children: [
                  _LessonTypeBadge(type: widget.lesson.type),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    '${widget.lesson.durationMin} min',
                    style: AppTextStyles.captionMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Text(widget.lesson.title, style: AppTextStyles.heading2),
              const SizedBox(height: AppDimensions.sm),
              if (widget.lesson.isDownloadable)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: déclencher le téléchargement offline
                  },
                  icon: const Icon(Icons.download_outlined,
                      size: AppDimensions.iconMd),
                  label: const Text('Télécharger pour regarder hors-ligne'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenu article (Markdown).
///
/// TODO: intégrer `flutter_markdown` pour un vrai rendu Markdown.
/// `contentUrl` est ici le texte Markdown brut pour les articles.
class _ArticleContent extends StatefulWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  const _ArticleContent({required this.lesson, required this.onEnd});

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
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      children: [
        Row(
          children: [
            _LessonTypeBadge(type: widget.lesson.type),
            const SizedBox(width: AppDimensions.sm),
            Text('${widget.lesson.durationMin} min de lecture',
                style: AppTextStyles.captionMedium),
          ],
        ),
        const SizedBox(height: AppDimensions.base),
        Text(widget.lesson.title, style: AppTextStyles.heading1),
        const SizedBox(height: AppDimensions.xl),
        const Divider(color: AppColors.divider),
        const SizedBox(height: AppDimensions.xl),
        // TODO: remplacer par MarkdownBody(data: widget.lesson.contentUrl)
        // via le package flutter_markdown
        Text(
          widget.lesson.contentUrl.startsWith('http')
              ? '(Contenu chargé depuis : ${widget.lesson.contentUrl})'
              : widget.lesson.contentUrl,
          style: AppTextStyles.body1.copyWith(height: 1.7),
        ),
        const SizedBox(height: AppDimensions.xxxl),
        // Marqueur de fin d'article
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
              Text('Fin de l\'article', style: AppTextStyles.body2
                  .copyWith(color: AppColors.success)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenu PDF.
///
/// TODO: intégrer `syncfusion_flutter_pdfviewer` ou `pdfx`.
class _PdfContent extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  const _PdfContent({required this.lesson, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.error, size: AppDimensions.iconXxl),
            ),
            const SizedBox(height: AppDimensions.base),
            Text(lesson.title, style: AppTextStyles.heading2,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Visionneuse PDF (intégration syncfusion ou pdfx à venir)',
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
          ],
        ),
      ),
    );
  }
}

/// Contenu code_demo — snippet de code avec coloration syntaxique.
///
/// TODO: intégrer `flutter_highlight` ou `code_text_field`.
class _CodeDemoContent extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEnd;
  const _CodeDemoContent({required this.lesson, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    // Appel onEnd au build car un code_demo n'a pas de "fin naturelle"
    WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      children: [
        Row(
          children: [
            _LessonTypeBadge(type: lesson.type),
            const SizedBox(width: AppDimensions.sm),
            Text('${lesson.durationMin} min', style: AppTextStyles.captionMedium),
          ],
        ),
        const SizedBox(height: AppDimensions.base),
        Text(lesson.title, style: AppTextStyles.heading2),
        const SizedBox(height: AppDimensions.xl),
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

// ── Badge type de leçon ────────────────────────────────────────

class _LessonTypeBadge extends StatelessWidget {
  final String type;
  const _LessonTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (type) {
      'video' => (Icons.play_circle_outline_rounded, 'Vidéo', AppColors.primary),
      'article' => (Icons.article_outlined, 'Article', AppColors.secondary),
      'pdf' => (Icons.picture_as_pdf_outlined, 'PDF', AppColors.error),
      'code_demo' => (Icons.code_rounded, 'Code', AppColors.success),
      _ => (Icons.book_outlined, type, AppColors.textTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
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

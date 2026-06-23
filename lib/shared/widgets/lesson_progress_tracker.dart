import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/lesson_model.dart';
import 'package:macin/shared/models/models.dart';

/// Widget réutilisable affichant la liste des leçons d'un module
/// avec leur statut de complétion (coché / verrouillé / disponible).
///
/// Utilisé dans :
///   - [CourseDetailPage] pour afficher le curriculum complet
///   - [LessonPlayerPage] drawer latéral (à venir)
///
/// Le [progress] est nullable : null = non inscrit (leçons verrouillées
/// sauf [LessonModel.isPreview]).
class LessonProgressTracker extends StatelessWidget {
  final String courseId;
  final List<LessonModel> lessons;
  final UserProgressModel? progress;
  final bool isEnrolled;

  /// Si true, les leçons non-preview sont cliquables même sans inscription
  /// (mode instructeur / admin).
  final bool overrideAccess;

  const LessonProgressTracker({
    super.key,
    required this.courseId,
    required this.lessons,
    required this.progress,
    required this.isEnrolled,
    this.overrideAccess = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Text('Aucune leçon dans ce module.',
            style: AppTextStyles.body2),
      );
    }

    return Column(
      children: lessons.map((lesson) {
        final isCompleted =
            progress?.isLessonCompleted(lesson.lessonId) ?? false;
        final canAccess =
            isEnrolled || lesson.isPreview || overrideAccess;

        return _LessonTile(
          lesson: lesson,
          isCompleted: isCompleted,
          canAccess: canAccess,
          onTap: canAccess
              ? () => context.goNamed(
            AppRoutes.lessonPlayer,
            pathParameters: {
              'id': courseId,
              'lessonId': lesson.lessonId,
            },
          )
              : null,
        );
      }).toList(),
    );
  }
}

// ── Tuile leçon ───────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final bool isCompleted;
  final bool canAccess;
  final VoidCallback? onTap;

  const _LessonTile({
    required this.lesson,
    required this.isCompleted,
    required this.canAccess,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppDimensions.lessonTileHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            // ── Icône statut ───────────────────────────────
            _StatusIcon(isCompleted: isCompleted, canAccess: canAccess),
            const SizedBox(width: AppDimensions.base),

            // ── Titre + type ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lesson.title,
                    style: AppTextStyles.body2.copyWith(
                      color: canAccess
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _TypeIcon(type: lesson.type),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.durationMin} min',
                        style: AppTextStyles.labelSmall,
                      ),
                      if (lesson.isPreview && !canAccess) ...[
                        const SizedBox(width: AppDimensions.sm),
                        _PreviewBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── XP reward ────────────────────────────────
            if (canAccess && !isCompleted) ...[
              const SizedBox(width: AppDimensions.sm),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.accent,
                      size: AppDimensions.iconSm),
                  Text(
                    '+${lesson.xpReward}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Icône de statut (complété / verrouillé / disponible) ─────

class _StatusIcon extends StatelessWidget {
  final bool isCompleted;
  final bool canAccess;

  const _StatusIcon({required this.isCompleted, required this.canAccess});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
        size: AppDimensions.iconLg,
      );
    }
    if (!canAccess) {
      return const Icon(
        Icons.lock_outline_rounded,
        color: AppColors.textTertiary,
        size: AppDimensions.iconLg,
      );
    }
    return Container(
      width: AppDimensions.iconLg,
      height: AppDimensions.iconLg,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );
  }
}

// ── Icône de type de leçon ────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'video' => (Icons.play_circle_outline_rounded, AppColors.primary),
      'article' => (Icons.article_outlined, AppColors.secondary),
      'pdf' => (Icons.picture_as_pdf_outlined, AppColors.error),
      'code_demo' => (Icons.code_rounded, AppColors.success),
      _ => (Icons.book_outlined, AppColors.textTertiary),
    };
    return Icon(icon, size: AppDimensions.iconSm, color: color);
  }
}

// ── Badge "Aperçu gratuit" ────────────────────────────────────

class _PreviewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Text(
        'Aperçu',
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.accent),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Widget récapitulatif de module (utilisé dans CourseDetailPage)
// ═══════════════════════════════════════════════════════════════

/// Affiche un module avec ses leçons dans un ExpansionTile.
///
/// [completedCount] est calculé par le parent depuis [UserProgressModel].
class ModuleExpansionTile extends StatelessWidget {
  final ModuleModel module;
  final List<LessonModel> lessons;
  final UserProgressModel? progress;
  final bool isEnrolled;
  final String courseId;

  const ModuleExpansionTile({
    super.key,
    required this.module,
    required this.lessons,
    required this.progress,
    required this.isEnrolled,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final completed = lessons
        .where((l) => progress?.isLessonCompleted(l.lessonId) ?? false)
        .length;
    final total = lessons.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.base,
            vertical: AppDimensions.xs,
          ),
          childrenPadding: EdgeInsets.zero,
          title: Text(module.title, style: AppTextStyles.body1Medium),
          subtitle: Text(
            '$completed/$total leçon${total > 1 ? 's' : ''} · ${module.totalDurationMin} min',
            style: AppTextStyles.captionMedium,
          ),
          trailing: completed == total && total > 0
              ? const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: AppDimensions.iconMd)
              : Text('$completed/$total',
              style: AppTextStyles.captionMedium),
          children: [
            const Divider(height: 1, color: AppColors.divider),
            LessonProgressTracker(
              courseId: courseId,
              lessons: lessons,
              progress: progress,
              isEnrolled: isEnrolled,
            ),
          ],
        ),
      ),
    );
  }
}

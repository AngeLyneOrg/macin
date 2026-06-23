import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/widgets/backgrounds/aurora_backdrop.dart';

/// Card "Reprendre l'apprentissage" affichée en haut de la [HomePage]
/// quand l'étudiant a au moins un cours en cours.
///
/// Traitée comme la carte CTA principale de l'écran : fond dégradé
/// [AuroraBackdrop] + anneau de progression circulaire, pour qu'elle
/// se distingue clairement du reste des cards à fond blanc.
///
/// Usage :
/// ```dart
/// ContinueLearningCard(
///   courseTitle: course.title,
///   completedLessons: progress.completedLessonIds.length,
///   totalLessons: course.totalLessons,
///   progressPercent: progress.progressPercent,
///   onTap: () => context.pushNamed(AppRoutes.courseDetail, ...),
/// )
/// ```
class ContinueLearningCard extends StatelessWidget {
  final String courseTitle;
  final int completedLessons;
  final int totalLessons;

  /// 0-100.
  final double progressPercent;
  final VoidCallback onTap;

  const ContinueLearningCard({
    super.key,
    required this.courseTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (totalLessons - completedLessons).clamp(0, totalLessons);
    final progress = (progressPercent / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: AuroraBackdrop(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        background: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        blobColors: [Colors.white.withOpacity(0.9), AppColors.accent],
        blobOpacity: 0.18,
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Row(
          children: [
            _MiniProgressRing(progress: progress),
            const SizedBox(width: AppDimensions.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reprendre l'apprentissage",
                    style: AppTextStyles.captionMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    courseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    remaining > 0
                        ? '$remaining leçon${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}'
                        : 'Cours terminé 🎉',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.sm),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: AppDimensions.iconMd),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProgressRing extends StatelessWidget {
  final double progress;
  const _MiniProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.25)),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentLight),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

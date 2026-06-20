import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';

/// Card "Reprendre l'apprentissage" affichée en haut de la [HomePage]
/// quand l'étudiant a au moins un cours en cours.
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reprendre l'apprentissage",
              style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppDimensions.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              child: LinearProgressIndicator(
                value: (progressPercent / 100).clamp(0.0, 1.0),
                minHeight: AppDimensions.xpBarHeight,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remaining > 0
                      ? '$remaining leçon${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}'
                      : 'Cours terminé 🎉',
                  style: AppTextStyles.captionMedium,
                ),
                Text(
                  '${progressPercent.round()}%',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

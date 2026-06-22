import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/ai_insight_models.dart';

/// Card de recommandation de leçon générée par MACI.
///
/// Affichée en liste horizontale dans le dashboard. Le badge
/// "Pourquoi" explique la raison de la recommandation (ex: score
/// faible sur ce sujet), ce qui rend l'IA plus transparente et
/// digne de confiance pour l'étudiant.
///
/// Usage :
/// ```dart
/// RecommendationCard(recommendation: rec, onTap: () => ...)
/// ```
class RecommendationCard extends StatelessWidget {
  final AiRecommendation recommendation;
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.aiSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 12, color: AppColors.aiPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'MACI',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.aiPrimary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${recommendation.estimatedMinutes} min',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              recommendation.lessonTitle,
              style: AppTextStyles.body1Medium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              recommendation.courseTitle,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              recommendation.reason,
              style: AppTextStyles.captionMedium.copyWith(color: AppColors.aiPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

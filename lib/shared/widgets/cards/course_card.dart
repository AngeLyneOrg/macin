import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/shared/models/course_model.dart';

enum _CourseCardVariant { featured, compact }

/// Card de cours réutilisable — deux variantes :
///   - [CourseCard.featured] : grande card image plein cadre (280x200),
///     pour les listes horizontales "mises en avant".
///   - [CourseCard.compact] : petite card image + infos dessous (168 de
///     large), pour les listes denses ("Tous les cours", recherche...).
///
/// NOTE : [CourseModel] ne stocke pas le nom du formateur (seulement
/// [CourseModel.instructorId]) — pour éviter une lecture Firestore par
/// card (problème N+1), le nom est passé en paramètre optionnel par
/// l'appelant s'il est déjà connu. Dénormaliser `instructorName` sur
/// [CourseModel] à la publication du cours réglerait ça proprement
/// (amélioration future, voir issue #19).
///
/// Usage :
/// ```dart
/// CourseCard.featured(course: course, onTap: () => ...)
/// CourseCard.compact(course: course, onTap: () => ..., instructorName: 'Awa K.')
/// ```
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final String? instructorName;

  /// 0-100. Si non null, affiche une barre de progression (cours déjà inscrit).
  final double? progressPercent;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;
  final _CourseCardVariant _variant;

  const CourseCard.featured({
    super.key,
    required this.course,
    required this.onTap,
    this.instructorName,
    this.progressPercent,
    this.isBookmarked = false,
    this.onBookmarkTap,
  }) : _variant = _CourseCardVariant.featured;

  const CourseCard.compact({
    super.key,
    required this.course,
    required this.onTap,
    this.instructorName,
    this.progressPercent,
    this.isBookmarked = false,
    this.onBookmarkTap,
  }) : _variant = _CourseCardVariant.compact;

  @override
  Widget build(BuildContext context) {
    return _variant == _CourseCardVariant.featured
        ? _buildFeatured(context)
        : _buildCompact(context);
  }

  // ── Featured ────────────────────────────────────────────

  Widget _buildFeatured(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.courseCardWidth,
        height: AppDimensions.courseCardHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          color: AppColors.surfaceVariant,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _networkImage(course.thumbnailUrl),
            // Dégradé pour la lisibilité du texte par-dessus l'image
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.78),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              top: AppDimensions.sm,
              left: AppDimensions.sm,
              child: _priceBadge(),
            ),
            if (onBookmarkTap != null)
              Positioned(
                top: AppDimensions.sm,
                right: AppDimensions.sm,
                child: _bookmarkButton(),
              ),
            Positioned(
              left: AppDimensions.md,
              right: AppDimensions.md,
              bottom: AppDimensions.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '${course.totalLessons} leçons',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                  if (progressPercent != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      child: LinearProgressIndicator(
                        value: (progressPercent! / 100).clamp(0.0, 1.0),
                        minHeight: AppDimensions.xpBarHeightSm,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact ─────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: _networkImage(course.thumbnailUrl),
                ),
                Positioned(
                  top: AppDimensions.xs,
                  left: AppDimensions.xs,
                  child: _priceBadge(small: true),
                ),
                if (onBookmarkTap != null)
                  Positioned(
                    top: AppDimensions.xs,
                    right: AppDimensions.xs,
                    child: _bookmarkButton(small: true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body1Medium,
                  ),
                  if (instructorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      instructorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: AppDimensions.iconSm, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        course.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.captionMedium,
                      ),
                      const Spacer(),
                      Text(
                        course.isFree ? 'Gratuit' : course.price.asFcfa,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (progressPercent != null) ...[
                    const SizedBox(height: AppDimensions.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      child: LinearProgressIndicator(
                        value: (progressPercent! / 100).clamp(0.0, 1.0),
                        minHeight: AppDimensions.xpBarHeightSm,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pièces communes ─────────────────────────────────────

  Widget _networkImage(String url) {
    if (url.isEmpty) return _imageFallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: AppColors.surfaceVariant);
      },
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textTertiary,
        size: AppDimensions.iconXl,
      ),
    );
  }

  Widget _priceBadge({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppDimensions.sm : AppDimensions.md,
        vertical: small ? 2 : AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Text(
        course.isFree ? 'Gratuit' : course.price.asFcfa,
        style: (small ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
            .copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _bookmarkButton({bool small = false}) {
    final size = small ? 28.0 : 34.0;
    return GestureDetector(
      onTap: onBookmarkTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: small ? AppDimensions.iconSm : AppDimensions.iconMd,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/models.dart';

/// Affiche un badge de gamification sous forme de médaillon.
///
/// La couleur de la bordure/glow dépend de [BadgeModel.rarity].
/// Si [isLocked] est vrai (badge pas encore obtenu), l'icône est
/// grisée et désaturée.
///
/// Usage :
/// ```dart
/// BadgeMedal(badge: badge, isLocked: !user.hasBadge(badge.badgeId))
/// ```
class BadgeMedal extends StatelessWidget {
  final BadgeModel badge;
  final bool isLocked;
  final VoidCallback? onTap;

  const BadgeMedal({
    super.key,
    required this.badge,
    this.isLocked = false,
    this.onTap,
  });

  Color get _rarityColor => switch (badge.rarity) {
    'rare' => AppColors.rarityRare,
    'epic' => AppColors.rarityEpic,
    'legendary' => AppColors.rarityLegendary,
    _ => AppColors.rarityCommon,
  };

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? AppColors.textTertiary : _rarityColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimensions.badgeMd,
            height: AppDimensions.badgeMd,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? AppColors.surfaceVariant
                  : color.withOpacity(0.12),
              border: Border.all(color: color, width: 2),
              boxShadow: isLocked
                  ? null
                  : [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isLocked ? Icons.lock_outline_rounded : _iconForCategory(),
              color: color,
              size: AppDimensions.iconLg,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          SizedBox(
            width: AppDimensions.badgeMd + AppDimensions.md,
            child: Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: isLocked
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory() => switch (badge.category) {
    'social' => Icons.people_alt_rounded,
    'certification' => Icons.workspace_premium_rounded,
    'achievement' => Icons.emoji_events_rounded,
    _ => Icons.school_rounded,
  };
}
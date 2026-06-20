import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/utils/xp_utils.dart';


/// Barre de progression XP réutilisable.
///
/// Affiche le niveau actuel, le titre gamifié, et la progression
/// vers le niveau suivant. Utilisé dans [ProfilePage] et la
/// future [HomeAppBar].
///
/// Usage :
/// ```dart
/// XpProgressBar(currentXp: user.xp)
/// ```
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final bool compact;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = XpUtils.levelFromXp(currentXp);
    final progress = XpUtils.progressInCurrentLevel(currentXp);
    final remaining = XpUtils.xpToNextLevel(currentXp);
    final title = XpUtils.levelTitle(level);
    final emoji = XpUtils.levelEmoji(level);

    if (compact) {
      return Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppDimensions.xpBarHeightSm,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppDimensions.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niveau $level', style: AppTextStyles.heading3),
                    Text(title, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
            Text(
              '$remaining XP restants',
              style: AppTextStyles.captionMedium,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppDimensions.xpBarHeight,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

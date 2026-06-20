import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Chip de suggestion rapide affiché au-dessus du champ de saisie
/// du chat IA, pour aider l'étudiant à démarrer une conversation.
///
/// Usage :
/// ```dart
/// AiSuggestionChip(label: 'Explique-moi les Widgets', onTap: () => ...)
/// ```
class AiSuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AiSuggestionChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.aiSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: AppColors.aiPrimary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: AppDimensions.iconSm, color: AppColors.aiPrimary),
            const SizedBox(width: AppDimensions.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.aiPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
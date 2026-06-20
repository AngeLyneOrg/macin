import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Chip de filtre sélectionnable (niveau, tag...).
///
/// Différent du `Chip` Material standard : état visuel "actif" plus
/// marqué (fond primaire plein) pour bien voir quel filtre est
/// appliqué dans une liste horizontale de chips.
///
/// Usage :
/// ```dart
/// MacinFilterChip(
///   label: 'Débutant',
///   isSelected: selectedLevel == 'beginner',
///   onTap: () => setState(() => selectedLevel = 'beginner'),
/// )
/// ```
class MacinFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const MacinFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppDimensions.iconSm,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.xs),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
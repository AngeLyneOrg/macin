import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Petite carte de statistique réutilisable : icône + valeur + label.
///
/// Utilisé en rangée dans [ProfilePage] (cours suivis, badges,
/// streak) et [WalletPage] (filleuls actifs, commissions totales).
///
/// Usage :
/// ```dart
/// StatPill(icon: Icons.local_fire_department_rounded, value: '12', label: 'Jours de suite')
/// ```
class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppDimensions.iconLg),
          const SizedBox(height: AppDimensions.xs),
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
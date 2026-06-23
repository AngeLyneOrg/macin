import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';

/// En-tête de section réutilisable : titre + bouton "Voir tout" optionnel.
///
/// [icon] et [subtitle] sont optionnels (par défaut absents, donc 100%
/// rétrocompatible avec les usages existants) — utilisés sur les pages
/// redesignées pour donner un peu plus de hiérarchie visuelle aux
/// sections (Catalogue, Profil, Wallet).
///
/// Usage :
/// ```dart
/// SectionHeader(title: 'Cours populaires', onSeeAll: () => ...)
/// SectionHeader(title: 'Mes badges', subtitle: '5/6 débloqués', icon: Icons.emoji_events_rounded)
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.seeAllLabel = 'Voir tout',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(icon, size: AppDimensions.iconSm, color: AppColors.primary),
                ),
                const SizedBox(width: AppDimensions.sm),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.heading2, overflow: TextOverflow.ellipsis),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(seeAllLabel),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_text_styles.dart';

/// En-tête de section réutilisable : titre + bouton "Voir tout" optionnel.
///
/// Usage :
/// ```dart
/// SectionHeader(title: 'Cours populaires', onSeeAll: () => ...)
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.seeAllLabel = 'Voir tout',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading2),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(seeAllLabel),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/ai_insight_models.dart';

/// Ligne de conseil généré par MACI (pédagogique, organisation du
/// temps, motivation, ou technique).
///
/// Usage :
/// ```dart
/// AiTipTile(tip: tip)
/// ```
class AiTipTile extends StatelessWidget {
  final AiTip tip;

  const AiTipTile({super.key, required this.tip});

  IconData get _icon => switch (tip.category) {
        AiTipCategory.study => Icons.menu_book_rounded,
        AiTipCategory.time => Icons.schedule_rounded,
        AiTipCategory.motivation => Icons.bolt_rounded,
        AiTipCategory.technical => Icons.code_rounded,
      };

  Color get _color => switch (tip.category) {
        AiTipCategory.study => AppColors.primary,
        AiTipCategory.time => AppColors.accent,
        AiTipCategory.motivation => AppColors.secondary,
        AiTipCategory.technical => AppColors.aiPrimary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 16, color: _color),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(tip.message, style: AppTextStyles.body2),
            ),
          ),
        ],
      ),
    );
  }
}

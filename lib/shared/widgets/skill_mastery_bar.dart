import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/ai_insight_models.dart';

/// Barre de maîtrise d'une compétence — utilisée dans la section
/// "Points faibles par compétence" du dashboard MACI.
///
/// Coloration automatique : rouge si [SkillStat.isWeak], vert
/// sinon. Permet à l'étudiant de voir en un coup d'œil où
/// concentrer ses efforts.
///
/// Usage :
/// ```dart
/// SkillMasteryBar(stat: SkillStat(skillName: 'Async/Await', masteryPercent: 42))
/// ```
class SkillMasteryBar extends StatelessWidget {
  final SkillStat stat;

  const SkillMasteryBar({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = stat.isWeak ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stat.skillName, style: AppTextStyles.body2),
              Text(
                '${stat.masteryPercent.round()}%',
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            child: LinearProgressIndicator(
              value: stat.masteryPercent / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

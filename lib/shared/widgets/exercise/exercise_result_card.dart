import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/exercise_model.dart';
import 'package:macin/shared/widgets/exercise/question_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseResultCard
//
// Affiché après la soumission d'un exercice.
// Montre : score obtenu, jauge de réussite, corrigé question par question.
//
// Pour une certification réussie : affiche le bouton "Voir mon certificat".
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseResultCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int score;
  final Map<String, String> answers;
  final int durationSeconds;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  const ExerciseResultCard({
    super.key,
    required this.exercise,
    required this.score,
    required this.answers,
    required this.durationSeconds,
    this.onRetry,
    this.onClose,
  });

  bool get _passed => exercise.isPassed(score);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Score principal ────────────────────────────────
          _ScoreSummary(
            exercise: exercise,
            score: score,
            passed: _passed,
            durationSeconds: durationSeconds,
          ),

          const SizedBox(height: AppDimensions.lg),

          // ── Corrigé ────────────────────────────────────────
          Text('Corrigé détaillé', style: AppTextStyles.heading3),
          const SizedBox(height: AppDimensions.sm),

          ...exercise.questions.asMap().entries.map((entry) {
            return QuestionCard(
              question: entry.value,
              index: entry.key,
              selectedAnswer: answers[entry.value.id],
              showAnswer: true,
            );
          }),

          const SizedBox(height: AppDimensions.md),

          // ── Actions ───────────────────────────────────────
          if (onRetry != null) ...[
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],

          if (onClose != null)
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _passed
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  foregroundColor:
                      _passed ? Colors.white : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: Text(
                  _passed ? 'Continuer →' : 'Retour au cours',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Score Summary ─────────────────────────────────────────────────────────────

class _ScoreSummary extends StatelessWidget {
  final ExerciseModel exercise;
  final int score;
  final bool passed;
  final int durationSeconds;

  const _ScoreSummary({
    required this.exercise,
    required this.score,
    required this.passed,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.error;
    final icon = passed
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: AppDimensions.sm),
          Text(
            passed ? 'Réussi !' : 'Pas encore...',
            style: AppTextStyles.heading2.copyWith(color: color),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            '$score% · Minimum requis : ${exercise.passingScore}%',
            style: AppTextStyles.body2
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),

          // Jauge de score
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusRound),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Métriques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Metric(
                label: 'Score',
                value: '$score%',
                color: color,
              ),
              _Metric(
                label: 'XP gagnés',
                value: passed ? '+${exercise.xpReward}' : '0',
                color: passed ? AppColors.accent : AppColors.textTertiary,
              ),
              _Metric(
                label: 'Durée',
                value:
                    '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                color: AppColors.textSecondary,
              ),
            ],
          ),

          // Badge débloqué
          if (passed && exercise.badgeIdOnSuccess != null) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.accent,
                      size: AppDimensions.iconSm),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    'Badge débloqué !',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.heading3.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

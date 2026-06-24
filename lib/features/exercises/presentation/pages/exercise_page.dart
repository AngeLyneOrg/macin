import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/exercise_model.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/repositories/repositories.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExercisePage
//
// Liste tous les exercices d'un module (quiz, exam, code_challenge,
// certification_test) avec le meilleur score de l'étudiant et un
// indicateur de réussite.
//
// Route : /catalog/:id/module/:moduleId/exercises
// Paramètres :
//   id       → courseId
//   moduleId → moduleId du module courant
// ─────────────────────────────────────────────────────────────────────────────

class ExercisePage extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const ExercisePage({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _courseRepo = CourseRepository();
  final _progressRepo = ProgressRepository();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late final Future<List<ExerciseModel>> _exercisesFuture =
  _courseRepo.getExercises(widget.courseId, widget.moduleId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: FutureBuilder<List<ExerciseModel>>(
              future: _exercisesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snap.hasError) {
                  return _buildError(snap.error.toString());
                }
                final exercises = snap.data ?? [];
                if (exercises.isEmpty) {
                  return _buildEmpty();
                }
                return _buildList(exercises);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        height: AppDimensions.appBarHeight,
        padding:
        const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border:
          Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: AppDimensions.xs),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exercices & Évaluations',
                    style: AppTextStyles.body1Medium),
                Text('Module · ID ${widget.moduleId}',
                    style: AppTextStyles.captionMedium,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── États ─────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_outlined,
              size: AppDimensions.iconXxl, color: AppColors.textTertiary),
          const SizedBox(height: AppDimensions.base),
          Text('Aucun exercice pour ce module',
              style: AppTextStyles.body1Medium),
          const SizedBox(height: AppDimensions.sm),
          Text('Revenez quand le formateur aura ajouté des exercices.',
              style: AppTextStyles.body2, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: AppDimensions.iconXxl, color: AppColors.error),
            const SizedBox(height: AppDimensions.base),
            Text('Impossible de charger les exercices',
                style: AppTextStyles.heading3),
            const SizedBox(height: AppDimensions.sm),
            Text(error,
                style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Liste ─────────────────────────────────────────────────

  Widget _buildList(List<ExerciseModel> exercises) {
    // Tri par order
    final sorted = [...exercises]
      ..sort((a, b) => a.order.compareTo(b.order));

    return StreamBuilder<UserProgressModel?>(
      stream: _uid != null
          ? _progressRepo.watchProgress(_uid!, widget.courseId)
          : const Stream.empty(),
      builder: (context, progressSnap) {
        final progress = progressSnap.data;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.pagePaddingV,
          ),
          itemCount: sorted.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            final ex = sorted[index];
            final isCompleted =
                progress?.isExercisePassed(ex.exerciseId) ?? false;
            final bestScore =
            progress?.exerciseScores[ex.exerciseId];

            return _ExerciseTile(
              exercise: ex,
              isCompleted: isCompleted,
              bestScore: bestScore,
              onTap: () => context.goNamed(
                AppRoutes.exerciseRunner,
                pathParameters: {
                  'id': widget.courseId,
                  'moduleId': widget.moduleId,
                  'exerciseId': ex.exerciseId,
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExerciseTile
//
// Carte d'un exercice dans la liste.
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isCompleted;
  final int? bestScore;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.exercise,
    required this.isCompleted,
    this.bestScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (typeIcon, typeLabel, typeColor) = _typeInfo(exercise.type);
    final passed = bestScore != null && exercise.isPassed(bestScore!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: passed ? AppColors.success : AppColors.border,
            width: passed ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child:
                  Icon(typeIcon, color: typeColor, size: AppDimensions.iconMd),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.title, style: AppTextStyles.body1Medium),
                      Text(typeLabel,
                          style: AppTextStyles.captionMedium
                              .copyWith(color: typeColor)),
                    ],
                  ),
                ),
                // Badge de statut
                if (passed)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: AppDimensions.iconMd)
                else if (bestScore != null)
                  const Icon(Icons.refresh_rounded,
                      color: AppColors.warning, size: AppDimensions.iconMd),
              ],
            ),

            const SizedBox(height: AppDimensions.sm),

            // ── Méta ──────────────────────────────────────────
            Row(
              children: [
                _MetaChip(
                  icon: Icons.help_outline_rounded,
                  label: '${exercise.questions.length} questions',
                ),
                const SizedBox(width: AppDimensions.sm),
                _MetaChip(
                  icon: Icons.bolt_rounded,
                  label: '+${exercise.xpReward} XP',
                  color: AppColors.accent,
                ),
                if (exercise.hasTimeLimit) ...[
                  const SizedBox(width: AppDimensions.sm),
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label: '${exercise.timeLimitMin} min',
                    color: AppColors.error,
                  ),
                ],
                const Spacer(),
                // Score requis
                Text(
                  'Requis ${exercise.passingScore} %',
                  style: AppTextStyles.captionMedium,
                ),
              ],
            ),

            // ── Meilleur score ───────────────────────────────
            if (bestScore != null) ...[
              const SizedBox(height: AppDimensions.sm),
              _ScoreBar(
                score: bestScore!,
                passingScore: exercise.passingScore,
              ),
            ],

            // ── Description ──────────────────────────────────
            if (exercise.description != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(exercise.description!,
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: AppDimensions.sm),

            // ── CTA ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: Icon(
                  passed ? Icons.replay_rounded : Icons.play_arrow_rounded,
                  size: AppDimensions.iconMd,
                ),
                label: Text(passed
                    ? 'Revoir / Réessayer'
                    : bestScore != null
                    ? 'Réessayer'
                    : 'Commencer'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                  passed ? AppColors.success : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  minimumSize:
                  const Size.fromHeight(AppDimensions.buttonHeightSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, Color) _typeInfo(String type) => switch (type) {
    'quiz' => (Icons.quiz_outlined, 'Quiz', AppColors.primary),
    'exam' => (Icons.assignment_outlined, 'Examen', AppColors.secondary),
    'certification_test' => (
    Icons.workspace_premium_outlined,
    'Certification',
    AppColors.accent
    ),
    'code_challenge' => (
    Icons.code_rounded,
    'Code challenge',
    AppColors.success
    ),
    _ => (Icons.help_outline_rounded, type, AppColors.textTertiary),
  };
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.captionMedium.copyWith(color: color)),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  final int passingScore;

  const _ScoreBar({required this.score, required this.passingScore});

  @override
  Widget build(BuildContext context) {
    final passed = score >= passingScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Meilleur score',
                style: AppTextStyles.captionMedium),
            Text(
              '$score %',
              style: AppTextStyles.captionMedium.copyWith(
                  color: passed ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: passed ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }
}
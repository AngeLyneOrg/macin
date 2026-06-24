import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/shared/models/exercise_model.dart';
import 'package:macin/shared/repositories/repositories.dart';
import 'package:macin/shared/widgets/exercise/exercise_runner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseRunnerPage
//
// Page hôte de [ExerciseRunner].
//
// Responsabilités :
//   1. Charger l'exercice depuis Firestore (via CourseRepository)
//   2. Passer le modèle à ExerciseRunner
//   3. Gérer la soumission → ProgressRepository.submitExercise()
//   4. Afficher les états loading / erreur / exercice
//
// Route : /catalog/:id/module/:moduleId/exercises/:exerciseId
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseRunnerPage extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String exerciseId;

  const ExerciseRunnerPage({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.exerciseId,
  });

  @override
  State<ExerciseRunnerPage> createState() => _ExerciseRunnerPageState();
}

class _ExerciseRunnerPageState extends State<ExerciseRunnerPage> {
  final _courseRepo = CourseRepository();
  final _progressRepo = ProgressRepository();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late final Future<ExerciseModel> _exerciseFuture = _loadExercise();

  Future<ExerciseModel> _loadExercise() async {
    final all = await _courseRepo.getExercises(
      widget.courseId,
      widget.moduleId,
    );
    return all.firstWhere(
          (e) => e.exerciseId == widget.exerciseId,
      orElse: () => throw Exception(
          'Exercice \${widget.exerciseId} introuvable dans ce module.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ExerciseModel>(
        future: _exerciseFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snap.hasError || !snap.hasData) {
            return _buildError(snap.error?.toString() ?? 'Exercice introuvable');
          }
          return _buildRunner(snap.data!);
        },
      ),
    );
  }

  // ── États ─────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _buildTopBar(title: 'Chargement…'),
        const Expanded(
          child:
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Column(
      children: [
        _buildTopBar(title: 'Erreur'),
        Expanded(
          child: Center(
            child: Padding(
              padding:
              const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: AppDimensions.iconXxl, color: AppColors.error),
                  const SizedBox(height: AppDimensions.base),
                  Text('Impossible de charger l\'exercice',
                      style: AppTextStyles.heading3,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppDimensions.sm),
                  Text(message,
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppDimensions.xl),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour aux exercices'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunner(ExerciseModel exercise) {
    return Column(
      children: [
        _buildTopBar(title: exercise.title, subtitle: _exerciseTypeLabel(exercise.type)),
        Expanded(
          child: ExerciseRunner(
            exercise: exercise,
            onSubmit: (answers, durationSeconds) async {
              final uid = _uid;
              if (uid == null) return;

              final score = exercise.calculateScore(answers);

              await _progressRepo.submitExercise(
                userId: uid,
                courseId: widget.courseId,
                exerciseId: widget.exerciseId,
                score: score,
                passingScore: exercise.passingScore,
              );

              if (mounted && exercise.isPassed(score)) {
                context.showSuccessSnack(
                    'Exercice réussi ! +${exercise.xpReward} XP');
              }
            },
            onPass: () {
              // Retour à la liste des exercices après réussite
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) context.pop();
              });
            },
            onCancel: () => context.pop(),
          ),
        ),
      ],
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  Widget _buildTopBar({required String title, String? subtitle}) {
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
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textPrimary,
              tooltip: 'Quitter l\'exercice',
              onPressed: () => _confirmQuit(context),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body1Medium,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null)
                    Text(subtitle,
                        style: AppTextStyles.captionMedium,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Future<void> _confirmQuit(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'exercice ?'),
        content: const Text(
            'Vos réponses ne seront pas enregistrées si vous quittez maintenant.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuer')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) context.pop();
  }

  String _exerciseTypeLabel(String type) => switch (type) {
    'quiz' => 'Quiz',
    'exam' => 'Examen',
    'certification_test' => 'Test de certification',
    'code_challenge' => 'Code challenge',
    _ => type,
  };
}
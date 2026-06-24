import 'dart:async';
import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/exercise_model.dart';
import 'package:macin/shared/widgets/exercise/question_card.dart';
import 'package:macin/shared/widgets/exercise/exercise_result_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseRunner
//
// Widget principal pour faire passer un exercice à un étudiant.
// Gère le cycle complet : affichage des questions → soumission → résultat.
//
// Supporte tous les types d'exercices de l'admin :
//   quiz              → questions simples, pas de limite de temps
//   exam              → avec timer, score affiché uniquement à la fin
//   certification_test → timer strict, ne peut passer qu'une seule fois
//   code_challenge    → affiche le template de code (lecture seule)
//
// Callbacks :
//   onSubmit(answers, durationSeconds) → appelé quand l'étudiant soumet
//   onPass()                           → appelé quand le score >= passingScore
//
// Usage :
//   ExerciseRunner(
//     exercise: exerciseModel,
//     onSubmit: (answers, duration) async {
//       await progressRepo.submitExercise(...);
//     },
//     onPass: () => context.pop(),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseRunner extends StatefulWidget {
  final ExerciseModel exercise;
  final Future<void> Function(Map<String, String> answers, int durationSeconds)
      onSubmit;
  final VoidCallback? onPass;
  final VoidCallback? onCancel;

  const ExerciseRunner({
    super.key,
    required this.exercise,
    required this.onSubmit,
    this.onPass,
    this.onCancel,
  });

  @override
  State<ExerciseRunner> createState() => _ExerciseRunnerState();
}

class _ExerciseRunnerState extends State<ExerciseRunner> {
  // État des réponses : {questionId: réponse sélectionnée}
  final Map<String, String> _answers = {};

  // Résultat après soumission
  int? _score;
  bool _submitted = false;
  bool _submitting = false;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Initialiser le compte à rebours si l'exercice a une limite de temps
    if (widget.exercise.hasTimeLimit) {
      _remainingSeconds = widget.exercise.timeLimitMin! * 60;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_remainingSeconds != null) {
          _remainingSeconds = _remainingSeconds! - 1;
          // Temps écoulé → soumission automatique
          if (_remainingSeconds! <= 0) {
            t.cancel();
            _submit(forcedByTimer: true);
          }
        }
      });
    });
  }

  Future<void> _submit({bool forcedByTimer = false}) async {
    if (_submitted || _submitting) return;
    _timer?.cancel();

    setState(() => _submitting = true);

    final score = widget.exercise.calculateScore(_answers);
    await widget.onSubmit(_answers, _elapsedSeconds);

    if (!mounted) return;
    setState(() {
      _score = score;
      _submitted = true;
      _submitting = false;
    });

    if (widget.exercise.isPassed(score)) {
      widget.onPass?.call();
    }
  }

  bool get _canSubmit {
    // Pour les quiz/examens : toutes les questions répondues
    if (widget.exercise.questions.isEmpty) return true;
    return _answers.length >= widget.exercise.questions.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted && _score != null) {
      return ExerciseResultCard(
        exercise: widget.exercise,
        score: _score!,
        answers: _answers,
        durationSeconds: _elapsedSeconds,
        onRetry: widget.exercise.isCertificationTest
            ? null // pas de réessai pour la certification
            : () => setState(() {
                  _answers.clear();
                  _score = null;
                  _submitted = false;
                  _elapsedSeconds = 0;
                  _remainingSeconds = widget.exercise.hasTimeLimit
                      ? widget.exercise.timeLimitMin! * 60
                      : null;
                  _startTimer();
                }),
        onClose: widget.onCancel,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête ────────────────────────────────────────
        _ExerciseHeader(
          exercise: widget.exercise,
          remainingSeconds: _remainingSeconds,
          answeredCount: _answers.length,
          totalCount: widget.exercise.questions.length,
        ),

        const SizedBox(height: AppDimensions.md),

        // ── Template de code (code_challenge uniquement) ──
        if (widget.exercise.isCodeChallenge &&
            widget.exercise.codeTemplate != null) ...[
          _CodeTemplateViewer(
            template: widget.exercise.codeTemplate!,
            language: widget.exercise.codeLanguage ?? 'dart',
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        // ── Questions ──────────────────────────────────────
        ...widget.exercise.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return QuestionCard(
            question: question,
            index: index,
            selectedAnswer: _answers[question.id],
            showAnswer: false, // révélé uniquement après soumission
            onAnswerSelected: (answer) {
              setState(() => _answers[question.id] = answer);
            },
          );
        }),

        const SizedBox(height: AppDimensions.lg),

        // ── Bouton soumettre ───────────────────────────────
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton(
            onPressed:
                (_canSubmit && !_submitting) ? () => _submit() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    widget.exercise.isCertificationTest
                        ? 'Soumettre et obtenir ma certification'
                        : 'Soumettre mes réponses',
                    style: AppTextStyles.labelLarge,
                  ),
          ),
        ),

        const SizedBox(height: AppDimensions.base),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Widgets privés
// ═════════════════════════════════════════════════════════════════════════════

class _ExerciseHeader extends StatelessWidget {
  final ExerciseModel exercise;
  final int? remainingSeconds;
  final int answeredCount;
  final int totalCount;

  const _ExerciseHeader({
    required this.exercise,
    required this.remainingSeconds,
    required this.answeredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(type: exercise.type),
              const Spacer(),
              // Timer
              if (remainingSeconds != null)
                _TimerBadge(remainingSeconds: remainingSeconds!),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(exercise.title, style: AppTextStyles.heading3),
          if (exercise.description != null &&
              exercise.description!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(exercise.description!,
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppDimensions.sm),
          // Progression des réponses
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                  child: LinearProgressIndicator(
                    value: totalCount > 0
                        ? answeredCount / totalCount
                        : 0,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                '$answeredCount/$totalCount',
                style: AppTextStyles.captionMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'quiz' => ('Quiz', AppColors.primary),
      'code_challenge' => ('Code', AppColors.success),
      'exam' => ('Examen', AppColors.warning),
      'certification_test' => ('Certification', AppColors.accent),
      _ => ('Exercice', AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int remainingSeconds;
  const _TimerBadge({required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds < 60;
    final color = isUrgent ? AppColors.error : AppColors.textSecondary;
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: AppDimensions.iconSm, color: color),
        const SizedBox(width: 4),
        Text(
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CodeTemplateViewer extends StatelessWidget {
  final String template;
  final String language;
  const _CodeTemplateViewer(
      {required this.template, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.codeBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs),
            child: Text(
              language.toUpperCase(),
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          const Divider(height: 1, color: AppColors.codeBorder),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppDimensions.md),
            child: SelectableText(
              template,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.codeText,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

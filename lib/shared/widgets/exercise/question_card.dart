import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/exercise_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionCard
//
// Affiche une question et ses options de réponse.
// Supporte les types définis dans l'admin :
//   mcq        → liste de boutons radio (options multiples)
//   true_false → deux boutons Vrai / Faux
//   text_input → champ texte libre
//   code_output → champ texte pour la sortie attendue
//
// En mode [showAnswer] (après soumission) :
//   - Option correcte en vert
//   - Option sélectionnée incorrecte en rouge
//   - Explication affichée en dessous
// ─────────────────────────────────────────────────────────────────────────────

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int index;
  final String? selectedAnswer;
  final bool showAnswer;
  final ValueChanged<String>? onAnswerSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    this.selectedAnswer,
    this.showAnswer = false,
    this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Numéro + Points ────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                '${question.points} point${question.points > 1 ? 's' : ''}',
                style: AppTextStyles.captionMedium,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.sm),

          // ── Énoncé ─────────────────────────────────────────
          Text(question.questionText, style: AppTextStyles.body1Medium),

          const SizedBox(height: AppDimensions.md),

          // ── Options de réponse ─────────────────────────────
          _buildOptions(),

          // ── Explication (après soumission) ─────────────────
          if (showAnswer &&
              question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            _ExplanationBanner(explanation: question.explanation!),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return switch (question.type) {
      'true_false' => _buildTrueFalseOptions(),
      'text_input' || 'code_output' => _buildTextInput(),
      _ => _buildMcqOptions(), // 'mcq' par défaut
    };
  }

  Widget _buildMcqOptions() {
    return Column(
      children: question.options.map((option) {
        final isSelected = selectedAnswer == option;
        final isCorrect = question.correctAnswer == option;

        Color borderColor = AppColors.border;
        Color bgColor = Colors.transparent;
        Color textColor = AppColors.textPrimary;

        if (showAnswer) {
          if (isCorrect) {
            borderColor = AppColors.success;
            bgColor = AppColors.successSurface;
            textColor = AppColors.success;
          } else if (isSelected && !isCorrect) {
            borderColor = AppColors.error;
            bgColor = AppColors.errorSurface;
            textColor = AppColors.error;
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primarySurface;
          textColor = AppColors.primary;
        }

        return GestureDetector(
          onTap: showAnswer ? null : () => onAnswerSelected?.call(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(option,
                      style: AppTextStyles.body2.copyWith(color: textColor)),
                ),
                if (showAnswer && isCorrect)
                  Icon(Icons.check_circle_rounded,
                      size: AppDimensions.iconSm, color: AppColors.success),
                if (showAnswer && isSelected && !isCorrect)
                  Icon(Icons.cancel_rounded,
                      size: AppDimensions.iconSm, color: AppColors.error),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions() {
    return Row(
      children: ['Vrai', 'Faux'].map((option) {
        final isSelected = selectedAnswer == option;
        final isCorrect = question.correctAnswer == option;

        Color borderColor = AppColors.border;
        Color bgColor = Colors.transparent;
        Color textColor = AppColors.textPrimary;
        IconData? icon;

        if (showAnswer) {
          if (isCorrect) {
            borderColor = AppColors.success;
            bgColor = AppColors.successSurface;
            textColor = AppColors.success;
            icon = Icons.check_rounded;
          } else if (isSelected && !isCorrect) {
            borderColor = AppColors.error;
            bgColor = AppColors.errorSurface;
            textColor = AppColors.error;
            icon = Icons.close_rounded;
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primarySurface;
          textColor = AppColors.primary;
        }

        return Expanded(
          child: GestureDetector(
            onTap: showAnswer ? null : () => onAnswerSelected?.call(option),
            child: Container(
              margin: EdgeInsets.only(
                right: option == 'Vrai' ? AppDimensions.xs : 0,
                left: option == 'Faux' ? AppDimensions.xs : 0,
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.md),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  if (icon != null)
                    Icon(icon, color: textColor, size: AppDimensions.iconMd),
                  Text(
                    option,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body1Medium.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput() {
    return _TextAnswerField(
      placeholder: question.type == 'code_output'
          ? 'Entrez la sortie attendue...'
          : 'Votre réponse...',
      initialValue: selectedAnswer ?? '',
      enabled: !showAnswer,
      onChanged: (v) => onAnswerSelected?.call(v),
      isCorrect: showAnswer ? question.isCorrect(selectedAnswer ?? '') : null,
      correctAnswer: showAnswer ? question.correctAnswer : null,
    );
  }
}

// ── Champ texte libre ─────────────────────────────────────────────────────────

class _TextAnswerField extends StatefulWidget {
  final String placeholder;
  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final bool? isCorrect;
  final String? correctAnswer;

  const _TextAnswerField({
    required this.placeholder,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
    this.isCorrect,
    this.correctAnswer,
  });

  @override
  State<_TextAnswerField> createState() => _TextAnswerFieldState();
}

class _TextAnswerFieldState extends State<_TextAnswerField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    if (widget.isCorrect == true) borderColor = AppColors.success;
    if (widget.isCorrect == false) borderColor = AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          maxLines: 3,
          style: AppTextStyles.body2.copyWith(fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle:
                AppTextStyles.body2.copyWith(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(AppDimensions.sm),
          ),
        ),
        if (widget.isCorrect == false && widget.correctAnswer != null) ...[
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Réponse attendue : ${widget.correctAnswer}',
            style: AppTextStyles.captionMedium
                .copyWith(color: AppColors.success),
          ),
        ],
      ],
    );
  }
}

// ── Explication ───────────────────────────────────────────────────────────────

class _ExplanationBanner extends StatelessWidget {
  final String explanation;
  const _ExplanationBanner({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border(
          left: BorderSide(color: AppColors.info, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: AppDimensions.iconSm, color: AppColors.info),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              explanation,
              style: AppTextStyles.body2
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

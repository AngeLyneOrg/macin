import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/ai_insight_models.dart';

/// Carte combinant une jauge circulaire (style speedometer) et un
/// statut textuel coloré pour représenter le score de risque/santé
/// d'apprentissage calculé par MACI.
///
/// [riskScore] est attendu entre 0.0 (aucun risque) et 1.0 (risque
/// élevé) — même échelle que [UserProgressModel.aiRiskScore].
///
/// Usage :
/// ```dart
/// RiskGaugeCard(riskScore: 0.28)
/// ```
class RiskGaugeCard extends StatelessWidget {
  final double riskScore;

  const RiskGaugeCard({super.key, required this.riskScore});

  Color get _color {
    final level = AiRiskLevelX.fromScore(riskScore);
    return switch (level) {
      AiRiskLevel.onTrack => AppColors.success,
      AiRiskLevel.attention => AppColors.warning,
      AiRiskLevel.atRisk => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final level = AiRiskLevelX.fromScore(riskScore);
    final healthScore = 1.0 - riskScore; // pour la jauge, on affiche la "santé"
    final color = _color;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _GaugePainter(value: healthScore, color: color),
              child: Center(
                child: Text(
                  '${(healthScore * 100).round()}%',
                  style: AppTextStyles.heading3.copyWith(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  ),
                  child: Text(
                    level.label,
                    style: AppTextStyles.labelSmall.copyWith(color: color),
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  level.description,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre custom pour la jauge en arc de cercle (style speedometer,
/// 270° de balayage, de -135° à +135°).
class _GaugePainter extends CustomPainter {
  final double value; // 0.0 - 1.0
  final Color color;

  _GaugePainter({required this.value, required this.color});

  static const _startAngle = -3 * pi / 4; // -135°
  static const _sweepMax = 3 * pi / 2; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepMax,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepMax * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

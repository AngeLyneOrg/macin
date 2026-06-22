import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/ai_insight_models.dart';

enum _ProgressMetric { xp, quizScore, completion }

/// Graphique de progression combinant trois métriques au choix :
/// XP gagné, score moyen aux quiz, taux de complétion.
///
/// Plutôt que d'afficher les trois courbes en même temps (illisible,
/// échelles différentes : XP en centaines, scores en %), l'étudiant
/// bascule via des chips au-dessus du graphique. Chaque métrique a
/// sa propre couleur cohérente avec le reste de l'app (accent pour
/// XP, primaire pour quiz, succès pour complétion).
///
/// Usage :
/// ```dart
/// ProgressMultiChart(points: weeklySnapshots)
/// ```
class ProgressMultiChart extends StatefulWidget {
  final List<WeeklyProgressPoint> points;

  const ProgressMultiChart({super.key, required this.points});

  @override
  State<ProgressMultiChart> createState() => _ProgressMultiChartState();
}

class _ProgressMultiChartState extends State<ProgressMultiChart> {
  _ProgressMetric _selected = _ProgressMetric.xp;

  Color get _color => switch (_selected) {
        _ProgressMetric.xp => AppColors.accent,
        _ProgressMetric.quizScore => AppColors.primary,
        _ProgressMetric.completion => AppColors.success,
      };

  String get _unit => switch (_selected) {
        _ProgressMetric.xp => 'XP',
        _ProgressMetric.quizScore => '%',
        _ProgressMetric.completion => '%',
      };

  double _valueFor(WeeklyProgressPoint p) => switch (_selected) {
        _ProgressMetric.xp => p.xpGained.toDouble(),
        _ProgressMetric.quizScore => p.averageQuizScore,
        _ProgressMetric.completion => p.completionRate,
      };

  double get _maxY => switch (_selected) {
        _ProgressMetric.xp =>
          (widget.points.map((p) => p.xpGained).reduce((a, b) => a > b ? a : b) * 1.2)
              .toDouble(),
        _ => 100,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ta progression', style: AppTextStyles.heading3),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              _MetricChip(
                label: 'XP',
                isSelected: _selected == _ProgressMetric.xp,
                color: AppColors.accent,
                onTap: () => setState(() => _selected = _ProgressMetric.xp),
              ),
              const SizedBox(width: AppDimensions.sm),
              _MetricChip(
                label: 'Score quiz',
                isSelected: _selected == _ProgressMetric.quizScore,
                color: AppColors.primary,
                onTap: () => setState(() => _selected = _ProgressMetric.quizScore),
              ),
              const SizedBox(width: AppDimensions.sm),
              _MetricChip(
                label: 'Complétion',
                isSelected: _selected == _ProgressMetric.completion,
                color: AppColors.success,
                onTap: () => setState(() => _selected = _ProgressMetric.completion),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.base),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: _maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.xs),
                          child: Text('S${index + 1}', style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${s.y.round()}$_unit',
                        AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.points
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), _valueFor(e.value)))
                        .toList(),
                    isCurved: true,
                    color: _color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(radius: 3, color: _color, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(show: true, color: _color.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MetricChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

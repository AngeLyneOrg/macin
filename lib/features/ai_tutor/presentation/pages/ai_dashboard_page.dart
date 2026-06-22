import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/models/ai_insight_models.dart';
import '../../../../shared/widgets/ai_tip_tile.dart';
import '../../../../shared/widgets/maci_avatar.dart';
import '../../../../shared/widgets/progress_multi_chart.dart';
import '../../../../shared/widgets/recommendation_card.dart';
import '../../../../shared/widgets/risk_gauge_card.dart';
import '../../../../shared/widgets/skill_mastery_bar.dart';

/// Dashboard d'analyse IA — vue principale de l'onglet "MACI".
///
/// Contrairement à un simple chatbot, cette page présente une
/// synthèse complète générée par l'agent MACI : santé
/// d'apprentissage (prédiction de risque), courbes de progression,
/// recommandations de contenu, conseils, et points faibles par
/// compétence. Le chat libre est accessible via le bouton dédié,
/// qui navigue vers [AiChatPage] (route séparée [AppRoutes.aiChat]).
///
/// DONNÉES TEMPLATES : toutes les sections utilisent des données en
/// dur (voir le bas du fichier). À terme :
///   - [RiskGaugeCard] consomme [UserProgressModel.aiRiskScore]
///     (calculé par FastAPI `/predict-failure`, voir roadmap M5)
///   - [ProgressMultiChart] consomme un historique hebdomadaire
///     agrégé (nouvel endpoint ou Cloud Function de snapshot)
///   - [RecommendationCard] consomme FastAPI `/recommend`
///   - Les conseils et compétences viennent du même pipeline IA
class AiDashboardPage extends StatelessWidget {
  const AiDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            title: Text('MACI', style: AppTextStyles.heading2),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.sm),
                  _buildHeader(context),
                  const SizedBox(height: AppDimensions.xl),
                  const RiskGaugeCard(riskScore: _templateRiskScore),
                  const SizedBox(height: AppDimensions.xl),
                  ProgressMultiChart(points: _templateWeeklyPoints),
                  const SizedBox(height: AppDimensions.xl),
                  _buildRecommendationsSection(context),
                  const SizedBox(height: AppDimensions.xl),
                  _buildSkillsSection(),
                  const SizedBox(height: AppDimensions.xl),
                  _buildTipsSection(),
                  const SizedBox(height: AppDimensions.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildChatFab(context),
    );
  }

  // ── Header : avatar MACI + synthèse du jour ───────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.aiSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          const MaciAvatar(size: 52, withGlow: true),
          const SizedBox(width: AppDimensions.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut, voici ton bilan',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 2),
                Text(
                  _templateDailySummary,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommandations ────────────────────────────────────────────
  Widget _buildRecommendationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommandé pour toi', style: AppTextStyles.heading2),
        const SizedBox(height: AppDimensions.base),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templateRecommendations.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, index) {
              final rec = _templateRecommendations[index];
              return RecommendationCard(
                recommendation: rec,
                onTap: () {
                  // TODO: context.pushNamed(AppRoutes.lessonPlayer, ...)
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Compétences ────────────────────────────────────────────────
  Widget _buildSkillsSection() {
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
          Text('Tes compétences', style: AppTextStyles.heading3),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Basé sur tes scores aux quiz et exercices.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppDimensions.base),
          ..._templateSkills.map((s) => SkillMasteryBar(stat: s)),
        ],
      ),
    );
  }

  // ── Conseils ───────────────────────────────────────────────────
  Widget _buildTipsSection() {
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
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.accent, size: AppDimensions.iconLg),
              const SizedBox(width: AppDimensions.sm),
              Text('Conseils de MACI', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ..._templateTips.map((tip) => AiTipTile(tip: tip)),
        ],
      ),
    );
  }

  // ── Bouton flottant vers le chat ───────────────────────────────
  Widget _buildChatFab(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.aiPrimary,
      onPressed: () => context.pushNamed(AppRoutes.aiChat),
      icon: const MaciAvatar(size: 24),
      label: Text(
        'Discuter avec MACI',
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }
}

// ── Données templates ────────────────────────────────────────

const _templateRiskScore = 0.28; // 0.0 = sain, 1.0 = risque élevé

const _templateDailySummary =
    "Tu progresses bien cette semaine ! Ton score moyen aux quiz est en hausse de 12%.";

final List<WeeklyProgressPoint> _templateWeeklyPoints = [
  WeeklyProgressPoint(
    weekStart: DateTime.now().subtract(const Duration(days: 35)),
    xpGained: 80,
    averageQuizScore: 62,
    completionRate: 20,
  ),
  WeeklyProgressPoint(
    weekStart: DateTime.now().subtract(const Duration(days: 28)),
    xpGained: 120,
    averageQuizScore: 68,
    completionRate: 35,
  ),
  WeeklyProgressPoint(
    weekStart: DateTime.now().subtract(const Duration(days: 21)),
    xpGained: 95,
    averageQuizScore: 71,
    completionRate: 48,
  ),
  WeeklyProgressPoint(
    weekStart: DateTime.now().subtract(const Duration(days: 14)),
    xpGained: 150,
    averageQuizScore: 75,
    completionRate: 60,
  ),
  WeeklyProgressPoint(
    weekStart: DateTime.now().subtract(const Duration(days: 7)),
    xpGained: 140,
    averageQuizScore: 79,
    completionRate: 72,
  ),
  WeeklyProgressPoint(
    weekStart: DateTime.now(),
    xpGained: 170,
    averageQuizScore: 84,
    completionRate: 81,
  ),
];

final List<AiRecommendation> _templateRecommendations = [
  const AiRecommendation(
    lessonId: 'lesson_async_basics',
    lessonTitle: 'Comprendre async/await',
    courseTitle: 'Dart avancé',
    reason: "Tu as eu 45% sur ce sujet au dernier quiz",
    estimatedMinutes: 12,
  ),
  const AiRecommendation(
    lessonId: 'lesson_firestore_rules',
    lessonTitle: 'Règles de sécurité Firestore',
    courseTitle: 'Firebase pour développeurs',
    reason: "Cours non terminé depuis 5 jours",
    estimatedMinutes: 9,
  ),
  const AiRecommendation(
    lessonId: 'lesson_state_management',
    lessonTitle: 'Gérer l\'état avec Provider',
    courseTitle: 'Les fondamentaux de Flutter',
    reason: "Suite logique de ton dernier module",
    estimatedMinutes: 15,
  ),
];

final List<SkillStat> _templateSkills = [
  const SkillStat(skillName: 'Widgets Flutter', masteryPercent: 82),
  const SkillStat(skillName: 'Async / Await', masteryPercent: 42),
  const SkillStat(skillName: 'Firestore', masteryPercent: 68),
  const SkillStat(skillName: 'Gestion d\'état', masteryPercent: 55),
];

final List<AiTip> _templateTips = [
  const AiTip(
    id: 'tip1',
    message: "Révise les async/await avant de continuer — c'est ton point le plus faible actuellement.",
    category: AiTipCategory.study,
  ),
  const AiTip(
    id: 'tip2',
    message: "Tu apprends mieux le matin : tes scores sont 15% plus élevés avant midi.",
    category: AiTipCategory.time,
  ),
  const AiTip(
    id: 'tip3',
    message: "Encore 3 leçons et tu débloques le badge 'Certifié Flutter' !",
    category: AiTipCategory.motivation,
  ),
];

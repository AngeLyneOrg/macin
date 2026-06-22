import 'package:equatable/equatable.dart';

/// Snapshot hebdomadaire de progression d'un étudiant, utilisé pour
/// tracer les courbes du dashboard MACI (XP, score quiz, complétion).
///
/// Ce n'est pas un modèle Firestore — c'est l'agrégation que l'agent
/// IA FastAPI calculera et renverra via l'endpoint `/predict-failure`
/// ou un futur `/weekly-snapshot`. En attendant ce endpoint, le
/// dashboard consomme des points générés localement (voir
/// `_templateWeeklySnapshots` dans [AiDashboardPage]).
class WeeklyProgressPoint extends Equatable {
  final DateTime weekStart;
  final int xpGained;
  final double averageQuizScore; // 0-100
  final double completionRate; // 0-100, % moyen des cours en cours

  const WeeklyProgressPoint({
    required this.weekStart,
    required this.xpGained,
    required this.averageQuizScore,
    required this.completionRate,
  });

  @override
  List<Object?> get props => [weekStart, xpGained, averageQuizScore, completionRate];
}

/// Niveau de risque d'échec calculé par l'agent MACI (FastAPI).
///
/// Correspond conceptuellement à [UserProgressModel.aiRiskScore],
/// mais enrichi côté UI avec un label et une couleur sémantique
/// pour l'affichage de la jauge + carte combinée du dashboard.
enum AiRiskLevel { onTrack, attention, atRisk }

extension AiRiskLevelX on AiRiskLevel {
  static AiRiskLevel fromScore(double score) {
    if (score < 0.35) return AiRiskLevel.onTrack;
    if (score < 0.65) return AiRiskLevel.attention;
    return AiRiskLevel.atRisk;
  }

  String get label => switch (this) {
    AiRiskLevel.onTrack => 'Sur la bonne voie',
    AiRiskLevel.attention => 'À surveiller',
    AiRiskLevel.atRisk => 'Risque de décrochage',
  };

  String get description => switch (this) {
    AiRiskLevel.onTrack =>
    'Ta régularité et tes scores sont bons. Continue comme ça !',
    AiRiskLevel.attention =>
    'Ton rythme a un peu baissé cette semaine. Un petit coup de collier ?',
    AiRiskLevel.atRisk =>
    'Tu sembles en difficulté. MACI peut te proposer un plan de rattrapage.',
  };
}

/// Recommandation de contenu générée par MACI (leçon, exercice...).
///
/// Correspond à ce que l'endpoint FastAPI `/recommend` retournera
/// (liste de `lessonId` avec score de pertinence) — ici enrichi avec
/// les infos d'affichage (titre, cours parent) pour le rendu direct
/// dans une card, en attendant la dénormalisation ou un join côté
/// Cloud Function proxy.
class AiRecommendation extends Equatable {
  final String lessonId;
  final String lessonTitle;
  final String courseTitle;
  final String reason; // ex: "Tu as eu 45% à ce sujet"
  final int estimatedMinutes;

  const AiRecommendation({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseTitle,
    required this.reason,
    required this.estimatedMinutes,
  });

  @override
  List<Object?> get props => [lessonId, lessonTitle, courseTitle];
}

/// Conseil textuel généré par MACI — pédagogique ou comportemental.
///
/// Catégorie utilisée pour choisir une icône cohérente dans l'UI.
enum AiTipCategory { study, time, motivation, technical }

class AiTip extends Equatable {
  final String id;
  final String message;
  final AiTipCategory category;

  const AiTip({
    required this.id,
    required this.message,
    required this.category,
  });

  @override
  List<Object?> get props => [id, message, category];
}

/// Statistique de compétence — utilisée pour la section "points
/// faibles par compétence" du dashboard.
class SkillStat extends Equatable {
  final String skillName; // ex: "Widgets", "Async/Await", "Firestore"
  final double masteryPercent; // 0-100

  const SkillStat({required this.skillName, required this.masteryPercent});

  bool get isWeak => masteryPercent < 50;

  @override
  List<Object?> get props => [skillName, masteryPercent];
}

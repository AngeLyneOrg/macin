import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/ai_insight_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AiRepository
//
// Client HTTP vers l'API FastAPI MACI.
// Tous les appels IA passent par ici — les widgets ne touchent jamais http.
//
// Endpoints consommés :
//   POST /predict-failure    → score de risque d'échec (0.0 à 1.0)
//   POST /recommend          → liste de lessonIds recommandés avec raison
//   POST /tips               → conseils pédagogiques personnalisés
//   POST /skill-stats        → maîtrise par compétence (pour le dashboard)
//   POST /weekly-snapshot    → points de progression hebdomadaire (graphique)
//
// Usage :
//   final ai = AiRepository();
//   final risk = await ai.predictFailureRisk(userId: uid, courseId: cid);
// ─────────────────────────────────────────────────────────────────────────────

class AiRepository {
  final String _baseUrl;
  final http.Client _client;

  AiRepository({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? AppConstants.aiApiBaseUrl,
        _client = client ?? http.Client();

  // ── Headers communs ───────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─────────────────────────────────────────────────────────
  // predictFailureRisk
  // POST /predict-failure
  //
  // Retourne un score entre 0.0 (aucun risque) et 1.0 (risque élevé).
  // Le score est aussi écrit dans user_progress/{id}.aiRiskScore
  // par une Cloud Function après cet appel (côté FastAPI).
  // ─────────────────────────────────────────────────────────

  Future<double> predictFailureRisk({
    required String userId,
    required String courseId,
    required double progressPercent,
    required List<int> recentQuizScores,
    required int daysSinceLastActivity,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/predict-failure'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'course_id': courseId,
              'progress_percent': progressPercent,
              'recent_quiz_scores': recentQuizScores,
              'days_since_last_activity': daysSinceLastActivity,
            }),
          )
          .timeout(AppConstants.aiRequestTimeout);

      _checkStatus(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['risk_score'] as num?)?.toDouble() ?? 0.0;
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(message: 'Erreur prédiction risque : $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // getRecommendations
  // POST /recommend
  //
  // Retourne une liste de [AiRecommendation] basée sur le profil
  // d'apprentissage, les leçons complétées et les scores récents.
  // ─────────────────────────────────────────────────────────

  Future<List<AiRecommendation>> getRecommendations({
    required String userId,
    required String courseId,
    required List<String> completedLessonIds,
    required Map<String, int> exerciseScores,
    int limit = 3,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/recommend'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'course_id': courseId,
              'completed_lesson_ids': completedLessonIds,
              'exercise_scores': exerciseScores,
              'limit': limit,
            }),
          )
          .timeout(AppConstants.aiRequestTimeout);

      _checkStatus(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['recommendations'] as List? ?? [];
      return rawList
          .map((item) => AiRecommendation(
                lessonId: item['lesson_id'] as String? ?? '',
                lessonTitle: item['lesson_title'] as String? ?? '',
                courseTitle: item['course_title'] as String? ?? '',
                reason: item['reason'] as String? ?? '',
                estimatedMinutes:
                    (item['estimated_minutes'] as num?)?.toInt() ?? 5,
              ))
          .toList();
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(message: 'Erreur recommandations : $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // getTips
  // POST /tips
  //
  // Retourne des conseils pédagogiques personnalisés ([AiTip])
  // affichés dans le dashboard via [AiTipTile].
  // ─────────────────────────────────────────────────────────

  Future<List<AiTip>> getTips({
    required String userId,
    required double progressPercent,
    required double riskScore,
    int limit = 3,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/tips'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'progress_percent': progressPercent,
              'risk_score': riskScore,
              'limit': limit,
            }),
          )
          .timeout(AppConstants.aiRequestTimeout);

      _checkStatus(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['tips'] as List? ?? [];
      return rawList
          .map((item) => AiTip(
                id: item['id'] as String? ?? '',
                message: item['message'] as String? ?? '',
                category: _parseTipCategory(item['category'] as String?),
              ))
          .toList();
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(message: 'Erreur conseils IA : $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // getSkillStats
  // POST /skill-stats
  //
  // Retourne la maîtrise par compétence ([SkillStat]) — utilisé
  // dans le dashboard via [SkillMasteryBar].
  // ─────────────────────────────────────────────────────────

  Future<List<SkillStat>> getSkillStats({
    required String userId,
    required String courseId,
    required Map<String, int> exerciseScores,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/skill-stats'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'course_id': courseId,
              'exercise_scores': exerciseScores,
            }),
          )
          .timeout(AppConstants.aiRequestTimeout);

      _checkStatus(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['skills'] as List? ?? [];
      return rawList
          .map((item) => SkillStat(
                skillName: item['skill_name'] as String? ?? '',
                masteryPercent:
                    (item['mastery_percent'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(message: 'Erreur statistiques compétences : $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // getWeeklySnapshots
  // POST /weekly-snapshot
  //
  // Retourne les points de progression hebdomadaire ([WeeklyProgressPoint])
  // pour les graphiques du dashboard ([ProgressMultiChart]).
  // ─────────────────────────────────────────────────────────

  Future<List<WeeklyProgressPoint>> getWeeklySnapshots({
    required String userId,
    required String courseId,
    int weeksBack = 8,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/weekly-snapshot'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'course_id': courseId,
              'weeks_back': weeksBack,
            }),
          )
          .timeout(AppConstants.aiRequestTimeout);

      _checkStatus(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['snapshots'] as List? ?? [];
      return rawList
          .map((item) => WeeklyProgressPoint(
                weekStart: DateTime.parse(item['week_start'] as String),
                xpGained: (item['xp_gained'] as num?)?.toInt() ?? 0,
                averageQuizScore:
                    (item['average_quiz_score'] as num?)?.toDouble() ?? 0.0,
                completionRate:
                    (item['completion_rate'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(message: 'Erreur snapshots hebdomadaires : $e');
    }
  }

  // ── Utilitaires privés ────────────────────────────────────

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(
        message: 'API IA : erreur ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  AiTipCategory _parseTipCategory(String? raw) => switch (raw) {
        'study' => AiTipCategory.study,
        'time' => AiTipCategory.time,
        'motivation' => AiTipCategory.motivation,
        'technical' => AiTipCategory.technical,
        _ => AiTipCategory.study,
      };

  void dispose() => _client.close();
}

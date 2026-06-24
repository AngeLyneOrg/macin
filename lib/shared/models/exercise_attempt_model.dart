import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseAttemptModel
//
// Sous-collection Firestore :
//   user_progress/{userId}_{courseId}/attempts/{attemptId}
//
// Chaque soumission d'un exercice (quiz, exam, certification) crée
// un document ici, ce qui permet :
//   - L'historique complet des tentatives (score, date, temps passé)
//   - Le calcul du meilleur score pour la progression
//   - Les statistiques IA (régularité, amélioration, décrochage)
//   - L'affichage du feedback détaillé question par question
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseAttemptModel extends Equatable {
  final String attemptId;
  final String userId;
  final String courseId;
  final String exerciseId;
  final String exerciseType; // 'quiz' | 'code_challenge' | 'exam' | 'certification_test'

  /// Réponses soumises : {questionId: réponse}
  final Map<String, String> answers;

  /// Score obtenu en % (0–100)
  final int score;

  /// Score minimum requis en % pour valider
  final int passingScore;

  /// true si score >= passingScore
  final bool passed;

  /// Durée réelle passée sur l'exercice (en secondes)
  final int durationSeconds;

  final DateTime submittedAt;

  const ExerciseAttemptModel({
    required this.attemptId,
    required this.userId,
    required this.courseId,
    required this.exerciseId,
    required this.exerciseType,
    required this.answers,
    required this.score,
    required this.passingScore,
    required this.passed,
    required this.durationSeconds,
    required this.submittedAt,
  });

  factory ExerciseAttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAnswers = data['answers'] as Map? ?? {};
    return ExerciseAttemptModel(
      attemptId: doc.id,
      userId: data['userId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      exerciseId: data['exerciseId'] as String? ?? '',
      exerciseType: data['exerciseType'] as String? ?? 'quiz',
      answers: rawAnswers.map((k, v) => MapEntry(k as String, v as String)),
      score: data['score'] as int? ?? 0,
      passingScore: data['passingScore'] as int? ?? 70,
      passed: data['passed'] as bool? ?? false,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courseId': courseId,
        'exerciseId': exerciseId,
        'exerciseType': exerciseType,
        'answers': answers,
        'score': score,
        'passingScore': passingScore,
        'passed': passed,
        'durationSeconds': durationSeconds,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };

  // ── Helpers ───────────────────────────────────────────────

  /// Durée formatée pour l'affichage (ex: "4 min 32 s")
  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '$s s';
    return '$m min $s s';
  }

  @override
  List<Object?> get props =>
      [attemptId, exerciseId, score, passed, submittedAt];
}

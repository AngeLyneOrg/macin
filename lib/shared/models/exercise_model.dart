import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionModel
// Imbriqué dans ExerciseModel.questions (pas de collection propre)
// ─────────────────────────────────────────────────────────────────────────────

class QuestionModel extends Equatable {
  final String id;
  final String questionText;

  /// 'mcq' (QCM) | 'true_false' | 'text_input' | 'code_output'
  final String type;

  /// Options de réponse (pour MCQ et true_false).
  final List<String> options;

  /// Réponse(s) correcte(s).
  final String correctAnswer;

  /// Explication affichée après réponse (feedback pédagogique).
  final String? explanation;

  /// Points attribués pour cette question.
  final int points;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.points,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> data) {
    return QuestionModel(
      id: data['id'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      type: data['type'] as String? ?? 'mcq',
      options: List<String>.from(data['options'] as List? ?? []),
      correctAnswer: data['correctAnswer'] as String? ?? '',
      explanation: data['explanation'] as String?,
      points: data['points'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'questionText': questionText,
        'type': type,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'points': points,
      };

  bool isCorrect(String answer) =>
      answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

  @override
  List<Object?> get props => [id, questionText, type, correctAnswer];
}

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseModel
// Collection : courses/{id}/modules/{id}/exercises/{exerciseId}
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseModel extends Equatable {
  final String exerciseId;
  final String moduleId;
  final String courseId;

  /// 'quiz' | 'code_challenge' | 'exam' | 'certification_test'
  final String type;

  final String title;
  final String? description;
  final List<QuestionModel> questions;

  /// Code de départ pour les exercices 'code_challenge'.
  final String? codeTemplate;
  final String? codeLanguage; // 'dart' | 'python' | 'javascript'

  /// Sortie attendue pour la comparaison automatique.
  final String? expectedOutput;

  /// Durée limite en minutes (null = pas de limite).
  final int? timeLimitMin;

  /// Score minimum en % pour valider l'exercice.
  final int passingScore;

  final int xpReward;
  final String? badgeIdOnSuccess;
  final bool unlocksCertificate;
  final int order;

  const ExerciseModel({
    required this.exerciseId,
    required this.moduleId,
    required this.courseId,
    required this.type,
    required this.title,
    this.description,
    required this.questions,
    this.codeTemplate,
    this.codeLanguage,
    this.expectedOutput,
    this.timeLimitMin,
    required this.passingScore,
    required this.xpReward,
    this.badgeIdOnSuccess,
    required this.unlocksCertificate,
    required this.order,
  });

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawQuestions = data['questions'] as List? ?? [];
    return ExerciseModel(
      exerciseId: doc.id,
      moduleId: data['moduleId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      type: data['type'] as String? ?? 'quiz',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      questions: rawQuestions
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      codeTemplate: data['codeTemplate'] as String?,
      codeLanguage: data['codeLanguage'] as String?,
      expectedOutput: data['expectedOutput'] as String?,
      timeLimitMin: data['timeLimitMin'] as int?,
      passingScore: data['passingScore'] as int? ?? 70,
      xpReward: data['xpReward'] as int? ?? 25,
      badgeIdOnSuccess: data['badgeIdOnSuccess'] as String?,
      unlocksCertificate: data['unlocksCertificate'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'moduleId': moduleId,
        'courseId': courseId,
        'type': type,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toMap()).toList(),
        'codeTemplate': codeTemplate,
        'codeLanguage': codeLanguage,
        'expectedOutput': expectedOutput,
        'timeLimitMin': timeLimitMin,
        'passingScore': passingScore,
        'xpReward': xpReward,
        'badgeIdOnSuccess': badgeIdOnSuccess,
        'unlocksCertificate': unlocksCertificate,
        'order': order,
      };

  bool get isQuiz => type == 'quiz';
  bool get isCodeChallenge => type == 'code_challenge';
  bool get isExam => type == 'exam';
  bool get isCertificationTest => type == 'certification_test';
  bool get hasTimeLimit => timeLimitMin != null;
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);

  /// Calcule le score en % depuis les réponses de l'utilisateur.
  int calculateScore(Map<String, String> answers) {
    if (questions.isEmpty) return 0;
    int earned = 0;
    for (final q in questions) {
      if (answers.containsKey(q.id) && q.isCorrect(answers[q.id]!)) {
        earned += q.points;
      }
    }
    return totalPoints == 0 ? 0 : ((earned / totalPoints) * 100).round();
  }

  bool isPassed(int score) => score >= passingScore;

  @override
  List<Object?> get props =>
      [exerciseId, moduleId, type, title, passingScore, order];
}

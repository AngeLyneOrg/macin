import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserProgressModel
// Collection : user_progress/{userId}_{courseId}
// ─────────────────────────────────────────────────────────────────────────────

/// Progression individuelle d'un étudiant sur un cours.
///
/// Le [progressId] suit le format `{userId}_{courseId}` pour permettre
/// une lecture directe sans query (getDoc au lieu de query).
///
/// StreamBuilder principal : [CourseDetailPage] et [LessonProgressTracker]
/// écoutent ce document en temps réel.
class UserProgressModel extends Equatable {
  final String progressId; // {userId}_{courseId}
  final String userId;
  final String courseId;
  final List<String> completedLessonIds;
  final List<String> completedExerciseIds;
  final Map<String, int> exerciseScores; // {exerciseId: score%}
  final double progressPercent; // 0.0 à 100.0
  final DateTime? lastAccessedAt;
  final bool certificateEarned;
  final String? certificateUrl;

  /// Score de risque d'échec calculé par FastAPI (0.0 = faible, 1.0 = élevé).
  /// null si l'IA n'a pas encore évalué cet étudiant.
  final double? aiRiskScore;

  const UserProgressModel({
    required this.progressId,
    required this.userId,
    required this.courseId,
    required this.completedLessonIds,
    required this.completedExerciseIds,
    required this.exerciseScores,
    required this.progressPercent,
    this.lastAccessedAt,
    required this.certificateEarned,
    this.certificateUrl,
    this.aiRiskScore,
  });

  static String buildId(String userId, String courseId) =>
      '${userId}_$courseId';

  factory UserProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawScores = data['exerciseScores'] as Map? ?? {};
    return UserProgressModel(
      progressId: doc.id,
      userId: data['userId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      completedLessonIds:
          List<String>.from(data['completedLessonIds'] as List? ?? []),
      completedExerciseIds:
          List<String>.from(data['completedExerciseIds'] as List? ?? []),
      exerciseScores: rawScores
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      progressPercent:
          (data['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastAccessedAt:
          (data['lastAccessedAt'] as Timestamp?)?.toDate(),
      certificateEarned: data['certificateEarned'] as bool? ?? false,
      certificateUrl: data['certificateUrl'] as String?,
      aiRiskScore: (data['aiRiskScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courseId': courseId,
        'completedLessonIds': completedLessonIds,
        'completedExerciseIds': completedExerciseIds,
        'exerciseScores': exerciseScores,
        'progressPercent': progressPercent,
        'lastAccessedAt': lastAccessedAt != null
            ? Timestamp.fromDate(lastAccessedAt!)
            : FieldValue.serverTimestamp(),
        'certificateEarned': certificateEarned,
        'certificateUrl': certificateUrl,
        'aiRiskScore': aiRiskScore,
      };

  static Map<String, dynamic> initialData(
      String userId, String courseId) => {
        'userId': userId,
        'courseId': courseId,
        'completedLessonIds': [],
        'completedExerciseIds': [],
        'exerciseScores': {},
        'progressPercent': 0.0,
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'certificateEarned': false,
        'certificateUrl': null,
        'aiRiskScore': null,
      };

  bool get isAtRisk => aiRiskScore != null && aiRiskScore! >= 0.6;
  bool isLessonCompleted(String lessonId) =>
      completedLessonIds.contains(lessonId);
  bool isExercisePassed(String exerciseId) =>
      completedExerciseIds.contains(exerciseId);
  int? scoreForExercise(String exerciseId) => exerciseScores[exerciseId];

  @override
  List<Object?> get props => [
        progressId, userId, courseId,
        completedLessonIds, progressPercent, certificateEarned,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// BadgeModel
// Collection : badges/{badgeId}
// ─────────────────────────────────────────────────────────────────────────────

class BadgeModel extends Equatable {
  final String badgeId;
  final String name;
  final String description;
  final String iconUrl;

  /// 'learning' | 'social' | 'achievement' | 'certification'
  final String category;

  final int xpBonus;

  /// 'common' | 'rare' | 'epic' | 'legendary'
  final String rarity;

  const BadgeModel({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.xpBonus,
    required this.rarity,
  });

  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeModel(
      badgeId: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconUrl: data['iconUrl'] as String? ?? '',
      category: data['category'] as String? ?? 'achievement',
      xpBonus: data['xpBonus'] as int? ?? 0,
      rarity: data['rarity'] as String? ?? 'common',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'category': category,
        'xpBonus': xpBonus,
        'rarity': rarity,
      };

  @override
  List<Object?> get props => [badgeId, name, rarity];
}

// ─────────────────────────────────────────────────────────────────────────────
// ReferralModel
// Collection : referrals/{referralId}
// ─────────────────────────────────────────────────────────────────────────────

class ReferralModel extends Equatable {
  final String referralId;
  final String referrerId; // UID du parrain
  final String referredId; // UID du filleul
  final String? courseId; // Cours acheté via parrainage
  final double commissionRate;
  final double commissionAmount;

  /// 'pending' | 'confirmed' | 'paid'
  final String status;

  final DateTime createdAt;

  const ReferralModel({
    required this.referralId,
    required this.referrerId,
    required this.referredId,
    this.courseId,
    required this.commissionRate,
    required this.commissionAmount,
    required this.status,
    required this.createdAt,
  });

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      referralId: doc.id,
      referrerId: data['referrerId'] as String? ?? '',
      referredId: data['referredId'] as String? ?? '',
      courseId: data['courseId'] as String?,
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 0.1,
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'referrerId': referrerId,
        'referredId': referredId,
        'courseId': courseId,
        'commissionRate': commissionRate,
        'commissionAmount': commissionAmount,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';

  @override
  List<Object?> get props =>
      [referralId, referrerId, referredId, status, commissionAmount];
}

// ─────────────────────────────────────────────────────────────────────────────
// AiSessionModel
// Collection : ai_sessions/{sessionId}
// ─────────────────────────────────────────────────────────────────────────────

class AiMessageModel extends Equatable {
  final String role; // 'user' | 'ai'
  final String content;
  final DateTime timestamp;

  const AiMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory AiMessageModel.fromMap(Map<String, dynamic> data) {
    return AiMessageModel(
      role: data['role'] as String? ?? 'user',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  bool get isUser => role == 'user';
  bool get isAi => role == 'ai';

  @override
  List<Object?> get props => [role, content, timestamp];
}

class AiSessionModel extends Equatable {
  final String sessionId;
  final String userId;
  final String? courseId;
  final List<AiMessageModel> messages;
  final Map<String, dynamic> context;
  final List<String> recommendations; // lessonIds recommandés
  final DateTime createdAt;

  const AiSessionModel({
    required this.sessionId,
    required this.userId,
    this.courseId,
    required this.messages,
    required this.context,
    required this.recommendations,
    required this.createdAt,
  });

  factory AiSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawMessages = data['messages'] as List? ?? [];
    return AiSessionModel(
      sessionId: doc.id,
      userId: data['userId'] as String? ?? '',
      courseId: data['courseId'] as String?,
      messages: rawMessages
          .map((m) => AiMessageModel.fromMap(m as Map<String, dynamic>))
          .toList(),
      context: Map<String, dynamic>.from(data['context'] as Map? ?? {}),
      recommendations:
          List<String>.from(data['recommendations'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courseId': courseId,
        'messages': messages.map((m) => m.toMap()).toList(),
        'context': context,
        'recommendations': recommendations,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AiSessionModel addMessage(AiMessageModel message) {
    return AiSessionModel(
      sessionId: sessionId,
      userId: userId,
      courseId: courseId,
      messages: [...messages, message],
      context: context,
      recommendations: recommendations,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [sessionId, userId, messages.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionModel
// Sous-collection : users/{uid}/transactions/{txId}
// ─────────────────────────────────────────────────────────────────────────────

class TransactionModel extends Equatable {
  final String txId;

  /// 'credit' | 'debit'
  final String type;

  final double amount;
  final String description;

  /// Référence optionnelle (courseId, referralId)
  final String? reference;

  final DateTime createdAt;

  const TransactionModel({
    required this.txId,
    required this.type,
    required this.amount,
    required this.description,
    this.reference,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      txId: doc.id,
      type: data['type'] as String? ?? 'credit',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      reference: data['reference'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'amount': amount,
        'description': description,
        'reference': reference,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isCredit => type == 'credit';

  @override
  List<Object?> get props => [txId, type, amount, createdAt];
}

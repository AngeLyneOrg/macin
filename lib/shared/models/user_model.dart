import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Modèle d'un utilisateur MACIN.
///
/// Correspond à la collection Firestore : `users/{uid}`
///
/// Ce modèle est utilisé par :
///   - [ProfilePage] via StreamBuilder<UserModel>
///   - [WalletPage] pour le solde
///   - [LeaderboardPage] pour le classement XP
///   - L'IA FastAPI pour le profil d'apprentissage
class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role; // 'student' | 'instructor' | 'admin'
  final int level;
  final int xp;
  final double walletBalance;
  final String referralCode;
  final String? referredBy; // UID du parrain
  final List<String> badgeIds;
  final List<String> enrolledCourseIds;
  final Map<String, dynamic> learningProfile;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.level,
    required this.xp,
    required this.walletBalance,
    required this.referralCode,
    this.referredBy,
    required this.badgeIds,
    required this.enrolledCourseIds,
    required this.learningProfile,
    required this.createdAt,
  });

  // ── Firestore ──────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'student',
      level: data['level'] as int? ?? 1,
      xp: data['xp'] as int? ?? 0,
      walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
      referralCode: data['referralCode'] as String? ?? '',
      referredBy: data['referredBy'] as String?,
      badgeIds: List<String>.from(data['badgeIds'] as List? ?? []),
      enrolledCourseIds:
      List<String>.from(data['enrolledCourseIds'] as List? ?? []),
      learningProfile:
      Map<String, dynamic>.from(data['learningProfile'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Reconstruit un [UserModel] depuis une Map issue du cache local (Hive),
  /// par opposition à [fromFirestore] qui prend un `DocumentSnapshot`.
  ///
  /// Le champ `createdAt` peut être un [Timestamp] (s'il vient directement
  /// de `toMap()`) — on gère ce cas pour rester robuste.
  factory UserModel.fromCachedMap(String uid, Map<String, dynamic> data) {
    DateTime created;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      created = rawCreatedAt.toDate();
    } else if (rawCreatedAt is int) {
      created = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      created = DateTime.now();
    }

    return UserModel(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'student',
      level: data['level'] as int? ?? 1,
      xp: data['xp'] as int? ?? 0,
      walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
      referralCode: data['referralCode'] as String? ?? '',
      referredBy: data['referredBy'] as String?,
      badgeIds: List<String>.from(data['badgeIds'] as List? ?? []),
      enrolledCourseIds:
      List<String>.from(data['enrolledCourseIds'] as List? ?? []),
      learningProfile:
      Map<String, dynamic>.from(data['learningProfile'] as Map? ?? {}),
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'level': level,
      'xp': xp,
      'walletBalance': walletBalance,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'badgeIds': badgeIds,
      'enrolledCourseIds': enrolledCourseIds,
      'learningProfile': learningProfile,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Données minimales à écrire lors de la création d'un nouveau compte.
  static Map<String, dynamic> initialData({
    required String uid,
    required String displayName,
    required String email,
    required String referralCode,
    String? photoUrl,
    String? referredBy,
  }) {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': 'student',
      'level': 1,
      'xp': 0,
      'walletBalance': 0.0,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'badgeIds': [],
      'enrolledCourseIds': [],
      'learningProfile': {
        'style': 'visual',   // sera mis à jour par l'IA
        'pace': 'normal',
        'lastActiveAt': Timestamp.now(),
      },
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Helpers ───────────────────────────────────────────────

  bool get isStudent => role == 'student';
  bool get isInstructor => role == 'instructor';
  bool get isAdmin => role == 'admin';
  bool isEnrolledIn(String courseId) => enrolledCourseIds.contains(courseId);
  bool hasBadge(String badgeId) => badgeIds.contains(badgeId);
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ── CopyWith ──────────────────────────────────────────────

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? role,
    int? level,
    int? xp,
    double? walletBalance,
    List<String>? badgeIds,
    List<String>? enrolledCourseIds,
    Map<String, dynamic>? learningProfile,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCode: referralCode,
      referredBy: referredBy,
      badgeIds: badgeIds ?? this.badgeIds,
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
      learningProfile: learningProfile ?? this.learningProfile,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid, displayName, email, photoUrl, role,
    level, xp, walletBalance, referralCode, referredBy,
    badgeIds, enrolledCourseIds, learningProfile, createdAt,
  ];
}

/// Constantes métier et configuration de MACIN.
abstract class AppConstants {
  // ── Nom de l'application ─────────────────────────────────
  static const String appName = 'MACIN';
  static const String appTagline =
      'Apprendre le développement logiciel, intelligemment.';

  // ── Collections Firestore ────────────────────────────────
  static const String colUsers = 'users';
  static const String colCourses = 'courses';
  static const String colModules = 'modules';
  static const String colLessons = 'lessons';
  static const String colExercises = 'exercises';
  static const String colUserProgress = 'user_progress';
  static const String colBadges = 'badges';
  static const String colReferrals = 'referrals';
  static const String colAiSessions = 'ai_sessions';
  static const String colNotifications = 'notifications';
  static const String colTransactions = 'transactions';
  static const String colReviews = 'reviews';

  // ── Sous-collections ─────────────────────────────────────
  static const String subColNotifications = 'notifications';
  static const String subColTransactions = 'transactions';
  static const String subColReviews = 'reviews';

  /// Sous-collection des tentatives d'exercices.
  /// Chemin complet : user_progress/{progressId}/attempts/{attemptId}
  static const String subColAttempts = 'attempts';

  // ── Rôles utilisateurs ───────────────────────────────────
  static const String roleStudent = 'student';
  static const String roleInstructor = 'instructor';
  static const String roleAdmin = 'admin';

  // ── Types de leçons ──────────────────────────────────────
  static const String lessonTypeVideo = 'video';
  static const String lessonTypeArticle = 'article';
  static const String lessonTypePdf = 'pdf';
  static const String lessonTypeCodeDemo = 'code_demo';

  // ── Types d'exercices ────────────────────────────────────
  static const String exerciseTypeQuiz = 'quiz';
  static const String exerciseTypeCode = 'code_challenge';
  static const String exerciseTypeExam = 'exam';
  static const String exerciseTypeCertification = 'certification_test';

  // ── Raretés des badges ───────────────────────────────────
  static const String rarityCommon = 'common';
  static const String rarityRare = 'rare';
  static const String rarityEpic = 'epic';
  static const String rarityLegendary = 'legendary';

  // ── Catégories de badges ─────────────────────────────────
  static const String badgeCatLearning = 'learning';
  static const String badgeCatSocial = 'social';
  static const String badgeCatAchievement = 'achievement';
  static const String badgeCatCertification = 'certification';

  // ── Niveaux de cours ─────────────────────────────────────
  static const String levelBeginner = 'beginner';
  static const String levelIntermediate = 'intermediate';
  static const String levelAdvanced = 'advanced';

  // ── Parrainage ───────────────────────────────────────────
  static const double referralCommissionRate = 0.10;
  static const String referralStatusPending = 'pending';
  static const String referralStatusConfirmed = 'confirmed';
  static const String referralStatusPaid = 'paid';

  // ── Gamification / XP ────────────────────────────────────
  static const int xpPerLessonCompleted = 10;
  static const int xpPerQuizPassed = 25;
  static const int xpPerExamPassed = 100;
  static const int xpPerCertification = 500;
  static const int xpPerLevel = 200;

  // ── IA / Tutorat ─────────────────────────────────────────
  static const double aiRiskThreshold = 0.6;
  static const int aiRecommendationCacheMinutes = 30;

  /// URL de base du backend FastAPI (proxifié via Cloud Function).
  /// À remplacer par la vraie URL après déploiement — Issue #45.
  static const String aiApiBaseUrl =
      'https://REGION-PROJECT_ID.cloudfunctions.net/ai';

  /// Timeout des requêtes vers l'API IA (en secondes).
  // static const int aiRequestTimeout = 30;
  // Ligne 105
  static const Duration aiRequestTimeout = Duration(seconds: 30);

  // ── Pagination Firestore ─────────────────────────────────
  static const int coursesPageSize = 10;
  static const int leaderboardPageSize = 50;
  static const int notificationsPageSize = 20;

  // ── Offline / Hive ───────────────────────────────────────
  static const String hiveBoxDownloads = 'downloads';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxAiCache = 'ai_cache';

  // ── URLs ─────────────────────────────────────────────────
  static const String cloudFunctionBaseUrl =
      'https://REGION-PROJECT_ID.cloudfunctions.net';

  // ── Cloudflare R2 ────────────────────────────────────────
  static const int r2PresignedUrlExpiryHours = 1;
}
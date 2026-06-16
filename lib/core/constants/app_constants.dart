/// Constantes métier et configuration de MACIN.
abstract class AppConstants {
  // ── Nom de l'application ─────────────────────────────────
  static const String appName = 'MACIN';
  static const String appTagline = 'Apprendre le développement logiciel, intelligemment.';

  // ── Collections Firestore ────────────────────────────────
  // Convention : snake_case pour correspondre à Firestore
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
  // Accédées via : colUsers + '/' + uid + '/' + subColNotifications
  static const String subColNotifications = 'notifications';
  static const String subColTransactions = 'transactions';
  static const String subColReviews = 'reviews';

  // ── Roles utilisateurs ───────────────────────────────────
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
  static const double referralCommissionRate = 0.10; // 10%
  static const String referralStatusPending = 'pending';
  static const String referralStatusConfirmed = 'confirmed';
  static const String referralStatusPaid = 'paid';

  // ── Gamification / XP ────────────────────────────────────
  static const int xpPerLessonCompleted = 10;
  static const int xpPerQuizPassed = 25;
  static const int xpPerExamPassed = 100;
  static const int xpPerCertification = 500;
  // XP requis par niveau : niveau N requiert N * xpPerLevel
  static const int xpPerLevel = 200;

  // ── IA ───────────────────────────────────────────────────
  // Seuil à partir duquel le AiRiskBanner s'affiche
  static const double aiRiskThreshold = 0.6;
  // Durée de cache des recommandations IA (en minutes)
  static const int aiRecommendationCacheMinutes = 30;

  // ── Pagination Firestore ─────────────────────────────────
  static const int coursesPageSize = 10;
  static const int leaderboardPageSize = 50;
  static const int notificationsPageSize = 20;

  // ── Offline ──────────────────────────────────────────────
  // Clés Hive pour le stockage local
  static const String hiveBoxDownloads = 'downloads';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxAiCache = 'ai_cache';

  // ── URLs ─────────────────────────────────────────────────
  // Firebase Cloud Function qui proxifie les appels FastAPI
  // (sera configurée après déploiement — Issue #45)
  static const String cloudFunctionBaseUrl =
      'https://REGION-PROJECT_ID.cloudfunctions.net';

  // ── Durée de l'URL pré-signée Cloudflare R2 (heures) ─────
  static const int r2PresignedUrlExpiryHours = 1;
}

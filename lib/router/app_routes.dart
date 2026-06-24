/// Noms de routes nommées pour go_router.
///
/// Toujours utiliser ces constantes pour naviguer :
///   context.goNamed(AppRoutes.home)
///   context.goNamed(AppRoutes.lessonPlayer, pathParameters: {
///     'id': courseId, 'lessonId': lessonId
///   })
///   context.goNamed(AppRoutes.exercisePage, pathParameters: {
///     'id': courseId, 'moduleId': moduleId
///   })
///   context.goNamed(AppRoutes.exerciseRunner, pathParameters: {
///     'id': courseId, 'moduleId': moduleId, 'exerciseId': exerciseId
///   })
abstract class AppRoutes {
  // ── Auth ─────────────────────────────────────────────────
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // ── Shell (MainScaffold avec BottomNav) ──────────────────
  static const String shell = 'shell';

  // ── Home ─────────────────────────────────────────────────
  static const String home = 'home';

  // ── Courses ──────────────────────────────────────────────
  static const String catalog = 'catalog';
  static const String courseDetail = 'course-detail';
  static const String courseCheckout = 'course-checkout';
  static const String myCourses = 'my-courses';

  // ── Lessons ──────────────────────────────────────────────
  static const String lessonPlayer = 'lesson-player';

  // ── Exercises ────────────────────────────────────────────
  /// Liste des exercices d'un module.
  /// Params: id (courseId), moduleId
  static const String exercisePage = 'exercise-page';

  /// Lecteur d'un exercice individuel.
  /// Params: id (courseId), moduleId, exerciseId
  static const String exerciseRunner = 'exercise-runner';

  // Anciens noms conservés pour rétrocompatibilité
  static const String quiz = 'quiz';
  static const String quizResult = 'quiz-result';
  static const String codeChallenge = 'code-challenge';
  static const String exam = 'exam';

  // ── Certification ────────────────────────────────────────
  static const String certificate = 'certificate';

  // ── Profile ──────────────────────────────────────────────
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  static const String badges = 'badges';
  static const String leaderboard = 'leaderboard';

  // ── AI Tutor (MACI) ──────────────────────────────────────
  static const String aiTutor = 'ai-tutor';
  static const String aiChat = 'ai-chat';

  // ── Wallet & Referral ────────────────────────────────────
  static const String wallet = 'wallet';
  static const String referral = 'referral';
  static const String referralStats = 'referral-stats';

  // ── Search ───────────────────────────────────────────────
  static const String search = 'search';

  // ── Notifications ────────────────────────────────────────
  static const String notifications = 'notifications';

  // ── Settings ─────────────────────────────────────────────
  static const String settings = 'settings';

  // ── Dashboards (formateur / admin) ───────────────────────
  static const String instructorDashboard = 'instructor-dashboard';
  static const String courseEditor = 'course-editor';
  static const String adminDashboard = 'admin-dashboard';
}

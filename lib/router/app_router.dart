import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:macin/features/ai_tutor/presentation/pages/ai_dashboard_page.dart';
import 'package:macin/features/ai_tutor/presentation/pages/ai_chat_page.dart';
import 'package:macin/features/auth/presentation/pages/login_page.dart';
import 'package:macin/features/auth/presentation/pages/register_page.dart';
import 'package:macin/features/auth/presentation/pages/splash_page.dart';
import 'package:macin/features/auth/presentation/pages/onboarding_page.dart';
import 'package:macin/features/courses/presentation/pages/catalog_page.dart';
import 'package:macin/features/courses/presentation/pages/course_detail_page.dart';
import 'package:macin/features/exercises/presentation/pages/exercise_page.dart';
import 'package:macin/features/exercises/presentation/pages/exercise_runner_page.dart';
import 'package:macin/features/home/presentation/pages/home_page.dart';
import 'package:macin/features/lessons/presentation/pages/lesson_player_page.dart';
import 'package:macin/features/profile/presentation/pages/profile_page.dart';
import 'package:macin/features/wallet/presentation/pages/wallet_page.dart';
import 'package:macin/shared/widgets/main_scaffold.dart';

import 'app_routes.dart';

/// Configuration go_router de l'application MACIN.
///
/// Arborescence des routes leçons / exercices :
///
///   /catalog
///     /:id                        → CourseDetailPage
///       /lesson/:lessonId         → LessonPlayerPage
///       /module/:moduleId
///         /exercises              → ExercisePage
///           /:exerciseId          → ExerciseRunnerPage
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static const _publicRoutes = [
    '/splash',
    '/onboarding',
    '/login',
    '/register'
  ];

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final isAuthenticated =
          FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isPublicRoute = _publicRoutes.contains(location);

      if (location == '/splash') return null;
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/home';
      }
      return null;
    },

    routes: [
      // ── Splash ───────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),

      // ── Onboarding ───────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),

      // ── Auth ─────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      // ── AI Chat (MACI) ────────────────────────────────
      GoRoute(
        path: '/ai-chat',
        name: AppRoutes.aiChat,
        builder: (_, __) => const AiChatPage(),
      ),

      // ── Shell avec BottomNavigationBar ────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (_, __) => const HomePage(),
          ),

          GoRoute(
            path: '/catalog',
            name: AppRoutes.catalog,
            builder: (_, __) => const CatalogPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: AppRoutes.courseDetail,
                builder: (context, state) => CourseDetailPage(
                  courseId: state.pathParameters['id']!,
                ),
                routes: [
                  // ── Leçon ──────────────────────────
                  GoRoute(
                    path: 'lesson/:lessonId',
                    name: AppRoutes.lessonPlayer,
                    builder: (context, state) => LessonPlayerPage(
                      lessonId: state.pathParameters['lessonId']!,
                      courseId: state.pathParameters['id']!,
                    ),
                  ),

                  // ── Exercices (liste + runner) ──────
                  GoRoute(
                    path: 'module/:moduleId/exercises',
                    name: AppRoutes.exercisePage,
                    builder: (context, state) => ExercisePage(
                      courseId: state.pathParameters['id']!,
                      moduleId: state.pathParameters['moduleId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: ':exerciseId',
                        name: AppRoutes.exerciseRunner,
                        builder: (context, state) =>
                            ExerciseRunnerPage(
                              courseId: state.pathParameters['id']!,
                              moduleId:
                              state.pathParameters['moduleId']!,
                              exerciseId:
                              state.pathParameters['exerciseId']!,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/profile',
            name: AppRoutes.profile,
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/wallet',
            name: AppRoutes.wallet,
            builder: (_, __) => const WalletPage(),
          ),
          GoRoute(
            path: '/ai-tutor',
            name: AppRoutes.aiTutor,
            builder: (_, __) => const AiDashboardPage(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page introuvable : ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}

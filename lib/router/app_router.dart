import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macin/features/ai_tutor/presentation/pages/ai_tutor_page.dart';
import 'package:macin/features/auth/presentation/pages/login_page.dart';
import 'package:macin/features/auth/presentation/pages/register_page.dart';
import 'package:macin/features/auth/presentation/pages/splash_page.dart';
import 'package:macin/features/courses/presentation/pages/catalog_page.dart';
import 'package:macin/features/courses/presentation/pages/course_detail_page.dart';
import 'package:macin/features/home/presentation/pages/home_page.dart';
import 'package:macin/features/lessons/presentation/pages/lesson_player_page.dart';
import 'package:macin/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:macin/features/profile/presentation/pages/profile_page.dart';
import 'package:macin/features/wallet/presentation/pages/wallet_page.dart';
import 'package:macin/shared/widgets/main_scaffold.dart';

import 'app_routes.dart';

/// Configuration go_router de l'application MACIN.
///
/// Logique de redirection :
///   - Non authentifié → /login
///   - Authentifié sur /login → /home
///   - Rôle 'instructor' → /instructor-dashboard (à implémenter en M7)
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: '/splash',
        debugLogDiagnostics: true,

        // ── Redirection basée sur l'état auth ────────────────
        redirect: (context, state) {
          final isAuthenticated =
              FirebaseAuth.instance.currentUser != null;
          final isOnAuthPage = state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/splash';

          // Pas encore authentifié et pas sur une page auth → login
          if (!isAuthenticated && !isOnAuthPage) {
            return '/login';
          }

          // Déjà authentifié et essaie d'aller sur login/register → home
          if (isAuthenticated &&
              (state.matchedLocation == '/login' ||
                  state.matchedLocation == '/register')) {
            return '/home';
          }

          return null; // pas de redirection
        },

        routes: [
          // ── Splash ─────────────────────────────────────────
          GoRoute(
            path: '/splash',
            name: AppRoutes.splash,
            builder: (context, state) => const SplashPage(),
          ),

          // ── Onboarding (premier contact, app non authentifiée) ──
          GoRoute(
            path: '/onboarding',
            name: AppRoutes.onboarding,
            builder: (context, state) => const OnboardingPage(),
          ),

          // ── Auth ───────────────────────────────────────────
          GoRoute(
            path: '/login',
            name: AppRoutes.login,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/register',
            name: AppRoutes.register,
            builder: (context, state) => const RegisterPage(),
          ),

          // ── Shell avec BottomNavigationBar ─────────────────
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) {
              return MainScaffold(child: child);
            },
            routes: [
              GoRoute(
                path: '/home',
                name: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
              GoRoute(
                path: '/catalog',
                name: AppRoutes.catalog,
                builder: (context, state) => const CatalogPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: AppRoutes.courseDetail,
                    builder: (context, state) => CourseDetailPage(
                      courseId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'lesson/:lessonId',
                        name: AppRoutes.lessonPlayer,
                        builder: (context, state) => LessonPlayerPage(
                          lessonId: state.pathParameters['lessonId']!,
                          courseId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/profile',
                name: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
              GoRoute(
                path: '/wallet',
                name: AppRoutes.wallet,
                builder: (context, state) => const WalletPage(),
              ),
              GoRoute(
                path: '/ai-tutor',
                name: AppRoutes.aiTutor,
                builder: (context, state) => const AiTutorPage(),
              ),
            ],
          ),
        ],

        // ── Page d'erreur ────────────────────────────────────
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

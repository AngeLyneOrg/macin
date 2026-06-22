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
import 'package:macin/features/home/presentation/pages/home_page.dart';
import 'package:macin/features/lessons/presentation/pages/lesson_player_page.dart';
import 'package:macin/features/profile/presentation/pages/profile_page.dart';
import 'package:macin/features/wallet/presentation/pages/wallet_page.dart';
import 'package:macin/shared/widgets/main_scaffold.dart';

import 'app_routes.dart';

/// Configuration go_router de l'application MACIN.
///
/// Logique de redirection :
///   - '/' et '/splash' ne sont JAMAIS interceptées par [redirect] —
///     c'est la SplashPage elle-même qui décide où aller, une fois.
///     Sinon on entre dans une boucle de redirection avec le check
///     "isOnAuthPage" ci-dessous.
///   - Non authentifié + route protégée → /login
///   - Authentifié + sur /login ou /register → /home
///   - /onboarding est toujours accessible (page de présentation,
///     pas une page d'auth) donc jamais redirigée vers /login.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Routes qui ne nécessitent jamais d'authentification et ne
  /// doivent jamais être interceptées par la redirection.
  static const _publicRoutes = ['/splash', '/onboarding', '/login', '/register'];

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // ── Redirection basée sur l'état auth ────────────────
    redirect: (context, state) {
      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isPublicRoute = _publicRoutes.contains(location);

      // Splash gère sa propre navigation initiale — ne JAMAIS
      // rediriger automatiquement depuis ou vers cette route ici,
      // sous peine de boucle avec le redirect de SplashPage.
      if (location == '/splash') return null;

      // Pas authentifié et route protégée → /login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // Authentifié mais sur /login ou /register → /home
      // (PAS sur /onboarding : un utilisateur déconnecté doit
      // pouvoir la revoir sans être bloqué).
      if (isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/home';
      }

      return null;
    },

    routes: [
      // ── Splash ─────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // ── Onboarding ─────────────────────────────────────
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

      // ── AI Chat (MACI) — hors du Shell, écran plein sans bottom nav ──
      GoRoute(
        path: '/ai-chat',
        name: AppRoutes.aiChat,
        builder: (context, state) => const AiChatPage(),
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
            builder: (context, state) => const AiDashboardPage(),
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
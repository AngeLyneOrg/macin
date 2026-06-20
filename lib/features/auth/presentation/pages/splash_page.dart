import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/features/auth/data/auth_repository.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/widgets/auth_widgets.dart';


/// Écran de démarrage de MACIN.
///
/// Affiche le logo et une barre de chargement pendant que :
///   1. Firebase Auth résout l'état de connexion (`authStateChanges`)
///   2. Un court délai minimum s'écoule pour éviter un flash trop bref
///
/// Redirection :
///   - Pas connecté → [AppRoutes.onboarding] (première visite) ou
///     [AppRoutes.login] (déjà vu l'onboarding — voir TODO)
///   - Connecté → [AppRoutes.home]
///
/// Cette page ne fait elle-même AUCUNE requête Firestore : elle ne
/// dépend que de l'état Firebase Auth, qui est instantané et local.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _authRepo = AuthRepository();
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _resolveInitialRoute() async {
    // Délai minimum d'affichage pour éviter un flash imperceptible
    // si Firebase répond instantanément (cache local de session).
    final minDelay = Future.delayed(const Duration(milliseconds: 900));

    // authStateChanges() émet immédiatement l'utilisateur courant
    // (ou null) dès le premier appel — pas besoin d'attendre un
    // "vrai" changement.
    final user = await _authRepo.authStateChanges.first;

    await minDelay;
    if (!mounted) return;

    if (user != null) {
      context.goNamed(AppRoutes.home);
    } else {
      // TODO(M2): vérifier un flag "onboarding déjà vu" (SharedPreferences)
      // pour ne montrer l'onboarding qu'au tout premier lancement.
      context.goNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──────────────────────────────────────
            const MacinLogo(size: 96),
            const SizedBox(height: AppDimensions.xl),
            Text(
              'MACIN',
              style: AppTextStyles.display1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Apprends le développement, intelligemment.',
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xxxl),

            // ── Barre de chargement ─────────────────────────
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(AppDimensions.radiusRound),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

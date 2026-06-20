import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/features/auth/data/auth_repository.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/widgets/auth_widgets.dart';
import 'package:macin/shared/widgets/buttons/macin_primary_button.dart';
import 'package:macin/shared/widgets/buttons/social_auth_button.dart';
import 'package:macin/shared/widgets/inputs/macin_text_field.dart';

/// Page de connexion MACIN.
///
/// Reprend le langage visuel de [OnboardingPage] : fond plein en
/// couleur primaire, logo en haut, container blanc arrondi en bas
/// qui porte tout le formulaire et les boutons sociaux.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isEmailLoading = false;
  SocialProvider? _loadingProvider;

  // TODO(M2-Issue#9): externaliser dans un .env / Remote Config
  static const _googleServerClientId =
      '172820456998-7er5c2vgf1619p7aoed5jlsjt5qra70j.apps.googleusercontent.com';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isEmailLoading = true);
    try {
      await _authRepo.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.goNamed(AppRoutes.home);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loadingProvider = SocialProvider.google);
    try {
      await _authRepo.signInWithGoogle(serverClientId: _googleServerClientId);
      if (mounted) context.goNamed(AppRoutes.home);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Future<void> _handleGitHubSignIn() async {
    setState(() => _loadingProvider = SocialProvider.github);
    try {
      await _authRepo.signInWithGitHub();
      if (mounted) context.goNamed(AppRoutes.home);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          maintainBottomViewPadding: false,
          child: Column(
            children: [
              // ── Bouton retour + logo ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.onboarding),
                    ),
                  ],
                ),
              ),
              // ⚠️ FIX: Remove Spacer() and use Expanded with flexible layout
              // const SizedBox(height: AppDimensions.lg), // Reduced spacing
              const MacinLogo(size: 48), // Slightly smaller logo
              const SizedBox(height: AppDimensions.md),

              // ── Container blanc bas ──────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusXl * 1.5),
                      topRight: Radius.circular(AppDimensions.radiusXl * 1.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePaddingH,
                      vertical: AppDimensions.pagePaddingV,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Connexion', style: AppTextStyles.heading1),
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            'Heureux de te revoir sur MACIN.',
                            style: AppTextStyles.body2,
                          ),
                          const SizedBox(height: AppDimensions.lg), // Reduced from xl

                          MacinTextField(
                            label: 'Email',
                            hint: 'toi@exemple.com',
                            controller: _emailController,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.isValidEmail)
                                ? 'Entre une adresse email valide'
                                : null,
                          ),
                          const SizedBox(height: AppDimensions.base),

                          MacinTextField(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.done,
                            validator: (v) => (v == null || !v.isValidPassword)
                                ? '6 caractères minimum'
                                : null,
                          ),
                          const SizedBox(height: AppDimensions.xs), // Reduced from sm

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO(M2-Issue#9): page mot de passe oublié
                              },
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md), // Reduced from base

                          MacinPrimaryButton(
                            label: 'Se connecter',
                            isLoading: _isEmailLoading,
                            onPressed: _handleEmailLogin,
                          ),

                          const SizedBox(height: AppDimensions.lg), // Reduced from xl
                          const AuthDivider(),
                          const SizedBox(height: AppDimensions.lg), // Reduced from xl

                          SocialAuthButton(
                            provider: SocialProvider.google,
                            isLoading:
                            _loadingProvider == SocialProvider.google,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: AppDimensions.sm), // Reduced from md
                          SocialAuthButton(
                            provider: SocialProvider.github,
                            isLoading:
                            _loadingProvider == SocialProvider.github,
                            onPressed: _handleGitHubSignIn,
                          ),

                          const SizedBox(height: AppDimensions.md), // Reduced from xl

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Pas encore de compte ?",
                                  style: AppTextStyles.body2),
                              TextButton(
                                onPressed: () =>
                                    context.pushNamed(AppRoutes.register),
                                child: const Text("S'inscrire"),
                              ),
                            ],
                          ),
                          // ⚠️ FIX: Add bottom padding for small screens
                          const SizedBox(height: AppDimensions.base),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
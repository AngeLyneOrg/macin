import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/core/utils/referral_utils.dart';
import 'package:macin/features/auth/data/auth_repository.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/widgets/auth_widgets.dart';
import 'package:macin/shared/widgets/buttons/macin_primary_button.dart';
import 'package:macin/shared/widgets/buttons/social_auth_button.dart';
import 'package:macin/shared/widgets/inputs/macin_text_field.dart';
import 'package:macin/shared/widgets/role_selector.dart';

/// Page d'inscription MACIN.
///
/// Le rôle choisi via [RoleSelector] ('student' | 'instructor') est
/// transmis à [AuthRepository], qui l'écrit dans Firestore lors de
/// la création du profil. Le code de parrainage, s'il est saisi,
/// est résolu côté repository.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _authRepo = AuthRepository();

  String _selectedRole = AppConstants.roleStudent;
  bool _isEmailLoading = false;
  SocialProvider? _loadingProvider;

  static const _googleServerClientId =
      '172820456998-7er5c2vgf1619p7aoed5jlsjt5qra70j.apps.googleusercontent.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isEmailLoading = true);
    try {
      await _authRepo.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        referralCodeInput: _referralController.text,
      );
      if (mounted) context.goNamed(AppRoutes.home);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _loadingProvider = SocialProvider.google);
    try {
      await _authRepo.signInWithGoogle(
        serverClientId: _googleServerClientId,
        role: _selectedRole,
        referralCodeInput: _referralController.text,
      );
      if (mounted) context.goNamed(AppRoutes.home);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Future<void> _handleGitHubSignUp() async {
    setState(() => _loadingProvider = SocialProvider.github);
    try {
      await _authRepo.signInWithGitHub(
        role: _selectedRole,
        referralCodeInput: _referralController.text,
      );
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Créer un compte', style: AppTextStyles.heading1),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Rejoins MACIN et commence à apprendre.',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppDimensions.xl),

                // ── Choix du rôle ──────────────────────────
                Text('Tu es...', style: AppTextStyles.body1Medium),
                const SizedBox(height: AppDimensions.sm),
                RoleSelector(
                  selectedRole: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),
                const SizedBox(height: AppDimensions.xl),

                // ── Nom complet ────────────────────────────
                MacinTextField(
                  label: 'Nom complet',
                  hint: 'Jean Dupont',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Entre ton nom complet'
                      : null,
                ),
                const SizedBox(height: AppDimensions.base),

                // ── Email ──────────────────────────────────
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

                // ── Mot de passe ───────────────────────────
                MacinTextField(
                  label: 'Mot de passe',
                  hint: '6 caractères minimum',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => (v == null || !v.isValidPassword)
                      ? '6 caractères minimum'
                      : null,
                ),
                const SizedBox(height: AppDimensions.base),

                // ── Code de parrainage (optionnel) ─────────
                MacinTextField(
                  label: 'Code de parrainage (optionnel)',
                  hint: 'EX: MAC4-K9RZ',
                  controller: _referralController,
                  prefixIcon: Icons.card_giftcard_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final normalized = ReferralUtils.normalizeCode(v);
                    return ReferralUtils.isValidFormat(normalized)
                        ? null
                        : 'Format attendu : XXXX-XXXX';
                  },
                ),
                const SizedBox(height: AppDimensions.xl),

                MacinPrimaryButton(
                  label: 'Créer mon compte',
                  isLoading: _isEmailLoading,
                  onPressed: _handleEmailRegister,
                ),

                const SizedBox(height: AppDimensions.xl),
                const AuthDivider(),
                const SizedBox(height: AppDimensions.xl),

                SocialAuthButton(
                  provider: SocialProvider.google,
                  isLoading: _loadingProvider == SocialProvider.google,
                  onPressed: _handleGoogleSignUp,
                ),
                const SizedBox(height: AppDimensions.md),
                SocialAuthButton(
                  provider: SocialProvider.github,
                  isLoading: _loadingProvider == SocialProvider.github,
                  onPressed: _handleGitHubSignUp,
                ),

                const SizedBox(height: AppDimensions.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Déjà un compte ?', style: AppTextStyles.body2),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

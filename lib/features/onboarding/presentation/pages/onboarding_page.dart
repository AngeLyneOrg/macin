import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond de la page (visible derrière l'image)
        color: AppColors.primary,
        child: SafeArea(
          maintainBottomViewPadding: false,
          child: Column(
            children: [
              // Logo en haut
              _buildMacinLogo(),

              // Espace flexible pour pousser le contenu vers le bas
              const Expanded(
                child: SizedBox(),
              ),

              // Contenu aligné en bas
              _buildBottomContent(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────
  Widget _buildMacinLogo() {
    return Center(
      child: Image.asset(
        'assets/images/macin_wordmark.png',
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          'MACIN',
          // ✅ Utilisation d'AppTextStyles au lieu de TextStyle direct
          style: AppTextStyles.display1.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Contenu du bas (illustration + container blanc) ──
  Widget _buildBottomContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Illustration avec les badges
        _buildIllustration(context),

        // Container blanc avec le texte et le bouton
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXl * 1.5),
              topRight: Radius.circular(AppDimensions.radiusXl * 1.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.pagePaddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.md),
                _buildTitle(),
                const SizedBox(height: AppDimensions.sm),
                _buildDescription(),
                const SizedBox(height: AppDimensions.xl),
                _buildGetStartedButton(),
                const SizedBox(height: AppDimensions.lg),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Illustration avec badges inclinés ──────────────────
  Widget _buildIllustration(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Image de la personne
        Image.asset(
          'assets/images/onboarding_character2.png',
          height: MediaQuery.of(context).size.height * 0.45,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person_4_rounded,
            size: 180,
            color: Colors.white.withOpacity(0.3),
          ),
        ),

        // ── Badge 1 : Development (incliné -30°) ────────
        Positioned(
          top: -20,
          left: screenWidth * 0.05,
          child: Transform.rotate(
            angle: 0.15,
            child: _buildFloatingBadge(
              icon: Icons.code_rounded,
              label: 'Development',
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Badge 2 : UX/UI Design (incliné +25°) ───────
        Positioned(
          top: -10,
          right: screenWidth * 0.05,
          child: Transform.rotate(
            angle: -0.10,
            child: _buildFloatingBadge(
              icon: Icons.design_services_rounded,
              label: 'UX/UI Design',
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Badge 3 : Graphic Design (incliné -35°) ─────
        Positioned(
          top: 50,
          left: screenWidth * 0.0,
          child: Transform.rotate(
            angle: -0.15,
            child: _buildFloatingBadge(
              icon: Icons.brush_rounded,
              label: 'Graphic Design',
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Badge 4 : Networking (incliné +40°) ─────────
        Positioned(
          top: 60,
          right: screenWidth * 0.0,
          child: Transform.rotate(
            angle: 0.20,
            child: _buildFloatingBadge(
              icon: Icons.wifi_rounded,
              label: 'Networking',
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Badge flottant ─────────────────────────────────────
  Widget _buildFloatingBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        // color: Color(0xFF6399FC),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconMd,
            color: color,
          ),
          const SizedBox(width: AppDimensions.xs),
          Text(
            label,
            // ✅ Utilisation d'AppTextStyles
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              // color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre ───────────────────────────────────────────────
  Widget _buildTitle() {
    return Text(
      "LET'S LEARN WITH OUR\nEXCITING COURSE",
      // ✅ Utilisation d'AppTextStyles au lieu de TextStyle direct
      style: AppTextStyles.heading1.copyWith(
        fontSize: 30,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Description ────────────────────────────────────────
  Widget _buildDescription() {
    return Text(
      'Excited to join your journey, making learning easy and\nfun as we reach goals together.',
      // ✅ Utilisation d'AppTextStyles (déjà configuré)
      style: AppTextStyles.body2.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Bouton Get Started ──────────────────────────────────
  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: () {
          // Navigation vers la page d'accueil
          // context.go('/home');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          elevation: 0,
          // ✅ Le textStyle est déjà défini dans le thème (AppTextStyles.button)
        ),
        child: Text(
          'Get Started',
          // ✅ Utilisation d'AppTextStyles pour le bouton
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}
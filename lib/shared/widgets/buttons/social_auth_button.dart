import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Fournisseurs sociaux supportés par MACIN.
///
/// Ajouter un nouveau provider = ajouter une valeur ici + un case
/// dans [SocialAuthButton._config]. Aucune autre modification nécessaire.
enum SocialProvider { google, github }

/// Bouton de connexion sociale réutilisable.
///
/// Un seul widget pour Google ET GitHub (et facilement extensible) :
/// l'apparence (icône/image, couleurs) est dérivée de [provider].
///
/// Google utilise désormais le logo PNG officiel (assets/images/google_logo.png)
/// au lieu de l'icône FontAwesome. Si l'asset n'est pas trouvé (pas encore
/// ajouté au pubspec.yaml), l'icône FontAwesome sert de repli automatique.
///
/// Usage :
/// ```dart
/// SocialAuthButton(
///   provider: SocialProvider.google,
///   isLoading: _loadingProvider == SocialProvider.google,
///   onPressed: () => _handleGoogleSignIn(),
/// )
/// ```
class SocialAuthButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  _ProviderConfig get _config => switch (provider) {
    SocialProvider.google => const _ProviderConfig(
      label: 'Continuer avec Google',
      imageAsset: 'assets/images/google_logo.png',
      fallbackIcon: FontAwesomeIcons.google,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      borderColor: AppColors.border,
    ),
    SocialProvider.github => const _ProviderConfig(
      label: 'Continuer avec GitHub',
      fallbackIcon: FontAwesomeIcons.github,
      backgroundColor: Color(0xFF24292F),
      foregroundColor: Colors.white,
      borderColor: Color(0xFF24292F),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          foregroundColor: config.foregroundColor,
          side: BorderSide(color: config.borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor:
            AlwaysStoppedAnimation(config.foregroundColor),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(config),
            const SizedBox(width: AppDimensions.md),
            Text(
              config.label,
              style: AppTextStyles.button
                  .copyWith(color: config.foregroundColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(_ProviderConfig config) {
    if (config.imageAsset != null) {
      return Image.asset(
        config.imageAsset!,
        width: 18,
        height: 18,
        errorBuilder: (_, __, ___) => FaIcon(
          config.fallbackIcon,
          size: 18,
          color: config.foregroundColor,
        ),
      );
    }
    return FaIcon(config.fallbackIcon, size: 18, color: config.foregroundColor);
  }
}

class _ProviderConfig {
  final String label;
  final String? imageAsset;
  final FaIconData fallbackIcon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _ProviderConfig({
    required this.label,
    this.imageAsset,
    required this.fallbackIcon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });
}

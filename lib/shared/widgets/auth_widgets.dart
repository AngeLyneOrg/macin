import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';


/// Séparateur "ou" entre le formulaire email et les boutons sociaux.
///
/// Utilisé dans [LoginPage] et [RegisterPage] pour séparer
/// visuellement les deux méthodes d'authentification.
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'ou'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(label, style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

/// Logo MACIN avec variante taille pour Splash / Login / AppBar.
///
/// Si le logo image n'est pas encore dans assets/images/logo.png,
/// affiche un fallback textuel stylé pour ne jamais bloquer le build.
class MacinLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const MacinLogo({super.key, this.size = 80, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Center(
            child: Text(
              'M',
              style: AppTextStyles.display1.copyWith(
                color: Colors.white,
                fontSize: size * 0.5,
              ),
            ),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppDimensions.base),
          Text('MACIN', style: AppTextStyles.display2),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Apprends le développement, intelligemment.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

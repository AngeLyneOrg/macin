import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Avatar de l'agent IA MACI.
///
/// Charge `assets/images/maci_avatar.png`. Si le fichier n'est pas
/// encore présent dans le projet, retombe automatiquement sur une
/// icône stylée pour ne jamais casser le build.
///
/// Usage :
/// ```dart
/// MaciAvatar(size: 48)
/// ```
class MaciAvatar extends StatelessWidget {
  final double size;
  final bool withGlow;

  const MaciAvatar({super.key, this.size = 48, this.withGlow = false});

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: Image.asset(
        'assets/images/maci_avatar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.aiSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.aiPrimary,
            size: size * 0.55,
          ),
        ),
      ),
    );

    if (!withGlow) return avatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.aiPrimary, width: 2),
      ),
      child: avatar,
    );
  }
}

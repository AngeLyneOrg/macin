import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/user_model.dart';

/// Card "formateur" compacte — utilisée dans la section "Top formateurs"
/// de la page d'accueil (liste horizontale).
///
/// [rank] (optionnel) affiche une couronne sur le 1er de la liste pour
/// renforcer le côté "mis en avant" sans dépendre d'une vraie métrique
/// de classement (à dénormaliser plus tard, voir [UserRepository.watchTopInstructors]).
///
/// Usage :
/// ```dart
/// MentorCard(mentor: instructor, rank: index + 1, onTap: () => ...)
/// ```
class MentorCard extends StatelessWidget {
  final UserModel mentor;
  final String subtitle;
  final int? rank;
  final VoidCallback? onTap;

  const MentorCard({
    super.key,
    required this.mentor,
    this.subtitle = 'Formateur MACIN',
    this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = mentor.photoUrl != null && mentor.photoUrl!.isNotEmpty;
    final isTop = rank == 1;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppDimensions.avatarLg + AppDimensions.lg,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isTop
                        ? const LinearGradient(
                      colors: [AppColors.accent, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isTop ? null : AppColors.border,
                  ),
                  child: CircleAvatar(
                    radius: AppDimensions.avatarLg / 2,
                    backgroundColor: AppColors.primarySurface,
                    backgroundImage: hasPhoto ? NetworkImage(mentor.photoUrl!) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                      mentor.initials,
                      style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                if (isTop)
                  Positioned(
                    top: -6,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              mentor.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1Medium,
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

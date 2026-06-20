import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/user_model.dart';

/// Card "formateur" compacte — utilisée dans la section "Top formateurs"
/// de la page d'accueil (liste horizontale).
///
/// Usage :
/// ```dart
/// MentorCard(mentor: instructor, onTap: () => ...)
/// ```
class MentorCard extends StatelessWidget {
  final UserModel mentor;
  final String subtitle;
  final VoidCallback? onTap;

  const MentorCard({
    super.key,
    required this.mentor,
    this.subtitle = 'Formateur MACIN',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = mentor.photoUrl != null && mentor.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppDimensions.avatarLg + AppDimensions.lg,
        child: Column(
          children: [
            CircleAvatar(
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

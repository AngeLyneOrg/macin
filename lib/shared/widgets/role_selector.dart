import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';


/// Sélecteur de rôle à l'inscription : Étudiant ou Formateur.
///
/// C'est ce choix qui détermine le rôle ('student' | 'instructor')
/// sauvegardé dans Firestore via [AuthRepository]. Le rôle 'admin'
/// n'est jamais sélectionnable depuis l'UI — il est attribué manuellement.
///
/// Usage :
/// ```dart
/// RoleSelector(
///   selectedRole: _role,
///   onChanged: (role) => setState(() => _role = role),
/// )
/// ```
class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            label: 'Étudiant',
            description: 'Je veux apprendre',
            icon: Icons.school_rounded,
            isSelected: selectedRole == AppConstants.roleStudent,
            onTap: () => onChanged(AppConstants.roleStudent),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _RoleCard(
            label: 'Formateur',
            description: 'Je veux enseigner',
            icon: Icons.cast_for_education_rounded,
            isSelected: selectedRole == AppConstants.roleInstructor,
            onTap: () => onChanged(AppConstants.roleInstructor),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.lg,
          horizontal: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXl,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              label,
              style: AppTextStyles.heading3.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

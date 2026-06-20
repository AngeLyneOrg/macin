import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';

/// Champ de saisie standardisé de MACIN.
///
/// Gère nativement le toggle "afficher/masquer" pour les mots de passe
/// et l'icône préfixe, pour éviter de reconstruire cette logique
/// dans LoginPage, RegisterPage, EditProfilePage, etc.
class MacinTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool enabled;

  const MacinTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<MacinTextField> createState() => _MacinTextFieldState();
}

class _MacinTextFieldState extends State<MacinTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.body1Medium),
        const SizedBox(height: AppDimensions.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          style: AppTextStyles.body1,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon,
                    size: AppDimensions.iconMd,
                    color: AppColors.textTertiary)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.iconMd,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

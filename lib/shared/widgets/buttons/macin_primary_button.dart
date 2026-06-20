import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';


/// Bouton principal de MACIN — fond plein, couleur primaire.
///
/// Gère lui-même l'état de chargement : passer [isLoading] à true
/// désactive le bouton et affiche un spinner à la place du texte.
/// Évite de dupliquer cette logique dans chaque page (Login, Register,
/// Checkout, Quiz submit...).
///
/// Usage :
/// ```dart
/// MacinPrimaryButton(
///   label: 'Se connecter',
///   isLoading: _isLoading,
///   onPressed: _handleLogin,
/// )
/// ```
class MacinPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final double? width;

  const MacinPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;
    final disabled = isLoading || onPressed == null;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(
                isOutlined ? bg : fg,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconMd),
                const SizedBox(width: AppDimensions.sm),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimensions.buttonHeight,
      child: isOutlined
          ? OutlinedButton(
              onPressed: disabled ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: bg,
                side: BorderSide(color: bg, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: disabled ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                disabledBackgroundColor: bg.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                elevation: 0,
              ),
              child: child,
            ),
    );
  }
}

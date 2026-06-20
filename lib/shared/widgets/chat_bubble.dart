import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Bulle de message dans le chat du tuteur IA.
///
/// [isUser] détermine l'alignement (droite/gauche) et la couleur
/// (primaire pour l'utilisateur, surface neutre pour l'IA).
///
/// Usage :
/// ```dart
/// ChatBubble(text: 'Comment fonctionne un StatefulWidget ?', isUser: true)
/// ```
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusLg),
            topRight: const Radius.circular(AppDimensions.radiusLg),
            bottomLeft: Radius.circular(
                isUser ? AppDimensions.radiusLg : AppDimensions.radiusXs),
            bottomRight: Radius.circular(
                isUser ? AppDimensions.radiusXs : AppDimensions.radiusLg),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.body1.copyWith(
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Indicateur "le tuteur écrit..." — trois points animés.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = (_controller.value - i * 0.2) % 1.0;
                final opacity = t < 0.5 ? (t * 2).clamp(0.3, 1.0) : 1.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
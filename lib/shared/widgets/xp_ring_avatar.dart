import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/utils/xp_utils.dart';

/// Avatar entouré d'un anneau de progression XP — élément signature de
/// MACIN, répété dans l'en-tête de [HomePage] (petit format) et de
/// [ProfilePage] (grand format) pour ancrer visuellement la
/// gamification dans toute l'app.
///
/// L'anneau affiche la progression vers le niveau suivant (voir
/// [XpUtils.progressInCurrentLevel]). Une pastille "Niveau N" peut être
/// affichée en bas à droite via [showLevelBadge].
///
/// Usage :
/// ```dart
/// XpRingAvatar(
///   xp: user.xp,
///   photoUrl: user.photoUrl,
///   initials: user.initials,
///   size: 56,
///   showLevelBadge: true,
/// )
/// ```
class XpRingAvatar extends StatelessWidget {
  final int xp;
  final String initials;
  final String? photoUrl;
  final double size;
  final double ringWidth;
  final bool showLevelBadge;

  const XpRingAvatar({
    super.key,
    required this.xp,
    required this.initials,
    this.photoUrl,
    this.size = 56.0,
    this.ringWidth = 4.0,
    this.showLevelBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = XpUtils.levelFromXp(xp);
    final progress = XpUtils.progressInCurrentLevel(xp).clamp(0.0, 1.0);
    final outerSize = size + ringWidth * 2 + 6.0;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(outerSize),
            painter: _RingPainter(progress: progress, strokeWidth: ringWidth),
          ),
          CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: hasPhoto
                ? null
                : Text(
                    initials,
                    style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                  ),
          ),
          if (showLevelBadge)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text(
                  '$level',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _RingPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.accent, AppColors.primary, AppColors.accent],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
}

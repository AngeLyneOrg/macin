import 'dart:ui';
import 'package:flutter/material.dart';

/// Toile de fond décorative "Aurora" — quelques halos de couleur flous
/// posés sur un fond ([background]), pour donner de la profondeur aux
/// sections héros sans dépendre d'images réseau.
///
/// Élément signature de MACIN : réutilisé dans l'en-tête de [HomePage],
/// l'en-tête de [ProfilePage] et la carte solde de [WalletPage] pour
/// donner une identité visuelle cohérente et reconnaissable d'un écran
/// à l'autre.
///
/// Le [child] est positionné par-dessus les halos, dans un [Stack].
///
/// Usage :
/// ```dart
/// AuroraBackdrop(
///   background: const BoxDecoration(color: AppColors.background),
///   blobColors: const [AppColors.primary, AppColors.secondary],
///   borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
///   padding: const EdgeInsets.all(20),
///   child: ...,
/// )
/// ```
class AuroraBackdrop extends StatelessWidget {
  final Decoration background;
  final List<Color> blobColors;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blobOpacity;

  const AuroraBackdrop({
    super.key,
    required this.background,
    required this.blobColors,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.blobOpacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: background,
        child: Stack(
          children: [
            if (blobColors.isNotEmpty)
              Positioned(
                top: -50,
                right: -36,
                child: _Blob(color: blobColors[0], size: 170, opacity: blobOpacity),
              ),
            if (blobColors.length > 1)
              Positioned(
                bottom: -60,
                left: -44,
                child: _Blob(color: blobColors[1], size: 190, opacity: blobOpacity),
              ),
            if (blobColors.length > 2)
              Positioned(
                top: 18,
                left: -26,
                child: _Blob(color: blobColors[2], size: 110, opacity: blobOpacity * 0.85),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity),
          ),
        ),
      ),
    );
  }
}

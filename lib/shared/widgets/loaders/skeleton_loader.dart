import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';

/// Effet de chargement "shimmer" maison — un simple pulse d'opacité en
/// boucle, pour éviter d'ajouter une dépendance externe (`shimmer`) pour
/// un besoin aussi basique. Si tu veux un vrai balayage de lumière plus
/// tard, le package `shimmer` peut remplacer ce widget sans toucher au
/// reste (même API : juste un `child`).
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Bloc de base pour construire un skeleton (rectangle gris arrondi).
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppDimensions.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton d'un [CourseCard] — tailles calquées sur les vraies cards
/// (featured vs compact) pour éviter un "saut" de layout au chargement.
class CourseCardSkeleton extends StatelessWidget {
  final bool featured;
  const CourseCardSkeleton({super.key, this.featured = false});

  @override
  Widget build(BuildContext context) {
    final width = featured ? AppDimensions.courseCardWidth : 168.0;
    final imageHeight = featured ? AppDimensions.courseCardHeight : 110.0;

    return Shimmer(
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: width,
              height: imageHeight,
              radius: AppDimensions.radiusLg,
            ),
            if (!featured) ...[
              const SizedBox(height: AppDimensions.sm),
              SkeletonBox(width: width * 0.8, height: AppDimensions.skeletonLineHeight),
              const SizedBox(height: AppDimensions.xs),
              SkeletonBox(width: width * 0.5, height: AppDimensions.skeletonLineHeightSm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton d'un [MentorCard].
class MentorCardSkeleton extends StatelessWidget {
  const MentorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        width: AppDimensions.avatarLg + AppDimensions.lg,
        child: Column(
          children: [
            ClipOval(
              child: SkeletonBox(
                width: AppDimensions.avatarLg,
                height: AppDimensions.avatarLg,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            SkeletonBox(
              width: AppDimensions.avatarLg * 0.8,
              height: AppDimensions.skeletonLineHeightSm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de l'en-tête [ProfilePage] (avatar + nom + email) pendant
/// le premier chargement du `StreamBuilder<UserModel>`.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Row(
        children: [
          ClipOval(
            child: SkeletonBox(width: AppDimensions.avatarXl, height: AppDimensions.avatarXl),
          ),
          const SizedBox(width: AppDimensions.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: AppDimensions.skeletonLineHeight),
                const SizedBox(height: AppDimensions.xs),
                SkeletonBox(width: 110, height: AppDimensions.skeletonLineHeightSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton d'une rangée de 3 [StatPill].
class StatRowSkeleton extends StatelessWidget {
  const StatRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget pill() => Expanded(
      child: Shimmer(
        child: SkeletonBox(
          width: double.infinity,
          height: 92,
          radius: AppDimensions.radiusLg,
        ),
      ),
    );
    return Row(
      children: [
        pill(),
        const SizedBox(width: AppDimensions.sm),
        pill(),
        const SizedBox(width: AppDimensions.sm),
        pill(),
      ],
    );
  }
}

/// Skeleton d'une ligne [TransactionTile].
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipOval(child: SkeletonBox(width: AppDimensions.avatarSm, height: AppDimensions.avatarSm)),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: AppDimensions.skeletonLineHeightSm),
                  const SizedBox(height: AppDimensions.xs),
                  SkeletonBox(width: 70, height: AppDimensions.skeletonLineHeightSm),
                ],
              ),
            ),
            SkeletonBox(width: 56, height: AppDimensions.skeletonLineHeightSm),
          ],
        ),
      ),
    );
  }
}

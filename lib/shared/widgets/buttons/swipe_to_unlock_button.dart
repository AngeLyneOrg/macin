import 'package:flutter/material.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';

/// Bouton "glisse pour débloquer" — inspiré de la maquette "Course
/// Details" jointe (track jaune avec "Swipe to unlock >>> $400").
///
/// L'utilisateur fait glisser le curseur vers la droite. Une fois le
/// seuil atteint, [onUnlock] est appelé et doit retourner `true` en cas
/// de succès (le curseur reste verrouillé-ouvert avec une coche) ou
/// `false` en cas d'échec (le curseur revient à zéro pour permettre un
/// nouvel essai). Gère lui-même son état de chargement pendant l'attente.
///
/// Usage :
/// ```dart
/// SwipeToUnlockButton(
///   label: 'Glisse pour débloquer',
///   priceLabel: course.price.asFcfa,
///   onUnlock: () async {
///     // ... logique d'achat ...
///     return success; // bool
///   },
/// )
/// ```
class SwipeToUnlockButton extends StatefulWidget {
  final String label;
  final String priceLabel;
  final Future<bool> Function() onUnlock;

  const SwipeToUnlockButton({
    super.key,
    required this.label,
    required this.priceLabel,
    required this.onUnlock,
  });

  @override
  State<SwipeToUnlockButton> createState() => _SwipeToUnlockButtonState();
}

class _SwipeToUnlockButtonState extends State<SwipeToUnlockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapController;
  double _dragX = 0;
  bool _unlocked = false;
  bool _isBusy = false;

  static const double _thumbSize = 44;
  static const double _threshold = 0.78;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(double maxDrag, double delta) {
    if (_unlocked || _isBusy) return;
    setState(() => _dragX = (_dragX + delta).clamp(0.0, maxDrag));
  }

  Future<void> _onDragEnd(double maxDrag) async {
    if (_unlocked || _isBusy) return;

    if (maxDrag <= 0 || _dragX / maxDrag < _threshold) {
      _animateTo(0);
      return;
    }

    setState(() {
      _dragX = maxDrag;
      _isBusy = true;
    });

    final success = await widget.onUnlock();
    if (!mounted) return;

    if (success) {
      setState(() {
        _unlocked = true;
        _isBusy = false;
      });
    } else {
      setState(() => _isBusy = false);
      _animateTo(0);
    }
  }

  void _animateTo(double target) {
    final tween = Tween<double>(begin: _dragX, end: target);
    _snapController.reset();
    void listener() => setState(() => _dragX = tween.evaluate(_snapController));
    _snapController.addListener(listener);
    _snapController
        .forward()
        .whenComplete(() => _snapController.removeListener(listener));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = (trackWidth - _thumbSize - 8).clamp(0.0, double.infinity);
        final progress = maxDrag > 0 ? (_dragX / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: AppDimensions.buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - progress * 1.3).clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      const SizedBox(width: _thumbSize + AppDimensions.sm),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: AppTextStyles.body1Medium
                              .copyWith(color: AppColors.primaryDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.base),
                        child: Text(
                          widget.priceLabel,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => _onDragUpdate(maxDrag, d.delta.dx),
                  onHorizontalDragEnd: (_) => _onDragEnd(maxDrag),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isBusy
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Icon(
                      _unlocked
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/shared/models/block_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LessonContentRenderer
//
// Widget central pour l'affichage du contenu enrichi d'une leçon.
// Rend la liste [LessonModel.blocks] en UI Flutter : chaque bloc JSON
// saisi dans l'admin devient un widget visuel stylisé.
//
// Blocs supportés :
//   heading  → titre H1/H2/H3 avec taille et poids adaptés
//   text     → paragraphe avec line-height généreux
//   code     → bloc code avec fond sombre, police mono, bouton copier
//   tip      → encadré vert avec icône ampoule
//   warning  → encadré orange avec icône alerte
//   divider  → séparateur horizontal
//   image    → image réseau avec légende optionnelle
//
// Usage :
//   LessonContentRenderer(blocks: lesson.blocks)
//   LessonContentRenderer(blocks: lesson.blocks, padding: EdgeInsets.zero)
// ─────────────────────────────────────────────────────────────────────────────

class LessonContentRenderer extends StatelessWidget {
  final List<BlockModel> blocks;
  final EdgeInsetsGeometry padding;

  const LessonContentRenderer({
    super.key,
    required this.blocks,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.base,
      vertical: AppDimensions.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) => _buildBlock(context, block)).toList(),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, BlockModel block) {
    return switch (block.type) {
      BlockType.heading => _HeadingBlock(block: block),
      BlockType.text => _TextBlock(block: block),
      BlockType.code => _CodeBlock(block: block),
      BlockType.tip => _CalloutBlock(
          block: block,
          icon: Icons.lightbulb_outline_rounded,
          borderColor: AppColors.success,
          backgroundColor: AppColors.successSurface,
          iconColor: AppColors.success,
        ),
      BlockType.warning => _CalloutBlock(
          block: block,
          icon: Icons.warning_amber_rounded,
          borderColor: AppColors.warning,
          backgroundColor: AppColors.warningSurface,
          iconColor: AppColors.warning,
        ),
      BlockType.divider => const _DividerBlock(),
      BlockType.image => _ImageBlock(block: block),
      BlockType.unknown => const SizedBox.shrink(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Blocs individuels (privés — utilisés uniquement par LessonContentRenderer)
// ═══════════════════════════════════════════════════════════════════════════

// ── Heading ──────────────────────────────────────────────────────────────────

class _HeadingBlock extends StatelessWidget {
  final BlockModel block;
  const _HeadingBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final style = switch (block.headingLevel) {
      1 => AppTextStyles.heading1,
      2 => AppTextStyles.heading2,
      _ => AppTextStyles.heading3,
    };
    final topPadding = switch (block.headingLevel) {
      1 => AppDimensions.xl,
      2 => AppDimensions.lg,
      _ => AppDimensions.md,
    };
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: AppDimensions.xs),
      child: Text(block.content ?? '', style: style),
    );
  }
}

// ── Text ─────────────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  final BlockModel block;
  const _TextBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Text(
        block.content ?? '',
        style: AppTextStyles.body1.copyWith(
          height: 1.75,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Code ─────────────────────────────────────────────────────────────────────

class _CodeBlock extends StatefulWidget {
  final BlockModel block;
  const _CodeBlock({required this.block});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
        ClipboardData(text: widget.block.content ?? ''));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.block.language?.toUpperCase() ?? 'CODE';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.codeBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.codeBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : langage + bouton copier
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.codeBorder,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusLg),
                  topRight: Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    language,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _copy,
                    child: Row(
                      children: [
                        Icon(
                          _copied
                              ? Icons.check_rounded
                              : Icons.copy_outlined,
                          size: AppDimensions.iconSm,
                          color: _copied
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copié !' : 'Copier',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _copied
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu code
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                widget.block.content ?? '',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.codeText,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Callout (Tip / Warning) ───────────────────────────────────────────────────

class _CalloutBlock extends StatelessWidget {
  final BlockModel block;
  final IconData icon;
  final Color borderColor;
  final Color backgroundColor;
  final Color iconColor;

  const _CalloutBlock({
    required this.block,
    required this.icon,
    required this.borderColor,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: AppDimensions.iconMd),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (block.title != null && block.title!.isNotEmpty) ...[
                    Text(
                      block.title!,
                      style: AppTextStyles.body1Medium.copyWith(
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                  ],
                  if (block.content != null && block.content!.isNotEmpty)
                    Text(
                      block.content!,
                      style: AppTextStyles.body2.copyWith(height: 1.6),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _DividerBlock extends StatelessWidget {
  const _DividerBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

// ── Image ─────────────────────────────────────────────────────────────────────

class _ImageBlock extends StatelessWidget {
  final BlockModel block;
  const _ImageBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.url == null || block.url!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Image.network(
              block.url!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textTertiary, size: 40),
                ),
              ),
            ),
          ),
          if (block.caption != null && block.caption!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              block.caption!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

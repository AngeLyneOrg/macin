import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/extensions/extensions.dart';
import '../models/models.dart';

/// Ligne d'historique de transaction du wallet.
///
/// Affiche une icône colorée selon le type (crédit/débit), la
/// description, la date relative, et le montant signé.
///
/// Usage :
/// ```dart
/// TransactionTile(transaction: tx)
/// ```
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionTile({super.key, required this.transaction});

  IconData get _icon {
    final desc = transaction.description.toLowerCase();
    if (desc.contains('parrainage') || desc.contains('commission')) {
      return Icons.people_alt_rounded;
    }
    if (desc.contains('recharge')) return Icons.add_card_rounded;
    if (desc.contains('achat')) return Icons.shopping_bag_rounded;
    return transaction.isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppColors.success : AppColors.error;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarSm,
            height: AppDimensions.avatarSm,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: color, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTextStyles.body1Medium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(transaction.createdAt.timeAgo, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '$sign${transaction.amount.toInt().asFcfa}',
            style: AppTextStyles.body1Medium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

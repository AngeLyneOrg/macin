import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/utils/referral_utils.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/models/referral_with_user.dart';
import '../../../../shared/widgets/buttons/macin_primary_button.dart';
import '../../../../shared/widgets/stat_pill.dart';
import '../../../../shared/widgets/transaction_tile.dart';

/// Page Wallet — solde, recharge, évolution du solde, historique,
/// parrainage et gains de commission.
///
/// DONNÉES TEMPLATES : [_templateTransactions] et
/// [_templateReferrals] simulent [UserRepository.watchTransactions]
/// et une future requête sur la collection `referrals` filtrée par
/// `referrerId`. Le solde et le code de parrainage sont en dur ;
/// à remplacer par un `StreamBuilder<UserModel>` une fois branché.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  static const _templateBalance = 47500.0;
  static const _templateReferralCode = 'MAC4-K9RZ';
  static const _templateActiveReferrals = 7;

  bool _showReferrals = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Portefeuille', style: AppTextStyles.heading2),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.sm,
        ),
        children: [
          _buildBalanceCard(context),
          const SizedBox(height: AppDimensions.xl),
          _buildEvolutionChart(),
          const SizedBox(height: AppDimensions.xl),
          _buildReferralStatsRow(),
          const SizedBox(height: AppDimensions.xl),
          _buildReferralCodeCard(context),
          const SizedBox(height: AppDimensions.xl),
          _buildToggleSection(),
          const SizedBox(height: AppDimensions.base),
          _showReferrals ? _buildReferralList() : _buildTransactionList(),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  // ── Carte solde + bouton recharger ───────────────────────────
  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde disponible',
            style: AppTextStyles.body2.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            _templateBalance.toInt().asFcfa,
            style: AppTextStyles.display1.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.base),
          Row(
            children: [
              Expanded(
                child: MacinPrimaryButton(
                  label: 'Recharger',
                  icon: Icons.add_rounded,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () => _showRechargeSheet(context),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: MacinPrimaryButton(
                  label: 'Retirer',
                  icon: Icons.arrow_upward_rounded,
                  isOutlined: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _showWithdrawSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRechargeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.xl,
          right: AppDimensions.xl,
          top: AppDimensions.xl,
          bottom: AppDimensions.xl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recharger mon solde', style: AppTextStyles.heading2),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Choisis ton opérateur mobile money. (Intégration Orange Money / MTN MoMo à venir)',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppDimensions.lg),
            Row(
              children: const [
                Expanded(child: _OperatorTile(label: 'Orange Money', color: Color(0xFFFF7900))),
                SizedBox(width: AppDimensions.md),
                Expanded(child: _OperatorTile(label: 'MTN MoMo', color: Color(0xFFFFCC00))),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    context.showInfoSnack('Retrait : fonctionnalité à venir.');
  }

  // ── Graphique d'évolution du solde ───────────────────────────
  Widget _buildEvolutionChart() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Évolution du solde', style: AppTextStyles.heading3),
          const SizedBox(height: AppDimensions.xs),
          Text('Derniers 6 mois', style: AppTextStyles.caption),
          const SizedBox(height: AppDimensions.base),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.xs),
                          child: Text(months[index], style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5000),
                      FlSpot(1, 12000),
                      FlSpot(2, 18000),
                      FlSpot(3, 22000),
                      FlSpot(4, 38000),
                      FlSpot(5, 47500),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats parrainage ─────────────────────────────────────────
  Widget _buildReferralStatsRow() {
    return Row(
      children: const [
        Expanded(
          child: StatPill(
            icon: Icons.people_alt_rounded,
            value: '$_templateActiveReferrals',
            label: 'Filleuls actifs',
            iconColor: AppColors.secondary,
          ),
        ),
        SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.savings_rounded,
            value: '32K',
            label: 'Gains parrainage',
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }

  // ── Carte code de parrainage ──────────────────────────────────
  Widget _buildReferralCodeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.secondary),
              const SizedBox(width: AppDimensions.sm),
              Text('Ton code de parrainage', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Partage ton code : tu gagnes une commission sur chaque achat de tes filleuls.',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: AppDimensions.base),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.base,
                    vertical: AppDimensions.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    _templateReferralCode,
                    style: AppTextStyles.heading3.copyWith(
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {
                  // Share.share(ReferralUtils.shareMessage(_templateReferralCode, 'Ange'));
                  context.showSuccessSnack('Code copié et prêt à partager !');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Toggle Historique / Parrainages ───────────────────────────
  Widget _buildToggleSection() {
    return Row(
      children: [
        Expanded(
          child: _ToggleTab(
            label: 'Historique',
            isSelected: !_showReferrals,
            onTap: () => setState(() => _showReferrals = false),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _ToggleTab(
            label: 'Mes filleuls',
            isSelected: _showReferrals,
            onTap: () => setState(() => _showReferrals = true),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_templateTransactions.isEmpty) {
      return _buildEmptyList('Aucune transaction pour le moment.');
    }
    return Column(
      children: _templateTransactions
          .map((tx) => TransactionTile(transaction: tx))
          .toList(),
    );
  }

  Widget _buildReferralList() {
    if (_templateReferrals.isEmpty) {
      return _buildEmptyList('Aucun filleul pour le moment.\nPartage ton code !');
    }
    return Column(
      children: _templateReferrals.map((r) => _ReferralTile(data: r)).toList(),
    );
  }

  Widget _buildEmptyList(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xxl),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body2,
        ),
      ),
    );
  }
}

// ── Widgets internes spécifiques au Wallet ─────────────────────

class _OperatorTile extends StatelessWidget {
  final String label;
  final Color color;

  const _OperatorTile({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final ReferralWithUser data;

  const _ReferralTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final referral = data.referral;
    final statusColor = switch (referral.status) {
      'paid' => AppColors.success,
      'confirmed' => AppColors.primary,
      _ => AppColors.warning,
    };
    final statusLabel = switch (referral.status) {
      'paid' => 'Versé',
      'confirmed' => 'Confirmé',
      _ => 'En attente',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm / 2,
            backgroundColor: AppColors.secondarySurface,
            child: Text(
              data.referredName.initials,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.referredName, style: AppTextStyles.body1Medium),
                const SizedBox(height: 2),
                Text(referral.createdAt.timeAgo, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${referral.commissionAmount.toInt().asFcfa}',
                style: AppTextStyles.body1Medium.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: AppTextStyles.labelSmall.copyWith(color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Données templates ────────────────────────────────────────

final List<TransactionModel> _templateTransactions = [
  TransactionModel(
    txId: 'tx1',
    type: 'credit',
    amount: 5000,
    description: 'Commission parrainage — Awa K.',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  TransactionModel(
    txId: 'tx2',
    type: 'debit',
    amount: 15000,
    description: 'Achat — Firebase pour développeurs',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TransactionModel(
    txId: 'tx3',
    type: 'credit',
    amount: 10000,
    description: 'Recharge Orange Money',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  TransactionModel(
    txId: 'tx4',
    type: 'credit',
    amount: 8000,
    description: 'Commission parrainage — Junior M.',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  TransactionModel(
    txId: 'tx5',
    type: 'debit',
    amount: 10000,
    description: 'Achat — UI/UX Design',
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
  ),
];

final List<ReferralWithUser> _templateReferrals = [
  ReferralWithUser(
    referral: ReferralModel(
      referralId: 'ref1',
      referrerId: 'me',
      referredId: 'u1',
      courseId: 'tpl_firebase_essentials',
      commissionRate: 0.10,
      commissionAmount: 1500,
      status: 'paid',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    referredName: 'Awa Kamga',
  ),
  ReferralWithUser(
    referral: ReferralModel(
      referralId: 'ref2',
      referrerId: 'me',
      referredId: 'u2',
      courseId: 'tpl_uiux_design',
      commissionRate: 0.10,
      commissionAmount: 1000,
      status: 'confirmed',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    referredName: 'Junior Mbarga',
  ),
  ReferralWithUser(
    referral: ReferralModel(
      referralId: 'ref3',
      referrerId: 'me',
      referredId: 'u3',
      courseId: null,
      commissionRate: 0.10,
      commissionAmount: 0,
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    referredName: 'Sandrine Eyenga',
  ),
];

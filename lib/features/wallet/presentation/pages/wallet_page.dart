import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/models/referral_with_user.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/repositories/user_repository.dart';
import '../../../../shared/services/local_auth_cache.dart';
import '../../../../shared/widgets/backgrounds/aurora_backdrop.dart';
import '../../../../shared/widgets/buttons/macin_primary_button.dart';
import '../../../../shared/widgets/loaders/skeleton_loader.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_pill.dart';
import '../../../../shared/widgets/transaction_tile.dart';

/// Page Wallet — solde (StreamBuilder sur UserModel), recharge, évolution
/// du solde, historique, parrainage et gains de commission.
///
/// Le solde et le code de parrainage sont désormais lus en temps réel via
/// [UserRepository.watchUser] — tout crédit/débit Firestore se reflète
/// instantanément sans rechargement.
///
/// L'historique des transactions sera branché sur
/// [UserRepository.watchTransactions] dès que la sous-collection
/// `users/{uid}/transactions` sera alimentée. En attendant les
/// [_templateTransactions] servent de données de démo.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  final _userRepo = UserRepository();
  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<UserModel>? _userStream =
  _uid != null ? _userRepo.watchUser(_uid!) : null;

  // TODO: brancher [UserRepository.watchTransactions] dès que disponible.
  static const _templateActiveReferrals = 7;

  bool _showReferrals = false;
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _uid == null || _userStream == null
            ? _buildUnauthenticated()
            : StreamBuilder<UserModel>(
          stream: _userStream,
          initialData: LocalAuthCache.getCachedUser(),
          builder: (context, snap) {
            final user = snap.data;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroBalance(context, user)),
                SliverToBoxAdapter(child: const SizedBox(height: AppDimensions.xl)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEvolutionChart(),
                        const SizedBox(height: AppDimensions.xl),
                        _buildReferralStatsRow(user),
                        const SizedBox(height: AppDimensions.xl),
                        _buildReferralCodeCard(context, user),
                        const SizedBox(height: AppDimensions.xl),
                        _buildHistorySection(),
                        const SizedBox(height: AppDimensions.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── En-tête héros — solde + actions ─────────────────────────
  Widget _buildHeroBalance(BuildContext context, UserModel? user) {
    final balance = user?.walletBalance ?? 0.0;

    return AuroraBackdrop(
      background: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      blobColors: const [Colors.white, AppColors.accent, AppColors.secondary],
      blobOpacity: 0.14,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusXl)),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.sm,
        AppDimensions.pagePaddingH,
        AppDimensions.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portefeuille',
                style: AppTextStyles.heading1.copyWith(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Solde disponible',
            style: AppTextStyles.body2.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.xs),
          user == null
              ? Container(
            height: 44,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          )
              : Text(
            balance.toInt().asFcfa,
            style: AppTextStyles.display1.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.lg),
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
                  backgroundColor: Colors.white.withOpacity(0.18),
                  foregroundColor: Colors.white,
                  onPressed: () => context.showInfoSnack('Retrait : fonctionnalité à venir.'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Graphique d'évolution du solde ───────────────────────────
  Widget _buildEvolutionChart() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Évolution du solde', style: AppTextStyles.heading3),
                  Text('Derniers 6 mois', style: AppTextStyles.caption),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: AppDimensions.iconSm, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('+850%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.base),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.xs),
                          child: Text(months[idx], style: AppTextStyles.caption),
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, idx) {
                        if (idx != 5) return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.18),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
  Widget _buildReferralStatsRow(UserModel? user) {
    return Row(
      children: [
        Expanded(
          child: StatPill(
            icon: Icons.people_alt_rounded,
            value: '$_templateActiveReferrals',
            label: 'Filleuls actifs',
            iconColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.savings_rounded,
            value: '32K',
            label: 'Gains parrainage',
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.account_balance_wallet_rounded,
            value: user != null ? user.walletBalance.toInt().asFcfa.replaceAll(' FCFA', '') : '—',
            label: 'Solde',
            iconColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ── Carte code de parrainage ──────────────────────────────────
  Widget _buildReferralCodeCard(BuildContext context, UserModel? user) {
    final code = user?.referralCode.isNotEmpty == true
        ? user!.referralCode
        : 'MAC4-XXXX';

    return AuroraBackdrop(
      background: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondarySurface, AppColors.aiSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.4)),
      ),
      blobColors: [AppColors.secondary, AppColors.aiPrimary],
      blobOpacity: 0.22,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.xs),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.secondary),
              ),
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
                    boxShadow: [
                      BoxShadow(color: AppColors.textPrimary.withOpacity(0.06), blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    code,
                    style: AppTextStyles.heading3.copyWith(
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                tooltip: 'Copier',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  context.showSuccessSnack('Code copié dans le presse-papier !');
                },
              ),
              const SizedBox(width: AppDimensions.xs),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                tooltip: 'Partager',
                onPressed: () {
                  context.showSuccessSnack('Code prêt à partager !');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section historique/filleuls avec onglets ─────────────────
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Activité', icon: Icons.history_rounded),
        const SizedBox(height: AppDimensions.base),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _SegmentTab(
                label: 'Historique',
                icon: Icons.receipt_long_rounded,
                isSelected: !_showReferrals,
                onTap: () => setState(() => _showReferrals = false),
              ),
              _SegmentTab(
                label: 'Mes filleuls',
                icon: Icons.people_alt_rounded,
                isSelected: _showReferrals,
                onTap: () => setState(() => _showReferrals = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.base),
        _showReferrals ? _buildReferralList() : _buildTransactionList(),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_templateTransactions.isEmpty) {
      return _buildEmptyList(
        icon: Icons.receipt_long_outlined,
        message: 'Aucune transaction pour le moment.',
      );
    }
    return Column(
      children: _templateTransactions
          .map((tx) => TransactionTile(transaction: tx))
          .toList(),
    );
  }

  Widget _buildReferralList() {
    if (_templateReferrals.isEmpty) {
      return _buildEmptyList(
        icon: Icons.people_outline_rounded,
        message: 'Aucun filleul pour le moment.\nPartage ton code !',
      );
    }
    return Column(
      children: _templateReferrals.map((r) => _ReferralTile(data: r)).toList(),
    );
  }

  Widget _buildEmptyList({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconXl, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticated() {
    return Center(
      child: Text('Aucun utilisateur connecté.', style: AppTextStyles.body2),
    );
  }

  // ── Sheet Recharge ───────────────────────────────────────────
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text('Recharger mon solde', style: AppTextStyles.heading2),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Choisis ton opérateur mobile money.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppDimensions.xs),
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: AppDimensions.iconMd, color: AppColors.warning),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Intégration Orange Money / MTN MoMo en cours (issue #checkout)',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Row(
              children: const [
                Expanded(child: _OperatorTile(
                  label: 'Orange Money',
                  emoji: '🟠',
                  color: Color(0xFFFF7900),
                )),
                SizedBox(width: AppDimensions.md),
                Expanded(child: _OperatorTile(
                  label: 'MTN MoMo',
                  emoji: '🟡',
                  color: Color(0xFFFFCC00),
                )),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes spécifiques au Wallet ─────────────────────

class _SegmentTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.textPrimary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconSm,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _OperatorTile({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: AppDimensions.sm),
            Text(label, style: AppTextStyles.labelMedium),
          ],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                ),
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

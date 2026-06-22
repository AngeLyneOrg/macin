import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/badge_medal.dart';
import '../../../../shared/widgets/stat_pill.dart';
import '../../../../shared/widgets/xp_progress_bar.dart';
import '../../../auth/data/auth_repository.dart';

/// Page Profil — infos étudiant, progression XP, statistiques, badges.
///
/// DONNÉES TEMPLATES : [_templateBadges] et les stats affichées
/// simulent ce que [UserRepository.watchUser] et une future requête
/// sur `user_progress` retourneront. Le `currentXp` est en dur ici ;
/// remplace tout le haut de page par un `StreamBuilder<UserModel>`
/// une fois prêt à brancher Firestore.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ── Données templates ──────────────────────────────────────
  static const _templateName = 'Ange Orelien';
  static const _templateEmail = 'ange.orelien@macin.app';
  static const _templateXp = 340;
  static const _templateCoursesCount = 4;
  static const _templateStreak = 12;
  static const _templateCertificates = 1;

  static final List<BadgeModel> _templateBadges = [
    const BadgeModel(
      badgeId: 'badge_first_lesson',
      name: 'Premier pas',
      description: 'Terminer ta première leçon',
      iconUrl: '',
      category: 'learning',
      xpBonus: 10,
      rarity: 'common',
    ),
    const BadgeModel(
      badgeId: 'badge_quiz_master',
      name: 'Quiz Master',
      description: 'Réussir 5 quiz',
      iconUrl: '',
      category: 'achievement',
      xpBonus: 50,
      rarity: 'rare',
    ),
    const BadgeModel(
      badgeId: 'badge_streak_7',
      name: '7 jours de suite',
      description: 'Une semaine sans pause',
      iconUrl: '',
      category: 'achievement',
      xpBonus: 30,
      rarity: 'rare',
    ),
    const BadgeModel(
      badgeId: 'badge_flutter_certified',
      name: 'Certifié Flutter',
      description: 'Certification obtenue',
      iconUrl: '',
      category: 'certification',
      xpBonus: 200,
      rarity: 'epic',
    ),
    const BadgeModel(
      badgeId: 'badge_referral_5',
      name: 'Ambassadeur',
      description: '5 filleuls inscrits',
      iconUrl: '',
      category: 'social',
      xpBonus: 100,
      rarity: 'legendary',
    ),
    // Badge non obtenu, pour montrer l'état "verrouillé"
    const BadgeModel(
      badgeId: 'badge_locked_example',
      name: 'Marathonien',
      description: '30 jours de suite',
      iconUrl: '',
      category: 'achievement',
      xpBonus: 150,
      rarity: 'epic',
    ),
  ];

  static const _unlockedBadgeIds = {
    'badge_first_lesson',
    'badge_quiz_master',
    'badge_streak_7',
    'badge_flutter_certified',
    'badge_referral_5',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            title: Text('Profil', style: AppTextStyles.heading2),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  // TODO: context.pushNamed(AppRoutes.settings)
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.sm),
                  _buildHeader(),
                  const SizedBox(height: AppDimensions.xl),
                  _buildXpCard(),
                  const SizedBox(height: AppDimensions.xl),
                  _buildStatsRow(),
                  const SizedBox(height: AppDimensions.xl),
                  _buildBadgesSection(context),
                  const SizedBox(height: AppDimensions.xl),
                  _buildMenuSection(context),
                  const SizedBox(height: AppDimensions.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header (avatar + nom + email) ───────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: AppDimensions.avatarXl,
          height: AppDimensions.avatarXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _templateName.initials,
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_templateName, style: AppTextStyles.heading2),
              const SizedBox(height: 2),
              Text(_templateEmail, style: AppTextStyles.body2),
              const SizedBox(height: AppDimensions.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  'Étudiant',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          onPressed: () {
            // TODO: context.pushNamed(AppRoutes.editProfile)
          },
        ),
      ],
    );
  }

  // ── Carte XP ─────────────────────────────────────────────────
  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: const XpProgressBar(currentXp: _templateXp),
    );
  }

  // ── Rangée de stats ──────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: const [
        Expanded(
          child: StatPill(
            icon: Icons.menu_book_rounded,
            value: '$_templateCoursesCount',
            label: 'Cours suivis',
          ),
        ),
        SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.local_fire_department_rounded,
            value: '$_templateStreak',
            label: 'Jours de suite',
            iconColor: AppColors.accent,
          ),
        ),
        SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.workspace_premium_rounded,
            value: '$_templateCertificates',
            label: 'Certificats',
            iconColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  // ── Badges ────────────────────────────────────────────────────
  Widget _buildBadgesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mes badges', style: AppTextStyles.heading2),
            Text(
              '${_unlockedBadgeIds.length}/${_templateBadges.length}',
              style: AppTextStyles.captionMedium,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.base),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templateBadges.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, index) {
              final badge = _templateBadges[index];
              final isLocked = !_unlockedBadgeIds.contains(badge.badgeId);
              return BadgeMedal(
                badge: badge,
                isLocked: isLocked,
                onTap: () => _showBadgeDetail(context, badge, isLocked),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge, bool isLocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedal(badge: badge, isLocked: isLocked),
            const SizedBox(height: AppDimensions.base),
            Text(badge.name, style: AppTextStyles.heading2),
            const SizedBox(height: AppDimensions.xs),
            Text(
              badge.description,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            if (!isLocked) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                '+${badge.xpBonus} XP',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
              ),
            ],
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }

  // ── Menu paramètres ───────────────────────────────────────────
  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paramètres', style: AppTextStyles.heading2),
        const SizedBox(height: AppDimensions.sm),
        _MenuTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        _MenuTile(
          icon: Icons.lock_outline_rounded,
          label: 'Confidentialité & sécurité',
          onTap: () {},
        ),
        _MenuTile(
          icon: Icons.dark_mode_outlined,
          label: 'Apparence',
          onTap: () {},
        ),
        _MenuTile(
          icon: Icons.help_outline_rounded,
          label: 'Aide & support',
          onTap: () {},
        ),
        const SizedBox(height: AppDimensions.sm),
        _MenuTile(
          icon: Icons.logout_rounded,
          label: 'Se déconnecter',
          color: AppColors.error,
          onTap: () => _handleSignOut(context),
        ),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Tu devras te reconnecter pour accéder à tes cours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthRepository().signOut();
      // Le routeur redirige automatiquement vers /login via le
      // `redirect` global de AppRouter une fois FirebaseAuth.currentUser == null.
    }
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        child: Row(
          children: [
            Icon(icon, color: tileColor, size: AppDimensions.iconLg),
            const SizedBox(width: AppDimensions.base),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body1Medium.copyWith(color: tileColor),
              ),
            ),
            if (color == null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

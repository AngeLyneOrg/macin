import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/core/extensions/extensions.dart';
import 'package:macin/core/utils/xp_utils.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/models/user_model.dart';
import 'package:macin/shared/repositories/repositories.dart';
import 'package:macin/shared/repositories/user_repository.dart';
import 'package:macin/shared/services/local_auth_cache.dart';
import 'package:macin/shared/widgets/backgrounds/aurora_backdrop.dart';
import 'package:macin/shared/widgets/badge_medal.dart';
import 'package:macin/shared/widgets/loaders/skeleton_loader.dart';
import 'package:macin/shared/widgets/section_header.dart';
import 'package:macin/shared/widgets/stat_pill.dart';
import 'package:macin/shared/widgets/xp_progress_bar.dart';
import 'package:macin/shared/widgets/xp_ring_avatar.dart';
import 'package:macin/features/auth/data/auth_repository.dart';

/// Page Profil — version fusionnée des deux variantes existantes.
///
/// Ce qui a été repris de chaque version :
///  - Header "hero" avec [AuroraBackdrop] + [XpRingAvatar], et cache local
///    ([LocalAuthCache]) en `initialData` pour un premier rendu instantané
///    même hors-ligne.
///  - Carte de niveau détaillée (titre, emoji, XP restant) via [XpUtils].
///  - Progression de cours réelle (en cours / terminés), calculée depuis
///    [ProgressRepository.watchAllProgress] plutôt qu'estimée.
///  - Streak basé sur la vraie donnée `learningProfile['streak']` quand
///    elle existe (sinon 0), au lieu d'une valeur figée en dur (ex-12).
///  - Galerie de badges complète (catalogue [_allBadges]) : on voit aussi
///    les badges pas encore obtenus, l'état "débloqué" étant calculé sur
///    les vraies données via [UserModel.hasBadge].
///  - Écrans dédiés pour "non connecté", "chargement" et "erreur".
///
/// Hypothèses faites sur [UserModel] (à ajuster si les noms diffèrent
/// dans le modèle réel) : `isStudent` / `isInstructor`, `hasBadge(id)`,
/// `learningProfile` (Map), `xp`, `initials`, `displayName`, `email`,
/// `photoUrl`, `enrolledCourseIds`, `badgeIds`.
///
/// TODO : remplacer [_allBadges] par une vraie collection Firestore
/// `badges` (via un futur `BadgeRepository`) dès qu'elle sera peuplée.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userRepo = UserRepository();
  final _progressRepo = ProgressRepository();

  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late final Stream<UserModel>? _userStream =
  _uid != null ? _userRepo.watchUser(_uid!) : null;

  late final Stream<List<UserProgressModel>>? _progressStream =
  _uid != null ? _progressRepo.watchAllProgress(_uid!) : null;

  // ── Catalogue de badges (pas encore en Firestore) ────────────────
  static final List<BadgeModel> _allBadges = [
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
    const BadgeModel(
      badgeId: 'badge_marathonien',
      name: 'Marathonien',
      description: '30 jours de suite',
      iconUrl: '',
      category: 'achievement',
      xpBonus: 150,
      rarity: 'epic',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_uid == null || _userStream == null) {
      return _buildUnauthenticated();
    }

    return StreamBuilder<UserModel>(
      stream: _userStream!,
      initialData: LocalAuthCache.getCachedUser(),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return _buildError();
        }

        final user = userSnap.data;
        if (user == null) {
          return _buildLoading();
        }

        return StreamBuilder<List<UserProgressModel>>(
          stream: _progressStream ?? const Stream.empty(),
          builder: (context, progressSnap) {
            final progressList =
                progressSnap.data ?? const <UserProgressModel>[];
            final coursesInProgress =
                progressList.where((p) => p.progressPercent < 100).length;
            final completedCourses =
                progressList.where((p) => p.progressPercent >= 100).length;
            // Streak réel si déjà calculé côté Firestore (Cloud Function
            // déclenchée à chaque leçon terminée), sinon 0 en attendant.
            final streak = (user.learningProfile['streak'] as int?) ?? 0;

            return _buildContent(
              user: user,
              coursesInProgress: coursesInProgress,
              completedCourses: completedCourses,
              streak: streak,
            );
          },
        );
      },
    );
  }

  // ── États ─────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: AppDimensions.sm),
              ProfileHeaderSkeleton(),
              SizedBox(height: AppDimensions.xl),
              StatRowSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined,
                size: AppDimensions.iconXxl, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.base),
            Text('Impossible de charger le profil',
                style: AppTextStyles.heading3),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticated() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: AppDimensions.iconXxl, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.base),
            Text('Connecte-toi pour voir ton profil',
                style: AppTextStyles.heading3),
            const SizedBox(height: AppDimensions.base),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.login),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contenu principal ────────────────────────────────────────

  Widget _buildContent({
    required UserModel user,
    required int coursesInProgress,
    required int completedCourses,
    required int streak,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader(context, user)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.lg),
                  _buildStatsRow(user, streak),
                  const SizedBox(height: AppDimensions.xl),
                  _buildLevelCard(user),
                  const SizedBox(height: AppDimensions.xl),
                  _buildProgressSection(coursesInProgress, completedCourses),
                  const SizedBox(height: AppDimensions.xl),
                  _buildBadgesSection(user),
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

  // ── En-tête héros (avatar + anneau XP + nom + rôle) ──────────
  Widget _buildHeroHeader(BuildContext context, UserModel user) {
    final roleLabel = user.isStudent
        ? 'Étudiant'
        : user.isInstructor
        ? 'Formateur'
        : 'Admin';

    return AuroraBackdrop(
      background: const BoxDecoration(color: AppColors.background),
      blobColors: const [
        AppColors.secondary,
        AppColors.primary,
        AppColors.accent
      ],
      blobOpacity: 0.16,
      borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl)),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.sm,
        AppDimensions.pagePaddingH,
        AppDimensions.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profil', style: AppTextStyles.heading1),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textPrimary),
                onPressed: () {
                  // TODO: context.pushNamed(AppRoutes.settings)
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              XpRingAvatar(
                xp: user.xp,
                initials: user.initials.isEmpty ? '?' : user.initials,
                photoUrl: user.photoUrl,
                size: 76,
                ringWidth: 4,
                showLevelBadge: true,
              ),
              const SizedBox(width: AppDimensions.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isEmpty
                          ? 'Étudiant MACIN'
                          : user.displayName,
                      style: AppTextStyles.heading2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTextStyles.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(AppDimensions.radiusRound),
                      ),
                      child: Text(
                        roleLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {
                  // TODO: context.pushNamed(AppRoutes.editProfile)
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rangée de stats ──────────────────────────────────────────
  Widget _buildStatsRow(UserModel user, int streak) {
    return Row(
      children: [
        Expanded(
          child: StatPill(
            icon: Icons.menu_book_rounded,
            value: '${user.enrolledCourseIds.length}',
            label: 'Cours suivis',
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            label: 'Jours de suite',
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: StatPill(
            icon: Icons.workspace_premium_rounded,
            value: '${user.badgeIds.length}',
            label: 'Badges',
            iconColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  // ── Carte de niveau (titre, emoji, XP restant) ───────────────
  Widget _buildLevelCard(UserModel user) {
    final level = XpUtils.levelFromXp(user.xp);
    final levelTitle = XpUtils.levelTitle(level);
    final levelEmoji = XpUtils.levelEmoji(level);
    final xpInLevel = XpUtils.xpInCurrentLevel(user.xp);
    final xpToNext = XpUtils.xpToNextLevel(user.xp);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(levelEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppDimensions.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Niveau $level — $levelTitle',
                      style: AppTextStyles.body1Medium),
                  Text('${user.xp} XP total',
                      style: AppTextStyles.captionMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.base),
          XpProgressBar(currentXp: user.xp),
          const SizedBox(height: AppDimensions.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$xpInLevel XP', style: AppTextStyles.captionMedium),
              Text('encore $xpToNext XP pour niv. ${level + 1}',
                  style: AppTextStyles.captionMedium),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progression des cours ─────────────────────────────────────
  Widget _buildProgressSection(int inProgress, int completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Ma progression', icon: Icons.trending_up_rounded),
        const SizedBox(height: AppDimensions.base),
        Row(
          children: [
            Expanded(
              child: _ProgressMiniCard(
                icon: Icons.play_circle_outline_rounded,
                color: AppColors.primary,
                value: '$inProgress',
                label: 'En cours',
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _ProgressMiniCard(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                value: '$completed',
                label: 'Terminés',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Badges ────────────────────────────────────────────────────
  Widget _buildBadgesSection(UserModel user) {
    final unlockedCount =
        _allBadges.where((b) => user.hasBadge(b.badgeId)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Mes badges',
          icon: Icons.emoji_events_rounded,
          subtitle: '$unlockedCount/${_allBadges.length} débloqués',
        ),
        const SizedBox(height: AppDimensions.base),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _allBadges.length,
            separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, index) {
              final badge = _allBadges[index];
              final isLocked = !user.hasBadge(badge.badgeId);
              return BadgeMedal(
                badge: badge,
                isLocked: isLocked,
                onTap: () => _showBadgeDetail(badge, isLocked),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBadgeDetail(BadgeModel badge, bool isLocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (ctx) => Padding(
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
        const SectionHeader(title: 'Paramètres', icon: Icons.tune_rounded),
        const SizedBox(height: AppDimensions.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.primary,
                label: 'Notifications',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.divider),
              _MenuTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.secondary,
                label: 'Confidentialité & sécurité',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.divider),
              _MenuTile(
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.textSecondary,
                label: 'Apparence',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.divider),
              _MenuTile(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.success,
                label: 'Aide & support',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.base),
        Container(
          decoration: BoxDecoration(
            color: AppColors.errorSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
          child: _MenuTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            label: 'Se déconnecter',
            labelColor: AppColors.error,
            onTap: () => _handleSignOut(context),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content:
        const Text('Tu devras te reconnecter pour accéder à tes cours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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

// ═══════════════════════════════════════════════════════════════
// Widgets internes
// ═══════════════════════════════════════════════════════════════

class _ProgressMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ProgressMiniCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconLg),
          const SizedBox(width: AppDimensions.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
              Text(label, style: AppTextStyles.captionMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = labelColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: AppDimensions.iconMd),
            ),
            const SizedBox(width: AppDimensions.base),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body1Medium.copyWith(color: tileColor),
              ),
            ),
            if (labelColor == null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
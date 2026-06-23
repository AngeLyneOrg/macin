import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/core/constants/app_text_styles.dart';
import 'package:macin/router/app_routes.dart';
import 'package:macin/shared/models/course_model.dart';
import 'package:macin/shared/models/models.dart';
import 'package:macin/shared/models/user_model.dart';
import 'package:macin/shared/repositories/repositories.dart';
import 'package:macin/shared/repositories/user_repository.dart';
import 'package:macin/shared/services/local_auth_cache.dart';
import 'package:macin/shared/widgets/backgrounds/aurora_backdrop.dart';
import 'package:macin/shared/widgets/cards/continue_learning_card.dart';
import 'package:macin/shared/widgets/cards/course_card.dart';
import 'package:macin/shared/widgets/cards/mentor_card.dart';
import 'package:macin/shared/widgets/loaders/skeleton_loader.dart';
import 'package:macin/shared/widgets/section_header.dart';
import 'package:macin/shared/widgets/xp_ring_avatar.dart';

/// Page d'accueil MACIN.
///
/// `CustomScrollView` + sections en `SliverToBoxAdapter`, chaque section
/// branchée sur son propre `StreamBuilder` indépendant (issue #26) :
///   - profil (en-tête + salutation + anneau XP)
///   - progression (carte "Reprendre l'apprentissage")
///   - formateurs mis en avant
///   - cours publiés (cards "featured" + liste compacte), filtrables
///     par catégorie
///
/// NOTE catégories : les valeurs de [_categories] doivent correspondre
/// aux `tags` réellement utilisés par les formateurs en Firestore — à
/// ajuster si ta taxonomie de tags diffère.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _CategoryItem {
  final String label;
  final String? value;
  final IconData icon;
  const _CategoryItem(this.label, this.value, this.icon);
}

class _HomePageState extends State<HomePage> {
  final _userRepo = UserRepository();
  final _courseRepo = CourseRepository();

  String? _selectedTag;

  static const List<_CategoryItem> _categories = [
    _CategoryItem('Tous', null, Icons.apps_rounded),
    _CategoryItem('Développement', 'dev', Icons.code_rounded),
    _CategoryItem('UI/UX Design', 'design', Icons.palette_rounded),
    _CategoryItem('Data & IA', 'data', Icons.auto_awesome_rounded),
  ];

  // `late final` : calculés une seule fois pour la durée de vie du State,
  // pas à chaque `build()`. Sinon chaque `setState()` (ex: tap sur une
  // catégorie) recréerait ces Stream et forcerait un nouvel abonnement
  // Firestore inutile pour des sections qui ne dépendent pas du filtre.
  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<UserModel>? _userStream =
  _uid != null ? _userRepo.watchUser(_uid!) : null;
  late final Stream<List<UserModel>> _mentorsStream = _userRepo.watchTopInstructors();

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader(uid)),
            SliverToBoxAdapter(child: const SizedBox(height: AppDimensions.sm)),
            SliverToBoxAdapter(child: _buildCategories()),
            if (uid != null) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.xl,
                  AppDimensions.pagePaddingH,
                  0,
                ),
                sliver: SliverToBoxAdapter(child: _ContinueLearningSection(uid: uid)),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.xl,
                0,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _buildMentorsSection()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.xl,
                0,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _buildCoursesSection()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xxl)),
          ],
        ),
      ),
    );
  }

  // ── En-tête héros (salutation + anneau XP + recherche) ────

  Widget _buildHeroHeader(String? uid) {
    return Column(
      children: [
        AuroraBackdrop(
          background: const BoxDecoration(color: AppColors.background),
          blobColors: const [AppColors.primary, AppColors.secondary, AppColors.accent],
          blobOpacity: 0.16,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusXl)),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.sm,
            AppDimensions.pagePaddingH,
            AppDimensions.xxl,
          ),
          child: uid == null || _userStream == null
              ? _buildHeaderRow(null)
              : StreamBuilder<UserModel>(
            stream: _userStream,
            initialData: LocalAuthCache.getCachedUser(),
            builder: (context, snap) => _buildHeaderRow(snap.data),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
            child: _buildSearchBar(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(UserModel? user) {
    final firstName = (user?.displayName ?? '').split(' ').first;
    final greeting = _greetingForNow();

    return Row(
      children: [
        if (user != null)
          XpRingAvatar(
            xp: user.xp,
            initials: user.initials.isEmpty ? '?' : user.initials,
            photoUrl: user.photoUrl,
            size: 46,
            ringWidth: 3,
          )
        else
          Container(
            width: AppDimensions.avatarSm,
            height: AppDimensions.avatarSm,
            decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTextStyles.body2),
              Text(
                firstName.isEmpty ? 'Bienvenue 👋' : '$firstName 👋',
                style: AppTextStyles.heading1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _circleIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            // TODO: brancher NotificationCenter (issue notifications).
          },
        ),
      ],
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.avatarSm,
        height: AppDimensions.avatarSm,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, size: AppDimensions.iconMd, color: AppColors.textPrimary),
      ),
    );
  }

  // ── Recherche ──────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: brancher AppRoutes.search une fois la page créée (issue #25).
      },
      child: Container(
        height: AppDimensions.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textTertiary),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text('Rechercher un cours...', style: AppTextStyles.body2),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: AppDimensions.iconMd),
            ),
          ],
        ),
      ),
    );
  }

  // ── Catégories ─────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedTag == category.value;

          return GestureDetector(
            onTap: () => setState(() => _selectedTag = category.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: AppDimensions.iconSm,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    category.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Formateurs ─────────────────────────────────────────────

  Widget _buildMentorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
          child: const SectionHeader(
            title: 'Top formateurs',
            icon: Icons.workspace_premium_rounded,
          ),
        ),
        const SizedBox(height: AppDimensions.base),
        SizedBox(
          height: AppDimensions.avatarLg + 56,
          child: StreamBuilder<List<UserModel>>(
            stream: _mentorsStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.base),
                  itemBuilder: (_, __) => const MentorCardSkeleton(),
                );
              }
              final mentors = snap.data!;
              if (mentors.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                  child: Text('Aucun formateur pour le moment.', style: AppTextStyles.body2),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                itemCount: mentors.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.base),
                itemBuilder: (context, index) => MentorCard(
                  mentor: mentors[index],
                  rank: index + 1,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Cours ──────────────────────────────────────────────────

  Widget _buildCoursesSection() {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseRepo.watchPublishedCourses(tagFilter: _selectedTag),
      builder: (context, snap) {
        final isLoading = !snap.hasData;
        final courses = snap.data ?? const <CourseModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
              child: const SectionHeader(title: 'Cours populaires', icon: Icons.local_fire_department_rounded),
            ),
            const SizedBox(height: AppDimensions.base),
            SizedBox(
              height: AppDimensions.courseCardHeight,
              child: isLoading
                  ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.base),
                itemBuilder: (_, __) => const CourseCardSkeleton(featured: true),
              )
                  : courses.isEmpty
                  ? _buildEmptyCoursesHint()
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.base),
                itemBuilder: (context, index) => CourseCard.featured(
                  course: courses[index],
                  onTap: () => _openCourse(context, courses[index]),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
              child: const SectionHeader(title: 'Tous les cours', icon: Icons.menu_book_rounded),
            ),
            const SizedBox(height: AppDimensions.base),
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
              child: isLoading
                  ? Wrap(
                spacing: AppDimensions.base,
                runSpacing: AppDimensions.base,
                children: List.generate(4, (_) => const CourseCardSkeleton()),
              )
                  : courses.isEmpty
                  ? Text('Rien à afficher pour l\'instant.', style: AppTextStyles.body2)
                  : Wrap(
                spacing: AppDimensions.base,
                runSpacing: AppDimensions.base,
                children: courses
                    .map((c) => CourseCard.compact(
                  course: c,
                  onTap: () => _openCourse(context, c),
                ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCoursesHint() {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, color: AppColors.textTertiary, size: AppDimensions.iconXl),
          const SizedBox(height: AppDimensions.sm),
          Text('Aucun cours pour cette catégorie.', style: AppTextStyles.body2, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _openCourse(BuildContext context, CourseModel course) {
    context.pushNamed(
      AppRoutes.courseDetail,
      pathParameters: {'id': course.courseId},
    );
  }
}

/// Section "Reprendre l'apprentissage" — isolée dans son propre widget
/// pour garder son `StreamBuilder` (progression) indépendant du reste
/// de la page, comme demandé par l'architecture cible (issue #26).
///
/// `StatefulWidget` (et non `StatelessWidget`) volontairement : ça
/// garantit que le `Stream` Firestore est créé une seule fois dans
/// `initState`, même si [HomePage] se reconstruit (ex: tap sur une
/// catégorie) — Flutter réutilise le même `State` tant que ce widget
/// reste au même endroit dans l'arbre, donc pas de réabonnement inutile.
class _ContinueLearningSection extends StatefulWidget {
  final String uid;
  const _ContinueLearningSection({required this.uid});

  @override
  State<_ContinueLearningSection> createState() => _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<_ContinueLearningSection> {
  final _progressRepo = ProgressRepository();
  final _courseRepo = CourseRepository();
  late final Stream<List<UserProgressModel>> _progressStream =
  _progressRepo.watchAllProgress(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProgressModel>>(
      stream: _progressStream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final inProgress = snap.data!
            .where((p) => p.progressPercent < 100)
            .toList()
          ..sort((a, b) {
            final aDate = a.lastAccessedAt ?? DateTime(2000);
            final bDate = b.lastAccessedAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });

        if (inProgress.isEmpty) return const SizedBox.shrink();
        final current = inProgress.first;

        return FutureBuilder<CourseModel?>(
          future: _courseRepo.getCourse(current.courseId),
          builder: (context, courseSnap) {
            final course = courseSnap.data;
            if (course == null) return const SizedBox.shrink();

            return ContinueLearningCard(
              courseTitle: course.title,
              completedLessons: current.completedLessonIds.length,
              totalLessons: course.totalLessons,
              progressPercent: current.progressPercent,
              onTap: () => context.pushNamed(
                AppRoutes.courseDetail,
                pathParameters: {'id': course.courseId},
              ),
            );
          },
        );
      },
    );
  }
}

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
import 'package:macin/shared/widgets/cards/continue_learning_card.dart';
import 'package:macin/shared/widgets/cards/course_card.dart';
import 'package:macin/shared/widgets/cards/mentor_card.dart';
import 'package:macin/shared/widgets/loaders/skeleton_loader.dart';
import 'package:macin/shared/widgets/section_header.dart';

/// Page d'accueil MACIN.
///
/// `CustomScrollView` + sections en `SliverToBoxAdapter`, chaque section
/// branchée sur son propre `StreamBuilder` indépendant (issue #26) :
///   - profil (en-tête + salutation)
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

class _HomePageState extends State<HomePage> {
  final _userRepo = UserRepository();
  final _courseRepo = CourseRepository();
  final _progressRepo = ProgressRepository();

  String? _selectedTag;

  static const Map<String, String?> _categories = {
    'Tous': null,
    'Développement': 'dev',
    'UI/UX Design': 'design',
    'Data & IA': 'data',
  };

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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.sm,
                AppDimensions.pagePaddingH,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _buildHeader(uid)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.lg,
                AppDimensions.pagePaddingH,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _buildSearchBar(context)),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: AppDimensions.base)),
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

  // ── En-tête / salutation ──────────────────────────────────

  Widget _buildHeader(String? uid) {
    if (uid == null || _userStream == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel>(
      stream: _userStream,
      initialData: LocalAuthCache.getCachedUser(),
      builder: (context, snap) {
        final user = snap.data;
        final firstName = (user?.displayName ?? '').split(' ').first;
        final greeting = _greetingForNow();

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: AppTextStyles.body2),
                  Text(
                    firstName.isEmpty ? 'Bienvenue 👋' : '$firstName 👋',
                    style: AppTextStyles.heading1,
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
            const SizedBox(width: AppDimensions.sm),
            CircleAvatar(
              radius: AppDimensions.avatarSm / 2,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? Text(
                user?.initials ?? '?',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              )
                  : null,
            ),
          ],
        );
      },
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
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
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
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textTertiary),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text('Rechercher un cours...', style: AppTextStyles.body2),
            ),
            const Icon(Icons.tune_rounded, color: AppColors.textTertiary, size: AppDimensions.iconMd),
          ],
        ),
      ),
    );
  }

  // ── Catégories ─────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final label = _categories.keys.elementAt(index);
          final value = _categories.values.elementAt(index);
          final isSelected = _selectedTag == value;

          return GestureDetector(
            onTap: () => setState(() => _selectedTag = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
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
          child: const SectionHeader(title: 'Top formateurs'),
        ),
        const SizedBox(height: AppDimensions.base),
        SizedBox(
          height: AppDimensions.avatarLg + 52,
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
                itemBuilder: (context, index) => MentorCard(mentor: mentors[index]),
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
              child: const SectionHeader(title: 'Cours populaires'),
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
                  ? Padding(
                padding: const EdgeInsets.only(right: AppDimensions.pagePaddingH),
                child: Text('Aucun cours pour cette catégorie.', style: AppTextStyles.body2),
              )
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
              child: const SectionHeader(title: 'Tous les cours'),
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

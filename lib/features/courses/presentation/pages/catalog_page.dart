import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/course_model.dart';
import '../../../../shared/repositories/repositories.dart';
import '../../../../shared/widgets/cards/course_card.dart';
import '../../../../shared/widgets/chips/macin_filter_chip.dart';
import '../../../../shared/widgets/inputs/macin_search_field.dart';
import '../../../../shared/widgets/loaders/skeleton_loader.dart';
import '../../../../shared/widgets/section_header.dart';

/// Page Catalogue — recherche + filtres (niveau, tags) + grille de cours.
///
/// Branchée sur [CourseRepository.watchPublishedCourses] (sans filtre
/// serveur) : recherche, niveau et tags sont ensuite appliqués en
/// mémoire ici. Choix volontaire — combiner `level` + `tags` +
/// `orderBy(createdAt)` côté Firestore demanderait un index composite
/// supplémentaire (déjà eu ce problème avec `watchPublishedCourses` sur
/// la home, voir le `FAILED_PRECONDITION` résolu précédemment) ; filtrer
/// en mémoire sur la page (limitée à [AppConstants.coursesPageSize]
/// cours) évite cette complexité tant que le catalogue reste petit.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  final _courseRepo = CourseRepository();
  late final Stream<List<CourseModel>> _coursesStream = _courseRepo.watchPublishedCourses();

  String? _selectedLevel; // null = tous les niveaux
  String? _selectedTag; // null = tous les tags
  String _searchQuery = '';

  static const _levels = [
    {'value': 'beginner', 'label': 'Débutant'},
    {'value': 'intermediate', 'label': 'Intermédiaire'},
    {'value': 'advanced', 'label': 'Avancé'},
  ];

  static const _tags = [
    'flutter', 'dart', 'firebase', 'backend', 'design', 'ui', 'ux', 'mobile',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedLevel != null || _selectedTag != null || _searchQuery.isNotEmpty;

  List<CourseModel> _applyFilters(List<CourseModel> source) {
    return source.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLevel = _selectedLevel == null || course.level == _selectedLevel;
      final matchesTag = _selectedTag == null || course.tags.contains(_selectedTag);
      return matchesSearch && matchesLevel && matchesTag;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedLevel = null;
      _selectedTag = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<CourseModel>>(
          stream: _coursesStream,
          builder: (context, snap) {
            final isLoading = !snap.hasData;
            final allCourses = snap.data ?? const <CourseModel>[];
            final filtered = isLoading ? const <CourseModel>[] : _applyFilters(allCourses);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.sm,
                    AppDimensions.pagePaddingH,
                    0,
                  ),
                  child: SectionHeader(
                    title: 'Catalogue',
                    icon: Icons.local_library_rounded,
                    subtitle: isLoading
                        ? 'Chargement…'
                        : '${filtered.length} cours disponible${filtered.length > 1 ? 's' : ''}',
                  ),
                ),

                // ── Recherche ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.base,
                    AppDimensions.pagePaddingH,
                    AppDimensions.md,
                  ),
                  child: MacinSearchField(
                    controller: _searchController,
                    hint: 'Rechercher un cours, une compétence...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),

                // ── Filtres niveau ───────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePaddingH,
                    ),
                    children: [
                      MacinFilterChip(
                        label: 'Tous les niveaux',
                        isSelected: _selectedLevel == null,
                        onTap: () => setState(() => _selectedLevel = null),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      ..._levels.expand((lvl) => [
                        MacinFilterChip(
                          label: lvl['label']!,
                          isSelected: _selectedLevel == lvl['value'],
                          onTap: () => setState(() => _selectedLevel = lvl['value']),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),

                // ── Filtres tags ──────────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePaddingH,
                    ),
                    children: [
                      MacinFilterChip(
                        label: 'Tous les tags',
                        icon: Icons.sell_outlined,
                        isSelected: _selectedTag == null,
                        onTap: () => setState(() => _selectedTag = null),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      ..._tags.expand((tag) => [
                        MacinFilterChip(
                          label: '#$tag',
                          isSelected: _selectedTag == tag,
                          onTap: () => setState(() => _selectedTag = tag),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                if (_hasActiveFilters) _buildActiveFiltersBar(),
                const SizedBox(height: AppDimensions.xs),

                // ── Grille de résultats ───────────────────────────────
                Expanded(
                  child: isLoading
                      ? _buildSkeletonGrid()
                      : filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildCourseGrid(filtered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: AppDimensions.iconSm, color: AppColors.primary),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              'Filtres actifs',
              style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary),
            ),
          ),
          GestureDetector(
            onTap: _resetFilters,
            child: Text(
              'Réinitialiser',
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.error,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid(List<CourseModel> courses) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.xs,
        AppDimensions.pagePaddingH,
        AppDimensions.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.md,
        crossAxisSpacing: AppDimensions.md,
        childAspectRatio: 0.72,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard.compact(
          course: course,
          onTap: () {
            // TODO: context.pushNamed(AppRoutes.courseDetail, pathParameters: {'id': course.courseId})
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.md,
        crossAxisSpacing: AppDimensions.md,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const CourseCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  size: AppDimensions.iconXxl, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppDimensions.base),
            Text('Aucun cours trouvé', style: AppTextStyles.heading3),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Essaie un autre mot-clé ou retire un filtre.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: AppDimensions.lg),
              OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.sm,
                  ),
                ),
                child: const Text('Réinitialiser les filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

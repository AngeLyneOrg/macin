import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/course_model.dart';
import '../../../../shared/widgets/cards/course_card.dart';
import '../../../../shared/widgets/chips/macin_filter_chip.dart';
import '../../../../shared/widgets/inputs/macin_search_field.dart';
import '../../../../shared/widgets/loaders/skeleton_loader.dart';

/// Page Catalogue — recherche + filtres (niveau, tags) + grille de cours.
///
/// DONNÉES TEMPLATES : la liste [_templateCourses] simule ce que
/// [CourseRepository.watchPublishedCourses] retournera une fois
/// branché. Le filtrage (recherche, niveau, tags) est fait
/// localement en mémoire ici — à remplacer par des requêtes
/// Firestore filtrées quand on branchera le vrai repository.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();

  String? _selectedLevel; // null = tous les niveaux
  String? _selectedTag; // null = tous les tags
  String _searchQuery = '';
  bool _isLoading = true;

  static const _levels = [
    {'value': 'beginner', 'label': 'Débutant'},
    {'value': 'intermediate', 'label': 'Intermédiaire'},
    {'value': 'advanced', 'label': 'Avancé'},
  ];

  static const _tags = [
    'flutter', 'dart', 'firebase', 'backend', 'design', 'ui', 'ux', 'mobile',
  ];

  @override
  void initState() {
    super.initState();
    // Simule le délai réseau initial (StreamBuilder en attente).
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CourseModel> get _filteredCourses {
    return _templateCourses.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLevel = _selectedLevel == null || course.level == _selectedLevel;
      final matchesTag = _selectedTag == null || course.tags.contains(_selectedTag);
      return matchesSearch && matchesLevel && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Catalogue', style: AppTextStyles.heading2),
      ),
      body: Column(
        children: [
          // ── Recherche ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.sm,
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
          const SizedBox(height: AppDimensions.md),

          // ── Grille de résultats ───────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildSkeletonGrid()
                : _filteredCourses.isEmpty
                ? _buildEmptyState()
                : _buildCourseGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid() {
    final courses = _filteredCourses;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        0,
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
          instructorName: 'Ange O.',
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
            const Icon(Icons.search_off_rounded,
                size: AppDimensions.iconXxl, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.base),
            Text('Aucun cours trouvé', style: AppTextStyles.heading3),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Essaie un autre mot-clé ou retire un filtre.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Données templates ────────────────────────────────────────
// À remplacer par CourseRepository.watchPublishedCourses() une fois
// le contenu réel disponible dans Firestore (voir projet macin-admin).

final List<CourseModel> _templateCourses = [
  CourseModel(
    courseId: 'tpl_flutter_basics',
    title: 'Les fondamentaux de Flutter',
    description: 'Apprends à construire des applications mobiles avec Flutter.',
    instructorId: 'tpl_instructor_1',
    thumbnailUrl: 'https://picsum.photos/seed/flutter-course/600/400',
    price: 0,
    level: 'beginner',
    tags: const ['flutter', 'dart', 'mobile'],
    totalLessons: 12,
    totalDurationMin: 145,
    isPublished: true,
    averageRating: 4.7,
    totalEnrollments: 234,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  CourseModel(
    courseId: 'tpl_firebase_essentials',
    title: 'Firebase pour développeurs mobiles',
    description: 'Maîtrise Firebase Auth, Firestore et Storage.',
    instructorId: 'tpl_instructor_1',
    thumbnailUrl: 'https://picsum.photos/seed/firebase-course/600/400',
    price: 15000,
    level: 'intermediate',
    tags: const ['firebase', 'backend', 'dart'],
    totalLessons: 18,
    totalDurationMin: 210,
    isPublished: true,
    averageRating: 4.5,
    totalEnrollments: 156,
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  ),
  CourseModel(
    courseId: 'tpl_uiux_design',
    title: 'UI/UX Design pour développeurs',
    description: 'Les principes de design pour créer des apps intuitives.',
    instructorId: 'tpl_instructor_2',
    thumbnailUrl: 'https://picsum.photos/seed/design-course/600/400',
    price: 10000,
    level: 'beginner',
    tags: const ['design', 'ui', 'ux'],
    totalLessons: 9,
    totalDurationMin: 98,
    isPublished: true,
    averageRating: 4.8,
    totalEnrollments: 312,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  CourseModel(
    courseId: 'tpl_advanced_dart',
    title: 'Dart avancé : Streams & Async',
    description: 'Comprendre la programmation asynchrone en profondeur.',
    instructorId: 'tpl_instructor_1',
    thumbnailUrl: 'https://picsum.photos/seed/dart-advanced/600/400',
    price: 20000,
    level: 'advanced',
    tags: const ['dart', 'flutter'],
    totalLessons: 15,
    totalDurationMin: 180,
    isPublished: true,
    averageRating: 4.6,
    totalEnrollments: 89,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  ),
  CourseModel(
    courseId: 'tpl_backend_node',
    title: 'Backend avec Node.js & Express',
    description: 'Construis des APIs REST robustes pour tes apps mobiles.',
    instructorId: 'tpl_instructor_2',
    thumbnailUrl: 'https://picsum.photos/seed/node-course/600/400',
    price: 18000,
    level: 'intermediate',
    tags: const ['backend'],
    totalLessons: 14,
    totalDurationMin: 165,
    isPublished: true,
    averageRating: 4.3,
    totalEnrollments: 67,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  CourseModel(
    courseId: 'tpl_mobile_design',
    title: 'Mockups mobiles avec Figma',
    description: 'De l’idée au prototype interactif, sans coder.',
    instructorId: 'tpl_instructor_2',
    thumbnailUrl: 'https://picsum.photos/seed/figma-course/600/400',
    price: 0,
    level: 'beginner',
    tags: const ['design', 'ui', 'mobile'],
    totalLessons: 7,
    totalDurationMin: 64,
    isPublished: true,
    averageRating: 4.9,
    totalEnrollments: 401,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
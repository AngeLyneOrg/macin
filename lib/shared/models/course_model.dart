import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Modèle d'un cours MACIN.
///
/// Collection Firestore : `courses/{courseId}`
/// Sous-collections : `modules`, `reviews`
class CourseModel extends Equatable {
  final String courseId;
  final String title;
  final String description;
  final String instructorId;
  final String thumbnailUrl;
  final double price; // 0 = gratuit
  final String level; // 'beginner' | 'intermediate' | 'advanced'
  final List<String> tags;
  final int totalLessons;
  final int totalDurationMin;
  final String? certificateTemplate;
  final bool isPublished;
  final double averageRating;
  final int totalEnrollments;
  final DateTime createdAt;

  const CourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.thumbnailUrl,
    required this.price,
    required this.level,
    required this.tags,
    required this.totalLessons,
    required this.totalDurationMin,
    this.certificateTemplate,
    required this.isPublished,
    required this.averageRating,
    required this.totalEnrollments,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      courseId: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      instructorId: data['instructorId'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      level: data['level'] as String? ?? 'beginner',
      tags: List<String>.from(data['tags'] as List? ?? []),
      totalLessons: data['totalLessons'] as int? ?? 0,
      totalDurationMin: data['totalDurationMin'] as int? ?? 0,
      certificateTemplate: data['certificateTemplate'] as String?,
      isPublished: data['isPublished'] as bool? ?? false,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalEnrollments: data['totalEnrollments'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'instructorId': instructorId,
        'thumbnailUrl': thumbnailUrl,
        'price': price,
        'level': level,
        'tags': tags,
        'totalLessons': totalLessons,
        'totalDurationMin': totalDurationMin,
        'certificateTemplate': certificateTemplate,
        'isPublished': isPublished,
        'averageRating': averageRating,
        'totalEnrollments': totalEnrollments,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isFree => price == 0;
  bool get hasCertificate => certificateTemplate != null;
  String get levelLabel => switch (level) {
        'beginner' => 'Débutant',
        'intermediate' => 'Intermédiaire',
        'advanced' => 'Avancé',
        _ => level,
      };

  @override
  List<Object?> get props => [
        courseId, title, instructorId, price, level,
        totalLessons, isPublished, averageRating, createdAt,
      ];
}

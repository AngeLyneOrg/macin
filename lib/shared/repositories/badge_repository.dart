import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/shared/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BadgeRepository
//
// Lecture de la collection `badges/{badgeId}` et gestion des badges
// obtenus par l'étudiant.
//
// La collection `badges` est gérée par l'admin Express.js.
// L'attribution à un utilisateur (badgeIds dans UserModel) est déclenchée
// par une Cloud Function `onProgressWrite` ou `onExerciseCompleted`.
//
// Ce repository permet à Flutter de :
//   - Afficher la liste de tous les badges disponibles (catalogue)
//   - Afficher les badges obtenus par l'utilisateur (profil)
//   - Écouter en temps réel si un nouveau badge est débloqué
// ─────────────────────────────────────────────────────────────────────────────

class BadgeRepository {
  final FirebaseFirestore _db;

  BadgeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _badges =>
      _db.collection(AppConstants.colBadges);

  // ── Streams ───────────────────────────────────────────────

  /// Écoute tous les badges disponibles en temps réel.
  ///
  /// Utilisé dans [BadgeCatalogPage] et [BadgeGrid].
  Stream<List<BadgeModel>> watchAllBadges() {
    return _badges
        .orderBy('category')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BadgeModel.fromFirestore(d)).toList());
  }

  /// Écoute les badges obtenus par un utilisateur en temps réel.
  ///
  /// Filtre [watchAllBadges] côté client depuis la liste [badgeIds]
  /// stockée sur [UserModel] — évite un index composite Firestore.
  ///
  /// Utilisé dans [ProfilePage] section trophées.
  Stream<List<BadgeModel>> watchUserBadges(List<String> badgeIds) {
    if (badgeIds.isEmpty) return Stream.value([]);
    return _badges
        .where(FieldPath.documentId, whereIn: badgeIds)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BadgeModel.fromFirestore(d)).toList());
  }

  // ── Futures ───────────────────────────────────────────────

  /// Récupère un badge par son ID (lecture unique).
  ///
  /// Utilisé lors du déblocage d'un badge pour afficher le dialogue
  /// de félicitations avec les détails (nom, description, rareté).
  Future<BadgeModel?> getBadge(String badgeId) async {
    try {
      final doc = await _badges.doc(badgeId).get();
      if (!doc.exists) return null;
      return BadgeModel.fromFirestore(doc);
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture badge : $e');
    }
  }

  /// Récupère plusieurs badges par leurs IDs en une seule opération.
  ///
  /// Limité à 30 IDs (contrainte Firestore whereIn).
  Future<List<BadgeModel>> getBadgesByIds(List<String> badgeIds) async {
    if (badgeIds.isEmpty) return [];
    try {
      // Batch en chunks de 30 (limite Firestore whereIn)
      final chunks = <List<String>>[];
      for (var i = 0; i < badgeIds.length; i += 30) {
        chunks.add(badgeIds.sublist(
            i, i + 30 > badgeIds.length ? badgeIds.length : i + 30));
      }
      final results = <BadgeModel>[];
      for (final chunk in chunks) {
        final snap = await _badges
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(
            snap.docs.map((d) => BadgeModel.fromFirestore(d)));
      }
      return results;
    } catch (e) {
      throw DatabaseException(message: 'Erreur lecture badges : $e');
    }
  }

  /// Récupère les badges d'une catégorie.
  ///
  /// Catégories : 'learning' | 'social' | 'achievement' | 'certification'
  Future<List<BadgeModel>> getBadgesByCategory(String category) async {
    try {
      final snap = await _badges
          .where('category', isEqualTo: category)
          .get();
      return snap.docs.map((d) => BadgeModel.fromFirestore(d)).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Erreur lecture badges par catégorie : $e');
    }
  }
}

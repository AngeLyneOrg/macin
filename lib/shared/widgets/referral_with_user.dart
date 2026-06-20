import '../models/models.dart';

/// Combine un [ReferralModel] avec les infos d'affichage du filleul
/// (nom, avatar) pour la liste de parrainage dans [WalletPage].
///
/// Ce n'est PAS un modèle Firestore — [ReferralModel] ne stocke que
/// des IDs (référence à la collection `users`) pour éviter la
/// duplication de données. Ce DTO existe uniquement côté UI, une fois
/// que le nom du filleul a été résolu (via [UserRepository.getUser]
/// ou directement dénormalisé si l'app évolue dans ce sens).
///
/// Usage :
/// ```dart
/// ReferralWithUser(referral: referral, referredName: 'Awa K.', referredPhotoUrl: url)
/// ```
class ReferralWithUser {
  final ReferralModel referral;
  final String referredName;
  final String? referredPhotoUrl;

  const ReferralWithUser({
    required this.referral,
    required this.referredName,
    this.referredPhotoUrl,
  });
}
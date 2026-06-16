/// Constantes de dimensions pour MACIN.
///
/// Toujours utiliser ces valeurs pour les paddings, margins,
/// border radius et tailles d'icônes. Jamais de chiffre magique
/// dans les widgets.
abstract class AppDimensions {
  // ── Espacement (système 4pt) ──────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ── Rayons de bordure ────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 100.0; // boutons pills, badges

  // ── Icônes ───────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 48.0;

  // ── Hauteurs de composants ───────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 60.0;
  static const double bottomNavHeight = 72.0;
  static const double cardElevation = 0.0; // flat design, bordures à la place

  // ── Tailles de cards ─────────────────────────────────────
  static const double courseCardWidth = 280.0;
  static const double courseCardHeight = 200.0;
  static const double courseCardThumbnailHeight = 140.0;
  static const double lessonTileHeight = 60.0;

  // ── Avatar ────────────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 72.0;
  static const double avatarXl = 96.0;

  // ── Badge icon ───────────────────────────────────────────
  static const double badgeSm = 40.0;
  static const double badgeMd = 56.0;
  static const double badgeLg = 80.0;

  // ── Padding horizontal de page ───────────────────────────
  static const double pagePaddingH = 20.0;
  static const double pagePaddingV = 24.0;

  // ── Barre XP ─────────────────────────────────────────────
  static const double xpBarHeight = 8.0;
  static const double xpBarHeightSm = 4.0;

  // ── Skeleton loader ──────────────────────────────────────
  static const double skeletonCourseCardHeight = 200.0;
  static const double skeletonLineHeight = 14.0;
  static const double skeletonLineHeightSm = 10.0;
}

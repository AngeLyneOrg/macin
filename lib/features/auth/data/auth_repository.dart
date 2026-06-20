import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:macin/core/constants/app_constants.dart';
import 'package:macin/core/errors/app_exceptions.dart';
import 'package:macin/core/utils/referral_utils.dart';
import 'package:macin/shared/models/user_model.dart';
import 'package:macin/shared/repositories/user_repository.dart';
import 'package:macin/shared/services/local_auth_cache.dart';


/// Résultat d'une opération d'authentification.
///
/// [isNewUser] indique si le profil Firestore vient d'être créé —
/// utile pour rediriger vers un écran "Choisir mon rôle" après un
/// premier login Google/GitHub.
///
/// [profile] peut être `null` même si [firebaseUser] est non-null :
/// cela arrive si Firestore est temporairement indisponible. Dans ce
/// cas l'utilisateur reste connecté côté Firebase Auth (donc l'app ne
/// le renvoie pas au login), et [LocalAuthCache] sert de filet de
/// sécurité pour afficher quand même un profil (le dernier connu).
class AuthResult {
  final User firebaseUser;
  final UserModel? profile;
  final bool isNewUser;

  const AuthResult({
    required this.firebaseUser,
    required this.profile,
    required this.isNewUser,
  });
}

/// Repository d'authentification de MACIN.
///
/// Centralise TOUTES les méthodes de connexion (email, Google, GitHub)
/// et garantit qu'à chaque connexion réussie :
///   1. Un profil Firestore existe (rôle, XP, code de parrainage...)
///   2. Ce profil est mis en cache local via [LocalAuthCache]
///
/// IMPORTANT — résilience Firestore :
/// L'authentification Firebase (étape 1, via FirebaseAuth) et la
/// lecture/écriture du profil métier (étape 2, via Firestore) sont
/// deux systèmes distincts. Si Firestore est temporairement
/// indisponible (API pas activée, pas de réseau...), on ne doit PAS
/// faire échouer la connexion : l'utilisateur EST authentifié, on
/// affichera juste un profil en cache ou minimal en attendant.
///
/// Les widgets (LoginPage, RegisterPage) n'appellent jamais
/// FirebaseAuth directement — toujours via ce repository.
class AuthRepository {
  final FirebaseAuth _auth;
  final UserRepository _userRepo;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    UserRepository? userRepo,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepo = userRepo ?? UserRepository(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Stream de l'état de connexion — consommé par [SplashPage] et le routeur.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── EMAIL / MOT DE PASSE ──────────────────────────────────

  /// Inscription par email. [role] détermine le parcours
  /// (étudiant par défaut, 'instructor' si formateur).
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String role = AppConstants.roleStudent,
    String? referralCodeInput,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName);

      final profile = await _createProfileIfNeededSafe(
        user: user,
        displayName: displayName,
        role: role,
        referralCodeInput: referralCodeInput,
      );

      return AuthResult(firebaseUser: user, profile: profile, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  /// Connexion par email / mot de passe.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final profile = await _fetchAndCacheProfileSafe(user.uid);

      return AuthResult(
        firebaseUser: user,
        profile: profile,
        isNewUser: false,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  // ── GOOGLE ───────────────────────────────────────────────

  /// Connexion / inscription via Google.
  ///
  /// Si c'est la première connexion, crée automatiquement le profil
  /// Firestore avec le rôle 'student' par défaut et génère un code
  /// de parrainage unique.
  ///
  /// Si Firestore est indisponible, l'authentification Google reste
  /// validée (l'utilisateur ne voit pas d'erreur bloquante) ; seul
  /// le profil métier sera resynchronisé plus tard.
  Future<AuthResult> signInWithGoogle({
    String role = AppConstants.roleStudent,
    String? referralCodeInput,
    required String serverClientId,
  }) async {
    final User user;
    final bool isNew;
    try {
      await _googleSignIn.initialize(serverClientId: serverClientId);
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      user = userCredential.user!;
      isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      final profile = await _createProfileIfNeededSafe(
        user: user,
        displayName:
        user.displayName ?? googleUser.displayName ?? 'Étudiant MACIN',
        role: role,
        referralCodeInput: referralCodeInput,
        photoUrl: user.photoURL,
      );

      return AuthResult(firebaseUser: user, profile: profile, isNewUser: isNew);
    } on FirebaseAuthException catch (e) {
      // Erreur réelle d'authentification (mauvais credentials, compte
      // désactivé...) — celle-ci doit bloquer la connexion.
      throw AuthException.fromFirebase(e.code);
    } catch (e) {
      throw AuthException(message: 'Connexion Google annulée ou échouée : $e');
    }
  }

  // ── GITHUB ───────────────────────────────────────────────

  /// Connexion / inscription via GitHub (utile pour un public développeurs).
  Future<AuthResult> signInWithGitHub({
    String role = AppConstants.roleStudent,
    String? referralCodeInput,
  }) async {
    final User user;
    final bool isNew;
    try {
      final githubProvider = GithubAuthProvider();
      final userCredential = await _auth.signInWithProvider(githubProvider);
      user = userCredential.user!;
      isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      final profile = await _createProfileIfNeededSafe(
        user: user,
        displayName: user.displayName ?? 'Étudiant MACIN',
        role: role,
        referralCodeInput: referralCodeInput,
        photoUrl: user.photoURL,
      );

      return AuthResult(firebaseUser: user, profile: profile, isNewUser: isNew);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } catch (e) {
      throw AuthException(message: 'Connexion GitHub annulée ou échouée : $e');
    }
  }

  // ── DÉCONNEXION ──────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    await LocalAuthCache.clear();
  }

  // ── Interne — résilience Firestore ────────────────────────

  /// Variante "safe" de la création de profil : si Firestore est
  /// indisponible (PERMISSION_DENIED, unavailable, pas de réseau...),
  /// on NE LANCE PAS d'exception. On retombe sur le cache local s'il
  /// existe, sinon on retourne null — mais l'utilisateur reste connecté.
  Future<UserModel?> _createProfileIfNeededSafe({
    required User user,
    required String displayName,
    required String role,
    String? referralCodeInput,
    String? photoUrl,
  }) async {
    try {
      final existing = await _userRepo.getUser(user.uid);
      if (existing != null) {
        await LocalAuthCache.saveUser(existing);
        return existing;
      }

      String? referrerId;
      if (referralCodeInput != null && referralCodeInput.trim().isNotEmpty) {
        final normalized = ReferralUtils.normalizeCode(referralCodeInput);
        if (ReferralUtils.isValidFormat(normalized)) {
          referrerId = await _userRepo.getReferrerIdByCode(normalized);
        }
      }

      final newCode = ReferralUtils.generateCode();

      await _userRepo.createUser(
        uid: user.uid,
        displayName: displayName,
        email: user.email ?? '',
        referralCode: newCode,
        photoUrl: photoUrl,
        referredBy: referrerId,
      );

      if (role != AppConstants.roleStudent) {
        await _userRepo.updateProfile(user.uid, displayName: displayName);
        // updateRole nécessite normalement une Cloud Function sécurisée
        // (Issue #17) — ici écrit directement pour le développement local.
      }

      final created = await _userRepo.getUser(user.uid);
      if (created != null) {
        await LocalAuthCache.saveUser(created);
      }
      return created;
    } catch (e) {
      // Firestore indisponible (API désactivée, offline, quota...).
      // On NE bloque PAS la connexion : on retombe sur le cache local.
      return LocalAuthCache.getCachedUser();
    }
  }

  /// Variante "safe" de la lecture de profil (login email).
  Future<UserModel?> _fetchAndCacheProfileSafe(String uid) async {
    try {
      final profile = await _userRepo.getUser(uid);
      if (profile != null) {
        await LocalAuthCache.saveUser(profile);
      }
      return profile;
    } catch (e) {
      return LocalAuthCache.getCachedUser();
    }
  }
}

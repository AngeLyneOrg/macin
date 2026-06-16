import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Définition de votre couleur principale en constante
  static const Color primaryColor = Color(0xFF013BFF);

  // --- AUTHENTIFICATION GOOGLE ---
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId:
        '172820456998-7er5c2vgf1619p7aoed5jlsjt5qra70j.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        print("Connection aborted by user");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      print("CONNEXION REUSSIE AVEC GOOGLE !");
    } catch (e) {
      print("Erreur de connexion Google : $e");
      if (context.mounted) {
        _showErrorSnackBar(context, e);
      }
    }
  }

  // --- AUTHENTIFICATION GITHUB ---
  Future<void> _signInWithGitHub(BuildContext context) async {
    try {
      // Firebase gère l'ouverture de la page web GitHub automatiquement
      GithubAuthProvider githubProvider = GithubAuthProvider();

      // Lance l'authentification dans une feuille de style sécurisée/page web
      await FirebaseAuth.instance.signInWithProvider(githubProvider);
      print("CONNEXION REUSSIE AVEC GITHUB !");
    } catch (e) {
      print("Erreur de connexion GitHub : $e");
      if (context.mounted) {
        _showErrorSnackBar(context, e);
      }
    }
  }

  // Méthode centralisée pour afficher les erreurs
  void _showErrorSnackBar(BuildContext context, Object e) {
    String errorMessage = "Une erreur est survenue.";

    if (e is FirebaseAuthException) {
      errorMessage = e.message ?? errorMessage;
    } else if (e.toString().contains("ApiException")) {
      errorMessage =
      "Erreur Google Configuration (Vérifiez votre clé SHA-1 dans Firebase) : $e";
    } else {
      errorMessage = "Erreur : ${e.toString()}";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Titre de votre application
              const Text(
                "Bienvenue",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 40),

              // BOUTON GOOGLE
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50), // Prend toute la largeur
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                label: const Text(
                  "Sign-In with Google",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _signInWithGoogle(context),
              ),
              const SizedBox(height: 16),

              // BOUTON GITHUB
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24292F), // Couleur officielle de GitHub
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: primaryColor, width: 1.5), // Rappel de votre couleur
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.github, color: Colors.white),
                label: const Text(
                  "Sign-In with GitHub",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _signInWithGitHub(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

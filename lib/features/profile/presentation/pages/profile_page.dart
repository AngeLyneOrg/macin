import 'package:flutter/material.dart';

/// Page placeholder — sera développée dans l'issue correspondante.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text(
          'Profil\n(à développer)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

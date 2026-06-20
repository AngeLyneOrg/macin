import 'package:flutter/material.dart';

/// Page placeholder — sera développée dans l'issue correspondante.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: const Center(
        child: Text(
          'Accueil\n(à développer)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

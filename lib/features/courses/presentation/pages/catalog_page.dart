import 'package:flutter/material.dart';

/// Page placeholder — sera développée dans l'issue correspondante.
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: const Center(
        child: Text(
          'Catalogue\n(à développer)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

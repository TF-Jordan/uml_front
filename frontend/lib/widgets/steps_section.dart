import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';

class HowToSection extends StatelessWidget {
  const HowToSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 100),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              'assets/images/umltocode.png',
              height: 200,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 100),
                  ),
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment convertir vos diagrammes UML en code',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                _buildStep('1', 'Déposez vos diagrammes UML (classes et séquences).'),
                const SizedBox(height: 30),
                _buildStep('2', 'Choisissez votre langage cible et configurez les options.'),
                const SizedBox(height: 30),
                _buildStep('3', 'Cliquez sur \'Générer\' et téléchargez votre projet.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }
}
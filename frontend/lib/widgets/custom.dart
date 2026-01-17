
import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';


class WhyChooseSection extends StatelessWidget {
const WhyChooseSection({Key? key}) : super(key: key);

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 100),
child: Column(
children: [
const Text(
'Pourquoi choisir notre générateur UML',
style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
),
const SizedBox(height: 60),
Row(
children: [
Expanded(
child: _buildFeatureCard(
Icons.auto_awesome,
'Conversion automatique',
'Transformez vos diagrammes UML en code fonctionnel en quelques clics.',
),
),
const SizedBox(width: 30),
Expanded(
child: _buildFeatureCard(
Icons.rocket_launch_outlined,
'Rapide et précis',
'Génération ultra-rapide avec respect des standards et bonnes pratiques.',
),
),
const SizedBox(width: 30),
Expanded(
child: _buildFeatureCard(
Icons.shield_outlined,
'Sécurisé',
'Vos fichiers sont traités de manière sécurisée et supprimés après génération.',
),
),
],
),
],
),
);
}

Widget _buildFeatureCard(IconData icon, String title, String description) {
return Container(
padding: const EdgeInsets.all(30),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(8),
border: Border.all(color: AppColors.borderGray),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(icon, color: AppColors.primaryOrange, size: 40),
const SizedBox(height: 20),
Text(
title,
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 15),
Text(
description,
style: const TextStyle(fontSize: 14, color: AppColors.secondaryGray, height: 1.6),
),
],
),
);
}
}
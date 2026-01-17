import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBlack,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.code, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 40),
          _buildNavItem('Vue d\'ensemble', false),
          _buildNavItem('Import UML', true),
          _buildNavItem('Génération', false),
          _buildNavItem('Téléchargement', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? AppColors.primaryOrange : Colors.white,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      child: Row(
        children: [
          Image.asset(
            'assets/pics/logo.png',
            height: 34,
            errorBuilder: (context, error, stackTrace) =>
            const Text(
              'UML2Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('Accueil', style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () {},
            child: const Text('Documentation', style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () {},
            child: const Text('À propos', style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Commencer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

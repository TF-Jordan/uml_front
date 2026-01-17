
import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';


class LanguageModel {
  final String name;
  final String logoPath; // Chemin vers l'image du logo
  final Color color;
  Icon icon;
  final List<String> versions;
  final List<String> dependencies;

  LanguageModel({
    required this.name,
    required this.logoPath,
    required this.icon,
    required this.color,
    required this.versions,
    required this.dependencies,
  });

  static List<LanguageModel> getAvailableLanguages() {
    return [
      LanguageModel(
        name: 'Dart',
        logoPath: 'assets/pics/dart.png',
        icon: Icon(Icons.telegram),
        color: AppColors.dartBlue,
        versions: ['3.0', '2.19', '2.18'],
        dependencies: ['http', 'provider', 'riverpod', 'bloc', 'dio', 'get_it'],
      ),
      LanguageModel(
        name: 'Spring Boot',
        logoPath: 'assets/logos/spring.jpg',
        icon: Icon(Icons.telegram),
        color: AppColors.springGreen,
        versions: ['3.1', '3.0', '2.7'],
        dependencies: ['Spring Data JPA', 'Spring Security', 'Spring Web', 'Lombok', 'MySQL Driver', 'PostgreSQL Driver'],
      ),
      LanguageModel(
        name: 'FastAPI',
        logoPath: 'assets/logos/fastApi.png',
        icon: Icon(Icons.telegram),
        color: AppColors.fastApiTeal,
        versions: ['0.100', '0.95', '0.90'],
        dependencies: ['SQLAlchemy', 'Pydantic', 'Uvicorn', 'Alembic', 'PyJWT', 'python-multipart'],
      ),
      LanguageModel(
        name: 'Laravel',
        logoPath: 'assets/logos/laravel.png',
        icon: Icon(Icons.telegram),
        color: AppColors.laravelRed,
        versions: ['10.x', '9.x', '8.x'],
        dependencies: ['Eloquent ORM', 'Sanctum', 'Horizon', 'Telescope', 'Breeze', 'Jetstream'],
      ),
    ];
  }
}

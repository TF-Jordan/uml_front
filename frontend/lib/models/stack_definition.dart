import 'package:flutter/material.dart';

class StackDefinition {
  const StackDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.asset,
    required this.color,
    this.logoScale = 1.0,
  });

  final String key;
  final String name;
  final String description;
  final String asset;
  final Color color;
  final double logoScale;
}

const List<StackDefinition> stackDefinitions = [
  StackDefinition(
    key: 'spring',
    name: 'Spring',
    description:
        'Stack Java entreprise avec des conventions solides, la sécurité et une '
        'intégration profonde des couches data et observabilité.',
    asset: 'assets/pics/spring.png',
    color: Color(0xFF6DB33F),
  ),
  StackDefinition(
    key: 'fastapi',
    name: 'FastAPI',
    description:
        'APIs orientées Python avec performances async, OpenAPI par défaut et '
        'validation claire pilotée par le typage.',
    asset: 'assets/pics/fastApi.png',
    color: Color(0xFF009688),
  ),
  StackDefinition(
    key: 'laravel',
    name: 'Laravel',
    description:
        'MVC structuré pour les équipes PHP qui veulent livrer vite avec un '
        'écosystème riche et des conventions propres.',
    asset: 'assets/pics/laravel.png',
    color: Color(0xFFFF2D20),
    logoScale: 1.1,
  ),
  StackDefinition(
    key: 'nestjs',
    name: 'NestJS',
    description:
        'Backend TypeScript avec architecture modulaire et structure de niveau '
        'entreprise dans l\'écosystème Node.',
    asset: 'assets/pics/NestJs.png',
    color: Color(0xFFE0234E),
  ),
  StackDefinition(
    key: 'dart',
    name: 'Dart',
    description:
        'Backend Dart basé sur Shelf avec une structure claire et '
        'des services prêts pour une API moderne.',
    asset: 'assets/pics/dart.png',
    color: Color(0xFF0175C2),
  ),
  StackDefinition(
    key: 'fiber',
    name: 'Go (Fiber)',
    description:
        'Backend Go avec Fiber et couches MVC propres, optimisé pour des APIs '
        'rapides et un outillage Go prêt production.',
    asset: 'assets/pics/go.png',
    color: Color(0xFF00ADD8),
  ),
];

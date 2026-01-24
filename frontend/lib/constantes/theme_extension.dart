import 'package:flutter/material.dart';

import 'app_themes.dart';
import '../services/settings_service.dart';

/// Extension pour accéder facilement au thème actuel depuis n'importe quel widget
extension ThemeExtension on BuildContext {
  /// Récupère le thème actuel basé sur les paramètres de l'utilisateur
  AppThemeData get currentAppTheme {
    return AppThemes.getById(SettingsService.instance.currentTheme);
  }

  /// Raccourci pour les couleurs du thème
  Color get inkColor => currentAppTheme.ink;
  Color get inkSoftColor => currentAppTheme.inkSoft;
  Color get inkMutedColor => currentAppTheme.inkMuted;
  Color get accentColor => currentAppTheme.accent;
  Color get accentDeepColor => currentAppTheme.accentDeep;
  Color get accentGlowColor => currentAppTheme.accentGlow;
  Color get successColor => currentAppTheme.success;
  Color get tealColor => currentAppTheme.teal;
  Color get sunColor => currentAppTheme.sun;
  Color get sandColor => currentAppTheme.sand;
  Color get sandDeepColor => currentAppTheme.sandDeep;
  Color get cloudColor => currentAppTheme.cloud;
  Color get surfaceColor => currentAppTheme.surface;
  Color get surfaceSoftColor => currentAppTheme.surfaceSoft;
  Color get borderColor => currentAppTheme.border;
  Color get gridColor => currentAppTheme.grid;
  Color get glassColor => currentAppTheme.glass;
}

/// Classe statique pour accéder au thème actuel sans contexte
/// Utile pour les cas où on n'a pas accès au BuildContext
class CurrentTheme {
  static AppThemeData get data {
    return AppThemes.getById(SettingsService.instance.currentTheme);
  }

  static Color get ink => data.ink;
  static Color get inkSoft => data.inkSoft;
  static Color get inkMuted => data.inkMuted;
  static Color get accent => data.accent;
  static Color get accentDeep => data.accentDeep;
  static Color get accentGlow => data.accentGlow;
  static Color get success => data.success;
  static Color get teal => data.teal;
  static Color get sun => data.sun;
  static Color get sand => data.sand;
  static Color get sandDeep => data.sandDeep;
  static Color get cloud => data.cloud;
  static Color get surface => data.surface;
  static Color get surfaceSoft => data.surfaceSoft;
  static Color get border => data.border;
  static Color get grid => data.grid;
  static Color get glass => data.glass;
}

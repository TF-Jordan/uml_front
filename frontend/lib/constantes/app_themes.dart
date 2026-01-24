import 'package:flutter/material.dart';

/// Définition d'un thème d'application
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.success,
    required this.teal,
    required this.sun,
    required this.sand,
    required this.sandDeep,
    required this.cloud,
    required this.surface,
    required this.surfaceSoft,
    required this.border,
    required this.grid,
    required this.glass,
    required this.brightness,
  });

  final String id;
  final String name;
  final String nameEn;
  final IconData icon;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color accent;
  final Color accentDeep;
  final Color accentGlow;
  final Color success;
  final Color teal;
  final Color sun;
  final Color sand;
  final Color sandDeep;
  final Color cloud;
  final Color surface;
  final Color surfaceSoft;
  final Color border;
  final Color grid;
  final Color glass;
  final Brightness brightness;
}

/// Thèmes disponibles dans l'application
class AppThemes {
  // ============ THÈME CLAIR (Sand) - Par défaut ============
  static const light = AppThemeData(
    id: 'light',
    name: 'Clair',
    nameEn: 'Light',
    icon: Icons.light_mode_rounded,
    ink: Color(0xFF0C111D),
    inkSoft: Color(0xFF1F2633),
    inkMuted: Color(0xFF4E5A6A),
    accent: Color(0xFFFF5C2A),
    accentDeep: Color(0xFFD64519),
    accentGlow: Color(0xFFFFA38A),
    success: Color(0xFF22C55E),
    teal: Color(0xFF24B1A4),
    sun: Color(0xFFF4C06D),
    sand: Color(0xFFF8F1E8),
    sandDeep: Color(0xFFEEE3D5),
    cloud: Color(0xFFFFFCF8),
    surface: Color(0xFFFFFAF4),
    surfaceSoft: Color(0xFFF6EFE7),
    border: Color(0xFFE3D6C7),
    grid: Color(0xFFEADFD2),
    glass: Color(0xCCFFFFFF),
    brightness: Brightness.light,
  );

  // ============ THÈME SOMBRE (Midnight) ============
  static const dark = AppThemeData(
    id: 'dark',
    name: 'Sombre',
    nameEn: 'Dark',
    icon: Icons.dark_mode_rounded,
    ink: Color(0xFFF5F5F7),
    inkSoft: Color(0xFFE0E0E5),
    inkMuted: Color(0xFF9CA3AF),
    accent: Color(0xFFFF6B3D),
    accentDeep: Color(0xFFFF8A5C),
    accentGlow: Color(0xFFFF6B3D),
    success: Color(0xFF34D399),
    teal: Color(0xFF2DD4BF),
    sun: Color(0xFFFBBF24),
    sand: Color(0xFF0F1419),
    sandDeep: Color(0xFF1A1F2E),
    cloud: Color(0xFF0A0D14),
    surface: Color(0xFF161B26),
    surfaceSoft: Color(0xFF1E2433),
    border: Color(0xFF2D3748),
    grid: Color(0xFF1E2433),
    glass: Color(0x99161B26),
    brightness: Brightness.dark,
  );

  // ============ THÈME OCÉAN (Deep Blue) ============
  static const ocean = AppThemeData(
    id: 'ocean',
    name: 'Océan',
    nameEn: 'Ocean',
    icon: Icons.water_rounded,
    ink: Color(0xFFF0F9FF),
    inkSoft: Color(0xFFE0F2FE),
    inkMuted: Color(0xFF94A3B8),
    accent: Color(0xFF06B6D4),
    accentDeep: Color(0xFF0891B2),
    accentGlow: Color(0xFF67E8F9),
    success: Color(0xFF10B981),
    teal: Color(0xFF14B8A6),
    sun: Color(0xFFFCD34D),
    sand: Color(0xFF0C1929),
    sandDeep: Color(0xFF0F2744),
    cloud: Color(0xFF071324),
    surface: Color(0xFF0F2744),
    surfaceSoft: Color(0xFF153358),
    border: Color(0xFF1E4976),
    grid: Color(0xFF153358),
    glass: Color(0x990F2744),
    brightness: Brightness.dark,
  );

  // ============ THÈME MINUIT VIOLET (Nebula) ============
  static const nebula = AppThemeData(
    id: 'nebula',
    name: 'Nébuleuse',
    nameEn: 'Nebula',
    icon: Icons.auto_awesome_rounded,
    ink: Color(0xFFFAF5FF),
    inkSoft: Color(0xFFF3E8FF),
    inkMuted: Color(0xFFA78BFA),
    accent: Color(0xFFA855F7),
    accentDeep: Color(0xFF9333EA),
    accentGlow: Color(0xFFC084FC),
    success: Color(0xFF22D3EE),
    teal: Color(0xFF06B6D4),
    sun: Color(0xFFFBBF24),
    sand: Color(0xFF13111C),
    sandDeep: Color(0xFF1C1726),
    cloud: Color(0xFF0D0B14),
    surface: Color(0xFF1C1726),
    surfaceSoft: Color(0xFF261F36),
    border: Color(0xFF3B2D5C),
    grid: Color(0xFF261F36),
    glass: Color(0x991C1726),
    brightness: Brightness.dark,
  );

  /// Liste de tous les thèmes disponibles
  static const List<AppThemeData> all = [light, dark, ocean, nebula];

  /// Récupère un thème par son ID
  static AppThemeData getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => light,
    );
  }

  /// Génère un ThemeData Flutter à partir d'un AppThemeData
  static ThemeData toFlutterTheme(AppThemeData theme) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: theme.accent,
      brightness: theme.brightness,
      primary: theme.accent,
      onPrimary: theme.brightness == Brightness.dark ? Colors.white : Colors.white,
      surface: theme.surface,
      onSurface: theme.ink,
      background: theme.sand,
      onBackground: theme.ink,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: theme.brightness,
      scaffoldBackgroundColor: theme.sand,
      cardColor: theme.surface,
      dividerColor: theme.border,
      hoverColor: theme.accent.withOpacity(0.1),
      splashColor: theme.accent.withOpacity(0.2),
      highlightColor: theme.accent.withOpacity(0.1),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.sand,
        foregroundColor: theme.ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: theme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.ink,
          side: BorderSide(color: theme.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return theme.accent;
          }
          return theme.inkMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return theme.accent.withOpacity(0.4);
          }
          return theme.surfaceSoft;
        }),
      ),
      iconTheme: IconThemeData(color: theme.ink),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: theme.ink),
        displayMedium: TextStyle(color: theme.ink),
        displaySmall: TextStyle(color: theme.ink),
        headlineLarge: TextStyle(color: theme.ink),
        headlineMedium: TextStyle(color: theme.ink),
        headlineSmall: TextStyle(color: theme.ink),
        titleLarge: TextStyle(color: theme.ink),
        titleMedium: TextStyle(color: theme.ink),
        titleSmall: TextStyle(color: theme.inkSoft),
        bodyLarge: TextStyle(color: theme.ink),
        bodyMedium: TextStyle(color: theme.inkSoft),
        bodySmall: TextStyle(color: theme.inkMuted),
        labelLarge: TextStyle(color: theme.ink),
        labelMedium: TextStyle(color: theme.inkSoft),
        labelSmall: TextStyle(color: theme.inkMuted),
      ),
    );
  }
}

/// Extension pour accéder facilement aux couleurs du thème actuel
extension ThemeDataExtension on BuildContext {
  AppThemeData get appTheme {
    final brightness = Theme.of(this).brightness;
    // On devrait utiliser le SettingsService ici, mais pour simplifier
    // on retourne le thème basé sur la brightness
    return brightness == Brightness.dark ? AppThemes.dark : AppThemes.light;
  }
}

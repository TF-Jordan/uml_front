import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constantes/app_themes.dart';
import 'l10n/app_localizations.dart';
import 'pages/overview.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.initialize();
  runApp(const UMLToCodeApp());
}

class UMLToCodeApp extends StatefulWidget {
  const UMLToCodeApp({Key? key}) : super(key: key);

  @override
  State<UMLToCodeApp> createState() => _UMLToCodeAppState();
}

class _UMLToCodeAppState extends State<UMLToCodeApp> {
  final _settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppThemes.getById(_settings.currentTheme);

    // Clé unique basée sur le thème et la locale pour forcer la reconstruction
    final appKey = ValueKey('${_settings.currentTheme}_${_settings.currentLocale}');

    return MaterialApp(
      key: appKey,
      title: 'UML to Code Generator',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: _buildTheme(currentTheme),
      darkTheme: _buildTheme(currentTheme),
      themeMode: ThemeMode.light, // On utilise toujours le theme construit

      // Localization configuration
      locale: _settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const OverviewPage(),
    );
  }

  ThemeData _buildTheme(AppThemeData appTheme) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: appTheme.accent,
      brightness: appTheme.brightness,
      primary: appTheme.accent,
      onPrimary: Colors.white,
      surface: appTheme.surface,
      onSurface: appTheme.ink,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: appTheme.brightness,
      scaffoldBackgroundColor: appTheme.sand,
      cardColor: appTheme.surface,
      dividerColor: appTheme.border,
      hoverColor: appTheme.accent.withOpacity(0.1),
      splashColor: appTheme.accent.withOpacity(0.2),
      highlightColor: appTheme.accent.withOpacity(0.1),
      textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: appTheme.ink,
        displayColor: appTheme.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appTheme.sand,
        foregroundColor: appTheme.ink,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: appTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: appTheme.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appTheme.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: appTheme.ink,
          side: BorderSide(color: appTheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: appTheme.ink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: appTheme.surface,
        contentTextStyle: TextStyle(color: appTheme.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

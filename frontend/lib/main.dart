import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constantes/modern_palette.dart';
import 'pages/overview.dart';

void main() {
  runApp(const UMLToCodeApp());
}

class UMLToCodeApp extends StatelessWidget {
  const UMLToCodeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ModernPalette.accent,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'UML to Code Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: ModernPalette.sand,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
      ),
      home: const OverviewPage(),
    );
  }
}

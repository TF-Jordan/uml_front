import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constantes/modern_palette.dart';
import '../services/docs_launcher.dart';
import 'page1.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 1024;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ModernPalette.sand,
                  ModernPalette.cloud,
                  ModernPalette.sandDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned.fill(child: _GridOverlay()),
          Positioned(
            left: -120,
            top: 120,
            child: Transform.rotate(
              angle: -0.3,
              child: _GradientRibbon(
                width: 360,
                height: 90,
                colors: [
                  ModernPalette.accent.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            right: -100,
            top: -120,
            child: _GlowingOrb(
              size: 240,
              color: ModernPalette.accentGlow.withOpacity(0.3),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 120,
            child: _GlowingOrb(
              size: 190,
              color: ModernPalette.teal.withOpacity(0.2),
            ),
          ),
          Positioned(
            right: 120,
            bottom: -100,
            child: _GlowingOrb(
              size: 200,
              color: ModernPalette.sun.withOpacity(0.25),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 32,
                    isCompact ? 110 : 120,
                    isCompact ? 16 : 32,
                    80,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReveal(
                            start: 0.08,
                            end: 0.4,
                            child: _HeroSection(
                              isCompact: isCompact,
                              onAction: _showMessage,
                            ),
                          ),
                          const SizedBox(height: 56),
                          _buildReveal(
                            start: 0.2,
                            end: 0.52,
                            child: _HighlightsRow(
                              isCompact: isCompact,
                              onStart: () => _goToUpload(context),
                              onDocumentation: () => DocsLauncher.open(context),
                            ),
                          ),    const SizedBox(height: 64),
                          _buildReveal(
                            start: 0.44,
                            end: 0.72,
                            child: _StepsSection(isCompact: isCompact),
                          ),
                          const SizedBox(height: 64),
                          _buildReveal(
                            start: 0.32,
                            end: 0.6,
                            child: _LanguageShowcase(isCompact: isCompact),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 32,
                      12,
                      isCompact ? 16 : 32,
                      0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: _TopNav(
                          isCompact: isCompact,
                          onDocumentation: () => DocsLauncher.open(context),
                          onStart: () => _goToUpload(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReveal({
    required double start,
    required double end,
    required Widget child,
  }) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(position: offset, child: child),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ModernPalette.ink,
      ),
    );
  }

  void _goToUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadPage()),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ModernPalette.grid.withOpacity(0.35)
      ..strokeWidth = 1;

    const step = 140.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GradientRibbon extends StatelessWidget {
  const _GradientRibbon({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 100,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.isCompact,
    required this.onDocumentation,
    required this.onStart,
  });

  final bool isCompact;
  final VoidCallback onDocumentation;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Row(
        children: [
          _BrandMark(),
          const Spacer(),
          OutlinedButton(
            onPressed: onDocumentation,
            style: OutlinedButton.styleFrom(
              foregroundColor: ModernPalette.ink,
              side: const BorderSide(color: ModernPalette.inkSoft),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Documentation'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernPalette.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Commencer'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: ModernPalette.accent.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/pics/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.auto_awesome, color: ModernPalette.accent),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UML2Code',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ModernPalette.ink,
              ),
            ),
            Text(
              'Suite de bureau',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: ModernPalette.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isCompact, required this.onAction});

  final bool isCompact;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final headlineSize = isCompact ? 38.0 : 52.0;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            text: 'Transformez vos',
            style: GoogleFonts.spaceGrotesk(
              fontSize: headlineSize,
              fontWeight: FontWeight.w700,
              color: ModernPalette.ink,
              height: 1.1,
            ),
            children: const [
              TextSpan(
                text: ' diagrammes \nUML ',
                style: TextStyle(color: ModernPalette.accent),
              ),
              TextSpan(text: ' en un projet prêt à l\'emploi.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
Container(
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ModernPalette.accent.withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    color: ModernPalette.inkSoft,
                    height: 1.6,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Importez',
                      style: TextStyle(
                        color: ModernPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' vos diagrammes, '),
                    TextSpan(
                      text: 'mettez-les en ordre',
                      style: TextStyle(
                        color: ModernPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' et obtenez une '),
                    TextSpan(
                      text: 'base de projet propre',
                      style: TextStyle(
                        color: ModernPalette.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(Icons.check_circle_outline, 
                      size: 16, 
                      color: ModernPalette.teal
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: ModernPalette.inkMuted,
                          height: 1.5,
                        ),
                        children: const [
                          TextSpan(text: 'Tout se fait '),
                          TextSpan(
                            text: 'sur votre ordinateur',
                            style: TextStyle(
                              color: ModernPalette.ink,
                    fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ', avec une partie en ligne optionnelle selon le résultat attendu.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );


    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textBlock,
          const SizedBox(height: 32),

        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: textBlock),
        const SizedBox(width: 32),
      ],
    );
  }
}



class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: ModernPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ModernPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMeter extends StatelessWidget {
  const _ProgressMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progression de génération',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: ModernPalette.inkMuted,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 10,
            color: ModernPalette.surfaceSoft,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ModernPalette.accent,
                        ModernPalette.sun,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({
    required this.isCompact,
    required this.onStart,
    required this.onDocumentation,
  });

  final bool isCompact;
  final VoidCallback onStart;
  final VoidCallback onDocumentation;

  @override
  Widget build(BuildContext context) {
    final spacing = isCompact ? 12.0 : 20.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth < 400 ? constraints.maxWidth : 380).toDouble();
        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: onDocumentation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ModernPalette.ink,
                        side: const BorderSide(color: ModernPalette.inkSoft),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        minimumSize: const Size(210, 60),
                        textStyle: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Documentation'),
                    ),
                    ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernPalette.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        minimumSize: const Size(210, 60),
                        textStyle: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Commencer'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: [
                  _HighlightCard(
                    width: tileWidth,
                    title: 'Tout reste local',
                    body:
                        'Le cœur du travail reste sur votre ordinateur.',
                    icon: Icons.lock_outline,
                  ),
                  _HighlightCard(
                    width: tileWidth,
                    title: 'Historique clair',
                    body:
                        'Vos choix sont conservés pour garder une trace simple.',
                    icon: Icons.data_object,
                  ),
                  _HighlightCard(
                    width: tileWidth,
                    title: 'Plusieurs choix',
                    body:
                        'Choisissez une technologie adaptée à votre projet.',
                    icon: Icons.layers_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.width,
    required this.title,
    required this.body,
    required this.icon,
  });

  final double width;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ModernPalette.border),
        boxShadow: [
          BoxShadow(
            color: ModernPalette.ink.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ModernPalette.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: ModernPalette.accent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ModernPalette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    color: ModernPalette.inkMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: ModernPalette.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernPalette.border),
        boxShadow: [
          BoxShadow(
            color: ModernPalette.ink.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ModernPalette.ink,
        ),
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionHeader(
          title: 'Comment ça marche',
          subtitle: 'Trois étapes simples et faciles à suivre.',
          center: true,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth =
                (constraints.maxWidth < 400 ? constraints.maxWidth : 380)
                    .toDouble();
            return Align(
              alignment: Alignment.center,
              child: Wrap(
                spacing: isCompact ? 12 : 20,
                runSpacing: isCompact ? 12 : 20,
                alignment: WrapAlignment.center,
                children: [
                  _StepCard(
                    width: tileWidth,
                    index: '01',
                    title: 'Importer vos schémas',
                    body:
                        'Vos diagrammes deviennent une base claire et lisible.',
                    icon: Icons.layers_outlined,
                  ),
                  _StepCard(
                    width: tileWidth,
                    index: '02',
                    title: 'Mettre en ordre',
                    body:
                        'Les informations sont organisées pour éviter les erreurs.',
                    icon: Icons.tune,
                  ),
                  _StepCard(
                    width: tileWidth,
                    index: '03',
                    title: 'Créer le projet',
                    body: 'Vous obtenez une base prête à personnaliser.',
                    icon: Icons.folder_open,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.width,
    required this.index,
    required this.title,
    required this.body,
    required this.icon,
  });

  final double width;
  final String index;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ModernPalette.border),
        boxShadow: [
          BoxShadow(
            color: ModernPalette.ink.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ModernPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  index,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ModernPalette.ink,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: ModernPalette.accent, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              fontSize: 19,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: ModernPalette.inkMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageShowcase extends StatefulWidget {
  const _LanguageShowcase({required this.isCompact});

  final bool isCompact;

  @override
  State<_LanguageShowcase> createState() => _LanguageShowcaseState();
}

class _LanguageShowcaseState extends State<_LanguageShowcase> {
  int? _hoveredIndex;

  final List<_LanguageItem> _items = [
    _LanguageItem(
      name: 'Go',
      color: const Color(0xFF00ADD8),
      description:
          'Go est apprécié pour sa rapidité et sa simplicité. '
          'Il convient aux projets qui doivent répondre vite et rester légers. '
          'Sa gestion de la concurrence aide quand beaucoup de tâches se passent '
          'en même temps. On l\'utilise souvent pour des services rapides et stables '
          'quand la performance et la fiabilité comptent. '
          'Fiber est un framework web rapide et minimaliste construit en Go. '
          'Il a été conçu pour offrir des performances extrêmes, tout en restant '
          'simple à utiliser. Son API est volontairement inspirée de frameworks '
          'modernes comme Express.js, ce qui facilite la prise en main pour les '
          'développeurs venant de l’écosystème JavaScript. '
          'Fiber repose sur un moteur HTTP très optimisé, ce qui lui permet de '
          'traiter un grand nombre de requêtes avec une latence très faible et une '
          'consommation mémoire réduite. Il est particulièrement adapté aux '
          'applications nécessitant rapidité, scalabilité et efficacité.',
      asset: 'assets/pics/go.png',
      logoScale: 6,
    ),
    _LanguageItem(
      name: 'Spring',
      color: const Color(0xFF6DB33F),
      description:
          'Spring Boot est un framework Java robuste et mature, conçu pour '
          'simplifier le développement d’applications backend professionnelles. '
          'Il repose sur l’écosystème Spring et permet de créer rapidement des '
          'applications autonomes, configurées par convention plutôt que par '
          'configuration manuelle. '
          'Spring Boot est particulièrement apprécié dans les environnements '
          'industriels pour sa fiabilité, son intégration native avec les '
          'architectures microservices, la sécurité avancée (Spring Security) et '
          'la gestion efficace des bases de données. Il est largement utilisé '
          'dans les systèmes bancaires, les plateformes d’entreprise et les '
          'applications à forte criticité.',
      asset: 'assets/pics/spring.png',
      logoScale: 6,
    ),
    _LanguageItem(
      name: 'FastAPI',
      color: const Color(0xFF009688),
      description:
          'FastAPI est un framework web moderne basé sur Python, reconnu pour sa '
          'vitesse élevée et sa simplicité. Il exploite les annotations de type '
          'Python pour générer automatiquement une documentation API interactive '
          'et garantir la validation des données. '
          'Très populaire dans les projets data science, IA et microservices '
          'légers, FastAPI permet de construire des API performantes avec peu de '
          'code. Il est particulièrement adapté aux applications nécessitant un '
          'prototypage rapide sans sacrifier la qualité ni les performances.',
      asset: 'assets/pics/fastApi.png',
      logoScale: 6,
    ),
    _LanguageItem(
      name: 'Laravel',
      color: const Color(0xFFFF2D20),
      description:
          'Laravel est un framework PHP élégant et expressif, conçu pour '
          'faciliter le développement d’applications web complètes. Il offre une '
          'syntaxe claire, une excellente organisation du code et de nombreux '
          'outils intégrés : ORM (Eloquent), authentification, files d’attente, '
          'tâches planifiées, etc. '
          'Laravel est très apprécié pour le développement rapide de plateformes '
          'web, API REST, backoffices et applications métier. Il combine '
          'productivité, lisibilité et richesse fonctionnelle, ce qui en fait un '
          'choix privilégié pour les startups et les projets académiques.',
      asset: 'assets/pics/laravel.png',
      logoScale: 8,
    ),
    _LanguageItem(
      name: 'NestJS',
      color: const Color(0xFFE0234E),
      description:
          'NestJS est un framework backend moderne basé sur Node.js et '
          'TypeScript. Il adopte une architecture fortement inspirée de Spring, '
          'avec une séparation claire des responsabilités (modules, '
          'contrôleurs, services). '
          'NestJS est idéal pour construire des API scalables, microservices, et '
          'applications temps réel. Son intégration native avec TypeScript '
          'améliore la maintenabilité et la robustesse du code, ce qui en fait un '
          'excellent choix pour des projets complexes et de grande envergure.',
      asset: 'assets/pics/NestJs.png',
      logoScale: 6,
    ),
    _LanguageItem(
      name: 'Dart',
      color: const Color(0xFF0175C2),
      description:
          'Dart est un langage de programmation moderne, principalement connu '
          'pour être le pilier du framework Flutter. Côté backend, Dart permet '
          'de développer des serveurs performants, typés et multiplateformes. '
          'Grâce à sa syntaxe claire et à son excellent support asynchrone, Dart '
          'est utilisé pour créer des API, des services backend et des '
          'applications full-stack cohérentes avec des clients mobiles Flutter. '
          'Il favorise une forte cohésion entre frontend et backend.',
      asset: 'assets/pics/dart.png',
      logoScale: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rowCount = (_items.length / 3).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionHeader(
          title: 'Langages',
          subtitle: 'Description de ce que nous avons préparé pour vous.',
          center: true,
        ),
        const SizedBox(height: 24),
        MouseRegion(
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              final start = rowIndex * 3;
              final end =
                  (start + 3) > _items.length ? _items.length : start + 3;
              final rowItems = _items.sublist(start, end);
              final count = rowItems.length;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex == rowCount - 1 ? 0 : 18,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const gap = 16.0;
                    final available = totalWidth - gap * (count - 1);
                    final safeWidth = totalWidth - 4;
                    final minWidth = 90.0;
                    final needsScroll = available < minWidth * count;
                    final layoutWidth = needsScroll
                        ? minWidth * count + gap * (count - 1)
                        : safeWidth;
                    final layoutAvailable = layoutWidth - gap * (count - 1);
                    final baseWidth = layoutAvailable / count;
                    final hoveredInRow = _hoveredIndex != null &&
                        _hoveredIndex! >= start &&
                        _hoveredIndex! < end;

                    double expandedWidth = baseWidth;
                    double collapsedWidth = baseWidth;
                    if (hoveredInRow && count > 1) {
                      final totalUnits = count * 2;
                      final expandedUnits = count + 1;
                      expandedWidth =
                          layoutAvailable * expandedUnits / totalUnits;
                      collapsedWidth = layoutAvailable / totalUnits;
                      if (collapsedWidth < minWidth) {
                        collapsedWidth = minWidth;
                        expandedWidth =
                            layoutAvailable - collapsedWidth * (count - 1);
                      }
                    }

                    final row = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(count, (index) {
                        final globalIndex = start + index;
                        final isHovered = _hoveredIndex == globalIndex;
                        final isDimmed =
                            _hoveredIndex != null && !isHovered;
                        final width = !hoveredInRow
                            ? baseWidth
                            : isHovered
                                ? expandedWidth
                                : collapsedWidth;
                        return Padding(
                          padding:
                              EdgeInsets.only(right: index == count - 1 ? 0 : gap),
                          child: _LanguageTile(
                            item: rowItems[index],
                            width: width,
                            isHovered: isHovered,
                            isDimmed: isDimmed,
                            isCompact: widget.isCompact,
                            onEnter: () =>
                                setState(() => _hoveredIndex = globalIndex),
                          ),
                        );
                      }),
                    );

                    final content = needsScroll
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: layoutWidth, child: row),
                          )
                        : row;

                    return Align(
                      alignment: Alignment.center,
                      child: content,
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _LanguageItem {
  const _LanguageItem({
    required this.name,
    required this.color,
    required this.description,
    required this.asset,
    this.logoScale = 1.0,
    this.needsBadge = false,
  });

  final String name;
  final Color color;
  final String description;
  final String asset;
  final double logoScale;
  final bool needsBadge;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.item,
    required this.width,
    required this.isHovered,
    required this.isDimmed,
    required this.isCompact,
    required this.onEnter,
  });

  final _LanguageItem item;
  final double width;
  final bool isHovered;
  final bool isDimmed;
  final bool isCompact;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final height = isCompact ? 320.0 : 360.0;
    return MouseRegion(
      onEnter: (_) => onEnter(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isDimmed ? 0.7 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: ModernPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered ? item.color : ModernPalette.border,
              width: isHovered ? 2 : 1,
            ),
            gradient: LinearGradient(
              colors: isHovered
                  ? [
                      item.color.withOpacity(0.08),
                      item.color.withOpacity(0.15),
                    ]
                  : [
                      Colors.white,
                      ModernPalette.surfaceSoft,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? item.color.withOpacity(0.25)
                    : ModernPalette.ink.withOpacity(0.08),
                blurRadius: isHovered ? 32 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Logo toujours visible en haut
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: isHovered ? 80 : 140,
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: isHovered ? Alignment.centerLeft : Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: EdgeInsets.all(isHovered ? 8 : 0),
                      decoration: BoxDecoration(
                        color: isHovered ? Colors.white.withOpacity(0.9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: item.color.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: _LanguageAsset(
                        asset: item.asset,
                        needsBadge: item.needsBadge,
                        size: isHovered ? 56 : 100,
                      ),
                    ),
                  ),
                ),
              ),
              // Nom du langage visible quand non survolé
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                bottom: isHovered ? 999 : 20,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isHovered ? 0 : 1,
                  child: Center(
                    child: Text(
                      item.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ModernPalette.ink,
                      ),
                    ),
                  ),
                ),
              ),
              // Panneau de description avec glassmorphism
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: isHovered ? 100 : height,
                left: 12,
                right: 12,
                bottom: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isHovered ? 1 : 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item.color.withOpacity(0.92),
                              item.color.withOpacity(0.98),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.description,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageAsset extends StatelessWidget {
  const _LanguageAsset({
    required this.asset,
    required this.needsBadge,
    required this.size,
  });

  final String asset;
  final bool needsBadge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isSvg = asset.toLowerCase().endsWith('.svg');

    final content = isSvg
        ? SvgPicture.asset(
            asset,
            height: size,
            width: size,
            fit: BoxFit.contain,
          )
        : Image.asset(
            asset,
            height: size,
            width: size,
            fit: BoxFit.contain,
          );

    if (!needsBadge) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ModernPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernPalette.border.withOpacity(0.7)),
      ),
      child: content,
    );
  }
}


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.center = false,
  });

  final String title;
  final String subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: ModernPalette.ink,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            color: ModernPalette.inkSoft,
            height: 1.5,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ModernPalette.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ModernPalette.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

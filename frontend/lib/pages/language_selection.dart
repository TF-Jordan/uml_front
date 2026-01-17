import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constantes/modern_palette.dart';
import '../models/stack_definition.dart';
import '../models/uml_inputs.dart';
import '../services/docs_launcher.dart';
import '../widgets/breadcrumb_bar.dart';
import 'page1.dart';
import 'stack_configuration.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({Key? key, required this.inputs}) : super(key: key);

  final UmlInputs inputs;

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  int? _selectedIndex;
  int? _hoveredIndex;

  final List<StackDefinition> _languages = stackDefinitions;

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
            right: -120,
            top: -80,
            child: _GlowingOrb(
              size: 240,
              color: ModernPalette.accentGlow.withOpacity(0.25),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 120,
            child: _GlowingOrb(
              size: 200,
              color: ModernPalette.teal.withOpacity(0.2),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 32,
                24,
                isCompact ? 16 : 32,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LanguageTopNav(
                        onDocumentation: () => DocsLauncher.open(context),
                      ),
                      const SizedBox(height: 16),
                      BreadcrumbBar(
                        items: const [
                          'Vue d\'ensemble',
                          'Import UML',
                          'Stack'
                        ],
                        activeIndex: 2,
                        onNavigate: _handleBreadcrumbNavigate,
                      ),
                      const SizedBox(height: 48),
                      _buildContent(isCompact),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isCompact) {
    final leftPanel = _InfoPanel(
      isCompact: isCompact,
      selectedLanguage:
          _selectedIndex == null ? null : _languages[_selectedIndex!].name,
    );

    final rightPanel = _GlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez votre stack',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sélectionnez une cible pour générer le squelette et les conventions de projet.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: ModernPalette.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildLanguageGrid(isCompact),
          const SizedBox(height: 28),
          // Row(
          //   children: [
          //     Expanded(
          //       child: ElevatedButton(
          //         onPressed: _selectedIndex == null
          //             ? null
          //             : () => _openConfiguration(_languages[_selectedIndex!]),
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: ModernPalette.accent,
          //           disabledBackgroundColor: ModernPalette.surfaceSoft,
          //           foregroundColor: Colors.white,
          //           padding: const EdgeInsets.symmetric(vertical: 16),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(16),
          //           ),
          //         ),
          //         child: const Text('Continuer'),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftPanel,
          const SizedBox(height: 24),
          rightPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: leftPanel),
        const SizedBox(width: 28),
        Expanded(flex: 6, child: rightPanel),
      ],
    );
  }

  Widget _buildLanguageGrid(bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = 14.0;
        const minTile = 120.0;
        final minWidth = columns * minTile + gap * (columns - 1);
        final needsScroll = constraints.maxWidth < minWidth;
        final gridWidth = needsScroll ? minWidth : constraints.maxWidth;

        final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: 1.0,
          ),
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final option = _languages[index];
            final isSelected = _selectedIndex == index;
            final isHovered = _hoveredIndex == index;
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _openConfiguration(option);
                },
                child: _LanguageTile(
                  option: option,
                  isSelected: isSelected,
                  isHovered: isHovered,
                  isCompact: isCompact,
                ),
              ),
            );
          },
        );

        if (!needsScroll) {
          return grid;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: gridWidth, child: grid),
        );
      },
    );
  }

  void _handleBreadcrumbNavigate(int index) {
    Navigator.popUntil(context, (route) => route.isFirst);
    if (index >= 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(initialInputs: widget.inputs),
        ),
      );
    }
    if (index >= 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(inputs: widget.inputs),
        ),
      );
    }
  }

  void _openConfiguration(StackDefinition stack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StackConfigurationPage(stack: stack, inputs: widget.inputs),
      ),
    );
  }

}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.isHovered,
    required this.isCompact,
  });

  final StackDefinition option;
  final bool isSelected;
  final bool isHovered;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 80.0 : 96.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: option.color.withOpacity(isHovered || isSelected ? 0.18 : 0.10),
        border: Border.all(
          color: isSelected
              ? option.color
              : isHovered
                  ? option.color.withOpacity(0.6)
                  : ModernPalette.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHovered || isSelected
                ? option.color.withOpacity(0.2)
                : ModernPalette.ink.withOpacity(0.06),
            blurRadius: isHovered || isSelected ? 24 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Semantics(
              label: option.name,
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Transform.scale(
                  scale: option.logoScale,
                  child: Image.asset(option.asset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          if (isSelected)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: option.color.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.check_circle, color: option.color, size: 26),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTopNav extends StatelessWidget {
  const _LanguageTopNav({required this.onDocumentation});

  final VoidCallback onDocumentation;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              'Choix du langage',
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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.isCompact, required this.selectedLanguage});

  final bool isCompact;
  final String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTag(selectedLanguage: selectedLanguage),
        const SizedBox(height: 20),
        Text(
          'Choisir la cible',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 32 : 42,
            fontWeight: FontWeight.w700,
            color: ModernPalette.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'La stack sélectionnée détermine la structure des dossiers, '
          'les conventions de code, et les frameworks générés.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            color: ModernPalette.inkSoft,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _SelectionCard(selectedLanguage: selectedLanguage),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: const [
            _InfoChip(icon: Icons.layers_outlined, label: 'Structure propre'),
            _InfoChip(icon: Icons.auto_fix_high, label: 'Conventions générées'),
            _InfoChip(icon: Icons.settings_suggest, label: 'Paramètres adaptés'),
          ],
        ),

      ],
    );
  }
}

class _StepTag extends StatelessWidget {
  const _StepTag({required this.selectedLanguage});

  final String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final label = selectedLanguage == null
        ? 'Étape 2/5 · aucune stack sélectionnée'
        : 'Étape 2/5 · $selectedLanguage sélectionné';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: ModernPalette.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.selectedLanguage});

  final String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLanguage != null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasSelection ? ModernPalette.accent.withOpacity(0.3) : ModernPalette.border),
        boxShadow: [
          BoxShadow(
            color: hasSelection ? ModernPalette.accent.withOpacity(0.08) : ModernPalette.ink.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasSelection
                  ? ModernPalette.accent.withOpacity(0.12)
                  : ModernPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasSelection ? Icons.check_circle : Icons.info_outline,
              color: hasSelection ? ModernPalette.accent : ModernPalette.inkMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hasSelection
                  ? 'Stack choisie : $selectedLanguage. Vous pouvez continuer.'
                  : 'Sélectionnez une stack pour activer la génération.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ModernPalette.inkSoft,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernPalette.border),
        boxShadow: [
          BoxShadow(
            color: ModernPalette.ink.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: ModernPalette.accent),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModernPalette.ink,
            ),
          ),
        ],
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
      ..color = ModernPalette.grid.withOpacity(0.32)
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

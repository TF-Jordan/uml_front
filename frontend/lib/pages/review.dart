import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

import '../constantes/modern_palette.dart';
import '../models/ai_config.dart';
import '../models/stack_definition.dart';
import '../models/uml_inputs.dart';
import '../services/docs_launcher.dart';
import '../widgets/breadcrumb_bar.dart';
import 'generation.dart';
import 'language_selection.dart';
import 'page1.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({
    Key? key,
    required this.inputs,
    required this.stack,
    required this.projectName,
    required this.outputDir,
    required this.selectSummary,
    required this.selectValues,
    required this.toggleSummary,
    required this.toggleValues,
    required this.aiConfig,
    this.packageName,
  }) : super(key: key);

  final UmlInputs inputs;
  final StackDefinition stack;
  final String projectName;
  final String outputDir;
  final String? packageName;
  final Map<String, String> selectSummary;
  final Map<String, String> selectValues;
  final Map<String, bool> toggleSummary;
  final Map<String, bool> toggleValues;
  final AiConfig aiConfig;

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
                isCompact ? 20 : 52,
                28,
                isCompact ? 20 : 52,
                60,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewTopNav(
                        onDocumentation: () => DocsLauncher.open(context),
                      ),
                      const SizedBox(height: 16),
                      BreadcrumbBar(
                        items: const [
                          'Vue d\'ensemble',
                          'Import UML',
                          'Stack',
                          'Configuration',
                          'Revue'
                        ],
                        activeIndex: 4,
                        onNavigate: (index) =>
                            _handleBreadcrumbNavigate(context, index),
                      ),
                      const SizedBox(height: 40),
                      _buildContent(context, isCompact),
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

  Widget _buildContent(BuildContext context, bool isCompact) {
    final leftPanel = _InfoPanel(
      isCompact: isCompact,
      stack: stack,
      projectName: projectName,
      outputDir: outputDir,
    );

    final rightPanel = _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revue de la configuration',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez chaque choix avant de lancer la génération.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              color: ModernPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          _SummaryTable(
            projectName: projectName,
            packageName: packageName,
            outputDir: outputDir,
            accent: stack.color,
          ),
          const SizedBox(height: 16),
          _AiSummaryCard(aiConfig: aiConfig),
          const SizedBox(height: 20),
          _SummaryChips(
            title: 'Options choisies',
            entries: selectSummary.entries.toList(),
            emptyLabel: 'Aucune option spécifique sélectionnée.',
          ),
          const SizedBox(height: 16),
          _ToggleChips(
            title: 'Modules activés',
            entries: toggleSummary.entries.toList(),
            accent: stack.color,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToGeneration(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernPalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Confirmer et générer'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleBack(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ModernPalette.ink,
                side: const BorderSide(color: ModernPalette.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Modifier la configuration'),
            ),
          ),
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

  void _handleBack(BuildContext context) {
    Navigator.pop(context);
  }

  void _handleBreadcrumbNavigate(BuildContext context, int index) {
    if (index == 3) {
      Navigator.pop(context);
      return;
    }
    Navigator.popUntil(context, (route) => route.isFirst);
    if (index >= 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(initialInputs: inputs),
        ),
      );
    }
    if (index >= 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(inputs: inputs),
        ),
      );
    }
  }

  void _goToGeneration(BuildContext context) {
    final resolvedOutputDir = _buildRunOutputDir(outputDir, projectName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerationPage(
          inputs: inputs,
          stack: stack,
          projectName: projectName,
          outputDir: resolvedOutputDir,
          packageName: packageName,
          selectSummary: selectSummary,
          selectValues: selectValues,
          toggleSummary: toggleSummary,
          toggleValues: toggleValues,
          aiConfig: aiConfig,
        ),
      ),
    );
  }

  String _buildRunOutputDir(String baseDir, String projectName) {
    final safeName = _sanitizeName(projectName);
    final stamp = _timestamp();
    final suffix = _randomSuffix(6);
    return p.join(baseDir, '${safeName}_$stamp\_$suffix');
  }

  String _timestamp() {
    final now = DateTime.now().toUtc();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '${yyyy}${mm}${dd}_${hh}${min}${ss}';
  }

  String _randomSuffix(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _sanitizeName(String value) {
    final buffer = StringBuffer();
    for (final ch in value.trim().split('')) {
      if (RegExp(r'[A-Za-z0-9_-]').hasMatch(ch)) {
        buffer.write(ch);
      } else if (ch.trim().isEmpty) {
        buffer.write('_');
      }
    }
    final result = buffer.toString();
    return result.isEmpty ? 'projet' : result;
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({required this.aiConfig});

  final AiConfig aiConfig;

  @override
  Widget build(BuildContext context) {
    final status = aiConfig.enabled ? 'Activée' : 'Désactivée';
    final provider = aiConfig.enabled ? aiConfig.label : '—';
    final keyStatus = aiConfig.enabled
        ? (aiConfig.hasKey ? 'Clé renseignée' : 'Clé manquante')
        : 'Non requis';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assistant IA',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'État',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    color: ModernPalette.inkMuted,
                  ),
                ),
              ),
              Text(
                status,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ModernPalette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fournisseur',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    color: ModernPalette.inkMuted,
                  ),
                ),
              ),
              Text(
                provider,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ModernPalette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Clé API',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    color: ModernPalette.inkMuted,
                  ),
                ),
              ),
              Text(
                keyStatus,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ModernPalette.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTopNav extends StatelessWidget {
  const _ReviewTopNav({required this.onDocumentation});

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
              'Revue',
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
  const _InfoPanel({
    required this.isCompact,
    required this.stack,
    required this.projectName,
    required this.outputDir,
  });

  final bool isCompact;
  final StackDefinition stack;
  final String projectName;
  final String outputDir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTag(),
        const SizedBox(height: 18),
        Text(
          'Revue finale',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.w700,
            color: ModernPalette.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirmez la stack, les versions et les modules. '
          'Une fois validé, la génération peut démarrer.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            color: ModernPalette.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _SummaryCard(
          stack: stack,
          projectName: projectName,
          outputDir: outputDir,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _InfoChip(icon: Icons.fact_check_outlined, label: 'Contrôle rapide'),
            _InfoChip(icon: Icons.rule_folder, label: 'Structure stable'),
            _InfoChip(icon: Icons.shield_outlined, label: 'Erreurs évitées'),
          ],
        ),
      ],
    );
  }
}

class _StepTag extends StatelessWidget {
  const _StepTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: ModernPalette.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Étape 4/5 · revue',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.stack,
    required this.projectName,
    required this.outputDir,
  });

  final StackDefinition stack;
  final String projectName;
  final String outputDir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stack.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(stack.asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Projet "$projectName" → $outputDir. '
              'La génération suivra les conventions ${stack.name}.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                color: ModernPalette.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({
    required this.projectName,
    required this.outputDir,
    required this.accent,
    this.packageName,
  });

  final String projectName;
  final String? packageName;
  final String outputDir;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRowData>[
      _SummaryRowData(label: 'Projet', value: projectName),
      if (packageName != null && packageName!.trim().isNotEmpty)
        _SummaryRowData(label: 'Package', value: packageName!.trim()),
      _SummaryRowData(label: 'Sortie', value: outputDir),
    ];

    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children:
            rows.map((row) => _SummaryRow(row: row, accent: accent)).toList(),
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.row, required this.accent});

  final _SummaryRowData row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            row.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: ModernPalette.inkMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ModernPalette.ink,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({
    required this.title,
    required this.entries,
    required this.emptyLabel,
  });

  final String title;
  final List<MapEntry<String, String>> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              emptyLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: ModernPalette.inkMuted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map((entry) =>
                      _SummaryChip(label: entry.key, value: entry.value))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernPalette.border),
      ),
      child: Text(
        '$label · $value',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: ModernPalette.ink,
        ),
      ),
    );
  }
}

class _ToggleChips extends StatelessWidget {
  const _ToggleChips({
    required this.title,
    required this.entries,
    required this.accent,
  });

  final String title;
  final List<MapEntry<String, bool>> entries;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabledEntries = entries.where((entry) => entry.value).toList();
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ModernPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (enabledEntries.isEmpty)
            Text(
              'Aucun module activé.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: ModernPalette.inkMuted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: enabledEntries
                  .map((entry) => _ToggleChip(
                        label: entry.key,
                        accent: accent,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: ModernPalette.ink,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ModernPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ModernPalette.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
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

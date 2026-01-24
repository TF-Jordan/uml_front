import 'dart:io';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

import '../constantes/modern_palette.dart';
import '../constantes/theme_extension.dart';
import '../l10n/app_localizations.dart';
import '../models/uml_inputs.dart';
import '../services/docs_launcher.dart';
import '../services/workspace_paths.dart';
import '../widgets/breadcrumb_bar.dart';
import 'language_selection.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key, this.initialInputs}) : super(key: key);

  final UmlInputs? initialInputs;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isHoveringDrop = false;
  final List<_UmlFileEntry> _uploadedFiles = [];
  static const int _maxFiles = 2;
  late final String _workspaceRoot = WorkspacePaths.resolveWorkspaceRoot();

  @override
  void initState() {
    super.initState();
    _seedInitialInputs();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 1024;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CurrentTheme.sand,
                  CurrentTheme.cloud,
                  CurrentTheme.sandDeep,
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
              color: CurrentTheme.accentGlow.withOpacity(0.25),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 120,
            child: _GlowingOrb(
              size: 200,
              color: CurrentTheme.teal.withOpacity(0.2),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 32,
                    220,
                    isCompact ? 16 : 32,
                    60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const SizedBox(height: 48),
                          _buildContent(isCompact),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CurrentTheme.sand,
                          CurrentTheme.sand.withOpacity(0.98),
                          CurrentTheme.sand.withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.85, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 16 : 32,
                        12,
                        isCompact ? 16 : 32,
                        16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1800),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _UploadTopNav(
                                onDocumentation: () => DocsLauncher.open(context),
                              ),
                              const SizedBox(height: 16),
                              Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context);
                                  return Center(
                                    child: BreadcrumbBar(
                                      items: [l10n.overview, l10n.importUml],
                                      activeIndex: 1,
                                      onNavigate: _handleBreadcrumbNavigate,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
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

  Widget _buildContent(bool isCompact) {
    final l10n = AppLocalizations.of(context);
    final leftPanel = _InfoPanel(
      isCompact: isCompact,
      filesCount: _uploadedFiles.length,
    );

    final rightPanel = _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dropYourUmlFiles,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.oneFileMinTwoMax,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              color: CurrentTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          _buildDropZone(),
          const SizedBox(height: 18),
          if (_uploadedFiles.isNotEmpty) ...[
            Text(
              l10n.importedFiles,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CurrentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            _buildFileChips(),
          ],
          const SizedBox(height: 18),
          _buildProgressBar(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _uploadedFiles.isNotEmpty ? _goToLanguagePage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CurrentTheme.accent,
                    disabledBackgroundColor: CurrentTheme.surfaceSoft,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.continueBtn),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // Row(
          //   children: [
          //     const Icon(Icons.lock_outline, size: 16, color: CurrentTheme.inkMuted),
          //     const SizedBox(width: 8),
          //     Expanded(
          //       child: Text(
          //         'Les fichiers restent sur votre machine. Aucun envoi externe par défaut.',
          //         style: GoogleFonts.spaceGrotesk(
          //           fontSize: 12,
          //           color: CurrentTheme.inkMuted,
          //         ),
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
        Expanded(flex: 5, child: leftPanel),
        const SizedBox(width: 28),
        Expanded(flex: 6, child: rightPanel),
      ],
    );
  }

  Widget _buildDropZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringDrop = true),
      onExit: (_) => setState(() => _isHoveringDrop = false),
      child: DottedBorder(
        color: _isHoveringDrop ? CurrentTheme.accent : CurrentTheme.border,
        strokeWidth: 1.4,
        dashPattern: const [10, 6],
        borderType: BorderType.RRect,
        radius: const Radius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHoveringDrop
                ? CurrentTheme.surfaceSoft
                :CurrentTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: _isUploading ? _buildUploadingState() : _buildIdleState(),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CurrentTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.cloud_upload_outlined,
                color: CurrentTheme.accent, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
          l10n.dragDiagramsHere,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.supportedFormats,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            color: CurrentTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _handleFilePicked,
            style: OutlinedButton.styleFrom(
              foregroundColor: CurrentTheme.ink,
              side: BorderSide(color: CurrentTheme.inkSoft),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.chooseFile),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: CurrentTheme.accent),
        const SizedBox(height: 12),
        Text(
          '${l10n.importInProgress} ${( _uploadProgress * 100).toInt()}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: CurrentTheme.surfaceSoft,
          color: CurrentTheme.accent,
        ),
      ],
    );
  }

  Widget _buildFileChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _uploadedFiles
          .map(
            (file) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CurrentTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CurrentTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: CurrentTheme.teal, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    file.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      color: CurrentTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildProgressBar() {
    final l10n = AppLocalizations.of(context);
    if (_uploadedFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CurrentTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CurrentTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: CurrentTheme.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.addFilesToContinue,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  color: CurrentTheme.inkMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: CurrentTheme.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _uploadedFiles.length >= _maxFiles
                  ? '$_uploadedFilesCountText. ${l10n.maximumReached}'
                  : '$_uploadedFilesCountText. ${l10n.canAddMore}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                color: CurrentTheme.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFilePicked() async {
    if (_uploadedFiles.length >= _maxFiles) {
      _showSnackBar('Maximum $_maxFiles fichiers autorisés.');
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['uml', 'xmi', 'xml', 'drawio'],
    );

    if (result != null) {
      final picked = result.files.first;
      if (picked.path == null) {
        _showSnackBar('Impossible d\'accéder au fichier sélectionné.');
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        final copyFuture = _prepareUmlFile(picked);
        await Future.wait([
          _simulateUpload(picked.name),
          copyFuture,
        ]);
        final entry = await copyFuture;

        setState(() {
          _isUploading = false;
          _uploadedFiles.add(entry);
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        _showSnackBar('Erreur lors de la copie: ${e.toString()}');
        return;
      }

      if (_uploadedFiles.length == 1) {
        _showSequenceDiagramDialog();
      } else if (_uploadedFiles.length >= _maxFiles) {
        _goToLanguagePage();
      }
    }
  }

  Future<void> _simulateUpload(String fileName) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() {
        _uploadProgress = i / 100;
      });
    }
  }

  void _showSequenceDiagramDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.sequenceDiagramQuestion,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        content: Text(
          l10n.wantToAddSequence,
          style: GoogleFonts.spaceGrotesk(color: CurrentTheme.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _goToLanguagePage();
            },
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CurrentTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<_UmlFileEntry> _prepareUmlFile(PlatformFile picked) async {
    final sourcePath = picked.path!;
    if (WorkspacePaths.isWithinRoot(_workspaceRoot, sourcePath)) {
      return _UmlFileEntry(name: picked.name, path: sourcePath);
    }

    final destPath = await _copyIntoWorkspace(sourcePath);
    return _UmlFileEntry(name: picked.name, path: destPath);
  }

  Future<String> _copyIntoWorkspace(String sourcePath) async {
    final destinationDir = p.join(_workspaceRoot, 'datas', 'imports');
    await Directory(destinationDir).create(recursive: true);

    final originalName = p.basename(sourcePath);
    var candidate = p.join(destinationDir, originalName);
    var counter = 1;
    while (File(candidate).existsSync()) {
      final stem = p.basenameWithoutExtension(originalName);
      final ext = p.extension(originalName);
      candidate = p.join(destinationDir, '${stem}_$counter$ext');
      counter += 1;
    }

    await File(sourcePath).copy(candidate);
    return candidate;
  }

  void _goToLanguagePage() {
    final l10n = AppLocalizations.of(context);
    if (_uploadedFiles.isEmpty) {
      _showSnackBar(l10n.addAtLeastOneFile);
      return;
    }
    final inputs = UmlInputs(
      classDiagramPath: _uploadedFiles.first.path,
      sequenceDiagramPath:
          _uploadedFiles.length > 1 ? _uploadedFiles[1].path : null,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageSelectionPage(inputs: inputs),
      ),
    );
  }

  void _handleBreadcrumbNavigate(int index) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
  }

  String get _uploadedFilesCountText {
    final l10n = AppLocalizations.of(context);
    return '${_uploadedFiles.length}/$_maxFiles ${l10n.filesImportedCount}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CurrentTheme.ink,
      ),
    );
  }

  void _seedInitialInputs() {
    final inputs = widget.initialInputs;
    if (inputs == null) {
      return;
    }
    _uploadedFiles
      ..clear()
      ..add(
        _UmlFileEntry(
          name: p.basename(inputs.classDiagramPath),
          path: inputs.classDiagramPath,
        ),
      );
    if (inputs.hasSequence) {
      _uploadedFiles.add(
        _UmlFileEntry(
          name: p.basename(inputs.sequenceDiagramPath!),
          path: inputs.sequenceDiagramPath!,
        ),
      );
    }
  }
}

class _UmlFileEntry {
  const _UmlFileEntry({required this.name, required this.path});

  final String name;
  final String path;
}

class _UploadTopNav extends StatelessWidget {
  const _UploadTopNav({required this.onDocumentation});

  final VoidCallback onDocumentation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Row(
        children: [
          _BrandMark(),
          const Spacer(),
          OutlinedButton(
            onPressed: onDocumentation,
            style: OutlinedButton.styleFrom(
              foregroundColor: CurrentTheme.ink,
              side: BorderSide(color: CurrentTheme.inkSoft),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.documentation),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                color: CurrentTheme.accent.withOpacity(0.2),
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
                  Icon(Icons.auto_awesome, color: CurrentTheme.accent),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CurrentTheme.ink,
              ),
            ),
            Text(
              l10n.importUml,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: CurrentTheme.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.isCompact, required this.filesCount});

  final bool isCompact;
  final int filesCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTag(count: filesCount),
        const SizedBox(height: 18),
        Text(
          l10n.importYourUmlDiagrams,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.w700,
            color: CurrentTheme.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.addClassFirst,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            color: CurrentTheme.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _ChecklistCard(),
        const SizedBox(height: 28),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoChip(icon: Icons.account_tree_outlined, label: l10n.classesRequired),
            _InfoChip(icon: Icons.timeline, label: l10n.sequenceOptional),
            _InfoChip(icon: Icons.shield_outlined, label: l10n.localAndSecure),
          ],
        ),

      ],
    );
  }
}

class _StepTag extends StatelessWidget {
  const _StepTag({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '${l10n.step} 1/5 · $count/2 ${l10n.filesImportedCount}',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
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
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CurrentTheme.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: CurrentTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beforeStarting,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 50,
              fontWeight: FontWeight.w900,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          _ChecklistItem(text: l10n.cleanClassDiagram),
          _ChecklistItem(text: l10n.normalizedNames),
          _ChecklistItem(text: l10n.explicitRelations),
          _ChecklistItem(text: l10n.optionalSequences),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              size: 16, color: CurrentTheme.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                color: CurrentTheme.inkSoft,
              ),
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
      ..color = CurrentTheme.grid.withOpacity(0.32)
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
            color: CurrentTheme.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CurrentTheme.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

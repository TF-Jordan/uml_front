import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

import '../constantes/modern_palette.dart';
import '../constantes/theme_extension.dart';
import '../l10n/app_localizations.dart';
import '../models/ai_config.dart';
import '../models/stack_definition.dart';
import '../models/uml_inputs.dart';
import '../services/docs_launcher.dart';
import '../services/docker_builder.dart';
import '../services/workspace_paths.dart';
import '../widgets/breadcrumb_bar.dart';
import 'language_selection.dart';
import 'page1.dart';
import 'stack_configuration.dart';

class GenerationPage extends StatefulWidget {
  const GenerationPage({
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
  State<GenerationPage> createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage> {
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatus = '';
  String? _generatedProjectPath;
  String? _generationError;
  final List<String> _generationLogs = [];
  Process? _runningProcess;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  String? _logFilePath;
  String? _lastUiLog;

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _runningProcess?.kill(ProcessSignal.sigterm);
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
                    isCompact ? 20 : 52,
                    220,
                    isCompact ? 20 : 52,
                    60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1800),
                      child: _buildContent(isCompact),
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
                        isCompact ? 20 : 52,
                        28,
                        isCompact ? 20 : 52,
                        16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GenerationTopNav(
                            onDocumentation: () => DocsLauncher.open(context),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Center(
                                child: BreadcrumbBar(
                                  items: [
                                    l10n.overview,
                                    l10n.importUml,
                                    l10n.stack,
                                    l10n.configuration,
                                    l10n.review,
                                    l10n.generation
                                  ],
                                  activeIndex: 5,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isCompact) {
    final leftPanel = _InfoPanel(
      isCompact: isCompact,
      stack: widget.stack,
      projectName: widget.projectName,
      outputDir: widget.outputDir,
    );

    final rightPanel = _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lancer la génération',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez le résumé, puis démarrez la création du projet.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              color: CurrentTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          _SummaryTable(
            projectName: widget.projectName,
            packageName: widget.packageName,
            outputDir: widget.outputDir,
            accent: widget.stack.color,
          ),
          const SizedBox(height: 20),
          _SummaryChips(
            title: 'Options choisies',
            entries: widget.selectSummary.entries.toList(),
            emptyLabel: 'Aucune option spécifique sélectionnée.',
          ),
          const SizedBox(height: 16),
          _ToggleChips(
            title: 'Modules activés',
            entries: widget.toggleSummary.entries.toList(),
            accent: widget.stack.color,
          ),
          const SizedBox(height: 24),
          if (_generatedProjectPath == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CurrentTheme.accent,
                  disabledBackgroundColor: CurrentTheme.surfaceSoft,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(_isGenerating ? 'Génération...' : 'Démarrer'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CurrentTheme.accent,
                      disabledBackgroundColor: CurrentTheme.surfaceSoft,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Démarrer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isGenerating ? null : _startNewFlow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CurrentTheme.ink,
                      side: BorderSide(color: CurrentTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Nouveau'),
                  ),
                ),
              ],
            ),
          ],
          if (_isGenerating) ...[
            const SizedBox(height: 18),
            _ProgressCard(
              status: _generationStatus,
              progress: _generationProgress,
              accent: widget.stack.color,
            ),
          ],
          if (_generationLogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LogCard(lines: _generationLogs),
          ],
          if (_generationError != null) ...[
            const SizedBox(height: 16),
            _ErrorCard(message: _generationError!),
          ],
          if (_generatedProjectPath != null) ...[
            const SizedBox(height: 18),
            _SuccessCard(
              path: _generatedProjectPath!,
              onOpen: _openGeneratedProject,
            ),
          ],
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

  void _handleBreadcrumbNavigate(int index) {
    if (index == 4) {
      Navigator.pop(context);
      return;
    }
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
    if (index >= 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StackConfigurationPage(
            stack: widget.stack,
            inputs: widget.inputs,
          ),
        ),
      );
    }
  }

  Future<void> _generateProject() async {
    if (_isGenerating) {
      return;
    }
    setState(() {
      _isGenerating = true;
      _generationProgress = 0.05;
      _generationStatus = 'Préparation de la configuration';
      _generatedProjectPath = null;
      _generationError = null;
      _generationLogs.clear();
    });

    try {
      final workspaceRoot = WorkspacePaths.resolveWorkspaceRoot();
      await _prepareLogFile(workspaceRoot);

      final classRel = WorkspacePaths.relativeToRoot(
        workspaceRoot,
        widget.inputs.classDiagramPath,
      );
      if (classRel == null) {
        throw Exception(
          'Le diagramme UML doit être dans le workspace pour Docker.',
        );
      }
      if (!File(widget.inputs.classDiagramPath).existsSync()) {
        throw Exception('Diagramme de classes introuvable.');
      }

      String? sequenceRel;
      if (widget.inputs.hasSequence) {
        sequenceRel = WorkspacePaths.relativeToRoot(
          workspaceRoot,
          widget.inputs.sequenceDiagramPath!,
        );
        if (sequenceRel == null) {
          throw Exception(
            'Le diagramme de séquence doit être dans le workspace.',
          );
        }
        if (!File(widget.inputs.sequenceDiagramPath!).existsSync()) {
          throw Exception('Diagramme de séquence introuvable.');
        }
      }

      if (widget.aiConfig.enabled && !widget.inputs.hasSequence) {
        throw Exception(
          'Ajoutez un diagramme de séquence pour activer l\'assistant IA.',
        );
      }

      final config = _buildConfig(
        classDiagramPath: classRel,
        sequenceDiagramPath: sequenceRel,
      );

      final configPath = p.join(workspaceRoot, 'uml2code.generated.json');
      await File(configPath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(config));

      _updateProgress('Configuration prête', 0.18);

      final dockerReady = await _checkDockerAvailable();
      if (!dockerReady) {
        throw Exception('Docker est introuvable ou inactif.');
      }

      _updateProgress('Préparation de l\'image Docker', 0.22);
      final imageName = DockerBuilder.resolveImageName();
      final imageResult = await DockerBuilder.ensureImageAvailable(
        image: imageName,
        onLog: _appendLog,
      );
      if (!imageResult.success) {
        throw Exception(imageResult.message);
      }

      _updateProgress('Lancement du générateur', 0.25);

      final configRel = p.relative(configPath, from: workspaceRoot);
      final envArgs = <String>[];
      if (widget.aiConfig.enabled && widget.aiConfig.hasKey) {
        envArgs.addAll([
          '-e',
          '${widget.aiConfig.userKeyId}=${widget.aiConfig.apiKey}',
        ]);
      }
      final dockerArgs = [
        'run',
        '--rm',
        ...await _dockerUserArgs(),
        ...envArgs,
        '-v',
        '$workspaceRoot:/workspace',
        '-w',
        '/workspace',
        imageName,
        '/workspace/$configRel',
      ];
      final process = await Process.start(
        'docker',
        dockerArgs,
        workingDirectory: workspaceRoot,
        runInShell: true,
        environment: _buildProcessEnvironment(),
      );
      _runningProcess = process;

      _stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLog(line));
      _stderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLog(line));

      final exitCode = await process.exitCode;
      if (!mounted) {
        return;
      }

      if (exitCode != 0) {
        throw Exception('La génération a échoué (code $exitCode).');
      }

      _updateProgress('Génération terminée', 1.0);
      setState(() {
        _isGenerating = false;
        _runningProcess = null;
        _generatedProjectPath =
            p.normalize(p.join(widget.outputDir, 'GeneratedProject'));
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _startNewFlow() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UploadPage()),
    );
  }

  Map<String, dynamic> _buildConfig({
    required String classDiagramPath,
    String? sequenceDiagramPath,
  }) {
    final meta = <String, dynamic>{
      'schema_version': '1.0',
      'project_name': widget.projectName,
      'stack': widget.stack.key,
      'output_dir': widget.outputDir,
    };

    final inputs = <String, dynamic>{
      'class_diagram_path': classDiagramPath,
    };
    if (sequenceDiagramPath != null) {
      inputs['sequence_diagram_path'] = sequenceDiagramPath;
    }

    final pipeline = <String, dynamic>{
      'mode': sequenceDiagramPath == null ? 'class_only' : 'class_plus_sequence_ia',
      'overwrite_strategy': 'backup',
    };

    final config = <String, dynamic>{
      'meta': meta,
      'inputs': inputs,
      'pipeline': pipeline,
    };

    final stackOptions = _buildStackOptions();
    if (stackOptions.isNotEmpty) {
      config[widget.stack.key] = stackOptions;
    }

    if (widget.aiConfig.enabled) {
      config['ai'] = {
        'enabled': true,
        'provider': widget.aiConfig.provider,
        'user_key_id': widget.aiConfig.userKeyId,
      };
    }

    return config;
  }

  Map<String, dynamic> _buildStackOptions() {
    final select = widget.selectValues;
    final toggle = widget.toggleValues;
    final packageName = widget.packageName;

    switch (widget.stack.key) {
      case 'spring':
        final deps = <String>[];
        if (toggle['security'] == true) deps.add('security');
        if (toggle['actuator'] == true) deps.add('actuator');
        if (toggle['devtools'] == true) deps.add('devtools');
        if (toggle['lombok'] == true) deps.add('lombok');
        final options = <String, dynamic>{
          'spring_boot_version': select['spring_boot_version'],
          'java_version': select['java_version'],
          'build_tool': select['build_tool'],
          'db': select['db'],
          'tests': select['tests'],
          'dependencies': deps,
        };
        if (packageName != null && packageName.isNotEmpty) {
          options['group_id'] = packageName;
        }
        return options;
      case 'fastapi':
        final options = {
          'fastapi_version': select['fastapi_version'],
          'python_version': select['python_version'],
          'orm': select['orm'],
          'db': select['db'],
          'migrations': select['migrations'],
          'auth': select['auth'],
          'deps': _enabledDeps([
            'httpx',
            'pytest',
            'passlib',
            'python-jose',
            'celery',
            'redis',
          ]),
        };
        _attachPackageName(options, packageName);
        return options;
      case 'laravel':
        final options = {
          'laravel_version': select['laravel_version'],
          'php_version': select['php_version'],
          'db': select['db'],
          'auth': select['auth'],
          'queue': select['queue'],
          'cache': select['cache'],
          'deps': _enabledDeps(['laravel/pint']),
        };
        _attachPackageName(options, packageName);
        return options;
      case 'nestjs':
        final options = {
          'node_version': select['node_version'],
          'nest_version': select['nest_version'],
          'package_manager': select['package_manager'],
          'orm': select['orm'],
          'db': select['db'],
          'auth': select['auth'],
        };
        _attachPackageName(options, packageName);
        return options;
      case 'dart':
        final options = {
          'dart_version': select['dart_version'],
          'framework': select['framework'],
          'db': select['db'],
        };
        _attachPackageName(options, packageName);
        return options;
      case 'fiber':
        final options = {
          'go_version': select['go_version'],
          'fiber_version': select['fiber_version'],
          'db': select['db'],
          'orm': select['orm'],
        };
        _attachPackageName(options, packageName);
        return options;
      default:
        return {};
    }
  }

  void _attachPackageName(Map<String, dynamic> options, String? packageName) {
    if (packageName != null && packageName.isNotEmpty) {
      options['package_name'] = packageName;
    }
  }

  List<String> _enabledDeps(List<String> keys) {
    return keys.where((key) => widget.toggleValues[key] == true).toList();
  }

  Map<String, String> _buildProcessEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    if (widget.aiConfig.enabled && widget.aiConfig.hasKey) {
      env[widget.aiConfig.userKeyId] = widget.aiConfig.apiKey;
    }
    return env;
  }

  void _appendLog(String line) {
    if (!mounted) {
      return;
    }
    _writeLogLine(line);
    final formatted = _formatLogLine(line);
    setState(() {
      if (formatted != null && formatted.isNotEmpty) {
        if (formatted != _lastUiLog) {
          _generationLogs.add(formatted);
          _lastUiLog = formatted;
        }
        if (_generationLogs.length > 8) {
          _generationLogs.removeAt(0);
        }
        _generationStatus = formatted;
      }
      if (_generationProgress < 0.9) {
        _generationProgress = _generationProgress + 0.05;
      }
    });
  }

  void _updateProgress(String status, double progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _generationStatus = status;
      _generationProgress = progress;
    });
  }

  Future<bool> _checkDockerAvailable() async {
    try {
      final result =
          await Process.run('docker', ['--version'], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> _dockerUserArgs() async {
    if (Platform.isWindows) {
      return [];
    }
    try {
      final uidResult =
          await Process.run('id', ['-u'], runInShell: true);
      final gidResult =
          await Process.run('id', ['-g'], runInShell: true);
      final uid = uidResult.stdout.toString().trim();
      final gid = gidResult.stdout.toString().trim();
      if (uid.isEmpty || gid.isEmpty) {
        return [];
      }
      return ['--user', '$uid:$gid'];
    } catch (_) {
      return [];
    }
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }
    final cleaned = message.replaceFirst('Exception: ', '');
    final logHint = _logFilePath != null
        ? '\nVoir le journal technique: $_logFilePath'
        : '';
    setState(() {
      _isGenerating = false;
      _generationProgress = 0.0;
      _generationStatus = '';
      _generationError = '$cleaned$logHint';
      _runningProcess = null;
    });
  }

  Future<void> _prepareLogFile(String workspaceRoot) async {
    final outputRoot = p.isAbsolute(widget.outputDir)
        ? widget.outputDir
        : p.join(workspaceRoot, widget.outputDir);
    final logsDir = Directory(p.join(outputRoot, 'cli_logs'));
    try {
      await logsDir.create(recursive: true);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        throw Exception(
          'Le dossier de sortie n\'est pas accessible. '
          'Choisissez un autre dossier de sortie ou corrigez les permissions.',
        );
      }
      rethrow;
    }
    final timestamp = _logTimestamp();
    final fileName = '${widget.projectName}_$timestamp.log';
    _logFilePath = p.join(logsDir.path, fileName);
    final header = 'UML2Code CLI log - ${DateTime.now().toIso8601String()}\n';
    await File(_logFilePath!).writeAsString(header);
  }

  void _writeLogLine(String line) {
    final logPath = _logFilePath;
    if (logPath == null) {
      return;
    }
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      return;
    }
    final stamped = '[${DateTime.now().toIso8601String()}] $trimmed\n';
    File(logPath).writeAsString(stamped, mode: FileMode.append);
  }

  String _logTimestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  String? _formatLogLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('Generated project in')) {
      return 'Projet généré.';
    }
    if (trimmed.startsWith('Normalized JSON:')) {
      return 'Diagramme de classes interprété.';
    }
    if (trimmed.startsWith('Prompt generated in') ||
        trimmed.startsWith('Prompt agrégé écrit dans')) {
      return 'Diagramme de séquence analysé.';
    }
    if (trimmed.startsWith('Appel à')) {
      return 'Assistant IA en cours...';
    }
    if (trimmed.startsWith('JSON IA écrit')) {
      return 'Assistant IA : réponse reçue.';
    }
    if (trimmed.startsWith('Import terminé')) {
      return 'Assistant IA : intégration terminée.';
    }
    if (trimmed.startsWith('AI response imported')) {
      return 'Assistant IA : code intégré.';
    }
    if (trimmed.contains('Analyse terminée avec succès')) {
      return 'Analyse terminée.';
    }
    if (trimmed.contains('Config OK')) {
      return 'Configuration validée.';
    }
    return null;
  }

  Future<void> _openGeneratedProject() async {
    final path = _generatedProjectPath;
    if (path == null) {
      return;
    }
    final absolutePath =
        p.isAbsolute(path)
            ? path
            : p.normalize(
                p.join(WorkspacePaths.resolveWorkspaceRoot(), path),
              );
    if (!Directory(absolutePath).existsSync()) {
      _showSnackBar('Dossier introuvable: $absolutePath');
      return;
    }
    try {
      if (Platform.isWindows) {
        await Process.start('explorer', [absolutePath], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.start('open', [absolutePath], runInShell: true);
      } else {
        await Process.start('xdg-open', [absolutePath], runInShell: true);
      }
    } catch (e) {
      _showSnackBar('Impossible d\'ouvrir le dossier: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CurrentTheme.ink,
      ),
    );
  }
}

class _GenerationTopNav extends StatelessWidget {
  const _GenerationTopNav({required this.onDocumentation});

  final VoidCallback onDocumentation;

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
              foregroundColor: CurrentTheme.ink,
              side: BorderSide(color: CurrentTheme.inkSoft),
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
              'UML2Code',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CurrentTheme.ink,
              ),
            ),
            Text(
              'Génération',
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
          'Générer ${stack.name}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.w700,
            color: CurrentTheme.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Toutes les options sont prêtes. Lancez la génération pour obtenir '
          'une structure de projet complète et exploitable immédiatement.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            color: CurrentTheme.inkSoft,
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
            _InfoChip(icon: Icons.bolt, label: 'Feedback instantané'),
            _InfoChip(icon: Icons.rule_folder, label: 'Structure standard'),
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
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Étape 5/5 · génération',
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
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CurrentTheme.border),
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
                color: CurrentTheme.inkSoft,
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
  final String outputDir;
  final String? packageName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRowData>[
      _SummaryRowData(label: 'Projet', value: projectName),
      if (packageName != null && packageName!.trim().isNotEmpty)
        _SummaryRowData(label: 'Package', value: packageName!.trim()),
      _SummaryRowData(label: 'Sortie', value: outputDir),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Column(
        children: rows
            .map((row) => _SummaryRow(row: row, accent: accent))
            .toList(),
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CurrentTheme.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Text(
            emptyLabel,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: CurrentTheme.inkMuted,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: entries
                .map(
                  (entry) => _SummaryChip(
                    label: entry.key,
                    value: entry.value,
                  ),
                )
                .toList(),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              color: CurrentTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
        ],
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
    final active = entries.where((entry) => entry.value).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          Text(
            'Aucun module activé.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: CurrentTheme.inkMuted,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: active
                .map(
                  (entry) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CurrentTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.status,
    required this.progress,
    required this.accent,
  });

  final String status;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.isEmpty ? 'Préparation…' : status,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: CurrentTheme.surfaceSoft,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.5,
                color: CurrentTheme.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  color: CurrentTheme.inkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CurrentTheme.accentDeep.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CurrentTheme.accentDeep.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline, color: CurrentTheme.accentDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
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
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.path, required this.onOpen});

  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CurrentTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CurrentTheme.success.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, color: CurrentTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projet généré avec succès',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CurrentTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: CurrentTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor: CurrentTheme.ink,
              side: BorderSide(color: CurrentTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ouvrir'),
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

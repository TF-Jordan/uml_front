import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constantes/modern_palette.dart';
import '../constantes/theme_extension.dart';
import '../l10n/app_localizations.dart';
import '../models/ai_config.dart';
import '../models/stack_definition.dart';
import '../models/uml_inputs.dart';
import '../services/ai_key_store.dart';
import '../services/docs_launcher.dart';
import '../services/settings_service.dart';
import '../widgets/breadcrumb_bar.dart';
import 'review.dart';
import 'language_selection.dart';
import 'page1.dart';

class StackConfigurationPage extends StatefulWidget {
  const StackConfigurationPage({
    Key? key,
    required this.stack,
    required this.inputs,
  }) : super(key: key);

  final StackDefinition stack;
  final UmlInputs inputs;

  @override
  State<StackConfigurationPage> createState() => _StackConfigurationPageState();
}

class _StackConfigurationPageState extends State<StackConfigurationPage> {
  final _projectNameController = TextEditingController();
  final _packageController = TextEditingController();
  final _outputController = TextEditingController(text: 'output');
  final _settings = SettingsService.instance;

  final Map<String, String> _selectValues = {};
  final Map<String, bool> _toggleValues = {};
  bool _aiEnabled = false;
  String _aiProvider = 'gemini';
  String _aiKey = '';
  bool _aiKeyVisible = false;
  bool _rememberKey = false;

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _loadSettingsAndKey();
  }

  Future<void> _loadSettingsAndKey() async {
    // Charger le fournisseur et la clé depuis les Settings
    final savedProvider = _settings.aiProvider;
    final savedKey = _settings.getApiKey(savedProvider);
    final savedOutputDir = _settings.defaultOutputDir;

    setState(() {
      _aiProvider = savedProvider;
      if (savedKey != null && savedKey.isNotEmpty) {
        _aiKey = savedKey;
        _rememberKey = true;
      }
      if (savedOutputDir.isNotEmpty) {
        _outputController.text = savedOutputDir;
      }
    });

    // Aussi vérifier l'ancien système AiKeyStore pour migration
    if (_aiKey.isEmpty) {
      _loadStoredKey(_aiProvider);
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _packageController.dispose();
    _outputController.dispose();
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
                        12,
                        isCompact ? 20 : 52,
                        16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1800),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ConfigTopNav(
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
                                        l10n.configuration
                                      ],
                                      activeIndex: 3,
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
      stack: widget.stack,
    );

    final rightPanel = _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.configurationOf} ${widget.stack.name}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CurrentTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.fillEssentialParams,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              color: CurrentTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: l10n.projectName,
            helper: l10n.projectNameRequiredHint,
            controller: _projectNameController,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: l10n.namespacePackage,
            helper: l10n.namespaceOptionalHint,
            controller: _packageController,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: l10n.outputDirectoryField,
            helper: l10n.outputDefault,
            controller: _outputController,
          ),
          const SizedBox(height: 20),
          _buildSelectSection(),
          const SizedBox(height: 20),
          _buildToggleSection(),
          const SizedBox(height: 20),
          _buildAiSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _canContinue() ? _goToReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CurrentTheme.accent,
                    disabledBackgroundColor: CurrentTheme.surfaceSoft,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Continuer vers la revue'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: CurrentTheme.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les champs obligatoires sont contrôlés pour éviter les erreurs.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: CurrentTheme.inkMuted,
                  ),
                ),
              ),
            ],
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

  Widget _buildTextField({
    required String label,
    required String helper,
    required TextEditingController controller,
    bool required = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CurrentTheme.ink,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 6),
              Text('*',
                  style: TextStyle(color: CurrentTheme.accent, fontSize: 14)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: helper,
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: CurrentTheme.inkMuted,
            ),
            filled: true,
            fillColor: CurrentTheme.surfaceSoft,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: CurrentTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: CurrentTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: widget.stack.color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectSection() {
    final selects =
        _selectOptions().where((option) => option.values.length > 1).toList();
    if (selects.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options de génération',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        ...selects.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _selectValues[option.id],
              decoration: InputDecoration(
                labelText: option.label,
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  color: CurrentTheme.inkMuted,
                ),
                filled: true,
                fillColor: CurrentTheme.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: CurrentTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: CurrentTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.stack.color),
                ),
              ),
              items: option.values
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _handleSelectChange(option.id, value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    final toggles = _toggleOptions();
    if (toggles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modules complémentaires',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        ...toggles.map(
          (option) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CurrentTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CurrentTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CurrentTheme.ink,
                        ),
                      ),
                      if (option.helper != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          option.helper!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            color: CurrentTheme.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: _toggleValues[option.id] ?? false,
                  activeColor: widget.stack.color,
                  onChanged: (value) {
                    setState(() => _toggleValues[option.id] = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSection() {
    if (!widget.inputs.hasSequence) {
      return const SizedBox.shrink();
    }
    if (!_supportsAi()) {
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
                'Assistant IA non disponible pour cette technologie.',
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

    final canUseAi = widget.inputs.hasSequence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assistant IA',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CurrentTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CurrentTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CurrentTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activer l\'assistant IA',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canUseAi
                          ? 'Ajoute des étapes intelligentes après le diagramme de séquence.'
                          : 'Ajoutez un diagramme de séquence pour activer l\'IA.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        color: CurrentTheme.surfaceSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _aiEnabled,
                activeColor: widget.stack.color,
                onChanged: canUseAi
                    ? (value) {
                        setState(() => _aiEnabled = value);
                      }
                    : null,
              ),
            ],
          ),
        ),
        if (_aiEnabled) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _aiProvider,
            decoration: InputDecoration(
              labelText: 'Fournisseur',
              labelStyle: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                color: Colors.white,
              ),
              filled: true,
              fillColor: CurrentTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CurrentTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CurrentTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.stack.color),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
              DropdownMenuItem(value: 'claude', child: Text('Claude')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _aiProvider = value;
                _aiKey = '';
                _rememberKey = false;
              });
              _loadStoredKey(value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: !_aiKeyVisible,
            onChanged: (value) => setState(() => _aiKey = value),
            decoration: InputDecoration(
              labelText: 'Clé API',
              helperText: 'La clé reste locale et n\'est pas affichée.',
              helperStyle: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: CurrentTheme.inkMuted,
              ),
              filled: true,
              fillColor: CurrentTheme.surface,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _aiKeyVisible = !_aiKeyVisible),
                icon: Icon(
                  _aiKeyVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CurrentTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CurrentTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.stack.color),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Switch(
                value: _rememberKey,
                activeColor: widget.stack.color,
                onChanged: (value) async {
                  setState(() => _rememberKey = value);
                  if (!value) {
                    await AiKeyStore.delete(_aiProvider);
                  } else if (_aiKey.trim().isNotEmpty) {
                    await AiKeyStore.write(_aiProvider, _aiKey.trim());
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Se souvenir de la clé sur cet appareil.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: CurrentTheme.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _initDefaults() {
    for (final option in _selectOptions()) {
      _selectValues.putIfAbsent(option.id, () => option.values.first);
    }
    for (final option in _toggleOptions()) {
      _toggleValues.putIfAbsent(option.id, () => option.defaultValue);
    }
  }

  bool _supportsAi() {
    return true;
  }

  List<_SelectOption> _selectOptions() {
    switch (widget.stack.key) {
      case 'spring':
        return const [
          _SelectOption(
            id: 'spring_boot_version',
            label: 'Spring Boot',
            values: ['4.0.1', '3.5.9', '3.4.13', '3.3.13', '3.2.x'],
          ),
          _SelectOption(
            id: 'java_version',
            label: 'Java',
            values: ['25', '24', '23', '21', '17'],
          ),
          _SelectOption(
            id: 'build_tool',
            label: 'Compilation',
            values: ['maven'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['mysql', 'postgres', 'mariadb', 'h2'],
          ),
          _SelectOption(
            id: 'tests',
            label: 'Tests',
            values: ['junit'],
          ),
        ];
      case 'fastapi':
        return const [
          _SelectOption(
            id: 'fastapi_version',
            label: 'FastAPI',
            values: [
              '0.128.0',
              '0.125.0',
              '0.124.4',
              '0.124.3',
              '0.124.2',
              '0.124.1'
            ],
          ),
          _SelectOption(
            id: 'python_version',
            label: 'Python',
            values: ['3.12', '3.13', '3.14', '3.10', '3.9'],
          ),
          _SelectOption(
            id: 'orm',
            label: 'ORM',
            values: ['sqlalchemy', 'sqlmodel'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['sqlite', 'postgres', 'mysql'],
          ),
          _SelectOption(
            id: 'migrations',
            label: 'Migrations',
            values: ['alembic', 'none'],
          ),
          _SelectOption(
            id: 'auth',
            label: 'Authentification',
            values: ['none', 'jwt', 'oauth'],
          ),
        ];
      case 'laravel':
        return const [
          _SelectOption(
            id: 'laravel_version',
            label: 'Laravel',
            values: ['12.44.0', '12.43.0', '12.42.0', '12.41.0', '12.40.0'],
          ),
          _SelectOption(
            id: 'php_version',
            label: 'PHP',
            values: ['8.4', '8.3', '8.2', '8.1'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['mysql', 'pgsql', 'sqlite'],
          ),
          _SelectOption(
            id: 'auth',
            label: 'Authentification',
            values: ['sanctum', 'passport', 'none'],
          ),
          _SelectOption(
            id: 'queue',
            label: 'File d\'attente',
            values: ['database', 'redis', 'none'],
          ),
          _SelectOption(
            id: 'cache',
            label: 'Cache',
            values: ['database', 'redis', 'file'],
          ),
        ];
      case 'nestjs':
        return const [
          _SelectOption(
            id: 'node_version',
            label: 'Node',
            values: ['24.12.0', '24.11.0', '25.2.1', '22.21.0', '24.9.0'],
          ),
          _SelectOption(
            id: 'nest_version',
            label: 'NestJS',
            values: ['11.1.x', '11.0.x', '10.9.x', '10.8.x', '10.7.x'],
          ),
          _SelectOption(
            id: 'package_manager',
            label: 'Gestionnaire de paquets',
            values: ['npm'],
          ),
          _SelectOption(
            id: 'orm',
            label: 'ORM',
            values: ['typeorm'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['postgres', 'mysql', 'sqlite', 'mongodb'],
          ),
          _SelectOption(
            id: 'auth',
            label: 'Authentification',
            values: ['none'],
          ),
        ];
      case 'dart':
        return const [
          _SelectOption(
            id: 'dart_version',
            label: 'Dart',
            values: ['3.10.x', '3.9.x', '3.8.x', '3.7.x', '3.6.x'],
          ),
          _SelectOption(
            id: 'framework',
            label: 'Framework',
            values: ['shelf'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['postgres'],
          ),
        ];
      case 'fiber':
        return const [
          _SelectOption(
            id: 'go_version',
            label: 'Go',
            values: ['1.21'],
          ),
          _SelectOption(
            id: 'fiber_version',
            label: 'Fiber',
            values: ['2.52.10', '2.52.9', '2.52.8', '2.52.6', '2.51.x'],
          ),
          _SelectOption(
            id: 'db',
            label: 'Base de données',
            values: ['postgres'],
          ),
          _SelectOption(
            id: 'orm',
            label: 'ORM',
            values: ['gorm'],
          ),
        ];
      default:
        return const [];
    }
  }

  List<_ToggleOption> _toggleOptions() {
    switch (widget.stack.key) {
      case 'spring':
        return const [
          _ToggleOption(
            id: 'security',
            label: 'spring-boot-starter-security',
            helper: 'Sécurité et authentification.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'actuator',
            label: 'spring-boot-starter-actuator',
            helper: 'Observabilité et checks de santé.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'devtools',
            label: 'spring-boot-devtools',
            helper: 'Hot reload pour le dev.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'lombok',
            label: 'lombok',
            helper: 'Réduction du boilerplate.',
            defaultValue: true,
          ),
        ];
      case 'fastapi':
        return const [
          _ToggleOption(
            id: 'httpx',
            label: 'httpx',
            helper: 'Client HTTP asynchrone.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'pytest',
            label: 'pytest',
            helper: 'Tests automatisés.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'passlib',
            label: 'passlib',
            helper: 'Hashing pour auth.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'python-jose',
            label: 'python-jose',
            helper: 'JWT / OAuth.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'celery',
            label: 'celery',
            helper: 'Tâches asynchrones.',
            defaultValue: false,
          ),
          _ToggleOption(
            id: 'redis',
            label: 'redis',
            helper: 'Cache et files d\'attente.',
            defaultValue: false,
          ),
        ];
      case 'laravel':
        return const [
          _ToggleOption(
            id: 'laravel/pint',
            label: 'laravel/pint',
            helper: 'Style code Laravel.',
            defaultValue: true,
          ),
        ];
      case 'nestjs':
        return const [];
      case 'dart':
        return const [];
      case 'fiber':
        return const [];
      default:
        return const [];
    }
  }

  void _handleSelectChange(String id, String value) {
    setState(() {
      _selectValues[id] = value;
    });
  }

  Future<void> _loadStoredKey(String provider) async {
    final stored = await AiKeyStore.read(provider);
    if (!mounted) {
      return;
    }
    if (stored != null && stored.trim().isNotEmpty) {
      setState(() {
        _aiKey = stored;
        _rememberKey = true;
      });
    }
  }

  bool _canContinue() {
    final nameOk = _projectNameController.text.trim().isNotEmpty;
    if (!_supportsAi() || !_aiEnabled) {
      return nameOk;
    }
    if (!widget.inputs.hasSequence) {
      return false;
    }
    return nameOk && _aiKey.trim().isNotEmpty;
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

  void _goToReview() {
    final projectName = _projectNameController.text.trim();
    final packageName = _packageController.text.trim();
    final outputDir = _outputController.text.trim().isEmpty
        ? 'output'
        : _outputController.text.trim();
    final selectSummary = <String, String>{};
    final selectValues = <String, String>{};
    for (final option in _selectOptions()) {
      final value = _selectValues[option.id] ?? option.values.first;
      selectSummary[option.label] = value;
      selectValues[option.id] = value;
    }
    final toggleSummary = <String, bool>{};
    final toggleValues = <String, bool>{};
    for (final option in _toggleOptions()) {
      final value = _toggleValues[option.id] ?? option.defaultValue;
      toggleSummary[option.label] = value;
      toggleValues[option.id] = value;
    }

    final aiConfig = AiConfig(
      enabled: _supportsAi() && _aiEnabled,
      provider: _aiProvider,
      apiKey: _aiKey.trim(),
    );

    // Synchroniser avec SettingsService et AiKeyStore
    if (aiConfig.enabled && aiConfig.hasKey) {
      if (_rememberKey) {
        // Sauvegarder dans les deux systèmes pour compatibilité
        AiKeyStore.write(_aiProvider, aiConfig.apiKey);
        _settings.setApiKey(_aiProvider, aiConfig.apiKey);
        _settings.setAiProvider(_aiProvider);
      } else {
        AiKeyStore.delete(_aiProvider);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(
          inputs: widget.inputs,
          stack: widget.stack,
          projectName: projectName,
          packageName: packageName.isEmpty ? null : packageName,
          outputDir: outputDir,
          selectSummary: selectSummary,
          selectValues: selectValues,
          toggleSummary: toggleSummary,
          toggleValues: toggleValues,
          aiConfig: aiConfig,
        ),
      ),
    );
  }
}

class _SelectOption {
  const _SelectOption({
    required this.id,
    required this.label,
    required this.values,
  });

  final String id;
  final String label;
  final List<String> values;
}

class _ToggleOption {
  const _ToggleOption({
    required this.id,
    required this.label,
    this.helper,
    required this.defaultValue,
  });

  final String id;
  final String label;
  final String? helper;
  final bool defaultValue;
}

class _ConfigTopNav extends StatelessWidget {
  const _ConfigTopNav({required this.onDocumentation});

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
              'Configuration',
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
  const _InfoPanel({required this.isCompact, required this.stack});

  final bool isCompact;
  final StackDefinition stack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTag(stackName: stack.name),
        const SizedBox(height: 18),
        Text(
          'Configurer ${stack.name}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.w700,
            color: CurrentTheme.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stack.description,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: CurrentTheme.inkSoft,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),
        _SummaryCard(stack: stack),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _InfoChip(icon: Icons.tune, label: 'Options contrôlées'),
            _InfoChip(icon: Icons.rule_folder, label: 'Structure stable'),
            _InfoChip(icon: Icons.shield_outlined, label: 'Erreurs évitées'),
          ],
        ),
      ],
    );
  }
}

class _StepTag extends StatelessWidget {
  const _StepTag({required this.stackName});

  final String stackName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CurrentTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Étape 3/5 · $stackName',
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
  const _SummaryCard({required this.stack});

  final StackDefinition stack;

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
              'Stack sélectionnée : ${stack.name}. \n'
              'Les options ci-contre personnalisent la génération.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                color: CurrentTheme.inkSoft,
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

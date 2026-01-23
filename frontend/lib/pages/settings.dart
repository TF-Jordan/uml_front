import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constantes/app_themes.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService.instance;
  final _outputDirController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _showApiKey = false;
  bool _isLoading = true;
  String _selectedTheme = 'light';
  String _selectedLocale = 'fr';
  String _selectedProvider = 'claude';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.initialize();
    setState(() {
      _selectedTheme = _settings.currentTheme;
      _selectedLocale = _settings.currentLocale;
      _selectedProvider = _settings.aiProvider;
      _outputDirController.text = _settings.defaultOutputDir;

      final apiKey = _settings.getApiKey(_selectedProvider);
      if (apiKey != null) {
        _apiKeyController.text = apiKey;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _outputDirController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  AppThemeData get _currentTheme => AppThemes.getById(_selectedTheme);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 900;
    final theme = _currentTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.sand,
        body: Center(
          child: CircularProgressIndicator(color: theme.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.sand,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.sand,
                  theme.cloud,
                  theme.sandDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Grid overlay
          Positioned.fill(child: _GridOverlay(theme: theme)),
          // Glowing orbs
          Positioned(
            right: -100,
            top: -50,
            child: _GlowingOrb(
              size: 200,
              color: theme.accent.withOpacity(0.15),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 100,
            child: _GlowingOrb(
              size: 180,
              color: theme.teal.withOpacity(0.12),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 20 : 60,
                32,
                isCompact ? 20 : 60,
                60,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme, isCompact),
                      const SizedBox(height: 40),
                      _buildAppearanceSection(theme, isCompact),
                      const SizedBox(height: 32),
                      _buildGenerationSection(theme, isCompact),
                      const SizedBox(height: 32),
                      _buildAiSection(theme, isCompact),
                      const SizedBox(height: 32),
                      _buildAboutSection(theme, isCompact),
                      const SizedBox(height: 40),
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

  Widget _buildHeader(AppThemeData theme, bool isCompact) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: theme.ink),
          style: IconButton.styleFrom(
            backgroundColor: theme.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isCompact ? 28 : 36,
                  fontWeight: FontWeight.w700,
                  color: theme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsSubtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: theme.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ APPARENCE ============

  Widget _buildAppearanceSection(AppThemeData theme, bool isCompact) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      theme: theme,
      icon: Icons.palette_outlined,
      title: l10n.appearanceSection,
      subtitle: l10n.appearanceDescription,
      children: [
        // Langue
        _SettingsTile(
          theme: theme,
          icon: Icons.language_rounded,
          title: l10n.languageLabel,
          subtitle: l10n.languageDescription,
          trailing: _buildLanguageSelector(theme),
        ),
        const SizedBox(height: 16),
        // Thème
        _SettingsTile(
          theme: theme,
          icon: Icons.brush_rounded,
          title: l10n.themeLabel,
          subtitle: l10n.themeDescription,
          trailing: null,
        ),
        const SizedBox(height: 16),
        _buildThemeGrid(theme),
      ],
    );
  }

  Widget _buildLanguageSelector(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocale,
          icon: Icon(Icons.expand_more, color: theme.inkMuted),
          dropdownColor: theme.surface,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.ink,
          ),
          items: [
            DropdownMenuItem(
              value: 'fr',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇫🇷', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Français'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇬🇧', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('English'),
                ],
              ),
            ),
          ],
          onChanged: (value) async {
            if (value != null) {
              setState(() => _selectedLocale = value);
              await _settings.setLocale(value);
              _showSavedSnackbar();
            }
          },
        ),
      ),
    );
  }

  Widget _buildThemeGrid(AppThemeData currentTheme) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      physics: const NeverScrollableScrollPhysics(),
      children: AppThemes.all.map((theme) {
        final isSelected = _selectedTheme == theme.id;
        return _ThemeCard(
          theme: theme,
          currentTheme: currentTheme,
          isSelected: isSelected,
          onTap: () async {
            setState(() => _selectedTheme = theme.id);
            await _settings.setTheme(theme.id);
            _showSavedSnackbar();
          },
        );
      }).toList(),
    );
  }

  // ============ GENERATION ============

  Widget _buildGenerationSection(AppThemeData theme, bool isCompact) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      theme: theme,
      icon: Icons.folder_outlined,
      title: l10n.generationSection,
      subtitle: l10n.generationDescription,
      children: [
        _SettingsTile(
          theme: theme,
          icon: Icons.drive_folder_upload_rounded,
          title: l10n.outputDirLabel,
          subtitle: l10n.outputDirDescription,
          trailing: null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _outputDirController,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: theme.ink,
                ),
                decoration: InputDecoration(
                  hintText: l10n.outputDirPlaceholder,
                  hintStyle: TextStyle(color: theme.inkMuted),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) async {
                  await _settings.setDefaultOutputDir(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _pickOutputDirectory,
              icon: const Icon(Icons.folder_open, size: 20),
              label: Text(l10n.selectFolder),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickOutputDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _outputDirController.text = result);
      await _settings.setDefaultOutputDir(result);
      _showSavedSnackbar();
    }
  }

  // ============ AI CONFIGURATION ============

  Widget _buildAiSection(AppThemeData theme, bool isCompact) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      theme: theme,
      icon: Icons.auto_awesome_outlined,
      title: l10n.aiSection,
      subtitle: l10n.aiDescription,
      children: [
        // Provider selector
        _SettingsTile(
          theme: theme,
          icon: Icons.smart_toy_outlined,
          title: l10n.aiProviderLabel,
          subtitle: l10n.aiProviderDescription,
          trailing: _buildProviderSelector(theme),
        ),
        const SizedBox(height: 20),
        // API Key
        _SettingsTile(
          theme: theme,
          icon: Icons.key_rounded,
          title: l10n.apiKeyLabel,
          subtitle: _settings.hasCurrentApiKey
              ? l10n.apiKeySaved
              : l10n.apiKeyNotSet,
          trailing: _buildApiKeyStatus(theme),
        ),
        const SizedBox(height: 12),
        _buildApiKeyInput(theme),
      ],
    );
  }

  Widget _buildProviderSelector(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvider,
          icon: Icon(Icons.expand_more, color: theme.inkMuted),
          dropdownColor: theme.surface,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.ink,
          ),
          items: [
            DropdownMenuItem(
              value: 'claude',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97757),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('C', style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Claude (Anthropic)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'gemini',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('G', style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Gemini (Google)'),
                ],
              ),
            ),
          ],
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                _selectedProvider = value;
                final apiKey = _settings.getApiKey(value);
                _apiKeyController.text = apiKey ?? '';
              });
              await _settings.setAiProvider(value);
              _showSavedSnackbar();
            }
          },
        ),
      ),
    );
  }

  Widget _buildApiKeyStatus(AppThemeData theme) {
    final hasKey = _settings.getApiKey(_selectedProvider)?.isNotEmpty ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasKey
            ? theme.success.withOpacity(0.15)
            : theme.inkMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasKey ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: hasKey ? theme.success : theme.inkMuted,
          ),
          const SizedBox(width: 6),
          Text(
            hasKey ? 'Configurée' : 'Non configurée',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hasKey ? theme.success : theme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInput(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _apiKeyController,
            obscureText: !_showApiKey,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: theme.ink,
            ),
            decoration: InputDecoration(
              hintText: l10n.apiKeyPlaceholder,
              hintStyle: TextStyle(color: theme.inkMuted),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showApiKey ? Icons.visibility_off : Icons.visibility,
                  color: theme.inkMuted,
                ),
                onPressed: () => setState(() => _showApiKey = !_showApiKey),
              ),
            ),
            onChanged: (value) async {
              await _settings.setApiKey(_selectedProvider, value);
            },
          ),
        ),
        const SizedBox(width: 12),
        if (_apiKeyController.text.isNotEmpty)
          IconButton(
            onPressed: () async {
              setState(() => _apiKeyController.clear());
              await _settings.deleteApiKey(_selectedProvider);
              _showSavedSnackbar();
            },
            icon: Icon(Icons.delete_outline, color: theme.accentDeep),
            style: IconButton.styleFrom(
              backgroundColor: theme.accentDeep.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
      ],
    );
  }

  // ============ ABOUT ============

  Widget _buildAboutSection(AppThemeData theme, bool isCompact) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      theme: theme,
      icon: Icons.info_outline_rounded,
      title: l10n.aboutSection,
      subtitle: l10n.aboutDescription,
      children: [
        _SettingsTile(
          theme: theme,
          icon: Icons.verified_outlined,
          title: l10n.versionLabel,
          subtitle: 'UML2Code v1.0.0',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Stable',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AboutButton(
                theme: theme,
                icon: Icons.menu_book_rounded,
                label: l10n.documentationLink,
                onTap: () => _launchUrl('https://github.com/TF-Jordan/uml_front'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AboutButton(
                theme: theme,
                icon: Icons.code_rounded,
                label: 'GitHub',
                onTap: () => _launchUrl('https://github.com/TF-Jordan/uml_front'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSavedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _currentTheme.success, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedLocale == 'fr' ? 'Paramètres enregistrés' : 'Settings saved',
              style: GoogleFonts.spaceGrotesk(
                color: _currentTheme.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: _currentTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _currentTheme.border),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ============ COMPOSANTS RÉUTILISABLES ============

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final AppThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: theme.accent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: theme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final AppThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.inkSoft, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.ink,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: theme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.currentTheme,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeData theme;
  final AppThemeData currentTheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? currentTheme.accent : theme.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentTheme.accent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Preview colors
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [theme.sand, theme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.border),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(theme.icon, size: 18, color: currentTheme.ink),
                      const SizedBox(width: 8),
                      Text(
                        theme.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: currentTheme.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.nameEn,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: currentTheme.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.accent, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.ink,
              ),
            ),
          ],
        ),
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
            color: color.withOpacity(0.4),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay({required this.theme});

  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(gridColor: theme.grid),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.gridColor});

  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1;

    const step = 120.0;
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

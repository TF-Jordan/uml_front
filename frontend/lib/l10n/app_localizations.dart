import 'package:flutter/material.dart';

/// Système d'internationalisation pour l'application
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  // ============ TRADUCTIONS ============

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      // Général
      'appName': 'UML2Code',
      'settings': 'Paramètres',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'back': 'Retour',
      'next': 'Suivant',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'warning': 'Attention',

      // Navigation / Breadcrumb
      'overview': 'Vue d\'ensemble',
      'importUml': 'Import UML',
      'stack': 'Stack',
      'configuration': 'Configuration',
      'review': 'Revue',
      'generation': 'Génération',

      // Page d'accueil
      'heroTitle': 'Transformez vos diagrammes UML',
      'heroSubtitle': 'en un projet prêt à l\'emploi.',
      'heroDescription': 'Importez vos diagrammes, mettez-les en ordre et obtenez une base de projet propre.',
      'getStarted': 'Commencer',
      'documentation': 'Documentation',

      // Settings - Sections
      'settingsTitle': 'Paramètres',
      'settingsSubtitle': 'Personnalisez votre expérience UML2Code',
      'appearanceSection': 'Apparence',
      'appearanceDescription': 'Personnalisez l\'affichage de l\'application',
      'languageLabel': 'Langue',
      'languageDescription': 'Choisissez la langue de l\'interface',
      'themeLabel': 'Thème',
      'themeDescription': 'Sélectionnez le thème visuel',
      'generationSection': 'Génération',
      'generationDescription': 'Paramètres de génération de projet',
      'outputDirLabel': 'Dossier de sortie par défaut',
      'outputDirDescription': 'Chemin où les projets seront générés',
      'outputDirPlaceholder': 'Ex: /home/user/projects',
      'selectFolder': 'Parcourir',
      'aiSection': 'Intelligence Artificielle',
      'aiDescription': 'Configuration de l\'assistant IA',
      'aiProviderLabel': 'Fournisseur IA',
      'aiProviderDescription': 'Choisissez votre fournisseur d\'IA préféré',
      'apiKeyLabel': 'Clé API',
      'apiKeyDescription': 'Votre clé API pour le fournisseur sélectionné',
      'apiKeyPlaceholder': 'Entrez votre clé API...',
      'apiKeyHidden': '••••••••••••••••',
      'apiKeySaved': 'Clé API enregistrée',
      'apiKeyNotSet': 'Non configurée',
      'showApiKey': 'Afficher',
      'hideApiKey': 'Masquer',
      'clearApiKey': 'Effacer',
      'aboutSection': 'À propos',
      'aboutDescription': 'Informations sur l\'application',
      'versionLabel': 'Version',
      'documentationLink': 'Documentation',
      'githubLink': 'GitHub',
      'checkUpdates': 'Vérifier les mises à jour',
      'noUpdates': 'Vous êtes à jour !',
      'updateAvailable': 'Mise à jour disponible',

      // Thèmes
      'themeLight': 'Clair',
      'themeDark': 'Sombre',
      'themeOcean': 'Océan',
      'themeNebula': 'Nébuleuse',
      'themeSystem': 'Système',

      // Langues
      'langFrench': 'Français',
      'langEnglish': 'English',

      // AI Providers
      'providerClaude': 'Claude (Anthropic)',
      'providerGemini': 'Gemini (Google)',

      // Messages
      'settingsSaved': 'Paramètres enregistrés',
      'apiKeyRequired': 'Clé API requise pour utiliser l\'assistant IA',
      'invalidApiKey': 'Clé API invalide',
      'folderSelected': 'Dossier sélectionné',
      'folderNotSelected': 'Aucun dossier sélectionné',

      // Génération
      'startGeneration': 'Démarrer',
      'generating': 'Génération en cours...',
      'generationComplete': 'Génération terminée',
      'generationFailed': 'Échec de la génération',
      'openFolder': 'Ouvrir le dossier',
      'newProject': 'Nouveau projet',
    },
    'en': {
      // General
      'appName': 'UML2Code',
      'settings': 'Settings',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',

      // Navigation / Breadcrumb
      'overview': 'Overview',
      'importUml': 'Import UML',
      'stack': 'Stack',
      'configuration': 'Configuration',
      'review': 'Review',
      'generation': 'Generation',

      // Home page
      'heroTitle': 'Transform your UML diagrams',
      'heroSubtitle': 'into a ready-to-use project.',
      'heroDescription': 'Import your diagrams, organize them and get a clean project base.',
      'getStarted': 'Get Started',
      'documentation': 'Documentation',

      // Settings - Sections
      'settingsTitle': 'Settings',
      'settingsSubtitle': 'Customize your UML2Code experience',
      'appearanceSection': 'Appearance',
      'appearanceDescription': 'Customize the application display',
      'languageLabel': 'Language',
      'languageDescription': 'Choose the interface language',
      'themeLabel': 'Theme',
      'themeDescription': 'Select the visual theme',
      'generationSection': 'Generation',
      'generationDescription': 'Project generation settings',
      'outputDirLabel': 'Default output folder',
      'outputDirDescription': 'Path where projects will be generated',
      'outputDirPlaceholder': 'E.g.: /home/user/projects',
      'selectFolder': 'Browse',
      'aiSection': 'Artificial Intelligence',
      'aiDescription': 'AI assistant configuration',
      'aiProviderLabel': 'AI Provider',
      'aiProviderDescription': 'Choose your preferred AI provider',
      'apiKeyLabel': 'API Key',
      'apiKeyDescription': 'Your API key for the selected provider',
      'apiKeyPlaceholder': 'Enter your API key...',
      'apiKeyHidden': '••••••••••••••••',
      'apiKeySaved': 'API key saved',
      'apiKeyNotSet': 'Not configured',
      'showApiKey': 'Show',
      'hideApiKey': 'Hide',
      'clearApiKey': 'Clear',
      'aboutSection': 'About',
      'aboutDescription': 'Application information',
      'versionLabel': 'Version',
      'documentationLink': 'Documentation',
      'githubLink': 'GitHub',
      'checkUpdates': 'Check for updates',
      'noUpdates': 'You\'re up to date!',
      'updateAvailable': 'Update available',

      // Themes
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeOcean': 'Ocean',
      'themeNebula': 'Nebula',
      'themeSystem': 'System',

      // Languages
      'langFrench': 'Français',
      'langEnglish': 'English',

      // AI Providers
      'providerClaude': 'Claude (Anthropic)',
      'providerGemini': 'Gemini (Google)',

      // Messages
      'settingsSaved': 'Settings saved',
      'apiKeyRequired': 'API key required to use the AI assistant',
      'invalidApiKey': 'Invalid API key',
      'folderSelected': 'Folder selected',
      'folderNotSelected': 'No folder selected',

      // Generation
      'startGeneration': 'Start',
      'generating': 'Generating...',
      'generationComplete': 'Generation complete',
      'generationFailed': 'Generation failed',
      'openFolder': 'Open folder',
      'newProject': 'New project',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }

  // Raccourcis pratiques
  String get appName => get('appName');
  String get settings => get('settings');
  String get save => get('save');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get close => get('close');
  String get back => get('back');
  String get next => get('next');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');

  // Navigation
  String get overview => get('overview');
  String get importUml => get('importUml');
  String get stack => get('stack');
  String get configuration => get('configuration');
  String get review => get('review');
  String get generation => get('generation');

  // Settings
  String get settingsTitle => get('settingsTitle');
  String get settingsSubtitle => get('settingsSubtitle');
  String get appearanceSection => get('appearanceSection');
  String get appearanceDescription => get('appearanceDescription');
  String get languageLabel => get('languageLabel');
  String get languageDescription => get('languageDescription');
  String get themeLabel => get('themeLabel');
  String get themeDescription => get('themeDescription');
  String get generationSection => get('generationSection');
  String get generationDescription => get('generationDescription');
  String get outputDirLabel => get('outputDirLabel');
  String get outputDirDescription => get('outputDirDescription');
  String get outputDirPlaceholder => get('outputDirPlaceholder');
  String get selectFolder => get('selectFolder');
  String get aiSection => get('aiSection');
  String get aiDescription => get('aiDescription');
  String get aiProviderLabel => get('aiProviderLabel');
  String get aiProviderDescription => get('aiProviderDescription');
  String get apiKeyLabel => get('apiKeyLabel');
  String get apiKeyDescription => get('apiKeyDescription');
  String get apiKeyPlaceholder => get('apiKeyPlaceholder');
  String get apiKeyHidden => get('apiKeyHidden');
  String get apiKeySaved => get('apiKeySaved');
  String get apiKeyNotSet => get('apiKeyNotSet');
  String get showApiKey => get('showApiKey');
  String get hideApiKey => get('hideApiKey');
  String get clearApiKey => get('clearApiKey');
  String get aboutSection => get('aboutSection');
  String get aboutDescription => get('aboutDescription');
  String get versionLabel => get('versionLabel');
  String get documentationLink => get('documentationLink');
  String get githubLink => get('githubLink');
  String get checkUpdates => get('checkUpdates');

  // Themes
  String get themeLight => get('themeLight');
  String get themeDark => get('themeDark');
  String get themeOcean => get('themeOcean');
  String get themeNebula => get('themeNebula');
  String get themeSystem => get('themeSystem');

  // Languages
  String get langFrench => get('langFrench');
  String get langEnglish => get('langEnglish');

  // Providers
  String get providerClaude => get('providerClaude');
  String get providerGemini => get('providerGemini');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

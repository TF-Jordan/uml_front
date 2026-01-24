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
      'or': 'ou',
      'and': 'et',

      // Navigation / Breadcrumb
      'overview': 'Vue d\'ensemble',
      'importUml': 'Import UML',
      'stack': 'Stack',
      'configuration': 'Configuration',
      'review': 'Revue',
      'generation': 'Génération',

      // Page d'accueil (Overview)
      'heroTitle': 'Transformez vos diagrammes UML',
      'heroSubtitle': 'en un projet prêt à l\'emploi.',
      'heroDescription': 'Importez vos diagrammes, mettez-les en ordre et obtenez une base de projet propre.',
      'heroDescriptionFull': 'Importez vos diagrammes, mettez-les en ordre et obtenez une base de projet propre.',
      'heroLocalFirst': 'Tout se fait sur votre ordinateur',
      'heroLocalDesc': ', avec une partie en ligne optionnelle.',
      'getStarted': 'Commencer',
      'documentation': 'Documentation',
      'availableStacks': 'Stacks disponibles',
      'chooseStack': 'Choisissez votre stack technologique',

      // Upload page (page1)
      'step1Title': 'Étape 1/5 · import',
      'importYourDiagrams': 'Importez vos diagrammes',
      'importDescription': 'Glissez-déposez ou parcourez pour sélectionner vos fichiers UML.',
      'classDiagram': 'Diagramme de classes',
      'classDiagramRequired': 'Requis',
      'classDiagramDesc': 'Format PlantUML (.puml) ou image (.png, .jpg)',
      'sequenceDiagram': 'Diagramme de séquence',
      'sequenceDiagramOptional': 'Optionnel',
      'sequenceDiagramDesc': 'Permet l\'intégration IA pour les méthodes',
      'dropFileHere': 'Glissez un fichier ici',
      'browseFiles': 'Parcourir',
      'fileSelected': 'Fichier sélectionné',
      'removeFile': 'Retirer',
      'continueToStack': 'Continuer vers Stack',
      'selectClassDiagram': 'Veuillez sélectionner un diagramme de classes',

      // Language selection page
      'step2Title': 'Étape 2/5 · stack',
      'chooseYourStack': 'Choisissez votre stack',
      'stackDescription': 'Sélectionnez la technologie backend pour votre projet.',
      'recommended': 'Recommandé',
      'popular': 'Populaire',

      // Stack configuration page
      'step3Title': 'Étape 3/5 · configuration',
      'configureProject': 'Configurez votre projet',
      'configureDescription': 'Personnalisez les paramètres de génération.',
      'projectSettings': 'Paramètres du projet',
      'projectName': 'Nom du projet',
      'projectNameHint': 'mon-projet',
      'packageName': 'Nom du package',
      'packageNameHint': 'com.example.projet',
      'outputDirectory': 'Dossier de sortie',
      'outputDirectoryHint': 'output',
      'stackOptions': 'Options du stack',
      'aiAssistant': 'Assistant IA',
      'aiAssistantDesc': 'Utilisez l\'IA pour implémenter les méthodes',
      'enableAi': 'Activer l\'assistant IA',
      'aiProvider': 'Fournisseur',
      'apiKey': 'Clé API',
      'apiKeyHint': 'Entrez votre clé API...',
      'rememberKey': 'Mémoriser la clé',
      'requiresSequence': 'Nécessite un diagramme de séquence',
      'continueToReview': 'Continuer vers Revue',
      'projectNameRequired': 'Veuillez entrer un nom de projet',
      'apiKeyRequiredForAi': 'Clé API requise pour l\'assistant IA',

      // Review page
      'step4Title': 'Étape 4/5 · revue',
      'reviewConfiguration': 'Revue de la configuration',
      'reviewDescription': 'Vérifiez les paramètres avant la génération.',
      'projectSummary': 'Résumé du projet',
      'inputFiles': 'Fichiers d\'entrée',
      'selectedOptions': 'Options choisies',
      'enabledModules': 'Modules activés',
      'noModulesEnabled': 'Aucun module activé.',
      'noOptionsSelected': 'Aucune option spécifique sélectionnée.',
      'aiConfiguration': 'Configuration IA',
      'aiEnabled': 'Activée',
      'aiDisabled': 'Désactivée',
      'keyProvided': 'Clé renseignée',
      'keyMissing': 'Clé manquante',
      'startGeneration': 'Démarrer la génération',

      // Generation page
      'step5Title': 'Étape 5/5 · génération',
      'generateProject': 'Générer',
      'generationDescription': 'Toutes les options sont prêtes. Lancez la génération pour obtenir une structure de projet complète et exploitable immédiatement.',
      'launchGeneration': 'Lancer la génération',
      'verifyAndStart': 'Vérifiez le résumé, puis démarrez la création du projet.',
      'generating': 'Génération en cours...',
      'generationComplete': 'Génération terminée',
      'generationFailed': 'Échec de la génération',
      'projectGenerated': 'Projet généré avec succès',
      'openFolder': 'Ouvrir',
      'newProject': 'Nouveau',
      'start': 'Démarrer',
      'history': 'Historique',
      'preparing': 'Préparation…',
      'instantFeedback': 'Feedback instantané',
      'standardStructure': 'Structure standard',
      'errorsAvoided': 'Erreurs évitées',

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
      'configured': 'Configurée',
      'notConfigured': 'Non configurée',

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

      // Breadcrumb dialog
      'returnTo': 'Revenir à',
      'abandonChanges': 'Cela va abandonner les modifications depuis',
      'continueQuestion': 'Continuer ?',
      'returnAction': 'Revenir',

      // Overview page extras
      'desktopSuite': 'Suite de bureau',
      'transformYour': 'Transformez vos',
      'umlDiagrams': 'diagrammes UML',
      'intoReadyProject': 'en un projet prêt à l\'emploi.',
      'importAction': 'Importez',
      'yourDiagrams': 'vos diagrammes,',
      'organizeAction': 'mettez-les en ordre',
      'andGetA': 'et obtenez une',
      'cleanProjectBase': 'base de projet propre',
      'everythingDone': 'Tout se fait',
      'onYourComputer': 'sur votre ordinateur',
      'withOnlinePart': ', avec une partie en ligne optionnelle.',
      'allStaysLocal': 'Tout reste local',
      'coreWorkLocal': 'Le cœur du travail reste sur votre ordinateur.',
      'clearHistory': 'Historique clair',
      'choicesKept': 'Vos choix sont conservés pour garder une trace simple.',
      'multipleChoices': 'Plusieurs choix',
      'chooseTech': 'Choisissez une technologie adaptée à votre projet.',
      'howItWorks': 'Comment ça marche',
      'threeSteps': 'Trois étapes simples et faciles à suivre.',
      'importSchemas': 'Importer vos schémas',
      'diagramsBecomeClear': 'Vos diagrammes deviennent une base claire et lisible.',
      'organizeStep': 'Mettre en ordre',
      'infoOrganized': 'Les informations sont organisées pour éviter les erreurs.',
      'createProject': 'Créer le projet',
      'getReadyBase': 'Vous obtenez une base prête à personnaliser.',
      'languagesSection': 'Langages',
      'whatWePrepared': 'Description de ce que nous avons préparé pour vous.',

      // Upload page extras
      'dropYourUmlFiles': 'Déposez vos fichiers UML',
      'oneFileMinTwoMax': '1 fichier minimum, 2 maximum. Classes requises, séquence optionnelle.',
      'importedFiles': 'Fichiers importés',
      'continueBtn': 'Continuer',
      'dragDiagramsHere': 'Glissez vos diagrammes ici',
      'supportedFormats': 'Formats supportés : .drawio (1 à 2 fichiers)',
      'chooseFile': 'Choisir un fichier',
      'importInProgress': 'Import en cours...',
      'addFilesToContinue': 'Ajoutez entre 1 et 2 fichiers pour activer la suite.',
      'maximumReached': 'Maximum atteint.',
      'canAddMore': 'Vous pouvez encore ajouter un fichier si besoin.',
      'sequenceDiagramQuestion': 'Diagramme de séquence ?',
      'wantToAddSequence': 'Souhaitez-vous ajouter un diagramme de séquence pour enrichir la génération ?',
      'no': 'Non',
      'yes': 'Oui',
      'filesImportedCount': 'fichiers importés',
      'importYourUmlDiagrams': 'Importer vos diagrammes UML',
      'addClassFirst': 'Ajoutez votre diagramme de classes en premier pour démarrer. Vous pouvez ensuite enrichir la génération avec un diagramme de séquence pour couvrir les cas d\'usage.',
      'beforeStarting': 'Avant de commencer',
      'cleanClassDiagram': 'Diagramme de classes propre et complet',
      'normalizedNames': 'Nom des classes normalisé',
      'explicitRelations': 'Relations UML explicites',
      'optionalSequences': 'Optionnel : séquences pour les cas clés',
      'classesRequired': 'Classes requises',
      'sequenceOptional': 'Séquence optionnelle',
      'localAndSecure': 'Local & sécurisé',
      'maxFilesAllowed': 'Maximum %d fichiers autorisés.',
      'addAtLeastOneFile': 'Ajoutez au moins un fichier UML.',

      // Language Selection extras
      'languageChoice': 'Choix du langage',
      'selectTargetForGeneration': 'Sélectionnez une cible pour générer le squelette et les conventions de projet.',
      'chooseTheStack': 'Choisir la Stack',
      'stackDetermines': 'La stack sélectionnée détermine la structure des dossiers, les conventions de code, et les frameworks générés.',
      'noStackSelected': 'aucune stack sélectionnée',
      'stackSelected': 'sélectionné',
      'stackChosenContinue': 'Stack choisie : %s. Vous pouvez continuer.',
      'selectStackToActivate': 'Sélectionnez une stack pour activer la génération.',
      'cleanStructure': 'Structure propre',
      'generatedConventions': 'Conventions générées',
      'adaptedSettings': 'Paramètres adaptés',

      // Stack Configuration extras
      'configurationOf': 'Configuration',
      'fillEssentialParams': 'Renseignez les paramètres essentiels pour générer un projet cohérent.',
      'projectNameRequiredHint': 'Obligatoire (ex: ecommerce_api)',
      'namespacePackage': 'Namespace / Package',
      'namespaceOptionalHint': 'Optionnel (ex: com.company.app)',
      'outputDirectoryField': 'Répertoire de sortie',
      'outputDefault': 'Par défaut: output',
      'generationOptions': 'Options de génération',
      'complementaryModules': 'Modules complémentaires',
      'enableAiAssistant': 'Activer l\'assistant IA',
      'addIntelligentSteps': 'Ajoute des étapes intelligentes après le diagramme de séquence.',
      'addSequenceForAi': 'Ajoutez un diagramme de séquence pour activer l\'IA.',
      'keyStaysLocal': 'La clé reste locale et n\'est pas affichée.',
      'rememberKeyOnDevice': 'Se souvenir de la clé sur cet appareil.',
      'continueToReviewBtn': 'Continuer vers la revue',
      'requiredFieldsChecked': 'Les champs obligatoires sont contrôlés pour éviter les erreurs.',
      'configureStackName': 'Configurer',
      'stackSelectedLabel': 'Stack sélectionnée : %s. Les options ci-contre personnalisent la génération.',
      'controlledOptions': 'Options contrôlées',
      'stableStructure': 'Structure stable',
      'aiNotAvailable': 'Assistant IA non disponible pour cette technologie.',

      // Review extras
      'checkBeforeGeneration': 'Vérifiez chaque choix avant de lancer la génération.',
      'confirmAndGenerate': 'Confirmer et générer',
      'modifyConfiguration': 'Modifier la configuration',
      'finalReview': 'Revue finale',
      'confirmStackVersions': 'Confirmez la stack, les versions et les modules. Une fois validé, la génération peut démarrer.',
      'quickCheck': 'Contrôle rapide',
      'projectLabel': 'Projet',
      'packageLabel': 'Package',
      'outputLabel': 'Sortie',
      'projectFollowConventions': 'Projet "%s" → %s. La génération suivra les conventions %s.',
      'stateLabel': 'État',
      'providerLabel': 'Fournisseur',
      'notRequired': 'Non requis',

      // Generation extras
      'launchTheGeneration': 'Lancer la génération',
      'generateStackName': 'Générer',
      'allOptionsReady': 'Toutes les options sont prêtes. Lancez la génération pour obtenir une structure de projet complète et exploitable immédiatement.',
      'startBtn': 'Démarrer',
      'newBtn': 'Nouveau',
      'preparingConfig': 'Préparation de la configuration',
      'configReady': 'Configuration prête',
      'preparingDocker': 'Préparation de l\'image Docker',
      'launchingGenerator': 'Lancement du générateur',
      'generationFinished': 'Génération terminée',
      'folderNotFound': 'Dossier introuvable',
      'cannotOpenFolder': 'Impossible d\'ouvrir le dossier',
      'historyLabel': 'Historique',
      'openBtn': 'Ouvrir',
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
      'or': 'or',
      'and': 'and',

      // Navigation / Breadcrumb
      'overview': 'Overview',
      'importUml': 'Import UML',
      'stack': 'Stack',
      'configuration': 'Configuration',
      'review': 'Review',
      'generation': 'Generation',

      // Home page (Overview)
      'heroTitle': 'Transform your UML diagrams',
      'heroSubtitle': 'into a ready-to-use project.',
      'heroDescription': 'Import your diagrams, organize them and get a clean project base.',
      'heroDescriptionFull': 'Import your diagrams, organize them and get a clean project base.',
      'heroLocalFirst': 'Everything runs on your computer',
      'heroLocalDesc': ', with an optional online part.',
      'getStarted': 'Get Started',
      'documentation': 'Documentation',
      'availableStacks': 'Available Stacks',
      'chooseStack': 'Choose your technology stack',

      // Upload page (page1)
      'step1Title': 'Step 1/5 · import',
      'importYourDiagrams': 'Import your diagrams',
      'importDescription': 'Drag and drop or browse to select your UML files.',
      'classDiagram': 'Class Diagram',
      'classDiagramRequired': 'Required',
      'classDiagramDesc': 'PlantUML format (.puml) or image (.png, .jpg)',
      'sequenceDiagram': 'Sequence Diagram',
      'sequenceDiagramOptional': 'Optional',
      'sequenceDiagramDesc': 'Enables AI integration for methods',
      'dropFileHere': 'Drop a file here',
      'browseFiles': 'Browse',
      'fileSelected': 'File selected',
      'removeFile': 'Remove',
      'continueToStack': 'Continue to Stack',
      'selectClassDiagram': 'Please select a class diagram',

      // Language selection page
      'step2Title': 'Step 2/5 · stack',
      'chooseYourStack': 'Choose your stack',
      'stackDescription': 'Select the backend technology for your project.',
      'recommended': 'Recommended',
      'popular': 'Popular',

      // Stack configuration page
      'step3Title': 'Step 3/5 · configuration',
      'configureProject': 'Configure your project',
      'configureDescription': 'Customize the generation settings.',
      'projectSettings': 'Project Settings',
      'projectName': 'Project name',
      'projectNameHint': 'my-project',
      'packageName': 'Package name',
      'packageNameHint': 'com.example.project',
      'outputDirectory': 'Output directory',
      'outputDirectoryHint': 'output',
      'stackOptions': 'Stack options',
      'aiAssistant': 'AI Assistant',
      'aiAssistantDesc': 'Use AI to implement methods',
      'enableAi': 'Enable AI assistant',
      'aiProvider': 'Provider',
      'apiKey': 'API Key',
      'apiKeyHint': 'Enter your API key...',
      'rememberKey': 'Remember key',
      'requiresSequence': 'Requires a sequence diagram',
      'continueToReview': 'Continue to Review',
      'projectNameRequired': 'Please enter a project name',
      'apiKeyRequiredForAi': 'API key required for AI assistant',

      // Review page
      'step4Title': 'Step 4/5 · review',
      'reviewConfiguration': 'Configuration Review',
      'reviewDescription': 'Check the settings before generation.',
      'projectSummary': 'Project Summary',
      'inputFiles': 'Input Files',
      'selectedOptions': 'Selected Options',
      'enabledModules': 'Enabled Modules',
      'noModulesEnabled': 'No modules enabled.',
      'noOptionsSelected': 'No specific options selected.',
      'aiConfiguration': 'AI Configuration',
      'aiEnabled': 'Enabled',
      'aiDisabled': 'Disabled',
      'keyProvided': 'Key provided',
      'keyMissing': 'Key missing',
      'startGeneration': 'Start Generation',

      // Generation page
      'step5Title': 'Step 5/5 · generation',
      'generateProject': 'Generate',
      'generationDescription': 'All options are ready. Start the generation to get a complete and immediately usable project structure.',
      'launchGeneration': 'Launch generation',
      'verifyAndStart': 'Verify the summary, then start project creation.',
      'generating': 'Generating...',
      'generationComplete': 'Generation complete',
      'generationFailed': 'Generation failed',
      'projectGenerated': 'Project generated successfully',
      'openFolder': 'Open',
      'newProject': 'New',
      'start': 'Start',
      'history': 'History',
      'preparing': 'Preparing…',
      'instantFeedback': 'Instant feedback',
      'standardStructure': 'Standard structure',
      'errorsAvoided': 'Errors avoided',

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
      'configured': 'Configured',
      'notConfigured': 'Not configured',

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

      // Breadcrumb dialog
      'returnTo': 'Return to',
      'abandonChanges': 'This will abandon changes from',
      'continueQuestion': 'Continue?',
      'returnAction': 'Return',

      // Overview page extras
      'desktopSuite': 'Desktop Suite',
      'transformYour': 'Transform your',
      'umlDiagrams': 'UML diagrams',
      'intoReadyProject': 'into a ready-to-use project.',
      'importAction': 'Import',
      'yourDiagrams': 'your diagrams,',
      'organizeAction': 'organize them',
      'andGetA': 'and get a',
      'cleanProjectBase': 'clean project base',
      'everythingDone': 'Everything is done',
      'onYourComputer': 'on your computer',
      'withOnlinePart': ', with an optional online part.',
      'allStaysLocal': 'Everything stays local',
      'coreWorkLocal': 'The core work stays on your computer.',
      'clearHistory': 'Clear history',
      'choicesKept': 'Your choices are kept for a simple record.',
      'multipleChoices': 'Multiple choices',
      'chooseTech': 'Choose a technology suited to your project.',
      'howItWorks': 'How it works',
      'threeSteps': 'Three simple and easy steps to follow.',
      'importSchemas': 'Import your schemas',
      'diagramsBecomeClear': 'Your diagrams become a clear and readable base.',
      'organizeStep': 'Organize',
      'infoOrganized': 'Information is organized to avoid errors.',
      'createProject': 'Create the project',
      'getReadyBase': 'You get a ready base to customize.',
      'languagesSection': 'Languages',
      'whatWePrepared': 'Description of what we prepared for you.',

      // Upload page extras
      'dropYourUmlFiles': 'Drop your UML files',
      'oneFileMinTwoMax': '1 file minimum, 2 maximum. Classes required, sequence optional.',
      'importedFiles': 'Imported files',
      'continueBtn': 'Continue',
      'dragDiagramsHere': 'Drag your diagrams here',
      'supportedFormats': 'Supported formats: .drawio (1 to 2 files)',
      'chooseFile': 'Choose a file',
      'importInProgress': 'Import in progress...',
      'addFilesToContinue': 'Add between 1 and 2 files to continue.',
      'maximumReached': 'Maximum reached.',
      'canAddMore': 'You can still add a file if needed.',
      'sequenceDiagramQuestion': 'Sequence diagram?',
      'wantToAddSequence': 'Would you like to add a sequence diagram to enrich the generation?',
      'no': 'No',
      'yes': 'Yes',
      'filesImportedCount': 'files imported',
      'importYourUmlDiagrams': 'Import your UML diagrams',
      'addClassFirst': 'Add your class diagram first to start. You can then enrich the generation with a sequence diagram to cover use cases.',
      'beforeStarting': 'Before starting',
      'cleanClassDiagram': 'Clean and complete class diagram',
      'normalizedNames': 'Normalized class names',
      'explicitRelations': 'Explicit UML relations',
      'optionalSequences': 'Optional: sequences for key cases',
      'classesRequired': 'Classes required',
      'sequenceOptional': 'Sequence optional',
      'localAndSecure': 'Local & secure',
      'maxFilesAllowed': 'Maximum %d files allowed.',
      'addAtLeastOneFile': 'Add at least one UML file.',

      // Language Selection extras
      'languageChoice': 'Language choice',
      'selectTargetForGeneration': 'Select a target to generate the skeleton and project conventions.',
      'chooseTheStack': 'Choose the Stack',
      'stackDetermines': 'The selected stack determines the folder structure, code conventions, and generated frameworks.',
      'noStackSelected': 'no stack selected',
      'stackSelected': 'selected',
      'stackChosenContinue': 'Stack chosen: %s. You can continue.',
      'selectStackToActivate': 'Select a stack to activate generation.',
      'cleanStructure': 'Clean structure',
      'generatedConventions': 'Generated conventions',
      'adaptedSettings': 'Adapted settings',

      // Stack Configuration extras
      'configurationOf': 'Configuration',
      'fillEssentialParams': 'Fill in essential parameters to generate a coherent project.',
      'projectNameRequiredHint': 'Required (e.g., ecommerce_api)',
      'namespacePackage': 'Namespace / Package',
      'namespaceOptionalHint': 'Optional (e.g., com.company.app)',
      'outputDirectoryField': 'Output directory',
      'outputDefault': 'Default: output',
      'generationOptions': 'Generation options',
      'complementaryModules': 'Complementary modules',
      'enableAiAssistant': 'Enable AI assistant',
      'addIntelligentSteps': 'Adds intelligent steps after the sequence diagram.',
      'addSequenceForAi': 'Add a sequence diagram to enable AI.',
      'keyStaysLocal': 'The key stays local and is not displayed.',
      'rememberKeyOnDevice': 'Remember key on this device.',
      'continueToReviewBtn': 'Continue to review',
      'requiredFieldsChecked': 'Required fields are checked to avoid errors.',
      'configureStackName': 'Configure',
      'stackSelectedLabel': 'Stack selected: %s. The options customize the generation.',
      'controlledOptions': 'Controlled options',
      'stableStructure': 'Stable structure',
      'aiNotAvailable': 'AI Assistant not available for this technology.',

      // Review extras
      'checkBeforeGeneration': 'Check each choice before starting generation.',
      'confirmAndGenerate': 'Confirm and generate',
      'modifyConfiguration': 'Modify configuration',
      'finalReview': 'Final review',
      'confirmStackVersions': 'Confirm the stack, versions and modules. Once validated, generation can start.',
      'quickCheck': 'Quick check',
      'projectLabel': 'Project',
      'packageLabel': 'Package',
      'outputLabel': 'Output',
      'projectFollowConventions': 'Project "%s" → %s. Generation will follow %s conventions.',
      'stateLabel': 'State',
      'providerLabel': 'Provider',
      'notRequired': 'Not required',

      // Generation extras
      'launchTheGeneration': 'Launch the generation',
      'generateStackName': 'Generate',
      'allOptionsReady': 'All options are ready. Start the generation to get a complete and immediately usable project structure.',
      'startBtn': 'Start',
      'newBtn': 'New',
      'preparingConfig': 'Preparing configuration',
      'configReady': 'Configuration ready',
      'preparingDocker': 'Preparing Docker image',
      'launchingGenerator': 'Launching generator',
      'generationFinished': 'Generation finished',
      'folderNotFound': 'Folder not found',
      'cannotOpenFolder': 'Cannot open folder',
      'historyLabel': 'History',
      'openBtn': 'Open',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }

  // Raccourcis pratiques - Général
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

  // Overview
  String get heroTitle => get('heroTitle');
  String get heroSubtitle => get('heroSubtitle');
  String get heroDescription => get('heroDescription');
  String get getStarted => get('getStarted');
  String get documentation => get('documentation');

  // Upload (page1)
  String get step1Title => get('step1Title');
  String get importYourDiagrams => get('importYourDiagrams');
  String get importDescription => get('importDescription');
  String get classDiagram => get('classDiagram');
  String get classDiagramRequired => get('classDiagramRequired');
  String get classDiagramDesc => get('classDiagramDesc');
  String get sequenceDiagram => get('sequenceDiagram');
  String get sequenceDiagramOptional => get('sequenceDiagramOptional');
  String get sequenceDiagramDesc => get('sequenceDiagramDesc');
  String get dropFileHere => get('dropFileHere');
  String get browseFiles => get('browseFiles');
  String get fileSelected => get('fileSelected');
  String get removeFile => get('removeFile');
  String get continueToStack => get('continueToStack');

  // Language selection
  String get step2Title => get('step2Title');
  String get chooseYourStack => get('chooseYourStack');
  String get stackDescription => get('stackDescription');

  // Stack configuration
  String get step3Title => get('step3Title');
  String get configureProject => get('configureProject');
  String get configureDescription => get('configureDescription');
  String get projectSettings => get('projectSettings');
  String get projectName => get('projectName');
  String get projectNameHint => get('projectNameHint');
  String get packageName => get('packageName');
  String get outputDirectory => get('outputDirectory');
  String get stackOptions => get('stackOptions');
  String get aiAssistant => get('aiAssistant');
  String get enableAi => get('enableAi');
  String get aiProvider => get('aiProvider');
  String get apiKey => get('apiKey');
  String get rememberKey => get('rememberKey');
  String get continueToReview => get('continueToReview');

  // Review
  String get step4Title => get('step4Title');
  String get reviewConfiguration => get('reviewConfiguration');
  String get reviewDescription => get('reviewDescription');
  String get projectSummary => get('projectSummary');
  String get inputFiles => get('inputFiles');
  String get selectedOptions => get('selectedOptions');
  String get enabledModules => get('enabledModules');
  String get noModulesEnabled => get('noModulesEnabled');
  String get aiConfiguration => get('aiConfiguration');
  String get startGeneration => get('startGeneration');

  // Generation
  String get step5Title => get('step5Title');
  String get generateProject => get('generateProject');
  String get generationDescription => get('generationDescription');
  String get launchGeneration => get('launchGeneration');
  String get verifyAndStart => get('verifyAndStart');
  String get generating => get('generating');
  String get generationComplete => get('generationComplete');
  String get generationFailed => get('generationFailed');
  String get projectGenerated => get('projectGenerated');
  String get openFolder => get('openFolder');
  String get newProject => get('newProject');
  String get start => get('start');
  String get history => get('history');

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
  // Duplicate key removed: String get generationDescription => get('generationDescription');
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

  // Breadcrumb dialog
  String get returnTo => get('returnTo');
  String get abandonChanges => get('abandonChanges');
  String get continueQuestion => get('continueQuestion');
  String get returnAction => get('returnAction');

  // Overview extras
  String get desktopSuite => get('desktopSuite');
  String get transformYour => get('transformYour');
  String get umlDiagrams => get('umlDiagrams');
  String get intoReadyProject => get('intoReadyProject');
  String get importAction => get('importAction');
  String get yourDiagrams => get('yourDiagrams');
  String get organizeAction => get('organizeAction');
  String get andGetA => get('andGetA');
  String get cleanProjectBase => get('cleanProjectBase');
  String get everythingDone => get('everythingDone');
  String get onYourComputer => get('onYourComputer');
  String get withOnlinePart => get('withOnlinePart');
  String get allStaysLocal => get('allStaysLocal');
  String get coreWorkLocal => get('coreWorkLocal');
  String get clearHistory => get('clearHistory');
  String get choicesKept => get('choicesKept');
  String get multipleChoices => get('multipleChoices');
  String get chooseTech => get('chooseTech');
  String get howItWorks => get('howItWorks');
  String get threeSteps => get('threeSteps');
  String get importSchemas => get('importSchemas');
  String get diagramsBecomeClear => get('diagramsBecomeClear');
  String get organizeStep => get('organizeStep');
  String get infoOrganized => get('infoOrganized');
  String get createProject => get('createProject');
  String get getReadyBase => get('getReadyBase');
  String get languagesSection => get('languagesSection');
  String get whatWePrepared => get('whatWePrepared');

  // Upload extras
  String get dropYourUmlFiles => get('dropYourUmlFiles');
  String get oneFileMinTwoMax => get('oneFileMinTwoMax');
  String get importedFiles => get('importedFiles');
  String get continueBtn => get('continueBtn');
  String get dragDiagramsHere => get('dragDiagramsHere');
  String get supportedFormats => get('supportedFormats');
  String get chooseFile => get('chooseFile');
  String get importInProgress => get('importInProgress');
  String get addFilesToContinue => get('addFilesToContinue');
  String get maximumReached => get('maximumReached');
  String get canAddMore => get('canAddMore');
  String get sequenceDiagramQuestion => get('sequenceDiagramQuestion');
  String get wantToAddSequence => get('wantToAddSequence');
  String get no => get('no');
  String get yes => get('yes');
  String get filesImportedCount => get('filesImportedCount');
  String get importYourUmlDiagrams => get('importYourUmlDiagrams');
  String get addClassFirst => get('addClassFirst');
  String get beforeStarting => get('beforeStarting');
  String get cleanClassDiagram => get('cleanClassDiagram');
  String get normalizedNames => get('normalizedNames');
  String get explicitRelations => get('explicitRelations');
  String get optionalSequences => get('optionalSequences');
  String get classesRequired => get('classesRequired');
  String get sequenceOptional => get('sequenceOptional');
  String get localAndSecure => get('localAndSecure');
  String get addAtLeastOneFile => get('addAtLeastOneFile');

  // Language Selection extras
  String get languageChoice => get('languageChoice');
  String get selectTargetForGeneration => get('selectTargetForGeneration');
  String get chooseTheStack => get('chooseTheStack');
  String get stackDetermines => get('stackDetermines');
  String get noStackSelected => get('noStackSelected');
  String get stackSelected => get('stackSelected');
  String get selectStackToActivate => get('selectStackToActivate');
  String get cleanStructure => get('cleanStructure');
  String get generatedConventions => get('generatedConventions');
  String get adaptedSettings => get('adaptedSettings');

  // Stack Configuration extras
  String get configurationOf => get('configurationOf');
  String get fillEssentialParams => get('fillEssentialParams');
  String get projectNameRequiredHint => get('projectNameRequiredHint');
  String get namespacePackage => get('namespacePackage');
  String get namespaceOptionalHint => get('namespaceOptionalHint');
  String get outputDirectoryField => get('outputDirectoryField');
  String get outputDefault => get('outputDefault');
  String get generationOptions => get('generationOptions');
  String get complementaryModules => get('complementaryModules');
  String get enableAiAssistant => get('enableAiAssistant');
  String get addIntelligentSteps => get('addIntelligentSteps');
  String get addSequenceForAi => get('addSequenceForAi');
  String get keyStaysLocal => get('keyStaysLocal');
  String get rememberKeyOnDevice => get('rememberKeyOnDevice');
  String get continueToReviewBtn => get('continueToReviewBtn');
  String get requiredFieldsChecked => get('requiredFieldsChecked');
  String get configureStackName => get('configureStackName');
  String get controlledOptions => get('controlledOptions');
  String get stableStructure => get('stableStructure');
  String get aiNotAvailable => get('aiNotAvailable');
  String get errorsAvoided => get('errorsAvoided');

  // Review extras
  String get checkBeforeGeneration => get('checkBeforeGeneration');
  String get confirmAndGenerate => get('confirmAndGenerate');
  String get modifyConfiguration => get('modifyConfiguration');
  String get finalReview => get('finalReview');
  String get confirmStackVersions => get('confirmStackVersions');
  String get quickCheck => get('quickCheck');
  String get projectLabel => get('projectLabel');
  String get packageLabel => get('packageLabel');
  String get outputLabel => get('outputLabel');
  String get stateLabel => get('stateLabel');
  String get providerLabel => get('providerLabel');
  String get notRequired => get('notRequired');

  // Generation extras
  String get launchTheGeneration => get('launchTheGeneration');
  String get generateStackName => get('generateStackName');
  String get allOptionsReady => get('allOptionsReady');
  String get startBtn => get('startBtn');
  String get newBtn => get('newBtn');
  String get preparingConfig => get('preparingConfig');
  String get configReady => get('configReady');
  String get preparingDocker => get('preparingDocker');
  String get launchingGenerator => get('launchingGenerator');
  String get generationFinished => get('generationFinished');
  String get folderNotFound => get('folderNotFound');
  String get cannotOpenFolder => get('cannotOpenFolder');
  String get historyLabel => get('historyLabel');
  String get openBtn => get('openBtn');

  // Liste des breadcrumb items localisés
  List<String> get breadcrumbItems => [
    overview,
    importUml,
    stack,
    configuration,
    review,
    generation,
  ];
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

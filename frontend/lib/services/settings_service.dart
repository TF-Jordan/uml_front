import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service centralisé pour la gestion des paramètres de l'application
class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  SettingsService._();

  SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Clés de stockage
  static const String _keyTheme = 'app_theme';
  static const String _keyLocale = 'app_locale';
  static const String _keyOutputDir = 'default_output_dir';
  static const String _keyAiProvider = 'ai_provider';
  static const String _keyAiEnabled = 'ai_enabled';

  // Valeurs par défaut
  static const String defaultTheme = 'light';
  static const String defaultLocale = 'fr';
  static const String defaultProvider = 'claude';

  // État actuel
  String _currentTheme = defaultTheme;
  String _currentLocale = defaultLocale;
  String _defaultOutputDir = '';
  String _aiProvider = defaultProvider;
  bool _aiEnabled = false;
  Map<String, String> _apiKeys = {};

  // Getters
  String get currentTheme => _currentTheme;
  String get currentLocale => _currentLocale;
  String get defaultOutputDir => _defaultOutputDir;
  String get aiProvider => _aiProvider;
  bool get aiEnabled => _aiEnabled;

  /// Initialise le service (à appeler au démarrage de l'app)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currentTheme = _prefs?.getString(_keyTheme) ?? defaultTheme;
    _currentLocale = _prefs?.getString(_keyLocale) ?? defaultLocale;
    _defaultOutputDir = _prefs?.getString(_keyOutputDir) ?? '';
    _aiProvider = _prefs?.getString(_keyAiProvider) ?? defaultProvider;
    _aiEnabled = _prefs?.getBool(_keyAiEnabled) ?? false;

    // Charger les clés API de manière sécurisée
    for (final provider in ['claude', 'gemini']) {
      final key = await _secureStorage.read(key: 'ai_key_$provider');
      if (key != null && key.isNotEmpty) {
        _apiKeys[provider] = key;
      }
    }

    notifyListeners();
  }

  // ============ THEME ============

  Future<void> setTheme(String theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    await _prefs?.setString(_keyTheme, theme);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  // ============ LOCALE ============

  Future<void> setLocale(String locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    await _prefs?.setString(_keyLocale, locale);
    notifyListeners();
  }

  Locale get locale => Locale(_currentLocale);

  // ============ OUTPUT DIRECTORY ============

  Future<void> setDefaultOutputDir(String dir) async {
    if (_defaultOutputDir == dir) return;
    _defaultOutputDir = dir;
    await _prefs?.setString(_keyOutputDir, dir);
    notifyListeners();
  }

  // ============ AI CONFIGURATION ============

  Future<void> setAiProvider(String provider) async {
    if (_aiProvider == provider) return;
    _aiProvider = provider;
    await _prefs?.setString(_keyAiProvider, provider);
    notifyListeners();
  }

  Future<void> setAiEnabled(bool enabled) async {
    if (_aiEnabled == enabled) return;
    _aiEnabled = enabled;
    await _prefs?.setBool(_keyAiEnabled, enabled);
    notifyListeners();
  }

  /// Récupère la clé API pour un fournisseur donné
  String? getApiKey(String provider) {
    return _apiKeys[provider.toLowerCase()];
  }

  /// Récupère la clé API pour le fournisseur actuellement sélectionné
  String? get currentApiKey => _apiKeys[_aiProvider.toLowerCase()];

  /// Vérifie si une clé API existe pour le fournisseur actuel
  bool get hasCurrentApiKey {
    final key = currentApiKey;
    return key != null && key.trim().isNotEmpty;
  }

  /// Enregistre une clé API de manière sécurisée
  Future<void> setApiKey(String provider, String key) async {
    final providerLower = provider.toLowerCase();
    if (key.isEmpty) {
      await _secureStorage.delete(key: 'ai_key_$providerLower');
      _apiKeys.remove(providerLower);
    } else {
      await _secureStorage.write(key: 'ai_key_$providerLower', value: key);
      _apiKeys[providerLower] = key;
    }
    notifyListeners();
  }

  /// Supprime la clé API pour un fournisseur
  Future<void> deleteApiKey(String provider) async {
    await setApiKey(provider, '');
  }

  // ============ HELPERS ============

  /// Retourne le nom d'affichage du fournisseur IA
  String getProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case 'claude':
        return 'Claude (Anthropic)';
      case 'gemini':
        return 'Gemini (Google)';
      default:
        return provider;
    }
  }

  /// Retourne l'ID de variable d'environnement pour le fournisseur
  String getProviderEnvKey(String provider) {
    switch (provider.toLowerCase()) {
      case 'claude':
        return 'ANTHROPIC_API_KEY';
      case 'gemini':
        return 'GEMINI_API_KEY';
      default:
        return '${provider.toUpperCase()}_API_KEY';
    }
  }

  /// Liste des fournisseurs IA disponibles
  List<String> get availableProviders => ['claude', 'gemini'];
}

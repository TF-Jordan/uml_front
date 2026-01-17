class AiConfig {
  const AiConfig({
    required this.enabled,
    required this.provider,
    required this.apiKey,
  });

  final bool enabled;
  final String provider;
  final String apiKey;

  bool get hasKey => apiKey.trim().isNotEmpty;

  String get userKeyId {
    if (provider.toLowerCase() == 'claude') {
      return 'ANTHROPIC_API_KEY';
    }
    return 'GEMINI_API_KEY';
  }

  String get label {
    if (provider.toLowerCase() == 'claude') {
      return 'Claude';
    }
    return 'Gemini';
  }
}

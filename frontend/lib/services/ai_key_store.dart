import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiKeyStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String _keyForProvider(String provider) {
    return 'ai_key_${provider.toLowerCase()}';
  }

  static Future<String?> read(String provider) {
    return _storage.read(key: _keyForProvider(provider));
  }

  static Future<void> write(String provider, String value) {
    return _storage.write(key: _keyForProvider(provider), value: value);
  }

  static Future<void> delete(String provider) {
    return _storage.delete(key: _keyForProvider(provider));
  }
}

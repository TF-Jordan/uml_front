import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'YOUR_API_URL_HERE'; // À remplacer par votre URL

  /// Upload un fichier UML vers le backend
  Future<Map<String, dynamic>> uploadUMLFile(
      File file,
      Function(double) onProgress,
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de l\'upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Génère le code à partir des fichiers UML uploadés
  Future<Map<String, dynamic>> generateCode({
    required String language,
    required String version,
    required List<String> dependencies,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'language': language,
          'version': version,
          'dependencies': dependencies,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la génération');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class TranslationService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  Future<String> _getApiKey() async {
    final key = await _storage.read(key: 'GEMINI_API_KEY');
    if (key == null || key.isEmpty) {
      _logger.e('Gemini API key not found.');
      throw Exception('Gemini API key not configured.');
    }
    return key;
  }

  Future<Map<String, String>> translateLine(String text) async {
    final apiKey = await _getApiKey();
    final url = 'https://generativelanguage.googleapis.com/v1beta2/models/gemini-2.0-flash:generateText?key=$apiKey';

    // Prepare prompts for English and Urdu translations
    final promptEn = 'Translate the following Persian poem line into poetic English preserving meaning:\n$text';
    final promptUr = 'Translate the following Persian poem line into poetic Urdu preserving meaning:\n$text';

    try {
      // API expects prompt as an object with 'text' field
      final responseEn = await _dio.post(url, data: {'prompt': {'text': promptEn}});
      final responseUr = await _dio.post(url, data: {'prompt': {'text': promptUr}});

      final eng = (responseEn.data['candidates'][0]['content'] as String).trim();
      final ur = (responseUr.data['candidates'][0]['content'] as String).trim();

      return {'eng': eng, 'ur': ur};
    } catch (e, st) {
      _logger.e('Translation API error', e, st);
      // Fallback: return original text for both translations on error
      return {'eng': text, 'ur': text};
    }
  }
}

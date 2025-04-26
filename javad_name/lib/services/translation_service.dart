import 'package:cloud_functions/cloud_functions.dart';

class TranslationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, String>> translateLine(String text) async {
    try {
      final callable = _functions.httpsCallable('translateLine');
      final result = await callable.call(<String, dynamic>{'text': text});
      final data = result.data as Map<String, dynamic>;
      return {
        'eng': data['eng'] as String,
        'ur': data['ur'] as String,
      };
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.message}');
    }
  }
}

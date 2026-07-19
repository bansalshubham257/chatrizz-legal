import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatrizz/core/constants/api_config.dart';
import 'package:chatrizz/core/utils/logger.dart';

class AiService {
  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> generateCompletion(String prompt) async {
    try {
      final url = '${ApiConfig.groqBaseUrl}/chat/completions';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': ApiConfig.groqModel,
          'messages': [
            {'role': 'system', 'content': 'You are ChatRizz, an AI dating conversation assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 500,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          return (choices[0] as Map<String, dynamic>)['message']['content'] as String;
        }
        throw Exception('No response from AI');
      } else {
        final body = response.body;
        Logger.e('AI API error: ${response.statusCode} $body');
        String message = 'Failed to generate reply (${response.statusCode})';
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['error'] != null) {
            message += ': ${(data['error'] as Map)['message']}';
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      Logger.e('AI service error', error: e);
      rethrow;
    }
  }

  Future<bool> classifyIntent(String message) async {
    try {
      final url = '${ApiConfig.groqBaseUrl}/chat/completions';
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': ApiConfig.groqModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You classify dating chat messages. Reply YES or NO only.',
            },
            {
              'role': 'user',
              'content':
                  'Is this message asking a question or making a proposition that requires a yes/no/maybe response (like asking to meet, go on a date, get drinks, come over, etc.)? Reply YES or NO only.\n\nMessage: $message',
            },
          ],
          'max_tokens': 5,
          'temperature': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final content =
              (choices[0] as Map<String, dynamic>)['message']['content']
                  as String;
          return content.trim().toUpperCase().contains('YES');
        }
      }
      return false;
    } catch (e) {
      Logger.e('Intent classification failed', error: e);
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

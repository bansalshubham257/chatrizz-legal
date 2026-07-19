class ApiConstants {
  ApiConstants._();

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsEndpoint = '/chat/completions';
  static const String defaultModel = 'gpt-4o-mini';

  static const int maxTokens = 500;
  static const double temperature = 0.8;
}

class ApiConfig {
  ApiConfig._();

  static const String aiProvider = 'groq';

  // Get your Groq API key from https://console.groq.com/keys
  static const String groqApiKey = 'gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.1-8b-instant';

  static const String openAiApiKey = '';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiModel = 'gpt-4o-mini';

  static const String geminiApiKey = '';
}

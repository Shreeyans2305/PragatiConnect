import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
class Environment {
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';

  static bool get useLocalAI =>
      dotenv.env['USE_LOCAL_AI']?.toLowerCase() == 'true';

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';

  /// Initialize environment - call before runApp()
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
}

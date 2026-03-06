import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
class Environment {
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Get the API base URL, handling iOS simulator localhost issue
  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
    
    // iOS simulator can't access localhost directly - use the host machine IP
    // For real device testing, set API_BASE_URL to your machine's local IP
    if (!kIsWeb && Platform.isIOS) {
      // Replace localhost with 127.0.0.1 for iOS simulator
      // For real devices, you'll need to set the actual IP in .env
      return envUrl
          .replaceAll('localhost', '127.0.0.1')
          .replaceAll('10.0.2.2', '127.0.0.1');
    }
    
    // Android emulator uses 10.0.2.2 to reach host localhost
    if (!kIsWeb && Platform.isAndroid) {
      return envUrl
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    
    return envUrl;
  }

  static bool get useLocalAI =>
      dotenv.env['USE_LOCAL_AI']?.toLowerCase() == 'true';

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';
  
  /// Whether to use the backend API for chat/voice (instead of local Gemini)
  static bool get useBackendApi {
    final value = dotenv.env['USE_BACKEND_API'];
    debugPrint('🔧 USE_BACKEND_API env value: "$value"');
    // Default to true when the env var is set to 'true' OR when not set at all
    // This makes backend API the default when the env var is missing
    return value?.toLowerCase() != 'false';
  }

  /// Initialize environment - call before runApp()
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    debugPrint('🔧 Environment loaded:');
    debugPrint('   API_BASE_URL (raw): ${dotenv.env['API_BASE_URL']}');
    debugPrint('   API_BASE_URL (actual): $apiBaseUrl');
    debugPrint('   USE_BACKEND_API: ${dotenv.env['USE_BACKEND_API']}');
    debugPrint('   useBackendApi getter: $useBackendApi');
  }
}

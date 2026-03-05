import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for interacting with the PragatiConnect Voice API.
/// 
/// Handles:
/// - Voice queries (audio -> text -> AI -> audio response)
/// - Speech-to-text transcription
/// - Text-to-speech synthesis
class VoiceApiService {
  final String baseUrl;
  String? _authToken;

  VoiceApiService({
    required this.baseUrl,
  });

  /// Set the authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Complete voice query: Send audio, get AI response as text and audio
  /// 
  /// [audioData] - Raw audio bytes (LINEAR16, OGG_OPUS, or MP3)
  /// [language] - Language code (hi, en, ta, te, bn, mr)
  /// [conversationId] - Optional conversation ID for context
  /// [encoding] - Audio encoding format
  /// [sampleRate] - Sample rate in Hz
  Future<VoiceQueryResult> voiceQuery({
    required Uint8List audioData,
    String language = 'hi',
    String? conversationId,
    String encoding = 'LINEAR16',
    int sampleRate = 16000,
  }) async {
    final body = jsonEncode({
      'audio_data': base64Encode(audioData),
      'language': language,
      'conversation_id': conversationId,
      'audio_encoding': encoding,
      'sample_rate': sampleRate,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/voice/query-base64'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VoiceQueryResult.fromJson(data);
    } else {
      throw VoiceApiException(
        'Voice query failed: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Transcribe audio to text (Speech-to-Text only)
  /// 
  /// Returns the transcribed text and confidence score
  Future<TranscriptionResult> transcribe({
    required Uint8List audioData,
    String language = 'hi',
    String encoding = 'LINEAR16',
    int sampleRate = 16000,
  }) async {
    final body = jsonEncode({
      'audio_data': base64Encode(audioData),
      'language': language,
      'audio_encoding': encoding,
      'sample_rate': sampleRate,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/voice/transcribe-base64'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TranscriptionResult.fromJson(data);
    } else {
      throw VoiceApiException(
        'Transcription failed: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Synthesize text to speech (Text-to-Speech only)
  /// 
  /// Returns audio data as bytes
  Future<SynthesisResult> synthesize({
    required String text,
    String language = 'hi',
    double speakingRate = 1.0,
    double pitch = 0.0,
    String outputFormat = 'MP3',
  }) async {
    final body = jsonEncode({
      'text': text,
      'language': language,
      'speaking_rate': speakingRate,
      'pitch': pitch,
      'output_format': outputFormat,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/voice/synthesize'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SynthesisResult.fromJson(data);
    } else {
      throw VoiceApiException(
        'Synthesis failed: ${response.statusCode}',
        response.body,
      );
    }
  }

  /// Save audio bytes to a temporary file for playback
  Future<File> saveAudioToFile(Uint8List audioData, String format) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/voice_response_$timestamp.$format');
    await file.writeAsBytes(audioData);
    return file;
  }
}

/// Result from a complete voice query
class VoiceQueryResult {
  final String userTranscript;
  final String aiResponse;
  final Uint8List audioResponse;
  final String audioFormat;
  final String conversationId;
  final String language;
  final double sttConfidence;

  VoiceQueryResult({
    required this.userTranscript,
    required this.aiResponse,
    required this.audioResponse,
    required this.audioFormat,
    required this.conversationId,
    required this.language,
    required this.sttConfidence,
  });

  factory VoiceQueryResult.fromJson(Map<String, dynamic> json) {
    return VoiceQueryResult(
      userTranscript: json['user_transcript'] as String,
      aiResponse: json['ai_response'] as String,
      audioResponse: base64Decode(json['audio_response'] as String),
      audioFormat: json['audio_format'] as String,
      conversationId: json['conversation_id'] as String,
      language: json['language'] as String,
      sttConfidence: (json['stt_confidence'] as num).toDouble(),
    );
  }
}

/// Result from speech-to-text transcription
class TranscriptionResult {
  final String transcript;
  final double confidence;
  final String language;
  final String? languageDetected;

  TranscriptionResult({
    required this.transcript,
    required this.confidence,
    required this.language,
    this.languageDetected,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcript: json['transcript'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      language: json['language'] as String,
      languageDetected: json['language_detected'] as String?,
    );
  }
}

/// Result from text-to-speech synthesis
class SynthesisResult {
  final Uint8List audioContent;
  final String audioFormat;
  final String language;

  SynthesisResult({
    required this.audioContent,
    required this.audioFormat,
    required this.language,
  });

  factory SynthesisResult.fromJson(Map<String, dynamic> json) {
    return SynthesisResult(
      audioContent: base64Decode(json['audio_content'] as String),
      audioFormat: json['audio_format'] as String,
      language: json['language'] as String,
    );
  }
}

/// Exception for Voice API errors
class VoiceApiException implements Exception {
  final String message;
  final String? details;

  VoiceApiException(this.message, [this.details]);

  @override
  String toString() => 'VoiceApiException: $message${details != null ? '\n$details' : ''}';
}

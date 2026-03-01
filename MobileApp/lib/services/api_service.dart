import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/user_profile.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException: [$errorCode] $message';

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return ApiException(
        statusCode: response.statusCode,
        errorCode: body['error_code'] as String? ?? 'UNKNOWN',
        message: body['message'] as String? ?? 'An error occurred',
        details: body['details'] as Map<String, dynamic>?,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        errorCode: 'PARSE_ERROR',
        message: 'Failed to parse error response',
      );
    }
  }
}

/// API Service for backend communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => Environment.apiBaseUrl;

  final http.Client _client = http.Client();

  // Headers for authenticated requests
  Map<String, String> _getHeaders({String? authToken}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  // Generic GET request
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    String? authToken,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    try {
      final response = await _client
          .get(uri, headers: _getHeaders(authToken: authToken))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'No internet connection',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> _post(
    String endpoint, {
    String? authToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await _client
          .post(
            uri,
            headers: _getHeaders(authToken: authToken),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'No internet connection',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> _put(
    String endpoint, {
    String? authToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await _client
          .put(
            uri,
            headers: _getHeaders(authToken: authToken),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'No internet connection',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
    }
  }

  // Multipart POST for file uploads
  Future<Map<String, dynamic>> _postMultipart(
    String endpoint, {
    String? authToken,
    required File file,
    String fileField = 'file',
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders(authToken: authToken));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'No internet connection',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('API Response [${response.statusCode}]: ${response.body.substring(0, response.body.length.clamp(0, 500))}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException.fromResponse(response);
    }
  }

  // ─── Authentication Endpoints ─────────────────────────────────────────────

  /// Register a new user
  Future<Map<String, dynamic>> register(String phoneNumber) async {
    return _post('/auth/register', body: {'phone_number': phoneNumber});
  }

  /// Verify OTP and get token
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return _post('/auth/verify-otp', body: {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  /// Refresh auth token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return _post('/auth/refresh-token', body: {'refresh_token': refreshToken});
  }

  // ─── Profile Endpoints ────────────────────────────────────────────────────

  /// Get user profile
  Future<UserProfile> getProfile(String authToken) async {
    final response = await _get('/profile', authToken: authToken);
    return UserProfile.fromJson(response);
  }

  /// Update user profile
  Future<UserProfile> updateProfile(String authToken, UserProfile profile) async {
    final response = await _put(
      '/profile',
      authToken: authToken,
      body: profile.toJson(),
    );
    return UserProfile.fromJson(response);
  }

  /// Sync profile to backend
  Future<void> syncProfile(String authToken, UserProfile profile) async {
    await _put('/profile', authToken: authToken, body: profile.toJson());
  }

  // ─── Chat Endpoints ───────────────────────────────────────────────────────

  /// Send chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String authToken,
    required String message,
    required String language,
    String? conversationId,
  }) async {
    return _post('/chat/message', authToken: authToken, body: {
      'message': message,
      'language': language,
      if (conversationId != null) 'conversation_id': conversationId,
    });
  }

  /// Send voice query
  Future<Map<String, dynamic>> sendVoiceQuery({
    required String authToken,
    required String transcript,
    required String language,
  }) async {
    return _post('/voice/query', authToken: authToken, body: {
      'transcript': transcript,
      'language': language,
    });
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getChatHistory(String authToken) async {
    final response = await _get('/chat/history', authToken: authToken);
    return (response['conversations'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ─── Schemes Endpoints ────────────────────────────────────────────────────

  /// Get schemes list
  Future<List<Map<String, dynamic>>> getSchemes({
    String? authToken,
    String? category,
    String? search,
  }) async {
    final response = await _get(
      '/schemes',
      authToken: authToken,
      queryParams: {
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      },
    );
    return (response['schemes'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Get scheme details
  Future<Map<String, dynamic>> getSchemeDetails(
    String schemeId, {
    String? authToken,
  }) async {
    return _get('/schemes/$schemeId', authToken: authToken);
  }

  /// Get eligible schemes for user
  Future<List<Map<String, dynamic>>> getEligibleSchemes(String authToken) async {
    final response = await _get('/schemes/eligible', authToken: authToken);
    return (response['schemes'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Ask question about a scheme
  Future<Map<String, dynamic>> askSchemeQuestion({
    required String authToken,
    required String schemeId,
    required String question,
    required String language,
  }) async {
    return _post('/schemes/query', authToken: authToken, body: {
      'scheme_id': schemeId,
      'question': question,
      'language': language,
    });
  }

  // ─── Price Estimation Endpoints ───────────────────────────────────────────

  /// Analyze image for price estimation
  Future<Map<String, dynamic>> analyzeImage({
    required String authToken,
    required File image,
    required String language,
  }) async {
    return _postMultipart(
      '/price/estimate',
      authToken: authToken,
      file: image,
      fileField: 'image',
      fields: {'language': language},
    );
  }

  /// Get price estimate history
  Future<List<Map<String, dynamic>>> getPriceHistory(String authToken) async {
    final response = await _get('/price/estimates', authToken: authToken);
    return (response['estimates'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ─── Business Tools Endpoints ─────────────────────────────────────────────

  /// Generate business profile
  Future<Map<String, dynamic>> generateBusinessProfile({
    required String authToken,
    required Map<String, dynamic> businessDetails,
    required String language,
  }) async {
    return _post('/business/profile-generator', authToken: authToken, body: {
      ...businessDetails,
      'language': language,
    });
  }
}

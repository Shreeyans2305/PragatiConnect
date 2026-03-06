import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/environment.dart';
import '../services/voice_api_service.dart';

/// Authentication states
enum AuthState {
  initial,
  unauthenticated,
  awaitingOtp,
  authenticated,
  error,
}

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'email';

  final ApiService _apiService = ApiService();
  late VoiceApiService _voiceApiService;

  AuthState _state = AuthState.initial;
  String? _accessToken;
  String? _refreshToken;
  String? _email;
  String? _errorMessage;
  bool _isLoading = false;

  AuthState get state => _state;
  String? get accessToken => _accessToken;
  String? get email => _email;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated && _accessToken != null;

  VoiceApiService get voiceApiService => _voiceApiService;

  AuthProvider() {
    _voiceApiService = VoiceApiService(baseUrl: Environment.apiBaseUrl);
  }

  /// Initialize provider - load saved tokens
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      _email = prefs.getString(_emailKey);

      if (_accessToken != null) {
        _state = AuthState.authenticated;
        _voiceApiService.setAuthToken(_accessToken!);
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      debugPrint('Error loading auth tokens: $e');
      _state = AuthState.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Request OTP for email
  Future<bool> requestOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(email);
      final emailSent = response['email_sent'] as bool?;
      if (emailSent == false) {
        _errorMessage = 'Verification email could not be sent. Please try again.';
        _state = AuthState.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _email = email;
      _state = AuthState.awaitingOtp;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send OTP. Please try again.';
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and authenticate
  Future<bool> verifyOtp(String otp) async {
    if (_email == null) {
      _errorMessage = 'Email not found. Please try again.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyOtp(_email!, otp);

      _accessToken = response['access_token'] as String?;
      _refreshToken = response['refresh_token'] as String?;

      if (_accessToken != null) {
        // Save tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, _accessToken!);
        if (_refreshToken != null) {
          await prefs.setString(_refreshTokenKey, _refreshToken!);
        }
        await prefs.setString(_emailKey, _email!);

        // Set token for voice API
        _voiceApiService.setAuthToken(_accessToken!);

        _state = AuthState.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Authentication failed. Please try again.';
        _state = AuthState.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Verification failed. Please try again.';
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _apiService.refreshToken(_refreshToken!);
      _accessToken = response['access_token'] as String?;

      if (_accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, _accessToken!);
        _voiceApiService.setAuthToken(_accessToken!);
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    return false;
  }

  /// Logout user
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _state = AuthState.unauthenticated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_emailKey);
    } catch (e) {
      debugPrint('Error clearing auth tokens: $e');
    }

    notifyListeners();
  }

  /// Reset error state
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _accessToken != null 
          ? AuthState.authenticated 
          : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Skip authentication (for demo mode)
  void skipAuth() {
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}

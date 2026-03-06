import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

/// Provider for managing user profile state
class UserProvider extends ChangeNotifier {
  static const String _profileKey = 'user_profile';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  UserProfile? _profile;
  bool _isLoading = true;
  bool _onboardingComplete = false;
  final ApiService _apiService = ApiService();

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _profile != null;
  bool get hasProfile => _profile != null;
  bool get onboardingComplete => _onboardingComplete;

  bool _isProfileComplete(UserProfile profile) {
    return (profile.name?.trim().isNotEmpty ?? false) &&
        profile.primaryTrade.trim().isNotEmpty &&
        profile.location.trim().isNotEmpty &&
        profile.state.trim().isNotEmpty;
  }

  /// Initialize provider - load saved profile
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;

      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        _profile = UserProfile.fromJson(
          json.decode(profileJson) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save user profile
  Future<void> saveProfile(UserProfile profile, {String? authToken}) async {
    _profile = profile;

    // Persist to backend first when authenticated.
    if (authToken != null && authToken.isNotEmpty) {
      try {
        final backendProfile = await _apiService.updateProfile(authToken, profile);
        _profile = backendProfile.copyWith(
          profilePhotoPath: profile.profilePhotoPath,
        );
      } catch (e) {
        debugPrint('Error syncing profile to backend: $e');
      }
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, json.encode(profile.toJson()));
      await prefs.setBool(_onboardingCompleteKey, true);
      _onboardingComplete = true;
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  /// Load profile from backend and derive onboarding completion from profile fields.
  Future<bool> loadProfileFromBackend(String authToken) async {
    try {
      final backendProfile = await _apiService.getProfile(authToken);
      final localPhotoPath = _profile?.profilePhotoPath;

      // Use backend-provided photo URL (fresh presigned URL) and preserve local path
      _profile = backendProfile.copyWith(
        profilePhotoPath: localPhotoPath,
        // backendProfile.profilePhotoUrl already has fresh presigned URL from server
      );
      _onboardingComplete = _isProfileComplete(_profile!);

      final prefs = await SharedPreferences.getInstance();
      // Save the merged profile so photo URL is cached for offline/relaunch
      await prefs.setString(_profileKey, json.encode(_profile!.toJson()));
      await prefs.setBool(_onboardingCompleteKey, _onboardingComplete);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading backend profile: $e');
      return false;
    }
  }

  /// Update existing profile
  Future<void> updateProfile({
    String? name,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    String? profilePhotoUrl,
    bool clearProfilePhotoUrl = false,
    String? primaryTrade,
    List<String>? secondaryTrades,
    String? location,
    String? state,
    String? preferredLanguage,
    bool? whatsappOptIn,
    String? authToken,
  }) async {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      name: name,
      profilePhotoPath: profilePhotoPath,
      clearProfilePhoto: clearProfilePhoto,
      profilePhotoUrl: profilePhotoUrl,
      clearProfilePhotoUrl: clearProfilePhotoUrl,
      primaryTrade: primaryTrade,
      secondaryTrades: secondaryTrades,
      location: location,
      state: state,
      preferredLanguage: preferredLanguage,
      whatsappOptIn: whatsappOptIn,
    );
    notifyListeners();

    try {
      if (authToken != null && authToken.isNotEmpty) {
        final backendResp = await _apiService.updateProfile(authToken, _profile!);
        _profile = backendResp.copyWith(
          profilePhotoPath: _profile!.profilePhotoPath,
          profilePhotoUrl: _profile!.profilePhotoUrl,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, json.encode(_profile!.toJson()));
      _onboardingComplete = _isProfileComplete(_profile!);
      await prefs.setBool(_onboardingCompleteKey, _onboardingComplete);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  /// Clear user profile (logout)
  Future<void> clearProfile() async {
    _profile = null;
    _onboardingComplete = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.setBool(_onboardingCompleteKey, false);
    } catch (e) {
      debugPrint('Error clearing user profile: $e');
    }
  }

  /// Skip onboarding (for demo mode)
  Future<void> skipOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
    } catch (e) {
      debugPrint('Error skipping onboarding: $e');
    }
  }
}

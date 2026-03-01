import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Provider for managing user profile state
class UserProvider extends ChangeNotifier {
  static const String _profileKey = 'user_profile';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  UserProfile? _profile;
  bool _isLoading = true;
  bool _onboardingComplete = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _profile != null;
  bool get hasProfile => _profile != null;
  bool get onboardingComplete => _onboardingComplete;

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
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
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

  /// Update existing profile
  Future<void> updateProfile({
    String? name,
    String? primaryTrade,
    List<String>? secondaryTrades,
    String? location,
    String? state,
    String? preferredLanguage,
    bool? whatsappOptIn,
  }) async {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      name: name,
      primaryTrade: primaryTrade,
      secondaryTrades: secondaryTrades,
      location: location,
      state: state,
      preferredLanguage: preferredLanguage,
      whatsappOptIn: whatsappOptIn,
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, json.encode(_profile!.toJson()));
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

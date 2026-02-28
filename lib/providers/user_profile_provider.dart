import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Manages user profile state and persists it via SharedPreferences.
class UserProfileProvider extends ChangeNotifier {
  static const _keyName = 'profile_name';
  static const _keyOccupation = 'profile_occupation';
  static const _keyGender = 'profile_gender';
  static const _keyAadhaar = 'profile_aadhaar';
  static const _keyPhone = 'profile_phone';
  static const _keyImagePath = 'profile_image_path';
  static const _keyImageScale = 'profile_image_scale';

  String _name = '';
  String _occupation = '';
  String _gender = '';
  String _aadhaarNo = '';
  String _phoneNo = '';
  String _profileImagePath = '';
  double _profileImageScale = 1.0;
  bool _isLoaded = false;

  // ─── Getters ─────────────────────────────────────────────────────────────
  String get name => _name;
  String get displayName => _name.isNotEmpty ? _name : 'User';
  String get occupation => _occupation;
  String get gender => _gender;
  String get aadhaarNo => _aadhaarNo;
  String get phoneNo => _phoneNo;
  String get profileImagePath => _profileImagePath;
  double get profileImageScale => _profileImageScale;
  bool get isLoaded => _isLoaded;
  bool get hasProfileImage =>
      _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

  // ─── Load from SharedPreferences ──────────────────────────────────────────
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_keyName) ?? '';
    _occupation = prefs.getString(_keyOccupation) ?? '';
    _gender = prefs.getString(_keyGender) ?? '';
    _aadhaarNo = prefs.getString(_keyAadhaar) ?? '';
    _phoneNo = prefs.getString(_keyPhone) ?? '';
    _profileImagePath = prefs.getString(_keyImagePath) ?? '';
    _profileImageScale = prefs.getDouble(_keyImageScale) ?? 1.0;
    _isLoaded = true;
    notifyListeners();
  }

  // ─── Update helpers ──────────────────────────────────────────────────────
  Future<void> updateName(String value) async {
    _name = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, _name);
    notifyListeners();
  }

  Future<void> updateOccupation(String value) async {
    _occupation = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOccupation, _occupation);
    notifyListeners();
  }

  Future<void> updateGender(String value) async {
    _gender = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGender, _gender);
    notifyListeners();
  }

  Future<void> updateAadhaar(String value) async {
    _aadhaarNo = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAadhaar, _aadhaarNo);
    notifyListeners();
  }

  Future<void> updatePhone(String value) async {
    _phoneNo = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, _phoneNo);
    notifyListeners();
  }

  /// Pick an image from gallery, copy it to app documents, and persist path.
  Future<bool> pickAndSaveProfileImage() async {
    return pickAndCropProfileImage(_profileImageScale);
  }

  /// Pick an image with a specific scale factor for display sizing.
  Future<bool> pickAndCropProfileImage(double scale) async {
    try {
      final picker = ImagePicker();
      final maxDim = (512 * scale).clamp(256, 1024).toDouble();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxDim,
        maxHeight: maxDim,
        imageQuality: 85,
      );
      if (image == null) return false;

      // Copy to app documents for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = '${appDir.path}/profile_picture.jpg';
      final bytes = await image.readAsBytes();
      await File(savedPath).writeAsBytes(bytes);

      _profileImagePath = savedPath;
      _profileImageScale = scale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyImagePath, savedPath);
      await prefs.setDouble(_keyImageScale, scale);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update just the image scale without re-picking.
  Future<void> updateImageScale(double scale) async {
    _profileImageScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyImageScale, scale);
    notifyListeners();
  }

  /// Directly set the profile image path (used after crop).
  Future<void> updateProfileImagePath(String path) async {
    _profileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImagePath, path);
    notifyListeners();
  }

  /// Clears all profile data (name, image, etc.) but keeps app settings.
  Future<void> resetAccount() async {
    final prefs = await SharedPreferences.getInstance();

    // Delete profile image file
    if (_profileImagePath.isNotEmpty) {
      try {
        final file = File(_profileImagePath);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }

    // Clear profile keys only
    for (final key in [
      _keyName,
      _keyOccupation,
      _keyGender,
      _keyAadhaar,
      _keyPhone,
      _keyImagePath,
    ]) {
      await prefs.remove(key);
    }

    _name = '';
    _occupation = '';
    _gender = '';
    _aadhaarNo = '';
    _phoneNo = '';
    _profileImagePath = '';
    notifyListeners();
  }

  /// Clears ALL app data — profile, settings, chat history, everything.
  Future<void> deleteAccount() async {
    // Delete profile image
    if (_profileImagePath.isNotEmpty) {
      try {
        final file = File(_profileImagePath);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }

    // Nuke all SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _name = '';
    _occupation = '';
    _gender = '';
    _aadhaarNo = '';
    _phoneNo = '';
    _profileImagePath = '';
    notifyListeners();
  }
}

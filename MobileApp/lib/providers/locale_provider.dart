import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ChangeNotifier-based locale provider with persistence.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';

  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isHindi => _locale.languageCode == 'hi';
  bool get isInitialized => _isInitialized;
  String get languageCode => _locale.languageCode;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
    Locale('bn'),
  ];

  /// Initialize from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null) {
        _locale = Locale(savedLocale);
      }
    } catch (e) {
      debugPrint('Error loading locale preference: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      _saveLocale();
      notifyListeners();
    }
  }

  void setLocaleByCode(String languageCode) {
    setLocale(Locale(languageCode));
  }

  void toggleLocale() {
    _locale =
        _locale.languageCode == 'en' ? const Locale('hi') : const Locale('en');
    _saveLocale();
    notifyListeners();
  }

  Future<void> _saveLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, _locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }
}

import 'package:flutter/material.dart';

/// ChangeNotifier-based locale provider for English/Hindi switching.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isHindi => _locale.languageCode == 'hi';

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    _locale = _locale.languageCode == 'en'
        ? const Locale('hi')
        : const Locale('en');
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'app_localizations.dart';

/// Global Language Controller
/// 
/// This controller manages the global language state for the entire application.
/// It stores the currently selected Locale and rebuilds the MaterialApp when
/// the language changes, enabling instant language switching without app restart.
/// 
/// Key Features:
/// - Global Locale state management using ChangeNotifier
/// - Hive persistence for offline language storage
/// - Instant language switching (no app restart required)
/// - Singleton pattern for consistent state across the app
/// - Integration with existing AppLocalizations system
class LanguageController extends ChangeNotifier {
  static final LanguageController _instance = LanguageController._internal();
  factory LanguageController() => _instance;
  LanguageController._internal();

  static const String _boxName = 'app_settings';
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguageCode = 'en';

  Locale _currentLocale = const Locale(_defaultLanguageCode);
  Box? _box;
  bool _isInitialized = false;

  /// Get current locale for MaterialApp
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  /// Check if language has been selected (not first launch)
  bool get hasSelectedLanguage => _isInitialized && _box?.get(_languageKey) != null;

  /// Get list of supported locales
  List<Locale> get supportedLocales => AppLocalizations.supportedLanguages
      .map((code) => Locale(code))
      .toList();

  /// Initialize the language controller
  /// 
  /// This must be called once at app startup after Hive.initFlutter().
  /// Loads the saved language from Hive or defaults to English.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      
      // Load saved language or use default
      final savedLanguage = _box?.get(_languageKey) as String?;
      if (savedLanguage != null && 
          AppLocalizations.supportedLanguages.contains(savedLanguage)) {
        _currentLocale = Locale(savedLanguage);
      } else {
        _currentLocale = const Locale(_defaultLanguageCode);
      }

      _isInitialized = true;
      print('LanguageController initialized: ${_currentLocale.languageCode}');
    } catch (e) {
      print('Error initializing LanguageController: $e');
      _currentLocale = const Locale(_defaultLanguageCode);
      _isInitialized = true;
    }
  }

  /// Change the current language
  /// 
  /// This updates the language immediately and persists the selection.
  /// The MaterialApp will rebuild automatically due to ChangeNotifier.
  /// 
  /// Parameters:
  /// - languageCode: Language code ('en', 'hi', 'kn')
  Future<void> changeLanguage(String languageCode) async {
    if (!AppLocalizations.supportedLanguages.contains(languageCode)) {
      print('Unsupported language code: $languageCode');
      return;
    }

    if (_currentLocale.languageCode == languageCode) {
      return; // Already using this language
    }

    // Update locale
    _currentLocale = Locale(languageCode);

    // Persist to Hive for offline support
    try {
      await _box?.put(_languageKey, languageCode);
      print('Language changed to: $languageCode');
    } catch (e) {
      print('Error saving language: $e');
    }

    // Notify MaterialApp to rebuild with new locale
    notifyListeners();
  }

  /// Translate a key to current language
  /// 
  /// This is a convenience method that uses the current language code
  /// to get translated text from AppLocalizations.
  /// 
  /// Usage:
  /// ```dart
  /// Text(LanguageController().t(LangKeys.login))
  /// ```
  /// 
  /// Parameters:
  /// - key: Translation key from LangKeys
  /// 
  /// Returns: Translated string in current language
  String t(String key) {
    return AppLocalizations.translate(key, _currentLocale.languageCode);
  }

  /// Get language name for display
  /// 
  /// Returns the native name of the language for UI display.
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'kn':
        return 'ಕನ್ನಡ';
      default:
        return languageCode;
    }
  }

  /// Close Hive box
  /// 
  /// Should be called when app is closing.
  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }
}
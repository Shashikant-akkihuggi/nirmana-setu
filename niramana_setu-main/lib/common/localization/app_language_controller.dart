import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'app_localizations.dart';

/// Global Language Controller
/// 
/// This controller manages the current language state and persists
/// the user's language selection using Hive for offline support.
/// 
/// Why ChangeNotifier?
/// - Notifies UI when language changes
/// - Enables hot language switching
/// - No app restart required
/// - Reactive UI updates
/// 
/// Why Hive?
/// - Offline-first storage
/// - Fast read/write
/// - No network required
/// - Persists across app restarts
class AppLanguageController extends ChangeNotifier {
  static final AppLanguageController _instance = AppLanguageController._internal();
  factory AppLanguageController() => _instance;
  AppLanguageController._internal();

  static const String _boxName = 'app_settings';
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  String _currentLanguage = _defaultLanguage;
  Box? _box;
  bool _isInitialized = false;

  /// Get current language code
  String get currentLanguage => _currentLanguage;

  /// Check if language has been selected (not first launch)
  bool get hasSelectedLanguage => _isInitialized && _box?.get(_languageKey) != null;

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
        _currentLanguage = savedLanguage;
      } else {
        _currentLanguage = _defaultLanguage;
      }

      _isInitialized = true;
      print('Language controller initialized: $_currentLanguage');
    } catch (e) {
      print('Error initializing language controller: $e');
      _currentLanguage = _defaultLanguage;
      _isInitialized = true;
    }
  }

  /// Change the current language
  /// 
  /// This updates the language immediately and persists the selection.
  /// All UI listening to this controller will rebuild automatically.
  /// 
  /// Parameters:
  /// - languageCode: Language code ('en', 'hi', 'kn')
  Future<void> changeLanguage(String languageCode) async {
    if (!AppLocalizations.supportedLanguages.contains(languageCode)) {
      print('Unsupported language code: $languageCode');
      return;
    }

    if (_currentLanguage == languageCode) {
      return; // Already using this language
    }

    _currentLanguage = languageCode;

    // Persist to Hive for offline support
    try {
      await _box?.put(_languageKey, languageCode);
      print('Language changed to: $languageCode');
    } catch (e) {
      print('Error saving language: $e');
    }

    // Notify all listeners to rebuild UI
    notifyListeners();
  }

  /// Translate a key to current language
  /// 
  /// This is the main method used throughout the app to get translated text.
  /// 
  /// Usage:
  /// ```dart
  /// Text(lang.t(LangKeys.login))
  /// ```
  /// 
  /// Parameters:
  /// - key: Translation key from LangKeys
  /// 
  /// Returns: Translated string in current language
  String t(String key) {
    return AppLocalizations.translate(key, _currentLanguage);
  }

  /// Get list of supported languages
  List<String> get supportedLanguages => AppLocalizations.supportedLanguages;

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
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      default:
        return languageCode;
    }
  }

  /// Close Hive box
  /// 
  /// Should be called when app is closing.
  Future<void> dispose() async {
    await _box?.close();
    super.dispose();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Backend base URL. Defaults to localhost (the backend runs on the same
/// machine as this desktop app); editable in the Settings screen.
class Config {
  static const _prefsKey = 'backend_base_url';

  static String _baseUrl = 'http://localhost:8000';

  static String get baseUrl => _baseUrl;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _baseUrl);
  }
}

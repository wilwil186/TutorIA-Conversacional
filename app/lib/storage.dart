import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local persistence: CEFR level + chosen AI provider settings.
///
/// Model and API key are stored per-provider so switching back and forth
/// doesn't lose what you typed.
class Storage {
  static const _levelKey = 'cefr_level';
  static const _providerKey = 'llm_provider';

  static Future<String?> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_levelKey);
  }

  static Future<void> setLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, level);
  }

  static Future<Provider> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderInfo.fromId(prefs.getString(_providerKey));
  }

  static Future<void> setProvider(Provider p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, p.id);
  }

  static Future<String?> getModel(Provider p) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('llm_model_${p.id}');
  }

  static Future<void> setModel(Provider p, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_model_${p.id}', model);
  }

  static Future<String?> getApiKey(Provider p) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('llm_apikey_${p.id}');
  }

  static Future<void> setApiKey(Provider p, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_apikey_${p.id}', key);
  }

  /// Build the config to send with a chat request.
  static Future<LlmConfig> getLlmConfig() async {
    final p = await getProvider();
    return LlmConfig(
      provider: p,
      model: await getModel(p),
      apiKey: await getApiKey(p),
    );
  }
}

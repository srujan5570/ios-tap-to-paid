import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _clientIdKey = 'castar_client_id';
  static const String defaultClientId = 'cskKFkzBSlmLUF';

  static Future<String> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clientIdKey) ?? defaultClientId;
  }

  static Future<bool> setClientId(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_clientIdKey, clientId);
  }
} 
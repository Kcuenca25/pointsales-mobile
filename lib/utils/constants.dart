// lib/utils/constants.dart
class AppConstants {
  // URLs del servidor para updates
  static const String serverBaseUrl = '';
  static const String updateConfigUrl = '$serverBaseUrl/app-updates/version.json';
  
  // Claves para almacenamiento local
  static const String prefsFirstTimeKey = 'is_first_time';
  static const String prefsConfigsKey = 'odoo_configurations';
  static const String prefsActiveConfigKey = 'active_configuration_id';
  
  // Valores por defecto (prellenados en onboarding)
  static const String defaultDomain = '';
  static const String defaultDbName = 'pointsales-v18';
  static const String defaultUsername = '';
  
  // Timeouts
  static const int connectionTimeout = 15000; // 15 segundos
  static const int receiveTimeout = 15000;
}

class OdooEndpoints {
  static const String jsonRpc = '/jsonrpc';
  static const String authenticate = '/web/session/authenticate';
  static const String getDatabases = '/web/database/get_list';
}

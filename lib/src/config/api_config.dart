// lib/src/config/api_config.dart
class ApiConfig {
  // ✅ URL CORRECTA PARA ODDO
  static const String baseUrl = 'https://solutions.tailorw.net';
  static const String dbName = 'pointsales_prodv18'; // Base de datos
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin';
  
  // ✅ ENDPOINTS JSON-RPC DE ODDO
  static const String commonEndpoint = '/jsonrpc';
  static const String objectEndpoint = '/jsonrpc';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
// lib/src/config/api_config.dart
class ApiConfig {
  // ✅ URL SE PUEDE CAMBIAR AHORA
  static String baseUrl = 'https://lmhlast.tailorw.net';
  static String dbName = 'pointsales-v18';
  static String defaultUsername = '';
  static String defaultPassword = 'A001admin';
  
  // ✅ ENDPOINTS JSON-RPC DE ODOO
  static const String commonEndpoint = '/jsonrpc';
  static const String objectEndpoint = '/jsonrpc';
  static const String physicalInventoryEndpoint = '/odoo/physical-inventory';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

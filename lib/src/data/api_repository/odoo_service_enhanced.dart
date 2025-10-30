// odoo_service_enhanced.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http; 


class OdooServiceEnhanced {
  final String baseUrl;
  final String dbName;
  int? uid;
  String? sessionId;
  String? username;
  String? password; 
  String? companyName; 
  int? companyId; 

  OdooServiceEnhanced({
    required this.baseUrl,
    required this.dbName,
  });

   Future<dynamic> callKw(Map<String, dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jsonrpc'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': params,
          'id': Random().nextInt(1000000000),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          throw Exception('Odoo Error: ${data['error']['data']['message']}');
        }
        return data['result'];
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('JSON-RPC Call Error: $e');
      rethrow;
    }
  }

  Future<dynamic> _jsonRpcCall(String method, dynamic params) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jsonrpc'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': method,
          'params': params,
          'id': Random().nextInt(1000000000),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          throw Exception('Odoo Error: ${data['error']['data']['message']}');
        }
        return data['result'];
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('JSON-RPC Call Error: $e');
      rethrow;
    }
  }


  Future<bool> login(String username, String password) async {
    try {
      final result = await callKw({
        'service': 'common',
        'method': 'login',
        'args': [dbName, username, password],
      });
      
      uid = result;
      this.username = username;
      this.password = password;
      
      // ✅ OBTENER INFORMACIÓN DE LA EMPRESA DESPUÉS DEL LOGIN
      if (uid != null) {
        await _loadCompanyInfo();
      }
      
      return uid != null;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }
  Future<void> _loadCompanyInfo() async {
    try {
      // Obtener la compañía actual del usuario
      final userInfo = await callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          dbName,
          uid,
          password,
          'res.users',
          'read',
          [uid], // Leer información del usuario actual
          {
            'fields': ['company_id', 'name']
          }
        ],
      });

      if (userInfo is List && userInfo.isNotEmpty) {
        final userData = userInfo[0];
        final companyId = userData['company_id']?[0]; // ID de la compañía
        
        if (companyId != null) {
          // Obtener detalles de la compañía
          final companyInfo = await callKw({
            'service': 'object',
            'method': 'execute_kw',
            'args': [
              dbName,
              uid,
              password,
              'res.company',
              'read',
              [companyId],
              {
                'fields': ['name', 'display_name']
              }
            ],
          });

          if (companyInfo is List && companyInfo.isNotEmpty) {
            companyName = companyInfo[0]['display_name'] ?? companyInfo[0]['name'];
            print('✅ Empresa cargada: $companyName');
          }
        }
      }
    } catch (e) {
      print('❌ Error cargando información de la empresa: $e');
      // Si falla, usar un nombre por defecto
      companyName = 'Mi Empresa';
    }
  }
   String? getCompanyName() {
    return companyName;
  }
}
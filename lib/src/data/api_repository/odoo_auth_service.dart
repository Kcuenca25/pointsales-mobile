//odoo_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecomerce_app/src/config/api_config.dart';

class OdooAuthService {
  Future<Map<String, dynamic>> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      print('🔐 Autenticando con JSON-RPC...');
      print('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.commonEndpoint}');
      print('💾 Base de datos: ${ApiConfig.dbName}');
      print('👤 Usuario: $username');

      // ✅ FORMATO CORRECTO PARA ODDO JSON-RPC
      final Map<String, dynamic> requestBody = {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "common",
          "method": "login",
          "args": [
            ApiConfig.dbName, // pointsales-v18
            username,         // admin
            password          // admin
          ]
        },
        "id": 1
      };

      print('📤 Request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commonEndpoint}'),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // ✅ ODDO RESPONDE CON "result": user_id SI ES EXITOSO
        if (responseData.containsKey('result') && responseData['result'] != false) {
          final int userId = responseData['result'];
          
          print('✅ Autenticación Odoo exitosa');
          print('   👤 User ID: $userId');
          
          // ✅ OBTENER INFORMACIÓN DE LA EMPRESA DESPUÉS DEL LOGIN
          final companyInfo = await _getCompanyInfo(userId, username, password);
          
          return {
            'success': true,
            'userId': userId,
            'sessionId': userId.toString(),
            'companyName': companyInfo['companyName'],
            'userName': companyInfo['userName'],
            'message': 'Autenticación Odoo exitosa',
          };
        } else {
          print('❌ Error en autenticación Odoo');
          final String error = responseData['error']?['data']?['message'] ?? 
                              'Credenciales incorrectas';
          
          return {
            'success': false,
            'error': error,
          };
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ✅ NUEVO MÉTODO: Obtener información de la empresa y usuario
  Future<Map<String, dynamic>> _getCompanyInfo(int userId, String username, String password) async {
    try {
      print('🏢 Obteniendo información de la empresa...');
      
      // Primero obtener información del usuario
      final userRequestBody = {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute_kw",
          "args": [
            ApiConfig.dbName,
            userId,
            password,
            "res.users",
            "read",
            [userId],
            {
              "fields": ["name", "company_id"]
            }
          ]
        },
        "id": 2
      };

      final userResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commonEndpoint}'),
        headers: ApiConfig.headers,
        body: json.encode(userRequestBody),
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        
        if (userData['result'] is List && userData['result'].isNotEmpty) {
          final userInfo = userData['result'][0];
          final companyId = userInfo['company_id']?[0];
          final userName = userInfo['name'] ?? username;
          
          String companyName = 'Mi Empresa'; // Valor por defecto
          
          // Si hay companyId, obtener detalles de la empresa
          if (companyId != null) {
            final companyRequestBody = {
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "service": "object",
                "method": "execute_kw",
                "args": [
                  ApiConfig.dbName,
                  userId,
                  password,
                  "res.company",
                  "read",
                  [companyId],
                  {
                    "fields": ["name", "display_name"]
                  }
                ]
              },
              "id": 3
            };

            final companyResponse = await http.post(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commonEndpoint}'),
              headers: ApiConfig.headers,
              body: json.encode(companyRequestBody),
            );

            if (companyResponse.statusCode == 200) {
              final companyData = json.decode(companyResponse.body);
              if (companyData['result'] is List && companyData['result'].isNotEmpty) {
                companyName = companyData['result'][0]['display_name'] ?? 
                             companyData['result'][0]['name'] ?? 
                             'Mi Empresa';
              }
            }
          }
          
          print('✅ Información obtenida:');
          print('   🏢 Empresa: $companyName');
          print('   👤 Usuario: $userName');
          
          return {
            'companyName': companyName,
            'userName': userName,
          };
        }
      }
      
      return {
        'companyName': 'Mi Empresa',
        'userName': username,
      };
    } catch (e) {
      print('❌ Error obteniendo información de empresa: $e');
      return {
        'companyName': 'Mi Empresa',
        'userName': username,
      };
    }
  }

  // Método para validar credenciales
  Map<String, dynamic> validateCredentials(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return {'valid': false, 'error': 'Todos los campos son obligatorios'};
    }
    
    return {'valid': true};
  }
}

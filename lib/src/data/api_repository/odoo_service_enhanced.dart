// odoo_service_enhanced.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart'; 


class OdooServiceEnhanced {
  final String baseUrl;
  final String dbName;
  int? uid;
  String? sessionId;
  String? username;
  String? password; 
  String? companyName; 
  int? companyId; 
  List<int> allowedCompanyIds = []; // ✅ AGREGAR

  OdooServiceEnhanced({
    required this.baseUrl,
    required this.dbName,
  });

   Future<dynamic> callKw(Map<String, dynamic> params) async {
    try {
       // Asegúrate que params tiene 'service'
      if (!params.containsKey('service')) {
        params['service'] = 'object'; // Valor por defecto
      }
      final requestBody = json.encode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': params,
        'id': Random().nextInt(1000000000),
      });
      final response = await http.post(
        Uri.parse('$baseUrl/jsonrpc'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
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
      
      // ✅ VERIFICAR QUE EL RESULTADO SEA UN INT (USER ID)
      if (result is int && result > 0) {
        uid = result;
        this.username = username;
        this.password = password;
        
        // ✅ OBTENER INFORMACIÓN DE LA EMPRESA DESPUÉS DEL LOGIN
        await _loadCompanyInfo();
        
        return true;
      } else {
        // Login falló - Odoo devolvió false o null
        print('❌ Login falló: $result (usuario: $username)');
        uid = null;
        return false;
      }
    } catch (e) {
      print('❌ Login Error: $e');
      uid = null;
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
            'fields': ['company_id', 'name', 'company_ids'] // ✅ AGREGADO company_ids
          }
        ],
      });

      if (userInfo is List && userInfo.isNotEmpty) {
        final userData = userInfo[0];
        this.companyId = userData['company_id']?[0]; // ✅ GUARDAR
        final allowedCompaniesData = userData['company_ids']; 
        if (allowedCompaniesData is List) {
          allowedCompanyIds = allowedCompaniesData.cast<int>();
        }
        
        print('🔍 Debug Compañías User: $userData');

        if (companyId != null) {
          // Obtener detalles de la compañía ACTUAL
          final companyInfo = await callKw({
            'service': 'object',
            'method': 'execute_kw',
            'args': [
              dbName,
              uid,
              password,
              'res.company',
              'read',
              [companyId], // Leer solo la actual
              {'fields': ['name', 'display_name']}
            ],
          });

          if (companyInfo is List && companyInfo.isNotEmpty) {
            companyName = companyInfo[0]['display_name'] ?? companyInfo[0]['name'];
            print('✅ Empresa ACTUAL cargada: $companyName');
          }
        }
        
        // ✅ DEBUG EXTRA: VERIFICAR SI EXISTE LMH LAST
        if (allowedCompanyIds.isNotEmpty) {
          final companiesList = await callKw({
            'service': 'object',
            'method': 'execute_kw',
            'args': [
              dbName,
              uid,
              password,
              'res.company',
              'read',
              [allowedCompanyIds], // ✅ ENVOLVER EN LISTA PARA read()
              {'fields': ['name']}
            ],
          });
          print('🏢 Compañías disponibles para este usuario:');
          for(var c in (companiesList as List)) {
            print('   - [${c['id']}] ${c['name']}');
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

  // ✅ HELPER PARA CONSTRUIR CONTEXTO CON COMPAÑÍAS
  Map<String, dynamic> getContext() {
    final Map<String, dynamic> ctx = {};
    if (allowedCompanyIds.isNotEmpty) {
      ctx['allowed_company_ids'] = allowedCompanyIds;
    } else if (companyId != null) {
      ctx['allowed_company_ids'] = [companyId];
    }
    if (companyId != null) {
      ctx['company_id'] = companyId;
    }
    return ctx;
  }

  // ✅ HELPER ASÍNCRONO PARA CONTEXTO BASADO EN LA UI
  Future<Map<String, dynamic>> getContextAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedStr = prefs.getString('selected_company_id');
    if (selectedStr != null && selectedStr.isNotEmpty) {
      final selectedId = int.tryParse(selectedStr);
      if (selectedId != null) {
        return {
          'allowed_company_ids': [selectedId],
          'company_id': selectedId,
        };
      }
    }
    return getContext(); // Fallback to user default
  }
}

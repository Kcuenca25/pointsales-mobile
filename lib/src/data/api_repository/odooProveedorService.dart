
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
// services/odoo_proveedor_service.dart - VERSIÓN CORREGIDA
class OdooProveedorService {
  final OdooServiceEnhanced odooService;

  OdooProveedorService(this.odooService);

  Future<List<Proveedor>> getProveedores({int limit = 100}) async {
    try {
      print('🚀 Cargando proveedores (solo empresas) desde Odoo...');
      
      // 🎯 PRIMERO: VERIFICAR LA CONEXIÓN
      print('🔐 Verificando autenticación...');
      if (odooService.uid == null) {
         throw Exception('OdooProveedorService: UID es nulo. El servicio debe estar autenticado previamente.');
      }
      
      print('✅ Autenticado - UID: ${odooService.uid}');
      
      // 🎯 SEGUNDO: HACER LA CONSULTA CON EL MISMO FILTRO QUE CLIENTES
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_read',
          [
            [['is_company', '=', true]] // ✅ FILTRO DE EMPRESAS RESTAURADO
          ],
          {
            'fields': [
              'id', 'name', 'email', 'phone', 'mobile', 'vat',
              'street', 'city', 'zip', 'country_id', 'is_company',
              // 'commercial_company_name' // REMOVIDO PARA EVITAR ERRORES
            ],
            'limit': limit,
            'order': 'name asc',
          }
        ],
      });

      print('📡 Respuesta cruda de Odoo para proveedores:');
      print('   Tipo: ${result.runtimeType}');
      if (result is List) {
        print('   Cantidad: ${result.length} elementos');
        if (result.isNotEmpty) {
          print('   Primer elemento: ${result.first}');
        }
      }

      final proveedores = <Proveedor>[];
      
      for (var item in (result as List)) {
        try {
          // print('🔍 Procesando proveedor: ${item['name']} (ID: ${item['id']})');
          
          final proveedor = Proveedor(
            id: _parseInt(item['id']),
            name: _parseString(item['name']) ?? 'Sin nombre',
            email: _parseString(item['email']),
            phone: _parseString(item['phone']),
            mobile: _parseString(item['mobile']),
            vat: _parseString(item['vat']),
            street: _parseString(item['street']),
            city: _parseString(item['city']),
            zip: _parseString(item['zip']),
            isCompany: _parseBool(item['is_company']),
          );
          
          proveedores.add(proveedor);
          
        } catch (e) {
          print('⚠️ Error procesando proveedor individual: $e');
        }
      }

      print('✅ Proveedores cargados: ${proveedores.length} empresas');
      return proveedores;
      
    } catch (e) {
      print('❌ Error cargando proveedores: $e');
      return [];
    }
  }

  // ✅ MÉTODOS AUXILIARES PARA PREVENIR ERRORES DE TIPO (Igual que en CustomerService)
  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _parseString(dynamic value) {
    if (value is String) return value.isNotEmpty ? value : null;
    if (value is bool) return null; // Odoo usa false para valores vacíos
    return null;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true; // Por defecto asumimos true si falla, o ajustar según necesidad
  }
}

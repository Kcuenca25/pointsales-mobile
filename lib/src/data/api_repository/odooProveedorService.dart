
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
        print('❌ No hay UID - Reautenticando...');
        final loggedIn = await odooService.login('admin', 'admin');
        if (!loggedIn) {
          throw Exception('No se pudo autenticar con Odoo');
        }
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
            [['is_company', '=', true]] // ✅ MISMO FILTRO QUE CLIENTES
          ],
          {
            'fields': [
              'id', 'name', 'email', 'phone', 'mobile', 'vat',
              'street', 'city', 'zip', 'country_id', 'is_company',
              'commercial_company_name' // ✅ AGREGAR ESTE CAMPO
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

      final proveedores = (result as List).map((item) {
        print('🔍 Procesando proveedor: ${item['name']} (ID: ${item['id']})');
        
        return Proveedor(
          id: item['id'] as int,
          name: item['name'] as String,
          email: item['email'] as String?,
          phone: item['phone'] as String?,
          mobile: item['mobile'] as String?,
          vat: item['vat'] as String?,
          street: item['street'] as String?,
          city: item['city'] as String?,
          zip: item['zip'] as String?,
          isCompany: item['is_company'] as bool? ?? true,
        );
      }).toList();

      print('✅ Proveedores cargados: ${proveedores.length} empresas');
      
      // 🎯 DEBUG: LISTAR TODOS LOS PROVEEDORES ENCONTRADOS
      for (var proveedor in proveedores) {
        print('   🏢 ${proveedor.name} (ID: ${proveedor.id})');
      }
      
      return proveedores;
      
    } catch (e) {
      print('❌ Error cargando proveedores: $e');
      print('   StackTrace: ${e.toString()}');
      return [];
    }
  }
}
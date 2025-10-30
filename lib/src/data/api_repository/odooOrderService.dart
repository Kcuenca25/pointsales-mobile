// odoo_order_service.dart;
//import 'package:ecomerce_app/src/domain/models/model_orden.dart';
//import 'package:ecomerce_app/src/domain/models/articulo.dart';
//import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class OdooCustomerService {
  final OdooServiceEnhanced odooService;

  OdooCustomerService(this.odooService);

  Future<List<Customer>> getCustomers({int limit = 20}) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_read',
          [], // ✅ QUITAR EL FILTRO O USAR UNO MÁS AMPLIO
          {
            'fields': [
              "id", "name", "commercial_company_name", "vat", "company_type",
              "email", "phone", "mobile", "street", "city", "zip", "country_id", "is_company"
            ],
            'limit': limit,
            'order': 'name asc',
          }
        ],
      });

      return (result as List).map((item) {
        return Customer.fromJson(item);
      }).toList();
    } catch (e) {
      print('❌ Error getting customers: $e');
      
      // ✅ INTENTAR MÉTODO ALTERNATIVO SIN FILTRO
      return await getCustomersAlternative(limit: limit);
    }
  }

  // ✅ MÉTODO ALTERNATIVO SIN FILTRO customer_rank
  Future<List<Customer>> getCustomersAlternative({int limit = 20}) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute', // ✅ USAR 'execute' COMO EN TU EJEMPLO DE POSTMAN
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_read',
          [], // ✅ DOMINIO VACÍO - TRAE TODOS LOS PARTNERS
          [
            "id", "name", "commercial_company_name", "vat", "company_type",
            "email", "phone", "mobile", "street", "city", "zip", "country_id", "is_company"
          ],
          0, // offset
          limit, // limit
          'name asc', // order
        ],
      });

      return (result as List).map((item) {
        return Customer.fromJson(item);
      }).toList();
    } catch (e) {
      print('❌ Error alternative getting customers: $e');
      return [];
    }
  }

  Future<int> getCustomerCount() async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_count',
          [], // ✅ CONTAR TODOS LOS PARTNERS SIN FILTRO
        ],
      });
      return result as int;
    } catch (e) {
      print('❌ Error counting customers: $e');
      return 0;
    }
  }

  // ✅ MÉTODO PARA FILTRAR SOLO CLIENTES (SI QUIERES MANTENER EL FILTRO)
  Future<List<Customer>> getCustomersWithFilter({int limit = 20}) async {
    try {
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
            '|', // ✅ FILTRO MÁS FLEXIBLE
            ['customer', '=', true],
            ['customer_rank', '>', 0]
          ],
          {
            'fields': [
              "id", "name", "commercial_company_name", "vat", "company_type",
              "email", "phone", "mobile", "street", "city", "zip", "country_id", "is_company"
            ],
            'limit': limit,
            'order': 'name asc',
          }
        ],
      });

      return (result as List).map((item) {
        return Customer.fromJson(item);
      }).toList();
    } catch (e) {
      print('❌ Error getting customers with filter: $e');
      return await getCustomersAlternative(limit: limit); // Fallback sin filtro
    }
  }
}
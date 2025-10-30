// odoo_customer_service.dart
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class OdooCustomerService {
  final OdooServiceEnhanced odooService;

  OdooCustomerService(this.odooService);

  Future<List<Customer>> getCustomers({int limit = 20}) async {
    try {
      print('🔄 Obteniendo clientes desde Odoo...');
      
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_read',
          [], // Dominio vacío para traer todos
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

      print('✅ Respuesta cruda de Odoo: $result');
      
      if (result is List) {
        print('📋 Número de clientes: ${result.length}');
        return _parseCustomers(result);
      } else {
        print('❌ Respuesta inesperada: ${result.runtimeType}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting customers: $e');
      return [];
    }
  }

  // ✅ MÉTODO PARA ANALIZAR Y CONVERTIR LOS DATOS
  List<Customer> _parseCustomers(List<dynamic> rawData) {
    final customers = <Customer>[];
    
    for (var item in rawData) {
      try {
        print('🔍 Procesando item: $item');
        
        final customer = Customer(
          id: _parseInt(item['id']),
          name: _parseString(item['name']) ?? 'Sin nombre', // ✅ PROPORCIONAR VALOR POR DEFECTO
          commercialCompanyName: _parseString(item['commercial_company_name']),
          vat: _parseString(item['vat']),
          companyType: _parseString(item['company_type']) ?? 'person', // ✅ VALOR POR DEFECTO
          email: _parseString(item['email']),
          phone: _parseString(item['phone']),
          mobile: _parseString(item['mobile']),
          street: _parseString(item['street']),
          city: _parseString(item['city']),
          zip: _parseString(item['zip']),
          country: _parseCountry(item['country_id']),
          isCompany: _parseBool(item['is_company']),
        );
        
        customers.add(customer);
        print('✅ Cliente procesado: ${customer.name}');
        
      } catch (e) {
        print('❌ Error procesando cliente: $e - Item: $item');
      }
    }
    
    return customers;
  }

  // ✅ MÉTODOS AUXILIARES PARA MANEJAR TIPOS DE DATOS
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
    return false;
  }

  List<dynamic>? _parseCountry(dynamic value) {
    if (value is List) return value;
    if (value is bool) return null; // Odoo usa false para valores vacíos
    return null;
  }
}
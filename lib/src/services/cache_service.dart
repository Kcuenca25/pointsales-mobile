import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';


class CacheService {
  static const String _customersBox = 'cached_customers';
  static const String _productsBox = 'cached_products';
  
  static Box<Map>? _customersBoxInstance;
  static Box<Map>? _productsBoxInstance;

  static const Duration cacheDuration = Duration(hours: 1);

    // ✅ VERIFICAR SI DEBE ACTUALIZARSE EL CACHÉ
  static Future<bool> shouldRefreshProducts() async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>(_productsBox);
      final data = box.get('products_data');
      
      if (data == null) return true; // No hay caché, necesita actualizar
      
      final stringData = Map<String, dynamic>.from(data);
      final lastUpdate = DateTime.parse(stringData['last_update']);
      final age = DateTime.now().difference(lastUpdate);
      
      return age > cacheDuration;
    } catch (e) {
      print('❌ Error verificando caché: $e');
      return true; // En caso de error, actualizar
    }
  }

    
  // ✅ MÉTODO SIMILAR PARA CLIENTES
  static Future<bool> shouldRefreshCustomers() async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>(_customersBox);
      final data = box.get('customers_data');
      
      if (data == null) return true;
      
      final stringData = Map<String, dynamic>.from(data);
      final lastUpdate = DateTime.parse(stringData['last_update']);
      final age = DateTime.now().difference(lastUpdate);
      
      return age > cacheDuration;
    } catch (e) {
      print('❌ Error verificando caché clientes: $e');
      return true;
    }
  }

  

  // ✅ SINGLETON PARA CUSTOMERS BOX
  static Future<Box<Map>> _getCustomersBox() async {
    if (_customersBoxInstance != null && _customersBoxInstance!.isOpen) {
      return _customersBoxInstance!;
    }
    
    if (!Hive.isBoxOpen(_customersBox)) {
      _customersBoxInstance = await Hive.openBox<Map>(_customersBox);
    } else {
      _customersBoxInstance = Hive.box<Map>(_customersBox);
    }
    
    return _customersBoxInstance!;
  }

  // ✅ SINGLETON PARA PRODUCTS BOX
  static Future<Box<Map>> _getProductsBox() async {
    if (_productsBoxInstance != null && _productsBoxInstance!.isOpen) {
      return _productsBoxInstance!;
    }
    
    if (!Hive.isBoxOpen(_productsBox)) {
      _productsBoxInstance = await Hive.openBox<Map>(_productsBox);
    } else {
      _productsBoxInstance = Hive.box<Map>(_productsBox);
    }
    
    return _productsBoxInstance!;
  }

  static String _getTimestamp() {
    return '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]';
  }

  // ✅ GUARDAR CLIENTES EN CACHÉ
  static Future<void> saveCustomers(List<Customer> customers) async {
    try {
      final box = await _getCustomersBox();
      await box.put('customers_data', {
        'data': customers.map((c) => _customerToMap(c)).toList(),
        'last_update': DateTime.now().toIso8601String(),
        'count': customers.length,
      });
      print('${_getTimestamp()} 💾 ${customers.length} clientes guardados en caché');
    } catch (e) {
      print('${_getTimestamp()} ❌ Error guardando clientes en caché: $e');
    }
  }
  
  static Future<List<Customer>> getCachedCustomers() async {
  try {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_customersBox);
    final data = box.get('customers_data');
    
    if (data != null) {
      // ✅ CONVERTIR Map<dynamic, dynamic> a Map<String, dynamic>
      final stringData = Map<String, dynamic>.from(data);
      
      final customers = (stringData['data'] as List)
          .map((map) => _mapToCustomer(map as Map<dynamic, dynamic>))
          .toList();
      
      final lastUpdate = DateTime.parse(stringData['last_update']);
      final age = DateTime.now().difference(lastUpdate);
      
      print('📦 Cargando ${customers.length} clientes cacheados (${age.inHours}h ${age.inMinutes.remainder(60)}min)');
      return customers;
    }
  } catch (e) {
    print('❌ Error cargando clientes cacheados: $e');
  }
  return [];
}

  //  GUARDAR PRODUCTOS EN CACHÉ
  static Future<void> saveProducts(List<Product> products) async {
    try {
      final box = await Hive.openBox<Map>(_productsBox);
      await box.put('products_data', {
        'data': products.map((p) => _productToMap(p)).toList(),
        'last_update': DateTime.now().toIso8601String(),
        'count': products.length,
      });
      print('💾 ${products.length} productos guardados en caché');
    } catch (e) {
      print('❌ Error guardando productos en caché: $e');
    }
  }
  
  // ✅ OBTENER PRODUCTOS DEL CACHÉ
 static Future<List<Product>> getCachedProducts() async {
  try {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_productsBox);
    final data = box.get('products_data');
    
    if (data != null) {
      // ✅ CONVERTIR Map<dynamic, dynamic> a Map<String, dynamic>
      final stringData = Map<String, dynamic>.from(data);
      
      final products = (stringData['data'] as List)
          .map((map) => _mapToProduct(map as Map<dynamic, dynamic>))
          .toList();
      
      final lastUpdate = DateTime.parse(stringData['last_update']);
      final age = DateTime.now().difference(lastUpdate);
      
      print('📦 Cargando ${products.length} productos cacheados (${age.inHours}h ${age.inMinutes.remainder(60)}min)');
      return products;
    }
  } catch (e) {
    print('❌ Error cargando productos cacheados: $e');
  }
  return [];
}
  
  // ✅ CONVERTIR CUSTOMER A MAP
  static Map<String, dynamic> _customerToMap(Customer customer) {
    return {
      'id': customer.id,
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'mobile': customer.mobile,
      'street': customer.street,
      'city': customer.city,
      'zip': customer.zip,
      'vat': customer.vat,
      'company_type': customer.companyType,
      'commercial_company_name': customer.commercialCompanyName,
      'is_company': customer.isCompany,
      'country_id': customer.countryId,
    };
  }
  
  // ✅ CONVERTIR MAP A CUSTOMER
 static Customer _mapToCustomer(Map<dynamic, dynamic> map) {
  // Convertir Map<dynamic, dynamic> a Map<String, dynamic>
  final stringMap = Map<String, dynamic>.from(map);
  
  return Customer(
    id: stringMap['id'] ?? 0,
    name: stringMap['name'] ?? '',
    email: stringMap['email'],
    phone: stringMap['phone'],
    mobile: stringMap['mobile'],
    street: stringMap['street'],
    city: stringMap['city'],
    zip: stringMap['zip'],
    vat: stringMap['vat'],
    companyType: stringMap['company_type'],
    commercialCompanyName: stringMap['commercial_company_name'],
    isCompany: stringMap['is_company'] ?? false,
    countryId: stringMap['country_id'],
  );
}
  
  // ✅ CONVERTIR PRODUCT A MAP
static Map<String, dynamic> _productToMap(Product product) {
  return {
    'id': product.id,
    'name': product.name,
    'default_code': product.defaultCode,
    'barcode': product.barcode,
    'list_price': product.listPrice,
    'standard_price': product.standardPrice,
    'type': product.type,
    'categ_id': product.categoryId,
    'category_name': product.categoryName,
    'description': product.description,
    // ❌ NO INCLUIR LOS GETTERS - se calculan dinámicamente
    'image': product.image,
    'rating_rate': product.ratingRate,
    'rating_count': product.ratingCount,
    'taxes_ids': product.taxesIds,
    'supplier_taxes_ids': product.supplierTaxesIds,
  };
}

// ✅ CONVERTIR MAP A PRODUCT (VERSIÓN CORREGIDA)
static Product _mapToProduct(Map<dynamic, dynamic> map) {
  // Convertir Map<dynamic, dynamic> a Map<String, dynamic>
  final stringMap = Map<String, dynamic>.from(map);
  
  return Product(
    id: stringMap['id'] ?? 0,
    name: stringMap['name'] ?? '',
    defaultCode: stringMap['default_code'],
    barcode: stringMap['barcode'],
    listPrice: stringMap['list_price'] ?? 0.0,
    standardPrice: stringMap['standard_price'],
    type: stringMap['type'] ?? 'consu',
    categoryId: stringMap['categ_id'],
    categoryName: stringMap['category_name'],
    description: stringMap['description'],
    image: stringMap['image'],
    ratingRate: stringMap['rating_rate'],
    ratingCount: stringMap['rating_count'],
    taxesIds: stringMap['taxes_ids'] != null ? List<dynamic>.from(stringMap['taxes_ids']) : null,
    supplierTaxesIds: stringMap['supplier_taxes_ids'] != null ? List<dynamic>.from(stringMap['supplier_taxes_ids']) : null,
  );
}
  // ✅ OBTENER INFORMACIÓN DEL CACHÉ
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final customersBox = await Hive.openBox<Map>(_customersBox);
      final productsBox = await Hive.openBox<Map>(_productsBox);
      
      final customersData = customersBox.get('customers_data');
      final productsData = productsBox.get('products_data');
      
      return {
        'has_customers': customersData != null,
        'has_products': productsData != null,
        'customers_count': customersData?['count'] ?? 0,
        'products_count': productsData?['count'] ?? 0,
        'customers_last_update': customersData?['last_update'],
        'products_last_update': productsData?['last_update'],
      };
    } catch (e) {
      return {};
    }
  }
  
  // ✅ LIMPIAR CACHÉ
  static Future<void> clearCache() async {
    try {
      final customersBox = await Hive.openBox<Map>(_customersBox);
      final productsBox = await Hive.openBox<Map>(_productsBox);
      
      await customersBox.clear();
      await productsBox.clear();
      
      print('🗑️ Caché limpiado correctamente');
    } catch (e) {
      print('❌ Error limpiando caché: $e');
    }
  }
  
  
}

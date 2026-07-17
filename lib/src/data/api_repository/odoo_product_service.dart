// odoo_product_service.dart
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
//import 'package:ecomerce_app/src/domain/models/customer_model.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class OdooProductService {
   final OdooServiceEnhanced odooService;

   OdooProductService(this.odooService);
   //  MÉTODO CON PAGINACIÓN
  Future<Map<String, dynamic>> getProductsPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
  }) async {
    try {
      final offset = page * pageSize;
      
      // ✅ DOMINIO DE BÚSQUEDA (si hay query)
      final query = searchQuery.trim();
      List<dynamic> domain = [];
      if (query.isNotEmpty) {
        domain = [
          '|', '|',
          ['name', 'ilike', query],
          ['default_code', 'ilike', query],
          ['barcode', 'ilike', query],
        ];
      }

      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_read',
          [domain], // ✅ CORREGIDO: Lista dentro de lista
          {
            'fields': [
              "id", "name", "default_code", "barcode", "list_price", 
              "standard_price", "type", "categ_id", "taxes_id", "supplier_taxes_id"
            ],
            'limit': pageSize,
            'offset': offset,
            'order': 'name asc',
            'context': odooService.getContext(),
          }
        ],
      });

      // ✅ OBTENER TOTAL DE REGISTROS
      final totalCount = await _getProductsCount(domain);

      return {
        'products': (result as List).map((item) => _parseProduct(item)).toList(),
        'totalCount': totalCount,
        'hasMore': (offset + pageSize) < totalCount,
        'currentPage': page,
        'totalPages': (totalCount / pageSize).ceil(),
      };
      
    } catch (e) {
      print('❌ Error en getProductsPaginated: $e');
      return {
        'products': [],
        'totalCount': 0,
        'hasMore': false,
        'currentPage': page,
        'totalPages': 0,
      };
    }
  }

  //  CONTAR TOTAL DE PRODUCTOS

  // ✅ CONTAR TOTAL DE PRODUCTOS
  Future<int> _getProductsCount(List<dynamic> domain) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_count',
          [domain],
        ],
      });

      return result as int;
    } catch (e) {
      print('❌ Error contando productos: $e');
      return 0;
    }
  }

  Product _parseProduct(Map<String, dynamic> item) {
    final category = item['categ_id'] as List?;
    final taxesIds = item['taxes_id'] as List?;
    final supplierTaxesIds = item['supplier_taxes_id'] as List?;
    
    return Product(
      id: _parseIntField(item['id']) ?? 0,
      name: _parseStringField(item['name']) ?? 'Sin nombre',
      defaultCode: _parseStringField(item['default_code']),
      barcode: _parseStringField(item['barcode']),
      listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
      standardPrice: _parseDoubleField(item['standard_price']),
      type: _parseStringField(item['type']) ?? 'consu',
      categoryId: _parseIntField(category?[0]),
      categoryName: _parseStringField(category?[1]),
      description: '',
      category: _parseStringField(category?[1]) ?? 'Sin categoría',
      taxesIds: taxesIds,
      supplierTaxesIds: supplierTaxesIds,
    );
  }



Future<List<Product>> getProducts({int limit = 50}) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw', // ✅ CAMBIADO de 'execute' a 'execute_kw'
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'product.product',
        'search_read',
        [[]], // ✅ DOMINIO VACÍO EN LISTA ANIDADA
        {
          'fields': [
            "id", 
            "name", 
            "default_code", 
            "barcode",
            "list_price", 
            "standard_price",
            "type", 
            "categ_id",
            "taxes_id",
            "supplier_taxes_id"
          ],
          'limit': limit,
          'context': odooService.getContext(),
        }
      ],
    });

    print('✅ Productos crudos de Odoo: $result');
    
    return (result as List).map((item) {
      try {
        final category = item['categ_id'] as List?;
        final taxesIds = item['taxes_id'] as List?;
        final supplierTaxesIds = item['supplier_taxes_id'] as List?;
        
        return Product(
          id: _parseIntField(item['id']) ?? 0,
          name: _parseStringField(item['name']) ?? 'Sin nombre',
          defaultCode: _parseStringField(item['default_code']),
          barcode: _parseStringField(item['barcode']),
          listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
          standardPrice: _parseDoubleField(item['standard_price']),
          type: _parseStringField(item['type']) ?? 'consu',
          categoryId: _parseIntField(category?[0]),
          categoryName: _parseStringField(category?[1]),
          description: '',
          category: _parseStringField(category?[1]) ?? 'Sin categoría',
          taxesIds: taxesIds,
          supplierTaxesIds: supplierTaxesIds,
        );
      } catch (e) {
        print('❌ Error procesando producto: $e - Item: $item');
        return Product(
          id: 0,
          name: 'Producto con error',
          defaultCode: '',
          listPrice: 0.0,
          type: 'consu',
        );
      }
    }).where((product) => product.id != 0).toList();
  } catch (e) {
    print('❌ Error getting products: $e');
    rethrow;
  }
}

  // ✅ MÉTODO CORREGIDO PARA CAMPOS STRING - MANEJA bool Y String
  String? _parseStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is bool) return null; // Cuando Odoo devuelve false
    if (value is num) return value.toString();
    return null;
  }

  // ✅ MÉTODO PARA CAMPOS DOUBLE
  double? _parseDoubleField(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ✅ MÉTODO PARA CAMPOS INT
  int? _parseIntField(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<List<Product>> searchProducts(String searchTerm, {int limit = 20}) async {
    try {
      final query = searchTerm.trim();
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_read',
          [
            [
              '|', '|',
              ['name', 'ilike', query],
              ['default_code', 'ilike', query],
              ['barcode', 'ilike', query]
            ]
          ],
          {
            'fields': [
              'id', 'name', 'default_code', 'barcode', 'list_price',
              'standard_price', 'type', 'categ_id', 'description',
              'taxes_id', 'supplier_taxes_id',
              'qty_available', 'uom_id'
            ],
            'limit': limit,
            'context': odooService.getContext(),
          }
        ],
      });

      final products = (result as List).cast<Map<String, dynamic>>();
      return products.map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      print('❌ Error buscando productos: $e');
      return [];
    }
  }


  // ✅ MÉTODO PARA OBTENER DETALLES COMPLETOS DE UN PRODUCTO
Future<Product?> getProductDetails(int productId) async {
  try {
    // Primero intenta con read
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'product.product',
        'read',
        [[productId]]
      ],
    });

    // Si no funciona con read, intenta con search_read
    if (result == null || (result is List && result.isEmpty)) {
      final searchResult = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_read',
          [
            [['id', '=', productId]]
          ],
          {
            'fields': [
              "id", "name", "default_code", "barcode", "list_price", 
              "standard_price", "type", "categ_id", "taxes_id", 
              "supplier_taxes_id", "description"
            ],
            'limit': 1,
          }
        ],
      });

      final products = (searchResult as List).cast<Map<String, dynamic>>();
      if (products.isEmpty) return null;
      
      final item = products.first;
      final category = item['categ_id'] as List?;
      final taxesIds = item['taxes_id'] as List?;
      final supplierTaxesIds = item['supplier_taxes_id'] as List?;
      
      return Product(
        id: _parseIntField(item['id']) ?? 0,
        name: _parseStringField(item['name']) ?? 'Sin nombre',
        defaultCode: _parseStringField(item['default_code']),
        barcode: _parseStringField(item['barcode']),
        listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
        standardPrice: _parseDoubleField(item['standard_price']),
        type: _parseStringField(item['type']) ?? 'consu',
        categoryId: _parseIntField(category?[0]),
        categoryName: _parseStringField(category?[1]),
        description: _parseStringField(item['description']) ?? '',
        category: _parseStringField(category?[1]) ?? 'Sin categoría',
        taxesIds: taxesIds,
        supplierTaxesIds: supplierTaxesIds,
      );
    }

    // Si read funcionó
    if (result is List && result.isNotEmpty) {
      final item = result[0];
      final category = item['categ_id'] as List?;
      final taxesIds = item['taxes_id'] as List?;
      final supplierTaxesIds = item['supplier_taxes_id'] as List?;
      
      return Product(
        id: _parseIntField(item['id']) ?? 0,
        name: _parseStringField(item['name']) ?? 'Sin nombre',
        defaultCode: _parseStringField(item['default_code']),
        barcode: _parseStringField(item['barcode']),
        listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
        standardPrice: _parseDoubleField(item['standard_price']),
        type: _parseStringField(item['type']) ?? 'consu',
        categoryId: _parseIntField(category?[0]),
        categoryName: _parseStringField(category?[1]),
        description: _parseStringField(item['description']) ?? '',
        category: _parseStringField(category?[1]) ?? 'Sin categoría',
        taxesIds: taxesIds,
        supplierTaxesIds: supplierTaxesIds,
      );
    }
    
    return null;
    
  } catch (e) {
    print('❌ Error getting product details: $e');
    return null;
  }
}

     Future<bool> checkProductByBarcode(String barcode) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_count',
          [
            ['|', ['barcode', '=', barcode], ['default_code', '=', barcode]]
          ],
        ],
      });

      return (result as int) > 0;
    } catch (e) {
      print('❌ Error verificando producto por código: $e');
      return false;
    }
  }

  /// Retorna TODOS los productos que coincidan con el código de barras o código interno.
  /// Útil cuando un mismo código está asignado a múltiples variantes (ej: tallas diferentes).
  Future<List<Product>> getProductsByBarcode(String barcodeIn) async {
    try {
      final barcode = barcodeIn.trim();
      print('🚀 Buscando TODOS los productos con código: "$barcode"');
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'product.product',
          'search_read',
          [
            ['|', ['barcode', 'ilike', barcode], ['default_code', 'ilike', barcode]]
          ],
          {
            'fields': [
              'id', 'name', 'default_code', 'barcode', 'list_price',
              'standard_price', 'type', 'categ_id', 'description',
              'taxes_id', 'supplier_taxes_id',
              'qty_available', 'uom_id'
            ],
            'limit': 20,
            'context': odooService.getContext(),
          }
        ],
      });

      final products = (result as List).cast<Map<String, dynamic>>();
      print('📦 Total productos encontrados para "$barcode": ${products.length}');
      return products.map((p) => _parseProduct(p)).toList();
    } catch (e) {
      print('❌ Error buscando productos por barcode: $e');
      return [];
    }
  }

  /// Retorna el primer producto que coincida (compatibilidad con código existente).
  Future<Product?> getProductByBarcode(String barcodeIn) async {
    final products = await getProductsByBarcode(barcodeIn);
    return products.isNotEmpty ? products.first : null;
  }

Future<Product?> getProductRealTime(int productId) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName, // ✅ CORREGIDO: odooService (no _odooService)
        odooService.uid,    // ✅ CORREGIDO
        odooService.password, // ✅ CORREGIDO
        'product.product',
        'read',
        [[productId]], // ✅ DOBLE LISTA: [[productId]]
        { // ✅ LOS CAMPOS VAN EN UN DICCIONARIO
          'fields': [
            "id", "name", "list_price", "default_code", "barcode", 
            "type", "categ_id", "taxes_id", "supplier_taxes_id", "description"
          ]
        }
      ],
    });

    if (result is List && result.isNotEmpty) {
      final item = result[0];
      final category = item['categ_id'] as List?;
      
      return Product(
        id: _parseIntField(item['id']) ?? 0,
        name: _parseStringField(item['name']) ?? 'Sin nombre',
        listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
        defaultCode: _parseStringField(item['default_code']),
        barcode: _parseStringField(item['barcode']),
        type: _parseStringField(item['type']) ?? 'consu',
        categoryId: _parseIntField(category?[0]),
        categoryName: _parseStringField(category?[1]),
        description: _parseStringField(item['description']) ?? '',
        category: _parseStringField(category?[1]) ?? 'Sin categoría',
        standardPrice: null, // Agregar si es necesario
        taxesIds: item['taxes_id'] as List?,
        supplierTaxesIds: item['supplier_taxes_id'] as List?,
      );
    }
    return null;
  } catch (e) {
    print('❌ Error obteniendo producto en tiempo real: $e');
    return null;
  }
}
}

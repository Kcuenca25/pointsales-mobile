// odoo_product_service.dart
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
//import 'package:ecomerce_app/src/domain/models/customer_model.dart';

class OdooProductService {
  final OdooServiceEnhanced _odooService;

  OdooProductService(this._odooService);
   //  MÉTODO CON PAGINACIÓN
  Future<Map<String, dynamic>> getProductsPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
  }) async {
    try {
      final offset = page * pageSize;
      
      //  DOMINIO DE BÚSQUEDA (si hay query)
      List<dynamic> domain = [];
      if (searchQuery.isNotEmpty) {
        domain = [
          ['name', 'ilike', searchQuery]
        ];
      }

      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_read',
          domain, // Usar dominio de búsqueda
          {
            'fields': [
              "id", "name", "default_code", "barcode", "list_price", 
              "standard_price", "type", "categ_id", "taxes_id", "supplier_taxes_id"
            ],
            'limit': pageSize,
            'offset': offset, // ✅ PAGINACIÓN
            'order': 'name asc', // ✅ ORDEN CONSISTENTE
          }
        ],
      });

      //  OBTENER TOTAL DE REGISTROS (para paginación)
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
      rethrow;
    }
  }

  //  CONTAR TOTAL DE PRODUCTOS
  Future<int> _getProductsCount(List<dynamic> domain) async {
    try {
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_count',
          [domain], // Mismo dominio para contar
        ],
      });

      return result as int;
    } catch (e) {
      print('❌ Error contando productos: $e');
      return 0;
    }
  }

  //  PARSER DE PRODUCTO
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
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_read',
          [],
          [
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
            defaultCode: _parseStringField(item['default_code']), // ✅ USAR MÉTODO CORREGIDO
            barcode: _parseStringField(item['barcode']), // ✅ USAR MÉTODO CORREGIDO
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
          // Retornar un producto por defecto en caso de error
          return Product(
            id: 0,
            name: 'Producto con error',
            defaultCode: '',
            listPrice: 0.0,
            type: 'consu',
          );
        }
      }).where((product) => product.id != 0).toList(); // Filtrar productos inválidos
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

  // ✅ MÉTODO PARA BUSCAR PRODUCTOS
  Future<List<Product>> searchProducts(String query) async {
    try {
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_read',
          [
            ['name', 'ilike', query]
          ],
          {
            'fields': [
              'id', 'name', 'list_price', 'categ_id', 
              'default_code', 'barcode', 'type'
            ],
          }
        ],
      });

      return (result as List).map((item) {
        final category = item['categ_id'] as List?;
        return Product(
          id: _parseIntField(item['id']) ?? 0,
          name: _parseStringField(item['name']) ?? 'Sin nombre',
          defaultCode: _parseStringField(item['default_code']),
          barcode: _parseStringField(item['barcode']),
          listPrice: _parseDoubleField(item['list_price']) ?? 0.0,
          type: _parseStringField(item['type']) ?? 'consu',
          categoryId: _parseIntField(category?[0]),
          categoryName: _parseStringField(category?[1]),
          description: '',
          category: _parseStringField(category?[1]) ?? 'Sin categoría',
        );
      }).where((product) => product.id != 0).toList();
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

  // ✅ MÉTODO PARA OBTENER DETALLES COMPLETOS DE UN PRODUCTO
  Future<Product?> getProductDetails(int productId) async {
    try {
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'read',
          [productId],
          [
            "id", "name", "default_code", "barcode", "list_price", 
            "standard_price", "type", "categ_id", "taxes_id", 
            "supplier_taxes_id", "description"
          ],
        ],
      });

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
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_count',
          [
            [['barcode', '=', barcode]]
          ],
        ],
      });

      return (result as int) > 0;
    } catch (e) {
      print('❌ Error verificando producto por código: $e');
      return false;
    }
  }

  // ✅ BUSCAR PRODUCTO POR CÓDIGO DE BARRAS
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final result = await _odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _odooService.dbName,
          _odooService.uid,
          _odooService.password,
          'product.product',
          'search_read',
          [
            [['barcode', '=', barcode]]
          ],
          {
            'fields': [
              'id', 'name', 'default_code', 'barcode', 'list_price',
              'standard_price', 'type', 'categ_id', 'qty_available'
            ],
          }
        ],
      });

      if (result is List && result.isNotEmpty) {
        final item = result[0];
        final category = item['categ_id'] as List?;
        
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
          stockQuantity: _parseDoubleField(item['qty_available']) ?? 0.0,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error buscando producto por código: $e');
      return null;
    }
  }

 Future<Product?> getProductRealTime(int productId) async {
  try {
    final result = await _odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        _odooService.dbName,
        _odooService.uid,
        _odooService.password,
        'product.product',
        'read',
        [productId],
        ["id", "name", "list_price", "default_code", "barcode", "type", "categ_id"] // ✅ AGREGAR type y categ_id
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
        type: _parseStringField(item['type']) ?? 'consu', // ✅ REQUERIDO
        categoryId: _parseIntField(category?[0]),
        categoryName: _parseStringField(category?[1]),
      );
    }
    return null;
  } catch (e) {
    print('❌ Error obteniendo producto en tiempo real: $e');
    return null;
  }
}
}
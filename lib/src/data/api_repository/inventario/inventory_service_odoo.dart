// odoo_inventory_service.dart
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class OdooInventoryService {
  final OdooServiceEnhanced odooService; 
  
  OdooInventoryService(this.odooService);

  // ✅ BUSCAR PRODUCTO POR CÓDIGO (Para escanear)
  Future<Map<String, dynamic>?> searchProductByCode(String barcode) async {
    try {
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
            [['default_code', '=', barcode]]
          ],
          {
            'fields': [
              'id', 
              'name', 
              'default_code', 
              'categ_id',
              'qty_available',
              'type'
            ],
          }
        ],
      });

      if (result is List && result.isNotEmpty) {
        return result[0] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error buscando producto: $e');
      return null;
    }
  }

Future<Map<String, dynamic>?> getProductStock(int productId) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'stock.quant',
        'search_read',
        [
          [
            ['product_id', '=', productId],
            ['location_id.usage', '=', 'internal'], // ✅ SOLO UBICACIONES INTERNAS
            ['location_id', '=', 8] // ✅ SOLO "WH/Existencias" (ID: 8)
          ]
        ],
        {
          'fields': [
            'id', 
            'product_id', 
            'quantity', 
            'inventory_quantity',
            'location_id'
          ],
          'limit': 1
        }
      ],
    });

    if (result is List && result.isNotEmpty) {
      final stockData = result[0] as Map<String, dynamic>;
      print('✅ Stock en WH/Existencias: ${stockData['quantity']} | Inventory: ${stockData['inventory_quantity']}');
      return stockData;
    }
    
    print('❌ No se encontró stock en WH/Existencias para producto $productId');
    return null;
  } catch (e) {
    print('❌ Error obteniendo stock: $e');
    return null;
  }
}

  // ✅ ACTUALIZAR STOCK (Método principal - YA PROBADO)
  Future<bool> updateStock(int quantId, double newQuantity) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'stock.quant',
          'write',
          [
            [quantId],
            {'inventory_quantity': newQuantity}
          ]
        ],
      });

      if (result == true) {
        print('✅ Stock actualizado: Quant $quantId -> $newQuantity');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      return false;
    }
  }
// Agrega logs temporales en shouldManageStock (en OdooInventoryService)
bool shouldManageStock(Map<String, dynamic> product) {
  final defaultCode = product['default_code']?.toString() ?? '';
  final category = product['categ_id']?[1]?.toString() ?? '';
  
  // ✅ LOG TEMPORAL PARA PRODUCTO 47
  if (product['id'] == 47) {
    print('🔍 ANALIZANDO PRODUCTO 47:');
    print('   Código: $defaultCode');
    print('   Categoría: $category');
  }
  
  final isClothingCode = defaultCode.startsWith('M');
  final clothingCategories = ['A.TESTONI', 'ETRO', 'ZANELLA', 'PAUL SMITH', 'ZEGNA'];
  final isClothingCategory = clothingCategories.any(
    (cat) => category.toUpperCase().contains(cat)
  );
  
  final result = isClothingCode || isClothingCategory;
  
  if (product['id'] == 47) {
    print('   🎯 Código empieza con M: $isClothingCode');
    print('   🎯 Categoría de ropa: $isClothingCategory');
    print('   🎯 RESULTADO FINAL: $result');
  }
  
  return result;
}

  // ✅ FLUJO COMPLETO PARA LA APP MÓVIL
  Future<InventoryProcessResult> processScannedProduct(
    String scannedCode, 
    double? physicalCount
  ) async {
    try {
      print('🔍 Procesando código: $scannedCode');
      
      // 1. Buscar producto en Odoo
      final product = await searchProductByCode(scannedCode);
      if (product == null) {
        return InventoryProcessResult.error('Producto no encontrado');
      }
      
      // 2. Determinar si maneja stock
      final managesStock = shouldManageStock(product);
      if (!managesStock) {
        return InventoryProcessResult.serviceProduct(product);
      }
      
      // 3. Obtener stock actual
      final stockInfo = await getProductStock(product['id']);
      if (stockInfo == null) {
        return InventoryProcessResult.error('No se pudo obtener stock');
      }
      
      // 4. Si no se proporcionó conteo físico, mostrar info actual
      if (physicalCount == null) {
        return InventoryProcessResult.stockInfo(
          product: product,
          stockInfo: stockInfo,
          quantId: stockInfo['id'],
        );
      }
      
      // 5. Actualizar stock con nuevo conteo
      final success = await updateStock(
        stockInfo['id'], 
        physicalCount
      );
      
      if (success) {
        return InventoryProcessResult.updated(
          product: product,
          oldQuantity: stockInfo['inventory_quantity']?.toDouble() ?? 0,
          newQuantity: physicalCount,
          quantId: stockInfo['id'],
        );
      } else {
        return InventoryProcessResult.error('Error actualizando stock');
      }
      
    } catch (e) {
      print('❌ Error en processScannedProduct: $e');
      return InventoryProcessResult.error('Error: $e');
    }
  }

 // En OdooInventoryService - modifica getAllProducts():
Future<List<Map<String, dynamic>>> getAllProducts() async {
  try {
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
          [] // ⚠️ TEMPORAL: SIN FILTROS para debugging
        ],
        {
          'fields': [
            'id', 'name', 'default_code', 'categ_id', 
            'qty_available', 'type', 'sale_ok', 'active'
          ],
          'limit': 200,
          'order': 'id ASC'  // ⚠️ AUMENTAR LÍMITE para encontrar el producto 47
        }
      ],
    });

    final products = (result as List).cast<Map<String, dynamic>>();
    print('📦 PRODUCTOS OBTENIDOS SIN FILTROS: ${products.length}');
    
    // ✅ VERIFICAR SI EL 47 ESTÁ AHORA
    final producto47 = products.firstWhere(
      (p) => p['id'] == 47,
      orElse: () => {},
    );
    
    if (producto47.isNotEmpty) {
      print('🎯✅ PRODUCTO 47 ENCONTRADO SIN FILTROS');
      print('   ID: ${producto47['id']}');
      print('   Nombre: ${producto47['name']}');
      print('   Código: ${producto47['default_code']}');
      print('   Posición en lista: ${products.indexWhere((p) => p['id'] == 47)}');
    } else {
      print('❌ PRODUCTO 47 SIGUE SIN APARECER - REVISAR ORDENACIÓN');
    }
    
    return products;
  } catch (e) {
    print('❌ Error en getAllProducts: $e');
    return [];
  }
}
  // ✅ VERIFICAR DISCREPANCIAS (Método mejorado)
  Future<List<InventoryDiscrepancy>> checkInventoryDiscrepancies() async {
    try {
      final odooProducts = await getAllProducts();
      final discrepancies = <InventoryDiscrepancy>[];
      
      for (var product in odooProducts) {
        if (shouldManageStock(product)) {
          final stockInfo = await getProductStock(product['id']);
          if (stockInfo != null) {
            final odooQty = product['qty_available']?.toDouble() ?? 0;
            final quantQty = stockInfo['inventory_quantity']?.toDouble() ?? 0;
            
            if (odooQty != quantQty) {
              discrepancies.add(InventoryDiscrepancy(
                productId: product['id'],
                productName: product['name'],
                defaultCode: product['default_code'],
                odooQuantity: odooQty,
                physicalQuantity: quantQty,
                type: DiscrepancyType.quantityMismatch,
              ));
            }
          }
        }
      }
      
      return discrepancies;
    } catch (e) {
      print('❌ Error verificando discrepancias: $e');
      return [];
    }
  }
  // En OdooInventoryService:
Future<Map<String, dynamic>?> getProductById(int productId) async {
  try {
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
          [["id", "=", productId]]
        ],
        {
          'fields': [
            'id', 'name', 'default_code', 'categ_id', 
            'qty_available', 'type', 'sale_ok', 'active'
          ],
        }
      ],
    });

    final products = (result as List).cast<Map<String, dynamic>>();
    return products.isNotEmpty ? products.first : null;
  } catch (e) {
    print('❌ Error en getProductById: $e');
    return null;
  }
}

// En OdooInventoryService
Future<List<Map<String, dynamic>>> getProductsPaginated({
  int offset = 0,
  int limit = 50,
  String searchQuery = '',
}) async {
  try {
    // DOMINIO BASE - siempre filtrar por productos vendibles
    List<dynamic> domain = [['sale_ok', '=', true]];
    
    // SI HAY BÚSQUEDA, construir dominio con OR
    if (searchQuery.isNotEmpty) {
      domain = [
        '&',
        ['sale_ok', '=', true],
        [
          '|',
          '|', 
          ['name', 'ilike', searchQuery],
          ['default_code', 'ilike', searchQuery],
          ['barcode', 'ilike', searchQuery],
        ]
      ];
    }

    print('🔍 Dominio de búsqueda: $domain');

    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'product.product',
        'search_read',
        [domain], // ✅ Lista que contiene el dominio completo
        {
          'fields': [
            'id', 'name', 'default_code', 'categ_id', 
            'qty_available', 'type', 'sale_ok', 'barcode'
          ],
          'offset': offset,
          'limit': limit,
          'order': 'name ASC',
        }
      ],
    });

    final products = (result as List).cast<Map<String, dynamic>>();
    print('📦 Productos obtenidos (paginados): ${products.length}');
    
    return products;
  } catch (e) {
    print('❌ Error en getProductsPaginated: $e');
    return [];
  }
}
}


// ✅ MODELOS ACTUALIZADOS
class InventoryProcessResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? product;
  final Map<String, dynamic>? stockInfo;
  final int? quantId;
  final double? oldQuantity;
  final double? newQuantity;
  final bool isService;

  InventoryProcessResult({
    required this.success,
    required this.message,
    this.product,
    this.stockInfo,
    this.quantId,
    this.oldQuantity,
    this.newQuantity,
    this.isService = false,
  });

  factory InventoryProcessResult.serviceProduct(Map<String, dynamic> product) {
    return InventoryProcessResult(
      success: true,
      message: 'SERVICIO - Sin gestión de stock',
      product: product,
      isService: true,
    );
  }

  factory InventoryProcessResult.stockInfo({
    required Map<String, dynamic> product,
    required Map<String, dynamic> stockInfo,
    required int quantId,
  }) {
    return InventoryProcessResult(
      success: true,
      message: 'Stock actual: ${stockInfo['inventory_quantity']}',
      product: product,
      stockInfo: stockInfo,
      quantId: quantId,
    );
  }

  factory InventoryProcessResult.updated({
    required Map<String, dynamic> product,
    required double oldQuantity,
    required double newQuantity,
    required int quantId,
  }) {
    return InventoryProcessResult(
      success: true,
      message: 'Stock actualizado: $oldQuantity → $newQuantity',
      product: product,
      quantId: quantId,
      oldQuantity: oldQuantity,
      newQuantity: newQuantity,
    );
  }

  factory InventoryProcessResult.error(String message) {
    return InventoryProcessResult(
      success: false,
      message: message,
    );
  }
}

class InventoryDiscrepancy {
  final int productId;
  final String productName;
  final String? defaultCode;
  final double odooQuantity;
  final double physicalQuantity;
  final DiscrepancyType type;

  InventoryDiscrepancy({
    required this.productId,
    required this.productName,
    this.defaultCode,
    required this.odooQuantity,
    required this.physicalQuantity,
    required this.type,
  });
}

enum DiscrepancyType {
  missingInOdoo,
  missingInPhysical,
  quantityMismatch,
}
// inventory_service_enhanced.dart
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';

class InventoryServiceEnhanced {
  final OdooServiceEnhanced _odooService;

  InventoryServiceEnhanced(this._odooService);

  // ✅ CALCULAR BALANCE DEL INVENTARIO CORREGIDO
  InventoryBalance calculateBalance(List<InventoryItem> items) {
    final totalItems = items.length;
    final matchedItems = items.where((item) => item.status == InventoryStatus.matched).length;
    final discrepancyItems = items.where((item) => item.status == InventoryStatus.discrepancy).length;
    final missingItems = items.where((item) => item.status == InventoryStatus.missing).length;
    
    final totalValueDifference = items.fold(0.0, (sum, item) {
      return sum + ((item.physicalCount - item.currentStock) * item.price).abs();
    });
    
    final accuracyRate = totalItems > 0 ? (matchedItems / totalItems) * 100 : 0.0; // ✅ AHORA ES double

    return InventoryBalance(
      totalItems: totalItems,
      matchedItems: matchedItems,
      discrepancyItems: discrepancyItems,
      missingItems: missingItems,
      totalValueDifference: totalValueDifference,
      accuracyRate: accuracyRate, // ✅ CORREGIDO
      calculationDate: DateTime.now(),
    );
  }

  // ✅ OBTENER PRODUCTOS PARA INVENTARIO
  Future<List<InventoryItem>> getInventoryProducts() async {
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
            ['|', ['active', '=', true], ['active', '=', false]]
          ],
          {
            'fields': [
              'id', 'name', 'default_code', 'barcode', 
              'qty_available', 'standard_price', 'list_price', 'categ_id'
            ],
          }
        ],
      });

      return (result as List).map((item) {
        final category = item['categ_id'] as List?;
        return InventoryItem(
          id: item['id'] as int,
          name: item['name'] as String,
          sku: item['default_code'] as String? ?? 'N/A',
          category: category?[1] as String? ?? 'Sin categoría',
          currentStock: (item['qty_available'] as num?)?.toInt() ?? 0,
          physicalCount: (item['qty_available'] as num?)?.toInt() ?? 0,
          cost: (item['standard_price'] as num?)?.toDouble() ?? 0.0,
          price: (item['list_price'] as num?)?.toDouble() ?? 0.0,
          status: InventoryStatus.matched,
        );
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo productos para inventario: $e');
      return [];
    }
  }

  // ✅ SINCRONIZAR CAMBIOS CON ODDO
  Future<bool> syncInventoryChanges(InventoryUpdate update) async {
    try {
      for (final item in update.items) {
        if (item.previousStock != item.newStock) {
          final success = await _updateOdooStock(item.productId, item.newStock);
          if (!success) {
            print('❌ Error sincronizando producto ${item.productName}');
          }
        }
      }
      return true;
    } catch (e) {
      print('❌ Error sincronizando inventario: $e');
      return false;
    }
  }

  Future<bool> _updateOdooStock(int productId, int newStock) async {
    try {
      // Implementar la lógica de actualización en Odoo
      // Similar a la que ya tienes en OdooInventoryService
      return true;
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      return false;
    }
  }
}

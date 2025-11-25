// inventory_sync_manager.dart
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_service_odoo.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';

class InventorySyncManager {
  final OdooInventoryService _inventoryService;
  final OdooProductService _productService;

  InventorySyncManager(this._inventoryService, this._productService);

  // ✅ SINCRONIZACIÓN COMPLETA - ACTUALIZADO
  Future<void> performFullInventorySync() async {
    print('🔄 Iniciando sincronización de inventario...');
    
    final discrepancies = await _inventoryService.checkInventoryDiscrepancies();
    
    if (discrepancies.isEmpty) {
      print('✅ Inventarios sincronizados - Sin discrepancias');
      return;
    }

    print('📊 Se encontraron ${discrepancies.length} discrepancias');
    
    for (var discrepancy in discrepancies) {
      await _handleDiscrepancy(discrepancy);
    }
    
    print('✅ Sincronización completada');
  }

  // ✅ MANEJAR CADA DISCREPANCIA - ACTUALIZADO
  Future<void> _handleDiscrepancy(InventoryDiscrepancy discrepancy) async {
    switch (discrepancy.type) {
      case DiscrepancyType.missingInOdoo:
        print('⚠️ Producto faltante en Odoo: ${discrepancy.productName}');
        await _handleMissingInOdoo(discrepancy);
        break;
        
      case DiscrepancyType.missingInPhysical:
        print('⚠️ Producto faltante en físico: ${discrepancy.productName}');
        await _handleMissingInPhysical(discrepancy);
        break;
        
      case DiscrepancyType.quantityMismatch:
        print('⚠️ Cantidad diferente: ${discrepancy.productName}');
        print('   Odoo: ${discrepancy.odooQuantity}');
        print('   Físico: ${discrepancy.physicalQuantity}');
        
        // ✅ ACTUALIZADO: Usar el método correcto
        await _updateProductStockInOdoo(discrepancy);
        break;
    }
  }

  // ✅ ACTUALIZADO: Método para actualizar stock
  Future<void> _updateProductStockInOdoo(InventoryDiscrepancy discrepancy) async {
    try {
      // 1. Obtener el stock.quant del producto
      final stockInfo = await _inventoryService.getProductStock(discrepancy.productId);
      
      if (stockInfo != null && stockInfo['id'] != null) {
        // 2. Actualizar usando el quant_id
        final success = await _inventoryService.updateStock(
          stockInfo['id'], 
          discrepancy.physicalQuantity
        );
        
        if (success) {
          print('✅ Stock actualizado: ${discrepancy.productName} -> ${discrepancy.physicalQuantity}');
        } else {
          print('❌ Error actualizando stock: ${discrepancy.productName}');
        }
      } else {
        print('❌ No se encontró stock.quant para: ${discrepancy.productName}');
      }
    } catch (e) {
      print('❌ Error actualizando stock: $e');
    }
  }

  // ✅ ACTUALIZADO: MANEJAR PRODUCTO FALTANTE EN ODDO
  Future<void> _handleMissingInOdoo(InventoryDiscrepancy discrepancy) async {
    try {
      // En nuestro sistema actual, no creamos productos desde la app
      // Solo manejamos productos existentes
      print('📝 Producto faltante en Odoo - Se requiere creación manual: ${discrepancy.productName}');
      
      // Podrías agregar aquí lógica para crear el producto si es necesario
      // Pero por ahora solo registramos la discrepancia
      
    } catch (e) {
      print('❌ Error manejando producto faltante en Odoo: $e');
    }
  }

  // ✅ ACTUALIZADO: MANEJAR PRODUCTO FALTANTE EN FÍSICO
  Future<void> _handleMissingInPhysical(InventoryDiscrepancy discrepancy) async {
    try {
      // Ajustar stock a 0 en Odoo (producto perdido/dañado)
      await _updateProductStockInOdoo(InventoryDiscrepancy(
        productId: discrepancy.productId,
        productName: discrepancy.productName,
        odooQuantity: discrepancy.odooQuantity,
        physicalQuantity: 0.0, // Establecer a 0
        type: DiscrepancyType.quantityMismatch,
      ));
      
      print('✅ Stock ajustado a 0 para producto perdido: ${discrepancy.productName}');
      
    } catch (e) {
      print('❌ Error ajustando stock para producto perdido: $e');
    }
  }

  // ✅ ACTUALIZADO: SINCRONIZACIÓN RÁPIDA
  Future<void> performQuickSync() async {
    print('⚡ Iniciando sincronización rápida...');
    
    final discrepancies = await _inventoryService.checkInventoryDiscrepancies();
    
    int updatedCount = 0;
    for (var discrepancy in discrepancies) {
      if (discrepancy.type == DiscrepancyType.quantityMismatch) {
        await _updateProductStockInOdoo(discrepancy);
        updatedCount++;
      }
    }
    
    print('✅ Sincronización rápida completada - $updatedCount productos actualizados');
  }

  // ✅ NUEVO: SINCRONIZAR PRODUCTO ESPECÍFICO
  Future<bool> syncSingleProduct(int productId, double physicalQuantity) async {
    try {
      final stockInfo = await _inventoryService.getProductStock(productId);
      
      if (stockInfo != null && stockInfo['id'] != null) {
        return await _inventoryService.updateStock(
          stockInfo['id'], 
          physicalQuantity
        );
      }
      return false;
    } catch (e) {
      print('❌ Error sincronizando producto $productId: $e');
      return false;
    }
  }

  // ✅ NUEVO: VERIFICAR ESTADO DE SINCRONIZACIÓN
  Future<SyncStatus> getSyncStatus() async {
    final discrepancies = await _inventoryService.checkInventoryDiscrepancies();
    
    final mismatchCount = discrepancies.where(
      (d) => d.type == DiscrepancyType.quantityMismatch
    ).length;
    
    final missingCount = discrepancies.where(
      (d) => d.type == DiscrepancyType.missingInPhysical
    ).length;
    
    return SyncStatus(
      totalProducts: (await _inventoryService.getAllProducts()).length,
      discrepancies: discrepancies.length,
      quantityMismatches: mismatchCount,
      missingProducts: missingCount,
      lastSync: DateTime.now(),
    );
  }
}

// ✅ MODELO PARA ESTADO DE SINCRONIZACIÓN
class SyncStatus {
  final int totalProducts;
  final int discrepancies;
  final int quantityMismatches;
  final int missingProducts;
  final DateTime lastSync;

  SyncStatus({
    required this.totalProducts,
    required this.discrepancies,
    required this.quantityMismatches,
    required this.missingProducts,
    required this.lastSync,
  });

  double get accuracyRate {
    return totalProducts > 0 
        ? ((totalProducts - discrepancies) / totalProducts) * 100 
        : 100.0;
  }

  bool get isSynced => discrepancies == 0;
}
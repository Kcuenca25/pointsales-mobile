import 'package:hive/hive.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';class OfflineOrderService {
  static const String _boxName = 'offline_orders';
  static Box<Map>? _box;

  // ✅ SINGLETON PARA EVITAR ABRIR MÚLTIPLES VECES
  static Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map>(_boxName);
    } else {
      _box = Hive.box<Map>(_boxName);
    }
    
    return _box!;
  }
  
  // ✅ GUARDAR ORDEN OFFLINE
 static Future<void> saveOrderOffline({
  required int partnerId,
  required String partnerName,
  required List<Map<String, dynamic>> orderLines,
  required double total,
}) async {
  try {
    final box = await _getBox();
    
    // ✅ GENERAR ID VÁLIDO PARA HIVE (máximo 32 bits)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final validId = timestamp % 0xFFFFFFFF; // Asegurar que esté en rango válido
    
    final orderData = {
      'id': validId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'order_lines': orderLines,
      'total': total,
      'date': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
      'created_at': timestamp,
    };
    
    await box.put(validId, orderData);
    print('💾 Orden guardada offline - ID: $validId');
    
  } catch (e) {
    print('❌ Error guardando orden offline: $e');
    // ✅ FALLBACK: Usar ID secuencial si falla
    await _saveOrderWithFallbackId(partnerId, partnerName, orderLines, total);
  }
}

// ✅ MÉTODO DE FALLBACK POR SI ACASO
static Future<void> _saveOrderWithFallbackId(
  int partnerId, 
  String partnerName, 
  List<Map<String, dynamic>> orderLines, 
  double total
) async {
  try {
    final box = await _getBox();
    
    // Usar un ID secuencial simple
    final allOrders = box.values.toList();
    final nextId = allOrders.isEmpty ? 1 : (allOrders.last['id'] as int) + 1;
    
    final orderData = {
      'id': nextId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'order_lines': orderLines,
      'total': total,
      'date': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    await box.put(nextId, orderData);
    print('💾 Orden guardada offline (fallback) - ID: $nextId');
    
  } catch (e) {
    print('❌ Error crítico guardando orden: $e');
    rethrow;
  }
}
  
  // ✅ OBTENER ÓRDENES PENDIENTES (CORREGIDO)
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      final box = await _getBox();
      final allOrders = box.values.toList();
      
      final pendingOrders = allOrders
          .where((order) => order['sync_status'] == 'pending')
          .cast<Map<String, dynamic>>()
          .toList();
          
      print('📦 Órdenes pendientes encontradas: ${pendingOrders.length}');
      return pendingOrders;
    } catch (e) {
      print('❌ Error obteniendo órdenes offline: $e');
      return [];
    }
  }
  
//  MARCAR ORDEN COMO SINCRONIZADA (CORREGIDO)
static Future<void> markAsSynced(int orderId) async {
  try {
    final box = await _getBox();
    final order = box.get(orderId);
    if (order != null) {
      // ✅ CREAR NUEVO MAPA PARA EVITAR PROBLEMAS DE TIPO
      final updatedOrder = Map<String, dynamic>.from(order);
      updatedOrder['sync_status'] = 'synced';
      
      await box.put(orderId, updatedOrder);
      print('✅ Orden $orderId marcada como sincronizada');
    }
  } catch (e) {
    print('❌ Error marcando orden como sincronizada: $e');
  }
}
  // ✅ CONTAR ÓRDENES PENDIENTES
  static Future<int> getPendingCount() async {
    final pending = await getPendingOrders();
    return pending.length;
  }

  // ✅ SINCRONIZAR ÓRDENES PENDIENTES
  static Future<void> syncPendingOrders() async {
    try {
      final pendingOrders = await getPendingOrders();
      
      if (pendingOrders.isEmpty) {
        print('📭 No hay órdenes pendientes de sincronizar');
        return;
      }
      
      print('🔄 Sincronizando ${pendingOrders.length} órdenes pendientes...');
      
      for (var order in pendingOrders) {
        try {
          print('📤 Sincronizando orden offline: ${order['id']}');
          
          // Verificar conexión antes de cada orden
          final tieneInternet = await ConnectivityService.hasInternet();
          if (!tieneInternet) {
            print('❌ Sin internet, cancelando sincronización');
            return;
          }
          
          // ✅ CREAR ORDEN EN ODDO
          final odooService = OdooServiceEnhanced(
            baseUrl: 'https://pointsalesqa.tailorw.net',
            dbName: 'pointsales_prodv18',
          );
          
          await odooService.login('admin', 'admin');
          final orderService = OdooOrderService(odooService);
          
          final result = await orderService.createSaleOrder(
            partnerId: order['partner_id'],
            orderLines: List<Map<String, dynamic>>.from(order['order_lines']),
          );
          
          if (result['success'] == true) {
            // ✅ MARCAR COMO SINCRONIZADA
            await markAsSynced(order['id']);
            print('✅ Orden ${order['id']} sincronizada exitosamente → Odoo ID: ${result['order_id']}');
          } else {
            print('❌ Error sincronizando orden ${order['id']}: ${result['error']}');
          }
          
        } catch (e) {
          print('❌ Error en orden ${order['id']}: $e');
        }
      }
      
      print('🎉 Sincronización completada');
      
    } catch (e) {
      print('❌ Error general en sincronización: $e');
    }
  }
  
  // ✅ VERIFICAR Y SINCRONIZAR SI HAY INTERNET
  static Future<void> checkAndSync() async {
    final tieneInternet = await ConnectivityService.hasInternet();
    
    if (tieneInternet) {
      final pendingCount = await getPendingCount();
      if (pendingCount > 0) {
        print('🌐 Internet detectado - Sincronizando $pendingCount órdenes...');
        await syncPendingOrders();
      }
    }
  }
}

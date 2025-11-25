import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

// odoo_order_service.dart

class OdooOrderService {
  final OdooServiceEnhanced odooService;

  OdooOrderService(this.odooService);

  String _formatDateForOdoo(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
  // ✅ CREAR ORDEN CON FLUJO AUTOMÁTICO
 
  // ✅ CREAR ORDEN CON FLUJO AUTOMÁTICO (CORREGIDO)
  Future<Map<String, dynamic>> createSaleOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
  }) async {
    try {
      // Preparar líneas de la orden
      List<dynamic> orderLineValues = [];
      for (var line in orderLines) {
        orderLineValues.add([
          0, 0, {
            'product_id': line['product_id'],
            'product_uom_qty': line['quantity'],
            'price_unit': line['price_unit'],
          }
        ]);
      }

      // ✅ FECHA FORMATEADA CORRECTAMENTE
      final fechaFormateada = _formatDateForOdoo(DateTime.now());

      // Crear la orden en Odoo
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'create',
          [
            {
              'partner_id': partnerId,
              'date_order': fechaFormateada, // ✅ FORMATO CORRECTO
              'order_line': orderLineValues,
            }
          ]
        ],
      });

      final orderId = result as int;
      print('✅ Orden creada en Odoo con ID: $orderId - Estado: draft');

      // 🔄 INICIAR FLUJO AUTOMÁTICO
      _iniciarFlujoAutomatico(orderId);

      return {
        'success': true, 
        'order_id': orderId,
        'state': 'draft'
      };
      
    } catch (e) {
      print('❌ Error creando orden: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 🔄 FLUJO AUTOMÁTICO DE ESTADOS
  void _iniciarFlujoAutomatico(int orderId) {
    print('🔄 Iniciando flujo automático para orden: $orderId');
    
    // 1. draft → sent (Inmediatamente después de crear)
    _cambiarASent(orderId);
  }
  

  void _cambiarASent(int orderId) async {
    try {
      // Cambiar a estado "sent" (Enviada)
      final result = await sendQuotation(orderId);
      
      if (result['success'] == true) {
        print('📤 Orden $orderId cambiada a SENT (Enviada)');
        
        // 2. Programar cambio a SALE en 2 minutos (para prueba)
        _programarCambioASale(orderId);
      } else {
        print('❌ Error cambiando a SENT: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error en _cambiarASent: $e');
    }
  }

  void _programarCambioASale(int orderId) {
    // Para pruebas usar 2 minutos, en producción usar 30 minutos
    Duration delay = Duration(seconds: 30); // Cambiar a 30 en producción
    
    Future.delayed(delay, () async {
      try {
        // Verificar que aún está en 'sent' antes de cambiar
        final detalles = await getOrderDetails(orderId);
        if (detalles.isNotEmpty && detalles['state'] == 'sent') {
          await confirmSaleOrder(orderId);
          print('🛒 Orden $orderId cambiada a SALE (En Proceso)');
          
          // 3. Programar cambio a FACTURA
          _programarCambioAFactura(orderId);
        } else {
          print('⏸️ Orden $orderId ya no está en SENT, saltando cambio');
        }
      } catch (e) {
        print('❌ Error en _programarCambioASale: $e');
      }
    });
    
    print('⏰ Programado cambio a SALE en ${delay.inMinutes} minutos');
  }

 void _programarCambioAFactura(int orderId) {
  Duration delay = Duration(minutes: 3);
  
  Future.delayed(delay, () async {
    try {
      final detalles = await getOrderDetails(orderId);
      if (detalles['state'] == 'sale') {
        await markAsInvoiced(orderId);
        
        // ✅ AGREGAR INFO DEL TOTAL
        final total = detalles['amount_total'] ?? 0.0;
        print('✅ Orden $orderId marcada como FACTURADA (Completada)');
        print('💰 Total de la orden: \$$total');
        print('🎉 Flujo automático completado para orden: $orderId');
        
      } else {
        print('⏸️ Orden $orderId ya no está en SALE, saltando cambio');
      }
    } catch (e) {
      print('❌ Error en _programarCambioAFactura: $e');
    }
  });
}

  // ✅ CONFIRMAR ORDEN (sale → "En Proceso")
  Future<Map<String, dynamic>> confirmSaleOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'action_confirm',
          [[orderId]]
        ],
      });

      print('✅ Orden $orderId confirmada en Odoo');
      return {'success': true, 'order_id': orderId, 'state': 'sale'};
      
    } catch (e) {
      print('❌ Error confirmando orden: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ ENVIAR COTIZACIÓN (sent → "Enviada")
  Future<Map<String, dynamic>> sendQuotation(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'action_quotation_sent',
          [[orderId]]
        ],
      });

      print('✅ Cotización $orderId enviada');
      return {'success': true, 'order_id': orderId, 'state': 'sent'};
      
    } catch (e) {
      print('❌ Error enviando cotización: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CANCELAR ORDEN (cancel → "Cancelada")
  Future<Map<String, dynamic>> cancelSaleOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'write',
          [
            [orderId],
            {"state": "cancel"}
          ]
        ],
      });

      if (result == true) {
        print('✅ Orden $orderId cancelada');
        return {'success': true, 'order_id': orderId, 'state': 'cancel'};
      } else {
        return {'success': false, 'error': 'No se pudo cancelar la orden'};
      }
      
    } catch (e) {
      print('❌ Error cancelando orden: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ MARCAR COMO FACTURADA/COMPLETADA
  Future<Map<String, dynamic>> markAsInvoiced(int orderId) async {
    try {
      // Agregar nota indicando que fue facturada/completada
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'write',
          [
            [orderId],
            {
              "note": "✅ Pedido facturado y completado - ${DateTime.now()}"
            }
          ]
        ],
      });

      if (result == true) {
        print('✅ Orden $orderId marcada como facturada/completada');
        return {'success': true, 'order_id': orderId, 'invoiced': true};
      } else {
        return {'success': false, 'error': 'No se pudo actualizar la orden'};
      }
      
    } catch (e) {
      print('❌ Error marcando como facturada: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ OBTENER DETALLES DE ORDEN
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'search_read',
          [
            [["id", "=", orderId]]
          ],
          {
            'fields': [
              "id", "name", "state", "date_order", "partner_id", 
              "amount_total", "invoice_status", "order_line", "note"
            ]
          }
        ],
      });

      final orders = (result as List).cast<Map<String, dynamic>>();
      return orders.isNotEmpty ? orders.first : {};
      
    } catch (e) {
      print('❌ Error obteniendo detalles: $e');
      return {};
    }
  }

  // ✅ OBTENER TODAS LAS ÓRDENES
  Future<List<Map<String, dynamic>>> getSaleOrders({int limit = 50}) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'sale.order',
          'search_read',
          [],
          {
            'fields': [
              "id", "name", "state", "date_order", "partner_id", 
              "amount_total", "invoice_status", "note"
            ],
            'limit': limit,
            'order': 'id desc',
          }
        ],
      });

      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo órdenes: $e');
      return [];
    }
  }
}
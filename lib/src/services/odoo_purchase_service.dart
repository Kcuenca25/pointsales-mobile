import 'package:ecomerce_app/src/domain/models/purchase_order_state.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdooPurchaseService {
  final OdooServiceEnhanced odooService;

  OdooPurchaseService(this.odooService);

Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
  try {
    print('🔄 CARGANDO ÓRDENES DE COMPRA CON DETALLES...');
    
    // ✅ FILTRO AMIGABLE: 
    // 1. Mostrar borradores (para ver P00124)
    // 2. Solo últimos 30 días (para ocultar P00001 del 2025)
    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final String dateFilter = thirtyDaysAgo.toIso8601String().split('T')[0];
    
    print('📅 Filtrando órdenes desde: $dateFilter hasta hoy');
    
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order',
        'search_read',
        [
          // ✅ FILTROS: Dominio de Odoo
          [
            ['date_order', '>=', dateFilter],
            // ['state', 'not in', ['draft', 'cancel']] // COMENTADO: Mostrar borradores recientes
          ]
        ],
        {
          'fields': [
            'id', 'name', 'partner_id', 'date_order', 'state',
            'amount_total', 'order_line', 'receipt_status', 
            'invoice_status', 'date_planned', 'notes',
            'partner_ref', 'amount_untaxed', 'amount_tax',
            'currency_id', 'company_id',
          ],
          'order': 'date_order desc, id desc',
          'limit': 30,  // ✅ Reducido de 100 a 30
        }
      ],
    });

    final orders = (result as List).cast<Map<String, dynamic>>();
    print('📦 Órdenes encontradas en Odoo: ${orders.length}');
    
    // ✅ **OPTIMIZACIÓN**: Procesar detalles de líneas en paralelo
    final List<Map<String, dynamic>> ordersWithDetails = [];
    
    for (var order in orders) {
      try {
        // ✅ Procesar order_line directamente del search_read
        if (order['order_line'] != null && (order['order_line'] as List).isNotEmpty) {
          // Convertir correctamente List<dynamic> a List<int>
          final lineIds = (order['order_line'] as List)
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
          
          if (lineIds.isNotEmpty) {
            final lineDetails = await _getOrderLineDetails(lineIds);
            order['order_line_details'] = lineDetails;
          } else {
            order['order_line_details'] = [];
          }
        } else {
          order['order_line_details'] = [];
        }
        
        // ✅ Agregar campos procesados
        order['supplier_name'] = order['partner_id'] is List && (order['partner_id'] as List).length > 1 
            ? (order['partner_id'] as List)[1] 
            : 'Sin proveedor';
        order['supplier_id'] = order['partner_id'] is List && (order['partner_id'] as List).isNotEmpty
            ? (order['partner_id'] as List)[0]
            : null;
        
        // 🔍 DEBUG: Verificar campos financieros
        print('   💰 Orden ${order['name']} - Campos financieros:');
        print('      amount_untaxed: ${order['amount_untaxed']} (${order['amount_untaxed'].runtimeType})');
        print('      amount_tax: ${order['amount_tax']} (${order['amount_tax'].runtimeType})');
        print('      amount_total: ${order['amount_total']} (${order['amount_total'].runtimeType})');
        
        ordersWithDetails.add(order);
        
        print('   ✅ ${order['name']}: ${(order['order_line_details'] as List).length} líneas');
      } catch (e) {
        print('   ❌ Error procesando orden ${order['id']}: $e');
        order['order_line_details'] = [];
        ordersWithDetails.add(order);
      }
    }
    
    print('✅ Total órdenes procesadas: ${ordersWithDetails.length}');
    
    return ordersWithDetails;
    
  } catch (e) {
    print('❌ Error obteniendo órdenes de compra: $e');
    return [];
  }
}
 Future<List<Map<String, dynamic>>> _getOrderLineDetails(List<int> lineIds) async {
  try {
    if (lineIds.isEmpty) return [];
    
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order.line',
        'search_read',
        [
          [['id', 'in', lineIds]]
        ],
        {
          'fields': [
            'id', 'product_id', 'name', 'product_qty', 
            'price_unit', 'price_subtotal', 'taxes_id',
            'order_id', 'product_uom', 'date_planned',
            'product_uom_qty', 'qty_received', 'qty_invoiced',
            'price_total',  // Precio total con impuestos
          ],
        }
      ],
    });

    final lines = (result as List).cast<Map<String, dynamic>>();
    
    print('🔍 _getOrderLineDetails - Líneas encontradas: ${lines.length}');
    
    return lines.map((line) {
      // DEBUG: Mostrar datos crudos
      print('   📦 Línea ID: ${line['id']}');
      print('      product_id: ${line['product_id']}');
      print('      name: ${line['name']}');
      print('      product_qty: ${line['product_qty']}');
      print('      price_unit: ${line['price_unit']}');
      print('      price_subtotal: ${line['price_subtotal']}');
      
      // El campo 'product_id' viene como [id, "nombre del producto"]
      String productName = 'Sin artículo especificado';
      int? productId;
      
      if (line['product_id'] is List && (line['product_id'] as List).isNotEmpty) {
        final productData = line['product_id'] as List;
        if (productData.length > 1) {
          productId = productData[0] as int?;
          productName = productData[1] as String;
        }
      }
      
      // Usar 'name' de la línea si está disponible, sino usar el nombre del producto
      final displayName = line['name']?.toString() ?? productName;
      
      // ✅ CALCULAR PRECIO UNITARIO SIN ITBIS
      final qty = (line['product_qty'] ?? 1.0) as num;
      final subtotal = (line['price_subtotal'] ?? 0.0) as num;
      final priceWithoutTax = qty > 0 ? (subtotal / qty) : 0.0;
      
      print('      ✅ Precio unitario SIN ITBIS: ${priceWithoutTax.toStringAsFixed(2)}');
      
      return {
        'id': line['id'],
        'product_id': productId,
        'product_name': productName,
        'name': displayName,  // Nombre a mostrar en la UI
        'quantity': qty.toDouble(),
        'price_unit': priceWithoutTax.toDouble(),  // ✅ SIN ITBIS
        'price_subtotal': subtotal.toDouble(),
        'price_total': (line['price_total'] ?? subtotal).toDouble(),
        'uom': line['product_uom'] is List && (line['product_uom'] as List).length > 1
            ? (line['product_uom'] as List)[1]
            : 'Unidad',
        'qty_received': line['qty_received'] ?? 0.0,
        'qty_invoiced': line['qty_invoiced'] ?? 0.0,
        'description': displayName,  // ✅ AGREGAR campo description
      };
    }).toList();
    
  } catch (e) {
    print('❌ Error obteniendo detalles de líneas: $e');
    return [];
  }
}



Future<List<Map<String, dynamic>>> getPurchaseOrdersByState(PurchaseOrderState state) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order',
        'search_read',
        [
          [['state', '=', state.value]]
        ],
        {
          'fields': ['id', 'name', 'partner_id', 'state', 'amount_total'],
          'limit': 10,
        }
      ],
    });

    return (result as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('❌ Error obteniendo órdenes por estado: $e');
    return [];
  }
}
Future<List<Map<String, dynamic>>> getSuppliers() async {
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
          [['supplier_rank', '>', 0]] // Solo proveedores
        ],
        {
          'fields': ['id', 'name', 'email', 'phone', 'vat'],
          'limit': 100,
        }
      ],
    });

    return (result as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('❌ Error obteniendo proveedores: $e');
    return [];
  }
}
Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order',
        'read',
        [
          [orderId]
        ],
        {
          'fields': [
            'id', 'name', 'partner_id', 'date_order', 'state',
            'amount_total', 'order_line', 'receipt_status', 
            'invoice_status', 'date_planned', 'notes',
            'partner_ref', 'currency_id', 'amount_untaxed', 'amount_tax'
          ],
        }
      ],
    });

    final orders = (result as List).cast<Map<String, dynamic>>();
    if (orders.isEmpty) return {};
    
    final order = orders.first;
    
    print('📋 Obteniendo detalles para orden ${order['name']} (ID: $orderId)');
    
    // ✅ **FORZAR OBTENCIÓN DE LÍNEAS INCLUSO SI EL CAMPO VIENE VACÍO**
    if (order['order_line'] != null && (order['order_line'] as List).isNotEmpty) {
      print('   📦 Tiene ${(order['order_line'] as List).length} líneas en order_line');
      
      // ✅ FIX: Convertir correctamente List<dynamic> a List<int>
      final lineIds = (order['order_line'] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
      
      if (lineIds.isNotEmpty) {
        final lineDetails = await _getOrderLineDetails(lineIds);
        order['order_line_details'] = lineDetails;
        print('   ✅ Se obtuvieron ${lineDetails.length} detalles de líneas');
      } else {
        print('   ⚠️ No se pudieron convertir IDs de líneas');
        order['order_line_details'] = [];
      }
    } else {
      print('   ⚠️ No hay líneas en order_line, buscando directamente...');
      // Si no hay líneas, intentar buscar directamente
      try {
        final directLines = await _searchOrderLinesDirectly(orderId);
        order['order_line_details'] = directLines;
        print('   🔍 Se encontraron ${directLines.length} líneas directamente');
      } catch (e) {
        print('   ❌ Error buscando líneas directamente: $e');
        order['order_line_details'] = [];
      }
    }
    
    // ✅ Calcular totales si no están presentes
    if (order['amount_total'] == null || order['amount_total'] == 0) {
      final lineDetails = order['order_line_details'] ?? [];
      final total = lineDetails.fold(0.0, (sum, line) => sum + (line['price_total'] ?? 0.0));
      order['amount_total'] = total;
    }
    
    return order;
    
  } catch (e) {
    print('❌ Error obteniendo detalles de orden $orderId: $e');
    return {};
  }
}
// ✅ NUEVO MÉTODO: Buscar líneas directamente
Future<List<Map<String, dynamic>>> _searchOrderLinesDirectly(int orderId) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order.line',
        'search_read',
        [
          [['order_id', '=', orderId]]
        ],
        {
          'fields': [
            'id', 'product_id', 'name', 'product_qty', 
            'price_unit', 'price_subtotal', 'taxes_id',
            'order_id', 'product_uom', 'date_planned',
            'product_uom_qty', 'qty_received', 'qty_invoiced',
            'price_total',
          ],
        }
      ],
    });

    final lines = (result as List).cast<Map<String, dynamic>>();
    
    return lines.map((line) {
      String productName = 'Sin artículo especificado';
      int? productId;
      
      if (line['product_id'] is List && (line['product_id'] as List).isNotEmpty) {
        final productData = line['product_id'] as List;
        if (productData.length > 1) {
          productId = productData[0] as int?;
          productName = productData[1] as String;
        }
      }
      
      final displayName = line['name']?.toString() ?? productName;
      
      return {
        'id': line['id'],
        'product_id': productId,
        'product_name': productName,
        'name': displayName,
        'quantity': line['product_qty'] ?? 0.0,  // ✅ Usar product_qty
        'price_unit': line['price_unit'] ?? 0.0,
        'price_subtotal': line['price_subtotal'] ?? 0.0,
        'price_total': line['price_total'] ?? 0.0,
        'uom': line['product_uom'] is List && (line['product_uom'] as List).length > 1
            ? (line['product_uom'] as List)[1]
            : 'Unidad',
        'qty_received': line['qty_received'] ?? 0.0,
        'qty_invoiced': line['qty_invoiced'] ?? 0.0,
        'description': displayName,
      };
    }).toList();
    
  } catch (e) {
    print('❌ Error buscando líneas directamente: $e');
    return [];
  }
}

 Future<void> _verificarCreacionOrdenOdoo(int orderId) async {
    try {
      print('🔍 VERIFICANDO ORDEN EN ODDO: ID $orderId');
      
      // Verificar si la orden existe en Odoo
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'read',
          [
            [orderId]
          ],
          {
            'fields': ['id', 'name', 'state', 'order_line', 'amount_total'],
          }
        ],
      });
      
      final ordenes = (result as List).cast<Map<String, dynamic>>();
      if (ordenes.isEmpty) {
        print('❌ Orden $orderId NO encontrada en Odoo');
        return;
      }
      
      final orden = ordenes.first;
      print('✅ Orden encontrada en Odoo:');
      print('   ID: ${orden['id']}');
      print('   Nombre: ${orden['name']}');
      print('   Estado: ${orden['state']}');
      print('   Líneas: ${orden['order_line']}');
      print('   Total: ${orden['amount_total']}');
      
      // Verificar líneas de la orden
      if (orden['order_line'] != null && (orden['order_line'] as List).isNotEmpty) {
        print('🔍 Verificando líneas de la orden...');
        
        final lineResult = await odooService.callKw({
          'service': 'object',
          'method': 'execute_kw',
          'args': [
            odooService.dbName,
            odooService.uid,
            odooService.password,
            'purchase.order.line',
            'search_read',
            [
              [['order_id', '=', orderId]]
            ],
            {
              'fields': ['id', 'product_id', 'name', 'product_qty', 'price_unit'],
            }
          ],
        });
        
        final lineas = (lineResult as List).cast<Map<String, dynamic>>();
        print('   📦 Líneas encontradas: ${lineas.length}');
        
        for (var linea in lineas) {
          print('      - ${linea['name']} x${linea['product_qty']} = \$${linea['price_unit']}');
        }
      } else {
        print('❌ La orden NO TIENE LÍNEAS en Odoo');
      }
      
    } catch (e) {
      print('❌ Error verificando orden en Odoo: $e');
    }
  }

  Future<Map<String, dynamic>> createPurchaseOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
    String? datePlanned,
    String? notes,
  }) async {
    try {
      // DEBUG: Mostrar datos que se enviarán
      print('🎯 CREANDO ORDEN DE COMPRA EN ODDO:');
      print('   Proveedor ID: $partnerId');
      print('   Líneas: ${orderLines.length}');
      
      for (var i = 0; i < orderLines.length; i++) {
        final line = orderLines[i];
        print('      ${i + 1}. Producto ID: ${line['product_id']}');
        print('         Cantidad: ${line['product_qty']}');
        print('         Precio: ${line['price_unit']}');
        print('         Nombre: ${line['name']}');
      }
      
      // Preparar líneas de orden
      final orderLineValues = orderLines.map((line) {
        return [
          0, 0, {
            'product_id': line['product_id'],
            'product_qty': line['product_qty'],
            'price_unit': line['price_unit'],
            'name': line['name'] ?? 'Product',
          }
        ];
      }).toList();

      // ✅ OBTENER LA COMPAÑÍA SELECCIONADA DE PREFERENCES
      final prefs = await SharedPreferences.getInstance();
      final selectedCompanyIdStr = prefs.getString('selected_company_id');
      int? companyId;
      if (selectedCompanyIdStr != null && selectedCompanyIdStr.isNotEmpty) {
        companyId = int.tryParse(selectedCompanyIdStr);
      }

      // ✅ BUSCAR PICKING_TYPE_ID (Deliver To) PARA LA COMPAÑÍA
      int? pickingTypeId;
      try {
        final List<dynamic> domain = [
          ['code', '=', 'incoming']
        ];
        if (companyId != null) {
          domain.add(['company_id', '=', companyId]);
        }
        
        final pickingTypesList = await odooService.callKw({
          'service': 'object',
          'method': 'execute_kw',
          'args': [
            odooService.dbName,
            odooService.uid,
            odooService.password,
            'stock.picking.type',
            'search_read',
            [domain],
            {
              'fields': ['id'],
              'limit': 1,
            }
          ],
        });
        
        if (pickingTypesList is List && pickingTypesList.isNotEmpty) {
          pickingTypeId = pickingTypesList.first['id'] as int;
          print('   🚚 Default picking_type_id encontrado: $pickingTypeId');
        } else {
          // Si no encuentra de la compañía, intentar sin filtrar por compañía
          final fallbackTypes = await odooService.callKw({
            'service': 'object',
            'method': 'execute_kw',
            'args': [
              odooService.dbName,
              odooService.uid,
              odooService.password,
              'stock.picking.type',
              'search_read',
              [[['code', '=', 'incoming']]],
              {'fields': ['id'], 'limit': 1}
            ],
          });
          if (fallbackTypes is List && fallbackTypes.isNotEmpty) {
            pickingTypeId = fallbackTypes.first['id'] as int;
            print('   🚚 Fallback picking_type_id encontrado: $pickingTypeId');
          } else {
             print('   ⚠️ No se encontró picking_type_id para receipts');
          }
        }
      } catch (e) {
        print('   ❌ Error obteniendo picking_type_id: $e');
      }

      final Map<String, dynamic> values = {
        'partner_id': partnerId,
        'order_line': orderLineValues,
        'date_planned': datePlanned ?? _getDefaultDeliveryDate(),
        'notes': notes ?? 'Creada desde app móvil',
      };

      if (companyId != null) {
        values['company_id'] = companyId;
      }
      
      if (pickingTypeId != null) {
        values['picking_type_id'] = pickingTypeId;
      }

      print('📤 Enviando datos a Odoo:');
      print('   Valores: $values');

      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'create',
          [values]
        ],
      });

      print('✅ Orden creada en Odoo con ID: $result');
      
      // Verificar inmediatamente después de crear
      if (result is int) {
        await _verificarCreacionOrdenOdoo(result);
      }

      return {'success': true, 'order_id': result};
    } catch (e) {
      print('❌ Error creando orden en Odoo: $e');
      print('   Stack trace: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmPurchaseOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_confirm',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

Future<Map<String, dynamic>> sendPurchaseOrder(int orderId) async {
  try {
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order',
        'write',  // ✅ USAR write
        [
          [orderId],
          {'state': 'sent'}  // ✅ CAMBIAR ESTADO A 'sent'
        ]
      ],
    });
    return {'success': true, 'result': result};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

  Future<Map<String, dynamic>> markAsReceived(int orderId) async {
    try {
      // Para órdenes de compra, marcar como hecho/done
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_done',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelPurchaseOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_cancel',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  String _getDefaultDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 7));
    return '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
  }
}

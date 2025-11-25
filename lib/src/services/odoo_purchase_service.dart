import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';


class OdooPurchaseService {
  final OdooServiceEnhanced odooService;

  OdooPurchaseService(this.odooService);

  // 🎯 MÉTODO PARA OBTENER ÓRDENES DE COMPRA
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
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
            [] // Dominio vacío para todas las órdenes
          ],
          {
            'fields': [
              'id', 'name', 'partner_id', 'date_order', 'state',
              'amount_total', 'order_line', 'receipt_status', 
              'invoice_status', 'date_planned'
            ],
            'limit': 50,
          }
        ],
      });

      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo órdenes de compra: $e');
      return [];
    }
  }

  // 🎯 MÉTODO PARA OBTENER PROVEEDORES
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

  // 🎯 MÉTODO PARA CONFIRMAR ORDEN DE COMPRA
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

  // 🎯 MÉTODO PARA CANCELAR ORDEN DE COMPRA
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

  // 🎯 MÉTODO PARA OBTENER DETALLES DE UNA ORDEN
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
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
            [['id', '=', orderId]]
          ],
          {
            'fields': [
              'id', 'name', 'partner_id', 'date_order', 'state',
              'amount_total', 'order_line', 'receipt_status', 
              'invoice_status', 'date_planned', 'notes'
            ],
          }
        ],
      });

      final orders = (result as List).cast<Map<String, dynamic>>();
      return orders.isNotEmpty ? orders.first : null;
    } catch (e) {
      print('❌ Error obteniendo detalles de orden: $e');
      return null;
    }
  }
}

// ✅ EXTENSIÓN PARA CREAR ÓRDENES DE COMPRA
extension PurchaseServiceExtension on OdooPurchaseService {


  Future<Map<String, dynamic>> createPurchaseOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
    String? datePlanned,
    String? notes,
  }) async {
    try {
      print('🚀 Creando orden de compra en Odoo...');
      print('   Partner ID: $partnerId');
      print('   Líneas de orden: ${orderLines.length}');
      
      // 🎯 CORREGIR: PREPARAR LÍNEAS DE ORDEN CORRECTAMENTE
      final orderLineValues = orderLines.map((line) {
        return [
          0, // 0 indica creación de nueva línea
          0, // 0 indica que no es una línea existente
          {
            'product_id': line['product_id'],
            'product_qty': line['product_qty'],
            'price_unit': line['price_unit'],
            'name': line['name'] ?? 'Producto',
          }
        ];
      }).toList();

      // 🎯 CORREGIR: ESTRUCTURA DE DATOS PARA ODDO
      final values = {
        'partner_id': partnerId,
        'order_line': orderLineValues,
        'date_planned': datePlanned ?? _getDefaultDeliveryDate(),
        'notes': notes,
      };

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
          [values] // ✅ IMPORTANTE: Enviar como lista
        ],
      });

      print('✅ Orden de compra creada exitosamente - ID: $result');
      return {'success': true, 'order_id': result};
      
    } catch (e) {
      print('❌ Error creando orden de compra: $e');
      print('   StackTrace: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    }
  }

  String _getDefaultDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 7));
    return '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
  }
}
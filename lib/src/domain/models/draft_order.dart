// lib/domain/models/draft_order.dart
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';

enum OrderType {
  venta,
  compra
}

class DraftOrder {
  final String id;
  final OrderType type;
  final DateTime createdAt;
  final Customer? customer;
  final Map<String, dynamic>? proveedor;
  final List<ArticuloItem> articulos;
  final double total;
  final String? notas;
  final String? fechaEntrega;

  DraftOrder({
    required this.id,
    required this.type,
    required this.createdAt,
    this.customer,
    this.proveedor,
    required this.articulos,
    required this.total,
    this.notas,
    this.fechaEntrega,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == OrderType.venta ? 'venta' : 'compra',
      'createdAt': createdAt.toIso8601String(),
      'customer': customer?.toJson(),
      'proveedor': proveedor,
      'articulos': articulos.map((a) => a.toJson()).toList(),
      'total': total,
      'notas': notas,
      'fechaEntrega': fechaEntrega,
    };
  }

  factory DraftOrder.fromJson(Map<String, dynamic> json) {
    final articulosList = (json['articulos'] as List<dynamic>)
        .map((item) => ArticuloItem.fromJson(item as Map<String, dynamic>))
        .toList();
    
    Customer? customer;
    if (json['customer'] != null && json['customer'] is Map) {
      customer = Customer.fromJsonMap(
        Map<String, dynamic>.from(json['customer'] as Map<dynamic, dynamic>)
      );
    }
    
    return DraftOrder(
      id: json['id'] as String,
      type: json['type'] == 'venta' ? OrderType.venta : OrderType.compra,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customer: customer,
      proveedor: json['proveedor'] != null 
          ? Map<String, dynamic>.from(json['proveedor'] as Map<dynamic, dynamic>)
          : null,
      articulos: articulosList,
      total: (json['total'] as num).toDouble(),
      notas: json['notas'] as String?,
      fechaEntrega: json['fechaEntrega'] as String?,
    );
  }

  String get displayType => type == OrderType.venta ? 'Venta' : 'Compra';
  
  String get displayCustomer => type == OrderType.venta
      ? customer?.name ?? 'Sin cliente'
      : proveedor?['name'] ?? 'Sin proveedor';
      
  int get totalItems => articulos.fold(0, (sum, item) => sum + item.cantidad);
}

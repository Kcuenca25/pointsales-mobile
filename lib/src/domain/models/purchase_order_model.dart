// lib/src/domain/models/purchase_order_model.dart
import 'package:ecomerce_app/src/domain/models/purchase_order_state.dart';
import 'package:flutter/material.dart';

class PurchaseOrder {
  final int id;
  final String name;
  final PurchaseOrderState state;
  final int partnerId;
  final String partnerName;
  final DateTime dateOrder;
  final double amountTotal;
  final DateTime? datePlanned;
  final List<int> orderLineIds;
  
  PurchaseOrder({
    required this.id,
    required this.name,
    required this.state,
    required this.partnerId,
    required this.partnerName,
    required this.dateOrder,
    required this.amountTotal,
    this.datePlanned,
    this.orderLineIds = const [],
  });
  
  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final partner = json['partner_id'] is List 
        ? json['partner_id'] 
        : [0, ''];
        
    return PurchaseOrder(
      id: json['id'],
      name: json['name'] ?? '',
      state: PurchaseOrderState.fromString(json['state'] ?? 'draft'),
      partnerId: partner.isNotEmpty ? partner[0] : 0,
      partnerName: partner.length > 1 ? partner[1] : '',
      dateOrder: DateTime.parse(json['date_order'] ?? DateTime.now().toString()),
      amountTotal: (json['amount_total'] ?? 0.0).toDouble(),
      datePlanned: json['date_planned'] != null 
          ? DateTime.parse(json['date_planned'])
          : null,
      orderLineIds: (json['order_line'] is List 
          ? List<int>.from(json['order_line'])
          : []),
    );
  }
  
  // Métodos de utilidad
  bool get isDraft => state == PurchaseOrderState.draft;
  bool get isConfirmed => state == PurchaseOrderState.purchase;
  bool get isDone => state == PurchaseOrderState.done;
  bool get isCanceled => state == PurchaseOrderState.cancel;
  
  String get statusText => state.displayName;
  Color get statusColor {
    switch (state) {
      case PurchaseOrderState.draft:
        return Colors.orange;
      case PurchaseOrderState.sent:
        return Colors.blue;
      case PurchaseOrderState.purchase:
        return Colors.green;
      case PurchaseOrderState.done:
        return Colors.purple;
      case PurchaseOrderState.cancel:
        return Colors.red;
    }
  }
}

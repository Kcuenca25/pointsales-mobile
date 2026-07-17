import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';

enum InventoryStatus { matched, discrepancy, missing }

class InventoryItem {
  final int id;
  final String name;
  final String sku;
  final String category;
  int currentStock;
  int physicalCount;
  final double cost;
  final double price;
  InventoryStatus status;
  final bool managesStock; 
  DateTime? lastUpdated;
  String? lastUpdatedBy;
  final Product? product; 

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.currentStock,
    required this.physicalCount,
    required this.cost,
    required this.price,
    required this.status,
    this.lastUpdated,
    this.lastUpdatedBy,
    this.product, 
    this.managesStock = true,
  });

  // ✅ FACTORY PARA CREAR DESDE PRODUCTO
  factory InventoryItem.fromProduct(Product product, int currentStock) {
    return InventoryItem(
      id: product.id,
      name: product.name,
      sku: product.defaultCode ?? 'N/A',
      category: product.categoryName ?? 'Sin categoría',
      currentStock: currentStock,
      physicalCount: currentStock, // Inicia igual al stock actual
      cost: product.standardPrice ?? 0.0,
      price: product.listPrice,
      status: InventoryStatus.matched,
      product: product, // ✅ GUARDAR REFERENCIA AL PRODUCTO
    );
  }

  InventoryItem copyWith({
    int? physicalCount,
    int? currentStock,
    InventoryStatus? status,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      sku: sku,
      category: category,
      currentStock: currentStock ?? this.currentStock,
      physicalCount: physicalCount ?? this.physicalCount,
      cost: cost,
      price: price,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      product: product, // ✅ MANTENER PRODUCTO
    );
  }
}

class InventoryBalance {
  final int totalItems;
  final int matchedItems;
  final int discrepancyItems;
  final int missingItems;
  final double totalValueDifference;
  final double accuracyRate;
  final DateTime calculationDate;

  InventoryBalance({
    required this.totalItems,
    required this.matchedItems,
    required this.discrepancyItems,
    required this.missingItems,
    required this.totalValueDifference,
    required this.accuracyRate,
    required this.calculationDate,
  });
}

class NuevaTomaInventario {
  final int id;
  final DateTime fechaCreacion;
  final String creadoPor;
  final String cliente;
  final String ubicacion;
  final String descripcion;
  final List<InventoryItem> items;
  final bool estaCompletada;

  NuevaTomaInventario({
    required this.id,
    required this.fechaCreacion,
    required this.creadoPor,
    required this.cliente,
    required this.ubicacion,
    required this.descripcion,
    required this.items,
    this.estaCompletada = false,
  });
}

class InventoryUpdate {
  final String id;
  final DateTime timestamp;
  final String updatedBy;
  final String customerName;
  final List<InventoryUpdateItem> items;
  final String notes;
  final InventoryBalance balance;

  InventoryUpdate({
    required this.id,
    required this.timestamp,
    required this.updatedBy,
    required this.customerName,
    required this.items,
    required this.notes,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'customerName': customerName,
      'notes': notes,
      'items': items.map((item) => item.toMap()).toList(),
      'balance': {
        'totalItems': balance.totalItems,
        'matchedItems': balance.matchedItems,
        'discrepancyItems': balance.discrepancyItems,
        'missingItems': balance.missingItems,
        'totalValueDifference': balance.totalValueDifference,
        'accuracyRate': balance.accuracyRate,
        'calculationDate': balance.calculationDate.toIso8601String(),
      },
    };
  }
}

class InventoryUpdateItem {
  final int productId;
  final String productName;
  final String sku;
  final String category;
  final int previousStock;
  final int newStock;
  final int difference;
  final String action;
  final double price;
  final double cost;
  final Product? product; // ✅ REFERENCIA AL PRODUCTO

  InventoryUpdateItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.category,
    required this.previousStock,
    required this.newStock,
    required this.difference,
    required this.action,
    required this.price,
    required this.cost,
    this.product, // ✅ AGREGAR PRODUCTO
  });

  // ✅ FACTORY PARA CREAR DESDE INVENTORYITEM
  factory InventoryUpdateItem.fromInventoryItem(InventoryItem item, int newStock) {
    return InventoryUpdateItem(
      productId: item.id,
      productName: item.name,
      sku: item.sku,
      category: item.category,
      previousStock: item.currentStock,
      newStock: newStock,
      difference: newStock - item.currentStock,
      action: newStock == 0 ? 'removed' : 
              newStock > item.currentStock ? 'added' : 'updated',
      price: item.price,
      cost: item.cost,
      product: item.product, // ✅ PASAR PRODUCTO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'category': category,
      'previousStock': previousStock,
      'newStock': newStock,
      'difference': difference,
      'action': action,
      'price': price,
      'cost': cost,
    };
  }

  double get valueDifference => difference * price;
}

// Modelo para productos disponibles
class Producto {
  final int id;
  final String nombre;
  final String sku;
  final String categoria;
  final double precio;
  final double costo;
  final int stockActual;

  Producto({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.categoria,
    required this.precio,
    required this.costo,
    this.stockActual = 0,
  });
}

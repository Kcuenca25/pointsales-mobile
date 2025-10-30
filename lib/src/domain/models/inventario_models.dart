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
  });
}

class InventoryBalance {
  final int totalItems;
  final int matchedItems;
  final int discrepancyItems;
  final int missingItems;
  final double totalValueDifference;
  final double accuracyRate;

  InventoryBalance({
    required this.totalItems,
    required this.matchedItems,
    required this.discrepancyItems,
    required this.missingItems,
    required this.totalValueDifference,
    required this.accuracyRate,
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
  final int id;
  final DateTime timestamp;
  final String updatedBy;
  final String customerName;
  final List<InventoryUpdateItem> items;
  final String notes;

  InventoryUpdate({
    required this.id,
    required this.timestamp,
    required this.updatedBy,
    required this.customerName,
    required this.items,
    this.notes = '',
  });
}

class InventoryUpdateItem {
  final int productId;
  final String productName;
  final String sku;
  final int previousStock;
  final int newStock;
  final int difference;
  final String action;

  InventoryUpdateItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.previousStock,
    required this.newStock,
    required this.difference,
    required this.action,
  });
}

class Producto {
  final int id;
  final String nombre;
  final String sku;
  final String categoria;
  final double precio;
  final double costo;

  Producto({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.categoria,
    required this.precio,
    required this.costo,
  });
}
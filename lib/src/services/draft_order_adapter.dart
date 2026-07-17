// lib/services/draft_order_adapter.dart
import 'package:hive/hive.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';

class DraftOrderAdapter extends TypeAdapter<DraftOrder> {
  @override
  final int typeId = 101; // IMPORTANTE: debe coincidir con @HiveType

  @override
  DraftOrder read(BinaryReader reader) {
    final id = reader.readString();
    final typeIndex = reader.readByte();
    final type = OrderType.values[typeIndex];
    final createdAt = DateTime.parse(reader.readString());
    
    // Leer customer
    final hasCustomer = reader.readBool();
    final customer = hasCustomer ? 
        Customer.fromJsonMap(Map<String, dynamic>.from(reader.readMap().cast<dynamic, dynamic>())) : 
        null;
    
    // Leer proveedor
    final hasProveedor = reader.readBool();
    final proveedor = hasProveedor ? 
        Map<String, dynamic>.from(reader.readMap().cast<dynamic, dynamic>()) : 
        null;
    
    // Leer articulos
    final articulosList = reader.readList().cast<Map<dynamic, dynamic>>();
    final articulos = articulosList
        .map((item) => ArticuloItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    
    final total = reader.readDouble();
    final notas = reader.readString();
    final fechaEntrega = reader.readString();
    
    return DraftOrder(
      id: id,
      type: type,
      createdAt: createdAt,
      customer: customer,
      proveedor: proveedor,
      articulos: articulos,
      total: total,
      notas: notas.isEmpty ? null : notas,
      fechaEntrega: fechaEntrega.isEmpty ? null : fechaEntrega,
    );
  }

  @override
  void write(BinaryWriter writer, DraftOrder obj) {
    writer.writeString(obj.id);
    writer.writeByte(obj.type.index);
    writer.writeString(obj.createdAt.toIso8601String());
    
    // Escribir customer
    writer.writeBool(obj.customer != null);
    if (obj.customer != null) {
      writer.writeMap(obj.customer!.toJson());
    }
    
    // Escribir proveedor
    writer.writeBool(obj.proveedor != null);
    if (obj.proveedor != null) {
      writer.writeMap(obj.proveedor!);
    }
    
    // Escribir articulos
    writer.writeList(obj.articulos.map((a) => a.toJson()).toList());
    
    writer.writeDouble(obj.total);
    writer.writeString(obj.notas ?? '');
    writer.writeString(obj.fechaEntrega ?? '');
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
